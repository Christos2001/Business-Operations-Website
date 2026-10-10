<?php

// deleteShift.php — shift delete, notification

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
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/shifts/validate_shift.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/mail/MailService.php';

        requirePrivilege($conn, 'shift');

        $inputUserID = isset($_POST['userID']) ? (int) $_POST['userID'] : 0;
        $shiftType = $_POST['shiftType'] ?? ''; // weekly | oneTime delete discriminator
        $startTime = $_POST['startTime'] ?? '';
        $endTime = $_POST['endTime'] ?? '';

// --- validation ---

        if ($inputUserID <= 0) {
            echo json_encode(['success' => false, 'errorMsg' => 'Invalid user ID.']);
            exit();
        }

        assertSameCompany($conn, $inputUserID);
        validateShiftDuration($startTime, $endTime);

        $companyId = getCurrentCompanyId($conn);
        $stmt = $conn->prepare('SELECT name FROM company WHERE id = ?');
        $stmt->bind_param('i', $companyId);
        if (!$stmt->execute()) {
            throw new Exception(1);
        }
        $companyRow = $stmt->get_result()->fetch_assoc();
        $stmt->close();
        if (!$companyRow) {
            throw new Exception(1);
        }
        $companyName = $companyRow['name'];

        $stmt = $conn->prepare('SELECT u.Name, u.Surname, u.email, u.emailVerified FROM user u WHERE u.id = ?');
        $stmt->bind_param('i', $inputUserID);
        if (!$stmt->execute()) {
            throw new Exception(1);
        }
        $employee = $stmt->get_result()->fetch_assoc();
        $stmt->close();

        if ($employee === false || !$employee) {
            echo json_encode(['success' => false, 'errorMsg' => 'User not found.']);
            exit();
        }

// --- delete shift ---

        $schedule = '';
        if ($shiftType === 'weekly') {
            $day = $_POST['day'] ?? '';
            validateShiftDay($day);
            $schedule = 'Every ' . $day;

            $stmt = $conn->prepare(
                'DELETE FROM shifts
                 WHERE userID = ? AND Day = ? AND Date IS NULL AND startTime = ? AND endTime = ?'
            );
            $stmt->bind_param('isss', $inputUserID, $day, $startTime, $endTime);
        } elseif ($shiftType === 'oneTime') {
            $date = $_POST['date'] ?? '';
            if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $date)) {
                echo json_encode(['success' => false, 'errorMsg' => 'Invalid date.']);
                exit();
            }
            $schedule = $date;

            $stmt = $conn->prepare(
                'DELETE FROM shifts
                 WHERE userID = ? AND Date = ? AND Day IS NULL AND startTime = ? AND endTime = ?'
            );
            $stmt->bind_param('isss', $inputUserID, $date, $startTime, $endTime);
        } else {
            echo json_encode(['success' => false, 'errorMsg' => 'Invalid shift type.']);
            exit();
        }

        if (!$stmt->execute()) {
            throw new Exception(1);
        }

        if ($stmt->affected_rows === 0) {
            $stmt->close();
            echo json_encode(['success' => false, 'errorMsg' => 'Shift not found.']);
            exit();
        }

        $stmt->close();

        $successMsg = 'Shift deleted successfully.';
        $employeeName = $employee['Name'] . ' ' . $employee['Surname'];

        if ($employee['emailVerified']) {
            try {
                MailService::sendShiftDeletionNotification($employee['email'], [
                    'employeeName' => $employeeName,
                    'schedule' => $schedule,
                    'startTime' => $startTime,
                    'endTime' => $endTime,
                    'companyName' => $companyName,
                ]);
                $successMsg = "Shift deleted successfully. Notification email sent to {$employeeName}.";
            } catch (Throwable $mailError) {
                logAppError($mailError);
                $successMsg = 'Shift deleted successfully, but the notification email could not be sent.';
            }
        }

// --- response ---

        echo json_encode(['success' => true, 'successMsg' => $successMsg]);
        exit();
// --- error ---

    } catch (Throwable $e) {
        logAppError($e);
        if (isDbUnavailable($e)) {
            respondDbUnavailable();
        }

        $message = $e->getMessage();
        if ($message === 'Check-out must be after check-in.'
            || $message === 'Shift cannot exceed 12 hours.'
            || $message === 'Invalid time.'
            || $message === 'No day found.') {
            echo json_encode(['success' => false, 'errorMsg' => $message]);
            exit();
        }

        echo json_encode(['success' => false, 'errorMsg' => 'An error occured.']);
        exit();
    }
?>
