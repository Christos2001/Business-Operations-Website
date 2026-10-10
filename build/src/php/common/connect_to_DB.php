<?php

// connect_to_DB.php — database connection

// --- Initialization ---

    require_once __DIR__ . '/../logs/log_helpers.php';
    mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);
    ini_set('display_errors', 0);
    ini_set('log_errors', 1);
    error_reporting(E_ALL);

    $servername = getenv('DB_SERVER_NAME');
    $username = getenv('DB_USERNAME');
    $password = getenv('DB_PASS');
    $dbname = getenv('DB_NAME');

    try {
        $conn = new mysqli($servername, $username, $password, $dbname);
    } catch (Throwable $e) {
        logAppError($e);
        throw new Exception(DB_UNAVAILABLE_MESSAGE, DB_UNAVAILABLE_HTTP_CODE);
    }

