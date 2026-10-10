<?php

// requestCompany.php — company registration request

// --- Initialization ---

    require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/connect_to_DB.php';
    require_once $_SERVER['DOCUMENT_ROOT'] . '/php/auth/rate_limit_helpers.php';
    require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/mail/MailService.php';
    require_once $_SERVER['DOCUMENT_ROOT'] . '/php/auth/email_verification_helpers.php';

    try {
        $companyName = trim($_POST['companyName'] ?? '');
        $requesterEmail = trim($_POST['requesterEmail'] ?? '');
        $ip = getClientIp();

        enforceRateLimitOrExit('company_request', $ip, $requesterEmail);
        recordRateLimitFailure('company_request', $ip, $requesterEmail); // every submit counts toward the 10-request cap

// --- validation ---

        if ($companyName === '' || $requesterEmail === '') {
            throw new Exception('All fields are required.');
        }

        if (!filter_var($requesterEmail, FILTER_VALIDATE_EMAIL)) {
            throw new Exception('Invalid email address.');
        }

        $stmt = $conn->prepare('SELECT COUNT(*) AS total FROM company WHERE name = ?');
        $stmt->bind_param('s', $companyName);
        $stmt->execute();
        if ((int) ($stmt->get_result()->fetch_assoc()['total'] ?? 0) > 0) {
            throw new Exception('Company name already exists.');
        }
        $stmt->close();

        $stmt = $conn->prepare(
            "SELECT COUNT(*) AS total FROM company_requests WHERE companyName = ? AND status = 'pending'"
        );
        $stmt->bind_param('s', $companyName);
        $stmt->execute();
        if ((int) ($stmt->get_result()->fetch_assoc()['total'] ?? 0) > 0) {
            throw new Exception('A request for this company name is already pending.');
        }
        $stmt->close();

        $stmt = $conn->prepare(
            "SELECT COUNT(*) AS total FROM company_requests WHERE requesterEmail = ? AND status = 'pending'"
        );
        $stmt->bind_param('s', $requesterEmail);
        $stmt->execute();
        if ((int) ($stmt->get_result()->fetch_assoc()['total'] ?? 0) > 0) {
            throw new Exception('A request with this email is already pending.');
        }
        $stmt->close();

// --- submit request ---

        $token = bin2hex(random_bytes(32)); // admin approval link token
        $stmt = $conn->prepare(
            'INSERT INTO company_requests (companyName, requesterEmail, token) VALUES (?, ?, ?)'
        );
        $stmt->bind_param('sss', $companyName, $requesterEmail, $token);
        if (!$stmt->execute()) {
            throw new Exception(1);
        }
        $stmt->close();

        MailService::sendCompanyActivationToAdmin($companyName, $requesterEmail, $token);
        MailService::sendCompanyRegistrationQuestionnaire($requesterEmail, $companyName);

// --- response ---

        echo '<script type="text/javascript">';
        echo 'alert("Request submitted. Check your email for subscription plan assessment instructions.");';
        echo 'window.location.href = "/html/auth/login.html";';
        echo '</script>';
        exit();
    } catch (Throwable $e) {
        logAppError($e);
        if (isDbUnavailable($e)) {
            respondDbUnavailable('html');
        }

// --- error ---

        $known = [
            'All fields are required.',
            'Invalid email address.',
            'Company name already exists.',
            'A request for this company name is already pending.',
            'A request with this email is already pending.',
            'Email is not configured.',
            'Could not send email. Please try again later.',
        ];
        $message = in_array($e->getMessage(), $known, true)
            ? $e->getMessage()
            : 'An error occurred. Please try again.';

        echo '<script type="text/javascript">';
        echo 'alert(' . json_encode($message) . ');';
        echo 'window.history.back()';
        echo '</script>';
        exit();
    }
?>
