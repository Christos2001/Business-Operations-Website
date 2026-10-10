<?php

// getHomeRecentTransactions.php — recent transactions for home

// --- Initialization ---

    header('Content-Type: application/json');
    ini_set('display_errors', 0);
    ini_set('log_errors', 1);
    error_reporting(E_ALL);

    const HOME_RECENT_LIMIT = 5; // home widget row cap per type

    try {
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/secure_cookies.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/connect_to_DB.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/check_session.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/auth_helpers.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/transactions/transaction_soft_delete_helpers.php';

        requireAnyPrivilege($conn, ['money-tracker', 'income', 'expenses']);

// --- query ---

        $companyId = getCurrentCompanyId($conn);
        $userId = getCurrentUserId($conn);
        $canIncome = hasPrivilege($conn, 'income', $userId); // include income side when granted
        $canExpenses = hasPrivilege($conn, 'expenses', $userId);

        if (!$canIncome && !$canExpenses) {
            echo json_encode(['success' => true, 'data' => []]);
            exit();
        }

        purgeExpiredSoftDeletedTransactions($conn);

        $transactions = [];

        if ($canIncome) {
            $stmt = $conn->prepare(
                "SELECT i.Source AS source, i.Income AS amount, i.DateOfIncome AS date
                 FROM income i
                 WHERE i.companyID = ? AND i.deletedAt IS NULL
                 ORDER BY i.DateOfIncome DESC
                 LIMIT ?"
            );
            $limit = HOME_RECENT_LIMIT;
            $stmt->bind_param('ii', $companyId, $limit);
            if (!$stmt->execute()) {
                throw new Exception(1);
            }
            $rows = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
            $stmt->close();

            foreach ($rows as $row) {
                $transactions[] = [
                    'type' => 'income',
                    'source' => $row['source'],
                    'amount' => $row['amount'],
                    'date' => $row['date'],
                ];
            }
        }

        if ($canExpenses) {
            $stmt = $conn->prepare(
                "SELECT e.source, e.expense AS amount, e.DateOfExpense AS date
                 FROM expenses e
                 WHERE e.companyID = ? AND e.deletedAt IS NULL
                 ORDER BY e.DateOfExpense DESC
                 LIMIT ?"
            );
            $limit = HOME_RECENT_LIMIT;
            $stmt->bind_param('ii', $companyId, $limit);
            if (!$stmt->execute()) {
                throw new Exception(1);
            }
            $rows = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
            $stmt->close();

            foreach ($rows as $row) {
                $transactions[] = [
                    'type' => 'expense',
                    'source' => $row['source'],
                    'amount' => $row['amount'],
                    'date' => $row['date'],
                ];
            }
        }

        usort($transactions, static function ($a, $b) {
            return strcmp($b['date'], $a['date']);
        });

        $transactions = array_slice($transactions, 0, HOME_RECENT_LIMIT);

        echo json_encode(['success' => true, 'data' => $transactions]);
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
