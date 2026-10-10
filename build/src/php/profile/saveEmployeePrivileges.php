<?php

// saveEmployeePrivileges.php — save employee privileges

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

// --- validation ---

        $employeeId = isset($_POST['employeeID']) ? (int)$_POST['employeeID'] : 0;
        if ($employeeId <= 0) {
            http_response_code(400);
            echo json_encode(['success' => false, 'errorMsg' => 'Invalid employee ID.']);
            exit();
        }

        $userId = getCurrentUserId($conn);
        if (!canManageEmployee($conn, $employeeId, $userId)) {
            http_response_code(403);
            echo json_encode(['success' => false, 'errorMsg' => 'Access denied.']);
            exit();
        }

        $income = !empty($_POST['income']) ? 1 : 0; // privilege bit flags (0/1)
        $expenses = !empty($_POST['expenses']) ? 1 : 0;
        $moneyTracker = (!empty($_POST['money-tracker']) || !empty($_POST['money_tracker'])) ? 1 : 0; // accept both POST keys
        $shift = !empty($_POST['shift']) ? 1 : 0;
        $manageEmployees = !empty($_POST['manage-employees']) ? 1 : 0;

// --- save ---

        $stmt = $conn->prepare(
            'INSERT INTO privileges (`employeeID`, `income`, `expenses`, `money-tracker`, `shift`, `manage-employees`)
             VALUES (?, ?, ?, ?, ?, ?)
             ON DUPLICATE KEY UPDATE
                `income` = VALUES(`income`),
                `expenses` = VALUES(`expenses`),
                `money-tracker` = VALUES(`money-tracker`),
                `shift` = VALUES(`shift`),
                `manage-employees` = VALUES(`manage-employees`)'
        );
        $stmt->bind_param('iiiiii', $employeeId, $income, $expenses, $moneyTracker, $shift, $manageEmployees);
        if (!$stmt->execute()) {
            throw new Exception(1);
        }
        $stmt->close();

        echo json_encode(['success' => true]);
        exit();
// --- error ---

    } catch (Throwable $e) {
        logAppError($e);
        if (isDbUnavailable($e)) {
            respondDbUnavailable();
        }

        echo json_encode(['success' => false, 'errorMsg' => 'An error occured.']);
        exit();
    }
?>
