<?php

// resetUsername.php — username reset completion

// --- Initialization ---

    require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/connect_to_DB.php';
    require_once $_SERVER['DOCUMENT_ROOT'] . '/php/auth/account_recovery_helpers.php';

    try {
        $token = trim($_POST['token'] ?? '');
        $username = trim($_POST['username'] ?? '');

// --- validation ---

        if ($token === '') {
            throw new Exception('Invalid recovery link.');
        }

        completeUsernameReset($conn, $token, $username);

// --- response ---

        echo '<script type="text/javascript">';
        echo 'alert("Username updated successfully. You can now log in.");';
        echo 'window.location.href = "/html/auth/login.html";';
        echo '</script>';
        exit();
    } catch (Throwable $e) {
        logAppError($e);

// --- error ---

        $known = [
            'Invalid recovery link.',
            'Invalid or expired recovery link.',
            'Recovery link has expired.',
            'Username must be at least 7 characters.',
            'Username is already taken.',
        ];
        $message = in_array($e->getMessage(), $known, true)
            ? $e->getMessage()
            : 'Could not change username. Please try again.';

        echo '<script type="text/javascript">';
        echo 'alert(' . json_encode($message) . ');';
        echo 'window.history.back()';
        echo '</script>';
        exit();
    }
?>
