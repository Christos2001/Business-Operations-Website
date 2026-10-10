<?php

// deleteExpense.php — expense soft delete

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
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/transactions/transaction_soft_delete_helpers.php';

        requirePrivilege($conn, 'expenses');
        purgeExpiredSoftDeletedTransactions($conn);

        $companyId = getCurrentCompanyId($conn);
        $userId = getCurrentUserId($conn);

// --- validation ---

        if (!isset($_POST['id'])) {
            echo json_encode(['success' => false, 'errorMsg' => 'Missing record id.']);
            exit();
        }

        $id = (int) $_POST['id'];

        $user = getUserNameAndId($conn, $userId);
        if ($user === null) {
            throw new Exception(1);
        }
// --- soft delete ---

        $suffix = buildDeleteNotesSuffix($user['Name'], $user['Surname'], (int) $user['id']); // audit line appended to Notes

        $selectSql = 'SELECT Notes FROM expenses WHERE id = ? AND companyID = ? AND deletedAt IS NULL';
        $selectStmt = $conn->prepare($selectSql);
        if (!$selectStmt) {
            throw new Exception($conn->error);
        }
        $selectStmt->bind_param('ii', $id, $companyId);
        if (!$selectStmt->execute()) {
            throw new Exception($conn->error);
        }
        $row = $selectStmt->get_result()->fetch_assoc();
        $selectStmt->close();
        if (!$row) {
            http_response_code(404);
            echo json_encode(['success' => false, 'errorMsg' => 'Record not found.']);
            exit();
        }

        $notes = appendNotesSuffix($row['Notes'] ?? '', $suffix);

        $sql = "UPDATE expenses
                SET Notes = ?,
                    deletedAt = NOW()
                WHERE id = ? AND companyID = ? AND deletedAt IS NULL";
        $stmt = $conn->prepare($sql);
        if (!$stmt) {
            throw new Exception($conn->error);
        }
        $stmt->bind_param('sii', $notes, $id, $companyId);

        if (!$stmt->execute()) {
            throw new Exception($conn->error);
        }

        if ($stmt->affected_rows === 0) {
            http_response_code(404);
            echo json_encode(['success' => false, 'errorMsg' => 'Record not found.']);
            exit();
        }

        $stmt->close();

// --- response ---

        echo json_encode([
            'success' => true,
            'successMsg' => 'Expense marked for deletion. It will be permanently deleted after 6 months.',
        ]);
        exit();
    } catch (Throwable $e) {

// --- error ---

        logAppError($e);
        if (isDbUnavailable($e)) {
            respondDbUnavailable();
        }

        echo json_encode(['success' => false, 'errorMsg' => 'An error occured.']);
        exit();
    }
?>
