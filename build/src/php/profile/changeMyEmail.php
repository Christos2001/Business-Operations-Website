<?php

// changeMyEmail.php — email change request, verification

// --- Initialization ---

    header('Content-Type: application/json');
    ini_set('display_errors', 0);
    ini_set('log_errors', 1);
    error_reporting(E_ALL);

    try {
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/secure_cookies.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/connect_to_DB.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/check_session.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/auth_helpers.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/mail/MailService.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/auth/email_verification_helpers.php';

// --- validation ---

        $newEmail = trim($_POST['newEmail'] ?? '');
        if ($newEmail === '' || !filter_var($newEmail, FILTER_VALIDATE_EMAIL)) {
            echo json_encode(['success' => false, 'errorMsg' => 'Invalid email address.']);
            exit();
        }

        $userId = getCurrentUserId($conn);

        $stmt = $conn->prepare('SELECT email, username FROM user WHERE id = ?');
        $stmt->bind_param('i', $userId);
        $stmt->execute();
        $user = $stmt->get_result()->fetch_assoc();
        $stmt->close();

        if (!$user) {
            echo json_encode(['success' => false, 'errorMsg' => 'User not found.']);
            exit();
        }

        if (strcasecmp($user['email'], $newEmail) === 0) {
            echo json_encode(['success' => false, 'errorMsg' => 'That is already your email.']);
            exit();
        }

        $stmt = $conn->prepare('SELECT COUNT(*) AS total FROM user WHERE email = ? AND id <> ?');
        $stmt->bind_param('si', $newEmail, $userId);
        $stmt->execute();
        if ((int) ($stmt->get_result()->fetch_assoc()['total'] ?? 0) > 0) {
            echo json_encode(['success' => false, 'errorMsg' => 'Email is already in use.']);
            exit();
        }
        $stmt->close();

// --- email change ---

        $token = createVerificationToken($conn, $userId, $newEmail);
        MailService::sendEmailChangeVerification($newEmail, $token, $user['username']);

        echo json_encode([
            'success' => true,
            'successMsg' => 'A verification email was sent to ' . $newEmail . '. Open the link to confirm your new address.'
        ]);
        exit();
// --- error ---

    } catch (Throwable $e) {
        logAppError($e);
        if (isDbUnavailable($e)) {
            respondDbUnavailable();
        }
        $message = $e->getMessage() === 'Could not send email. Please try again later.'
            || $e->getMessage() === 'Email is not configured.'
            ? 'Could not send verification email. Try again later.'
            : 'An error occurred.';

        echo json_encode(['success' => false, 'errorMsg' => $message]);
        exit();
    }
?>
