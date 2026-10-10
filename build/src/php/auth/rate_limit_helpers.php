<?php

// rate_limit_helpers.php — IP rate limit storage, enforcement

// --- Initialization ---

require_once __DIR__ . '/../logs/log_helpers.php';

define('RATE_LIMIT_FILE', dirname(__DIR__, 3) . '/logs/auth_rate_limits.json'); // JSON bucket store
const RATE_LIMIT_MAX_ATTEMPTS = 5; // failures before cooldown
const RATE_LIMIT_MAX_ATTEMPTS_COMPANY_REQUEST = 10; // company request counts every submit
const RATE_LIMIT_WINDOW_SECONDS = 900; // rolling attempt window (15 min)
const RATE_LIMIT_COOLDOWN_SECONDS = 900; // block duration after max attempts

// --- Client IP helpers ---

function getClientIp(): string
{
    return $_SERVER['REMOTE_ADDR'] ?? 'unknown';
}

function rateLimitKey(string $action, string $ip, string $identifier): string
{
    return $action . ':' . $ip . ':' . strtolower(trim($identifier));
}

function getRateLimitMaxAttempts(string $action): int
{
    if ($action === 'company_request') {
        return RATE_LIMIT_MAX_ATTEMPTS_COMPANY_REQUEST;
    }

    return RATE_LIMIT_MAX_ATTEMPTS;
}

function rateLimitAttemptTimestamp($attempt): int
{
    if (is_array($attempt)) {
        return (int) ($attempt['ts'] ?? 0);
    }

    return (int) $attempt; // older files stored a bare unix time
}

function rateLimitAttemptRecord(int $timestamp): array
{
    return [
        'at' => date('Y-m-d H:i:s', $timestamp),
        'ts' => $timestamp,
    ];
}

function rateLimitBlockedUntilFields(int $blockedUntil): array
{
    if ($blockedUntil <= 0) {
        return [
            'blockedUntil' => 0,
            'blockedUntilAt' => null,
        ];
    }

    return [
        'blockedUntil' => $blockedUntil,
        'blockedUntilAt' => date('Y-m-d H:i:s', $blockedUntil),
    ];
}

// --- Storage helpers ---

function loadRateLimits(): array
{
    if (!is_file(RATE_LIMIT_FILE)) {
        return [];
    }

    $raw = file_get_contents(RATE_LIMIT_FILE);
    if ($raw === false || $raw === '') {
        return [];
    }

    $data = json_decode($raw, true);
    return is_array($data) ? $data : [];
}

function saveRateLimits(array $data): void
{
    $dir = dirname(RATE_LIMIT_FILE);
    if (!is_dir($dir)) {
        mkdir($dir, 0755, true);
    }

    file_put_contents(RATE_LIMIT_FILE, json_encode($data, JSON_PRETTY_PRINT), LOCK_EX);
}

function pruneRateLimits(array $data): array
{
    $now = time();
    foreach ($data as $key => $entry) {
        $blockedUntil = (int) ($entry['blockedUntil'] ?? 0); // expired cooldown marker
        $attempts = $entry['attempts'] ?? [];
        $attempts = array_values(array_filter($attempts, static function ($attempt) use ($now) {
            $ts = rateLimitAttemptTimestamp($attempt);
            return $ts > 0 && ($now - $ts) <= RATE_LIMIT_WINDOW_SECONDS; // drop attempts outside window
        }));
        $attempts = array_map(static function ($attempt) {
            return rateLimitAttemptRecord(rateLimitAttemptTimestamp($attempt));
        }, $attempts);

        if ($blockedUntil <= $now && count($attempts) === 0) {
            unset($data[$key]);
            continue;
        }

        $data[$key]['attempts'] = $attempts;
        $data[$key] = array_merge($data[$key], rateLimitBlockedUntilFields($blockedUntil));
    }

    return $data;
}

// --- Rate limit checks ---

function getRateLimitCooldownRemaining(string $action, string $ip, string $identifier): ?int
{
    $key = rateLimitKey($action, $ip, $identifier); // action:ip:identifier bucket
    $data = pruneRateLimits(loadRateLimits());

    if (!isset($data[$key])) {
        saveRateLimits($data);
        return null;
    }

    $blockedUntil = (int) ($data[$key]['blockedUntil'] ?? 0); // unix cooldown expiry
    $now = time();
    if ($blockedUntil > $now) {
        saveRateLimits($data);
        return $blockedUntil - $now;
    }

    saveRateLimits($data);
    return null;
}

function recordRateLimitFailure(string $action, string $ip, string $identifier): void
{
    $key = rateLimitKey($action, $ip, $identifier);
    $data = pruneRateLimits(loadRateLimits());
    $now = time();

    if (!isset($data[$key])) {
        $data[$key] = array_merge(['attempts' => []], rateLimitBlockedUntilFields(0));
    }

    $data[$key]['attempts'][] = rateLimitAttemptRecord($now);
    $data[$key]['attempts'] = array_values(array_filter(
        $data[$key]['attempts'],
        static function ($attempt) use ($now) {
            $ts = rateLimitAttemptTimestamp($attempt);
            return $ts > 0 && ($now - $ts) <= RATE_LIMIT_WINDOW_SECONDS;
        }
    ));

    if (count($data[$key]['attempts']) >= getRateLimitMaxAttempts($action)) {
        $data[$key] = array_merge($data[$key], rateLimitBlockedUntilFields($now + RATE_LIMIT_COOLDOWN_SECONDS)); // start cooldown window
        $data[$key]['attempts'] = [];
        logAppError(
            new Exception('Rate limit cooldown applied'),
            $action . ' ip=' . $ip . ' id=' . strtolower(trim($identifier))
        );
    }

    saveRateLimits($data);
}

function clearRateLimit(string $action, string $ip, string $identifier): void
{
    $key = rateLimitKey($action, $ip, $identifier);
    $data = loadRateLimits();
    unset($data[$key]);
    saveRateLimits($data);
}

function enforceRateLimitOrExit(string $action, string $ip, string $identifier): void
{
    $remaining = getRateLimitCooldownRemaining($action, $ip, $identifier);
    if ($remaining === null) {
        return;
    }

    $minutes = max(1, (int) ceil($remaining / 60));
    echo '<script type="text/javascript">';
    echo 'alert(' . json_encode("Too many attempts. Try again in about {$minutes}'.") . ');';
    echo 'window.history.back()';
    echo '</script>';
    exit();
}
