<?php

// saveMyRole.php — save own role title

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

        $role = substr(trim($_POST['role'] ?? ''), 0, 50);

// --- save ---

        $sessionUserId = getCurrentUserId($conn);

        if (isManager($conn, $sessionUserId)) {
            $stmt = $conn->prepare('UPDATE manager SET role = ? WHERE id = ?');
        } else {
            $stmt = $conn->prepare('UPDATE employee SET role = ? WHERE id = ?');
        }

        $stmt->bind_param('si', $role, $sessionUserId);
        if (!$stmt->execute()) {
            throw new Exception(1);
        }
        $stmt->close();

        echo json_encode(['success' => true, 'successMsg' => 'Role saved successfully.']);
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
