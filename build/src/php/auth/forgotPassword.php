<?php

// forgotPassword.php — password reset email, rate limiting

// --- Initialization ---

    header('Content-Type: application/json');
    ini_set('display_errors', 0);
    ini_set('log_errors', 1);
    error_reporting(E_ALL);

    require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/connect_to_DB.php';
    require_once $_SERVER['DOCUMENT_ROOT'] . '/php/auth/rate_limit_helpers.php';
    require_once $_SERVER['DOCUMENT_ROOT'] . '/php/auth/account_recovery_helpers.php';

    const RECOVERY_SUCCESS_MSG = 'If an account exists for this email, a message was sent to change your password.'; // anti-enumeration response

    try {
        $email = trim($_POST['email'] ?? '');
        $ip = getClientIp();

// --- validation ---

        if ($email === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
            echo json_encode(['success' => false, 'errorMsg' => 'Enter a valid email address.']);
            exit();
        }

        $remaining = getRateLimitCooldownRemaining('forgot_password', $ip, $email);
        if ($remaining !== null) {
            $minutes = max(1, (int) ceil($remaining / 60));
            echo json_encode(['success' => false, 'errorMsg' => "Too many attempts. Try again in about {$minutes} minute(s)."]);
            exit();
        }

        $user = findUserByEmail($conn, $email);
        if ($user) {
            $token = createRecoveryToken($conn, (int) $user['id'], 'password');
            MailService::sendPasswordResetEmail($user['email'], $token, $user['username']);
            clearRateLimit('forgot_password', $ip, $email);
        } else {
            recordRateLimitFailure('forgot_password', $ip, $email);
        }

// --- response ---

        echo json_encode(['success' => true, 'successMsg' => RECOVERY_SUCCESS_MSG]);
        exit();
    } catch (Throwable $e) {
        logAppError($e);
        recordRateLimitFailure('forgot_password', getClientIp(), $_POST['email'] ?? '');

// --- error ---

        echo json_encode([
            'success' => true,
            'successMsg' => RECOVERY_SUCCESS_MSG,
        ]);
        exit();
    }
?>
