<?php

// logClientError.php — client-side error logging endpoint

// --- Initialization ---

    header('Content-Type: application/json');
    ini_set('display_errors', 0);
    error_reporting(E_ALL);

    require_once __DIR__ . '/log_helpers.php';

    try {
// --- validation ---

        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            throw new Exception('Invalid request method.');
        }

        $body = json_decode(file_get_contents('php://input'), true);
        if (!is_array($body)) {
            throw new Exception('Invalid request body.');
        }

        $message = isset($body['message']) ? trim((string) $body['message']) : '';
        $source = isset($body['source']) ? trim((string) $body['source']) : '';
        if ($message === '') {
            throw new Exception('Missing error message.');
        }

        $message = mb_substr($message, 0, 2000); // cap logged client payload
        $source = mb_substr($source, 0, 500);
        $detail = $source !== '' ? $message . ' [' . $source . ']' : $message; // tag client-reported source
// --- response ---

        logAppError(new Exception($detail), 'client');

        echo json_encode(['success' => true]);
        exit();
// --- error ---

    } catch (Throwable $e) {
        logAppError($e);
        echo json_encode(['success' => false]);
        exit();
    }
?>
