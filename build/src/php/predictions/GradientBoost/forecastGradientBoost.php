<?php

// forecastGradientBoost.php — thin bridge to Python Optuna/XGBoost forecast (NDJSON stream)

ini_set('display_errors', 0);
ini_set('log_errors', 1);
error_reporting(E_ALL);

$gbStreamStarted = false;
$gbProc = null;

register_shutdown_function(function (): void {
    global $gbProc;
    if (is_resource($gbProc)) {
        killGradientBoostProcess($gbProc);
        $gbProc = null;
    }
});

function beginGradientBoostStream(): void
{
    global $gbStreamStarted;
    if ($gbStreamStarted) {
        return;
    }
    $gbStreamStarted = true;
    while (ob_get_level() > 0) {
        ob_end_flush();
    }
    header('Content-Type: application/x-ndjson');
    header('Cache-Control: no-cache');
    header('X-Accel-Buffering: no');
    if (function_exists('apache_setenv')) {
        @apache_setenv('no-gzip', '1');
    }
    ini_set('zlib.output_compression', '0');
    ini_set('output_buffering', 'off');
}

function writeGradientBoostNdjson(array $payload): void
{
    beginGradientBoostStream();
    echo json_encode($payload, JSON_UNESCAPED_UNICODE) . "\n";
    if (function_exists('ob_flush')) {
        @ob_flush();
    }
    flush();
}

function writeGradientBoostResult(array $result): void
{
    writeGradientBoostNdjson(array_merge(['type' => 'result'], $result));
}

function killGradientBoostProcess($proc): void
{
    if (!is_resource($proc)) {
        return;
    }
    $status = @proc_get_status($proc);
    $pid = isset($status['pid']) ? (int) $status['pid'] : 0;
    if ($pid > 0 && defined('PHP_OS_FAMILY') && PHP_OS_FAMILY === 'Windows') {
        @exec('taskkill /PID ' . $pid . ' /T /F');
    }
    if ($pid > 0 && function_exists('posix_kill')) {
        @posix_kill($pid, 9);
    }
    @proc_terminate($proc, 9);
}

function consumeGradientBoostStderrLine(string $line, string &$stderrOther): void
{
    $trimmed = trim($line);
    if ($trimmed === '') {
        return;
    }
    $decoded = json_decode($trimmed, true);
    if (is_array($decoded) && isset($decoded['bar'], $decoded['pct'])) {
        writeGradientBoostNdjson([
            'type' => 'progress',
            'bar' => $decoded['bar'],
            'pct' => (int) $decoded['pct'],
            'message' => isset($decoded['message']) ? (string) $decoded['message'] : '',
        ]);
        return;
    }
    $stderrOther .= $trimmed . "\n";
}

function awaitGradientBoostProcess($proc, array $pipes, ?int $hardLimitSec = null): array
{
    stream_set_blocking($pipes[1], false);
    stream_set_blocking($pipes[2], false);

    $stdout = '';
    $stderrBuf = '';
    $stderrOther = '';
    $killed = false;
    $killReason = '';
    $started = time();

    while (true) {
        $status = proc_get_status($proc);
        if (empty($status['running'])) {
            break;
        }
        echo "\n";
        if (function_exists('ob_flush')) {
            @ob_flush();
        }
        flush();
        if (connection_aborted()) {
            killGradientBoostProcess($proc);
            $killed = true;
            $killReason = 'abort';
            break;
        }
        if ($hardLimitSec !== null && (time() - $started) >= $hardLimitSec) {
            killGradientBoostProcess($proc);
            $killed = true;
            $killReason = 'timeout';
            break;
        }
        $read = [$pipes[1], $pipes[2]];
        $write = null;
        $except = null;
        if (@stream_select($read, $write, $except, 0, 200000) > 0) {
            foreach ($read as $pipe) {
                $chunk = fread($pipe, 8192);
                if ($chunk === false || $chunk === '') {
                    continue;
                }
                if ($pipe === $pipes[1]) {
                    $stdout .= $chunk;
                    continue;
                }
                $stderrBuf .= $chunk;
                while (($pos = strpos($stderrBuf, "\n")) !== false) {
                    $line = substr($stderrBuf, 0, $pos);
                    $stderrBuf = substr($stderrBuf, $pos + 1);
                    consumeGradientBoostStderrLine($line, $stderrOther);
                }
            }
        }
    }

    if (!$killed) {
        $stdout .= (string) stream_get_contents($pipes[1]);
        $stderrBuf .= (string) stream_get_contents($pipes[2]);
    }

    while (($pos = strpos($stderrBuf, "\n")) !== false) {
        $line = substr($stderrBuf, 0, $pos);
        $stderrBuf = substr($stderrBuf, $pos + 1);
        consumeGradientBoostStderrLine($line, $stderrOther);
    }
    if ($stderrBuf !== '') {
        consumeGradientBoostStderrLine($stderrBuf, $stderrOther);
        $stderrBuf = '';
    }

    return [$stdout, $stderrOther, $killed, $killReason];
}

try {
    require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/secure_cookies.php';
    require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/connect_to_DB.php';
    require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/check_session.php';
    require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/auth_helpers.php';

    requirePrivilege($conn, 'money-tracker');
    $companyId = getCurrentCompanyId($conn);

    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        throw new Exception('Invalid request method.');
    }

    $body = json_decode(file_get_contents('php://input'), true);
    if (!is_array($body)) {
        throw new Exception('Invalid request body.');
    }

    $targetYear = isset($body['targetYear']) ? (int) $body['targetYear'] : 0;
    $numYears = isset($body['numYears']) ? (int) $body['numYears'] : 0;
    $plotType = isset($body['plotType']) ? (string) $body['plotType'] : '';
    $includeCurrentMonth = array_key_exists('includeCurrentMonth', $body)
        ? (bool) $body['includeCurrentMonth']
        : true;
    $trainingOverlays = isset($body['trainingOverlays']) && is_array($body['trainingOverlays'])
        ? $body['trainingOverlays']
        : new stdClass();
    $nTrials = isset($body['nTrials']) ? (int) $body['nTrials'] : 0;
    $pruner = isset($body['pruner']) ? strtolower((string) $body['pruner']) : '';
    $timeoutSec = null;
    if (array_key_exists('timeoutSec', $body) && $body['timeoutSec'] !== null && $body['timeoutSec'] !== '') {
        $timeoutSec = (int) $body['timeoutSec'];
    }

    if ($targetYear < 1 || $numYears < 1) {
        throw new Exception('Invalid forecast parameters.');
    }
    if (!in_array($plotType, ['Income', 'Expense', 'NetIncome'], true)) {
        throw new Exception('Invalid plot type.');
    }
    if (!in_array($nTrials, [50, 100, 200, 500], true)) {
        throw new Exception('Invalid Optuna trial count.');
    }
    if (!in_array($pruner, ['none', 'median', 'hyperband'], true)) {
        throw new Exception('Invalid Optuna pruner.');
    }
    $maxTimeoutSec = (99 * 3600) + (59 * 60);
    if ($timeoutSec !== null && ($timeoutSec < 60 || $timeoutSec > $maxTimeoutSec)) {
        throw new Exception('Invalid time cap.');
    }

    $thisYear = (int) date('Y');
    $currentMonth = (int) date('n');
    $startYear = $targetYear - $numYears;
    $minYear = min($startYear, $targetYear - 1) - 1;
    $maxYear = max($thisYear, $targetYear);

    $incomeStmt = $conn->prepare(
        "SELECT Source, Income, DateOfIncome FROM income
         WHERE companyID = ? AND YEAR(DateOfIncome) BETWEEN ? AND ? AND deletedAt IS NULL
         ORDER BY DateOfIncome"
    );
    $incomeStmt->bind_param('iii', $companyId, $minYear, $maxYear);
    $incomeStmt->execute();
    $incomeRows = $incomeStmt->get_result()->fetch_all(MYSQLI_ASSOC);
    $incomeStmt->close();

    $expenseStmt = $conn->prepare(
        "SELECT source, expense, DateOfExpense FROM expenses
         WHERE companyID = ? AND YEAR(DateOfExpense) BETWEEN ? AND ? AND deletedAt IS NULL
         ORDER BY DateOfExpense"
    );
    $expenseStmt->bind_param('iii', $companyId, $minYear, $maxYear);
    $expenseStmt->execute();
    $expenseRows = $expenseStmt->get_result()->fetch_all(MYSQLI_ASSOC);
    $expenseStmt->close();

    $payload = json_encode([
        'plotType' => $plotType,
        'targetYear' => $targetYear,
        'numYears' => $numYears,
        'thisYear' => $thisYear,
        'currentMonth' => $currentMonth,
        'includeCurrentMonth' => $includeCurrentMonth,
        'nTrials' => $nTrials,
        'pruner' => $pruner,
        'timeoutSec' => $timeoutSec,
        'incomeRows' => $incomeRows,
        'expenseRows' => $expenseRows,
        'trainingOverlays' => $trainingOverlays,
    ], JSON_UNESCAPED_UNICODE);

    if ($payload === false) {
        throw new Exception('Could not encode forecast payload.');
    }

    $script = dirname($_SERVER['DOCUMENT_ROOT']) . '/src/python/gradient_boost/forecast.py';
    if (!is_file($script)) {
        throw new Exception('Gradient Boost script not found.');
    }

    session_write_close();
    ignore_user_abort(true);
    set_time_limit(0);

    $python = 'python3';
    $descriptors = [
        0 => ['pipe', 'r'],
        1 => ['pipe', 'w'],
        2 => ['pipe', 'w'],
    ];
    $proc = proc_open([$python, $script], $descriptors, $pipes, null, null, ['bypass_shell' => true]);
    if (!is_resource($proc)) {
        throw new Exception('Could not start Gradient Boost process.');
    }

    $gbProc = $proc;
    beginGradientBoostStream();
    fwrite($pipes[0], $payload);
    fclose($pipes[0]);
    $hardLimitSec = $timeoutSec !== null ? $timeoutSec + 30 : null;
    [$stdout, $stderr, $killed, $killReason] = awaitGradientBoostProcess($proc, $pipes, $hardLimitSec);
    fclose($pipes[1]);
    fclose($pipes[2]);
    $code = proc_close($proc);
    $gbProc = null;
    if ($killed) {
        if ($killReason === 'timeout') {
            writeGradientBoostResult([
                'success' => false,
                'errorMsg' => 'Forecast timed out.',
            ]);
        }
        exit();
    }

    $result = json_decode((string) $stdout, true);
    if (!is_array($result)) {
        throw new Exception($stderr !== '' ? $stderr : 'Gradient Boost returned invalid output.');
    }
    if (empty($result['success'])) {
        throw new Exception($result['errorMsg'] ?? 'Gradient Boost failed.');
    }
    if ($code !== 0 && empty($result['months'])) {
        throw new Exception($stderr !== '' ? $stderr : 'Gradient Boost process failed.');
    }

    writeGradientBoostResult([
        'success' => true,
        'months' => $result['months'],
        'incomeMonths' => $result['incomeMonths'] ?? null,
        'expenseMonths' => $result['expenseMonths'] ?? null,
        'partialYear' => $result['partialYear'] ?? false,
        'forecastFromMonth' => $result['forecastFromMonth'] ?? null,
        'incomeDiagnose' => $result['incomeDiagnose'] ?? null,
        'expenseDiagnose' => $result['expenseDiagnose'] ?? null,
    ]);
    exit();
} catch (Throwable $e) {
    logAppError($e);
    if (isDbUnavailable($e)) {
        respondDbUnavailable();
    }
    writeGradientBoostResult([
        'success' => false,
        'errorMsg' => $e->getMessage() ?: 'An error occured.',
    ]);
    exit();
}
