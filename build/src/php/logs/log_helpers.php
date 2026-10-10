<?php

// log_helpers.php — app error logging, DB unavailable handling

// --- Initialization ---

if (!defined('APP_ERROR_LOG_PATH')) {
    define('APP_ERROR_LOG_PATH', dirname(__DIR__, 3) . '/logs/appErrorLog.json'); // append-only JSON log
}

if (!defined('APP_LOG_PATH')) {
    define('APP_LOG_PATH', APP_ERROR_LOG_PATH);
}

if (!defined('PHP_ERROR_LOG_PATH')) {
    define('PHP_ERROR_LOG_PATH', dirname(__DIR__, 3) . '/logs/php_errors.log');
}

if (!defined('DB_UNAVAILABLE_HTTP_CODE')) {
    define('DB_UNAVAILABLE_HTTP_CODE', 503); // sentinel for DB-down responses
}

if (!defined('DB_UNAVAILABLE_MESSAGE')) {
    define('DB_UNAVAILABLE_MESSAGE', 'Try again later.'); // generic client-facing DB error
}

// --- DB unavailable ---

function isDbUnavailable(Throwable $e): bool {
    return (int) $e->getCode() === DB_UNAVAILABLE_HTTP_CODE
        || $e->getMessage() === DB_UNAVAILABLE_MESSAGE
        || $e->getMessage() === '0';
}

function respondDbUnavailable(string $format = 'json'): void { // json API vs HTML alert
    http_response_code(DB_UNAVAILABLE_HTTP_CODE);
    $message = DB_UNAVAILABLE_MESSAGE;

    if ($format === 'html') {
        echo '<script type="text/javascript">';
        echo 'alert(' . json_encode($message) . ');';
        echo 'window.history.back()';
        echo '</script>';
        exit();
    }

    if (!headers_sent()) {
        header('Content-Type: application/json');
    }

    echo json_encode(['success' => false, 'errorMsg' => $message]);
    exit();
}

function registerDbUnavailableExceptionHandler(): void {
    static $registered = false; // register exception handler once
    if ($registered) {
        return;
    }
    $registered = true;

    set_exception_handler(function (Throwable $e): void {
        if (!isDbUnavailable($e)) {
            return;
        }

        logAppError($e);

        $accept = $_SERVER['HTTP_ACCEPT'] ?? '';
        $contentType = $_SERVER['CONTENT_TYPE'] ?? '';
        $uri = $_SERVER['REQUEST_URI'] ?? '';
        $wantsJson = str_contains($accept, 'application/json')
            || str_contains($contentType, 'application/json')
            || str_starts_with($uri, '/php/'); // API routes get JSON 503

        respondDbUnavailable($wantsJson ? 'json' : 'html');
    });
}

// --- Log setup ---

function ensureAppLogDir(): void {
    $dir = dirname(APP_ERROR_LOG_PATH);
    if (!is_dir($dir)) {
        mkdir($dir, 0755, true);
    }
}

function initAppLogging(): void {
    static $initialized = false; // init logging paths once
    if ($initialized) {
        return;
    }
    $initialized = true;
    ensureAppLogDir();
    ini_set('log_errors', '1');
    ini_set('error_log', PHP_ERROR_LOG_PATH);
}

// --- Logging ---

function appendToAppErrorLog(array $entry): void {
    ensureAppLogDir();
    $path = APP_ERROR_LOG_PATH;
    $entries = [];

    if (is_file($path) && filesize($path) > 0) {
        $decoded = json_decode((string) file_get_contents($path), true);
        if (is_array($decoded)) {
            $entries = $decoded;
        }
    }

    $entries[] = $entry;

    file_put_contents(
        $path,
        json_encode($entries, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
        LOCK_EX
    );
}

function describeLoggedErrorMessage(Throwable $e): string {
    $msg = trim((string) $e->getMessage());
    $labels = [
        '0' => 'Database unavailable.',
        '1' => 'Internal error (code 1).',
        '2' => 'Wrong password.',
        '3' => 'Wrong username.',
    ];
    if ($msg === '') {
        return '(no error message)';
    }
    return $labels[$msg] ?? $msg;
}

function buildAppErrorContext(?string $note): ?string {
    $parts = [];
    if ($note !== null && $note !== '') {
        $parts[] = $note;
    }
    $method = $_SERVER['REQUEST_METHOD'] ?? '';
    $uri = $_SERVER['REQUEST_URI'] ?? '';
    if (strlen($uri) > 300) {
        $uri = substr($uri, 0, 300) . '…';
    }
    $request = trim($method . ' ' . $uri);
    if ($request !== '') {
        $parts[] = $request;
    }
    if ($parts === []) {
        return null;
    }
    return implode(' | ', $parts);
}

function logAppError(Throwable $e, ?string $context = null): void {
    initAppLogging();

    $entry = [
        'timestamp' => date('Y-m-d H:i:s'),
        'message' => describeLoggedErrorMessage($e),
        'file' => $e->getFile(),
        'line' => $e->getLine(),
        'type' => get_class($e),
    ];

    $resolvedContext = buildAppErrorContext($context);
    if ($resolvedContext !== null) {
        $entry['context'] = $resolvedContext;
    }

    appendToAppErrorLog($entry);
}

initAppLogging();
registerDbUnavailableExceptionHandler();
