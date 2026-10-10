<?php

// check_session.php — login gate

// --- Initialization ---

    if (session_status() === PHP_SESSION_NONE) {
        session_start();
    }

// --- login check ---

    $accept = $_SERVER['HTTP_ACCEPT'] ?? '';
    $uri = $_SERVER['REQUEST_URI'] ?? '';
    $isJsonRequest = str_contains($accept, 'application/json')
        || str_starts_with($uri, '/php/'); // API vs HTML login redirect

    if (!function_exists('denyAppAccess')) {
        function denyAppAccess(bool $isJsonRequest, string $errorMsg = 'Not logged in.'): void
        {
            if ($isJsonRequest) {
                header('Content-Type: application/json');
                http_response_code(401);
                echo json_encode(['success' => false, 'errorMsg' => $errorMsg]);
                exit();
            }

            header('Location: /html/auth/login.html');
            exit();
        }
    }

    if (!isset($_SESSION['loggedin']) || $_SESSION['loggedin'] !== true) {
        denyAppAccess($isJsonRequest);
    }
