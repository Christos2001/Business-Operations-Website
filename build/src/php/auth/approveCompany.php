<?php

// approveCompany.php — company approval from admin link

// --- Initialization ---

    require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/connect_to_DB.php';
    require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/mail/MailService.php';
    require_once $_SERVER['DOCUMENT_ROOT'] . '/php/auth/email_verification_helpers.php';

    try {

// --- validation ---

        if (!isset($_GET['token']) || trim($_GET['token']) === '') {
            throw new Exception('Invalid approval link.');
        }

        $token = trim($_GET['token']);
        $stmt = $conn->prepare(
            "SELECT id, companyName, requesterEmail FROM company_requests WHERE token = ? AND status = 'pending' LIMIT 1"
        );
        $stmt->bind_param('s', $token);
        if (!$stmt->execute()) {
            throw new Exception(1);
        }
        $request = $stmt->get_result()->fetch_assoc();
        $stmt->close();

        if (!$request) {
            throw new Exception('Request already approved.');
        }

        $companyName = $request['companyName'];
        $requesterEmail = $request['requesterEmail'];
        $requestId = (int) $request['id'];

        $stmt = $conn->prepare('SELECT COUNT(*) AS total FROM company WHERE name = ?');
        $stmt->bind_param('s', $companyName);
        $stmt->execute();
        if ((int) ($stmt->get_result()->fetch_assoc()['total'] ?? 0) > 0) {
            throw new Exception('Company name already exists.');
        }
        $stmt->close();

        $managerCode = generateCompanyCode(); // signup invite codes
        $employeeCode = generateCompanyCode();

// --- approve company ---

        $conn->begin_transaction();
        try {
            $stmt = $conn->prepare(
                'INSERT INTO company (name, codeManager, codeEmployee) VALUES (?, ?, ?)'
            );
            $stmt->bind_param('sss', $companyName, $managerCode, $employeeCode);
            if (!$stmt->execute()) {
                throw new Exception(1);
            }
            $stmt->close();

            $stmt = $conn->prepare("UPDATE company_requests SET status = 'approved' WHERE id = ?");
            $stmt->bind_param('i', $requestId);
            if (!$stmt->execute()) {
                throw new Exception(1);
            }
            $stmt->close();

            $conn->commit();
        } catch (Throwable $e) {
            $conn->rollback();
            throw $e;
        }

        MailService::sendCompanyApproved($requesterEmail, $companyName, $managerCode, $employeeCode);

// --- response ---

        echo '<script type="text/javascript">';
        echo 'alert("Company activated. Registration codes have been sent to the company.");';
        echo 'window.location.href = "/html/auth/login.html";';
        echo '</script>';
        exit();
    } catch (Throwable $e) {
        logAppError($e);

// --- error ---

        $known = [
            'Invalid approval link.',
            'Request not found or already approved.',
            'Company name already exists.',
            'Could not send email. Please try again later.',
        ];
        $message = in_array($e->getMessage(), $known, true)
            ? $e->getMessage()
            : 'Could not approve company.';

        echo '<script type="text/javascript">';
        echo 'alert(' . json_encode($message) . ');';
        echo 'window.location.href = "/html/auth/login.html";';
        echo '</script>';
        exit();
    }
?>
