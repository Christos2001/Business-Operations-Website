<?php

// addOneTimeShift.php — one-time shift insert, notification

// --- Initialization ---

    try {
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/secure_cookies.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/connect_to_DB.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/check_session.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/auth_helpers.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/shifts/validate_shift.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/mail/MailService.php';

        requirePrivilege($conn, 'shift');
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

// --- validation ---

        $inputShiftDate = $_POST["sDate"];
        $inputStartTime = $_POST["startTime"];
        $inputEndTime = $_POST["endTime"];
        $inputUserID = (int) $_POST["userID"];

        assertSameCompany($conn, $inputUserID);

        validateShiftDate($inputShiftDate);
        validateShiftDuration($inputStartTime, $inputEndTime);

        $stmt = $conn->prepare("SELECT u.Name, u.Surname, u.email, u.emailVerified FROM user u WHERE u.id = ?");
        $stmt->bind_param("i", $inputUserID);
        if (!$stmt->execute()) {
            throw new Exception(1);
        }
        $employeeResult = $stmt->get_result();
        $employee = $employeeResult->fetch_assoc();

        if ($employee === false) {
            throw new Exception(1);
        }
        if (!$employee) {
            throw new Exception("User not found.");
        }

// --- add shift ---

        $stmt = $conn->prepare("INSERT INTO shifts (userID, Date, startTime, endTime) VALUES (?, ?, ?, ?)");
        $stmt->bind_param("isss", $inputUserID, $inputShiftDate, $inputStartTime, $inputEndTime);

        if (!$stmt->execute()) {
            throw new Exception(1);
        }

        $employeeName = $employee['Name'] . ' ' . $employee['Surname'];
        $alertMessage = 'Shift saved!';

        if ($employee['emailVerified']) {
            try {
                MailService::sendShiftNotification($employee['email'], [
                    'employeeName' => $employeeName,
                    'schedule' => $inputShiftDate,
                    'startTime' => $inputStartTime,
                    'endTime' => $inputEndTime,
                    'companyName' => $companyName,
                ]);
                $alertMessage = "Shift saved! Email sent to {$employeeName}";
            } catch (Throwable $mailError) {
                logAppError($mailError);
                $alertMessage = 'Shift saved, but the notification email could not be sent.';
            }
        }

// --- response ---

        echo '<script type="text/javascript">';
        echo 'alert(' . json_encode($alertMessage) . ');';
        echo 'window.location.href = "/html/searchEmployee.html?q=addShift";';
        echo '</script>';
        exit();
// --- error ---

    } catch (Throwable $e) {
        logAppError($e);
        if (isDbUnavailable($e)) {
            respondDbUnavailable('html');
        }

        if ($e->getMessage() == "User not found.") {
            echo '<script type="text/javascript">';
            echo 'alert("User not found.");';
            echo 'window.history.back()';
            echo '</script>';
            exit();
        }

        if ($e->getMessage() == "Cannot pick a past date.") {
            echo '<script type="text/javascript">';
            echo 'alert("Cannot pick a past date.");';
            echo 'window.history.back()';
            echo '</script>';
            exit();
        }

        if ($e->getMessage() == "Check-out must be after check-in.") {
            echo '<script type="text/javascript">';
            echo 'alert("Check-out must be after check-in.");';
            echo 'window.history.back()';
            echo '</script>';
            exit();
        }

        if ($e->getMessage() == "Shift cannot exceed 12 hours.") {
            echo '<script type="text/javascript">';
            echo 'alert("Shift cannot exceed 12 hours.");';
            echo 'window.history.back()';
            echo '</script>';
            exit();
        }

        echo '<script type="text/javascript">';
        echo 'alert("An error occured.");';
        echo 'window.history.back()';
        echo '</script>';
        exit();
    }
?>
