<?php

// resetPassword.php — password reset completion

// --- Initialization ---

    require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/connect_to_DB.php';
    require_once $_SERVER['DOCUMENT_ROOT'] . '/php/auth/account_recovery_helpers.php';

    try {
        $token = trim($_POST['token'] ?? '');
        $password = $_POST['password'] ?? '';
        $confirmPassword = $_POST['confirmPassword'] ?? '';

// --- validation ---

        if ($token === '') {
            throw new Exception('Invalid recovery link.');
        }

        if ($password !== $confirmPassword) {
            throw new Exception('Passwords do not match.');
        }

        completePasswordReset($conn, $token, $password);

// --- response ---

        echo '<script type="text/javascript">';
        echo 'alert("Password updated successfully. You can now log in.");';
        echo 'window.location.href = "/html/auth/login.html";';
        echo '</script>';
        exit();
    } catch (Throwable $e) {

// --- error ---

        logAppError($e);
        $known = [
            'Invalid recovery link.',
            'Invalid or expired recovery link.',
            'Recovery link has expired.',
            'Passwords do not match.',
            'Password must be at least 8 characters with one letter and one number.',
        ];
        $message = in_array($e->getMessage(), $known, true)
            ? $e->getMessage()
            : 'Could not reset password. Please try again.';

        echo '<script type="text/javascript">';
        echo 'alert(' . json_encode($message) . ');';
        echo 'window.history.back()';
        echo '</script>';
        exit();
    }
?>
