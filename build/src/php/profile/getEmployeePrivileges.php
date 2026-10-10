<?php

// getEmployeePrivileges.php — employee privileges query

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

        $employeeId = isset($_GET['i']) ? (int)$_GET['i'] : 0;
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

// --- query ---

        $row = getPrivilegeRow($conn, $employeeId);
        $privileges = [ // default privilege map when no row exists
            'income' => false,
            'expenses' => false,
            'money-tracker' => false,
            'shift' => false,
            'manage-employees' => false
        ];

        if ($row) {
            foreach ($privileges as $key => $value) {
                $privileges[$key] = !empty($row[$key]);
            }
        }

        echo json_encode(['success' => true, 'data' => $privileges]);
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
