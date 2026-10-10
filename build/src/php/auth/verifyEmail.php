<?php

// verifyEmail.php — email verification token handling

// --- Initialization ---

    require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/connect_to_DB.php';
    require_once $_SERVER['DOCUMENT_ROOT'] . '/php/auth/email_verification_helpers.php';

    try {

// --- validation ---

        if (!isset($_GET['token']) || trim($_GET['token']) === '') {
            throw new Exception('Invalid verification link.');
        }

        $token = trim($_GET['token']);
        $tokenRow = verifyEmailToken($conn, $token);
        $isEmailChange = $tokenRow['newEmail'] !== null && $tokenRow['newEmail'] !== ''; // email-change vs signup verify

        completeEmailVerification($conn, $token);

// --- response ---

        if ($isEmailChange) {
            $message = 'Your new email has been confirmed successfully.';
            $redirect = '/html/profile/profile.html';
        } else {
            $message = 'Email verified successfully! You can now log in.';
            $redirect = '/html/auth/login.html';
        }

        echo '<script type="text/javascript">';
        echo 'alert(' . json_encode($message) . ');';
        echo 'window.location.href = ' . json_encode($redirect) . ';';
        echo '</script>';
        exit();
    } catch (Throwable $e) {
        logAppError($e);

// --- error ---

        $message = $e->getMessage();
        if (!in_array($message, ['Invalid verification link.', 'Verification link has expired.', 'Email is already in use.'], true)) {
            $message = 'Could not verify email. Please try again.';
        }

        echo '<script type="text/javascript">';
        echo 'alert(' . json_encode($message) . ');';
        echo 'window.location.href = "/html/auth/login.html";';
        echo '</script>';
        exit();
    }
?>
