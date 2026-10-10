<?php

// getIncome.php — income list query, pagination, year filter

// --- Initialization ---

    header('Content-Type: application/json');
    ini_set('display_errors', 0);
    ini_set('log_errors', 1);
    error_reporting(E_ALL);

    const RECORDS_PAGE_SIZE = 100; // records.html page size

    try {
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/secure_cookies.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/connect_to_DB.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/check_session.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/auth_helpers.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/transactions/transaction_soft_delete_helpers.php';

// --- query ---

        $companyId = getCurrentCompanyId($conn);

        // Predictions / charts: ?year=2025 — rows for that year only.
        if (isset($_GET['year']) && $_GET['year'] !== '') {
            requirePrivilege($conn, 'money-tracker');
            $year = (int) $_GET['year'];
            if ($year < 1) {
                echo json_encode(['success' => false, 'errorMsg' => 'Invalid year.']);
                exit();
            }

            $stmt = $conn->prepare(
                "SELECT i.id, i.Source, i.Income, i.DateOfIncome, i.Notes,
                        CASE WHEN a.id IS NOT NULL THEN 1 ELSE 0 END AS hasAttachment
                 FROM income i
                 LEFT JOIN attachments a ON a.incomeID = i.id
                 WHERE i.companyID = ? AND YEAR(i.DateOfIncome) = ? AND i.deletedAt IS NULL
                 ORDER BY i.DateOfIncome DESC"
            );
            if (!$stmt) {
                throw new Exception($conn->error);
            }
            $stmt->bind_param('ii', $companyId, $year);
            if (!$stmt->execute()) {
                throw new Exception($conn->error);
            }
            $results = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
            $stmt->close();

            if ($results === false) {
                throw new Exception(1);
            }

            echo json_encode(['success' => true, 'data' => $results]);
            exit();
        }

        // records.html: requires ?page=N — one page of 100 rows only.
        if (!isset($_GET['page'])) {
            echo json_encode(['success' => false, 'errorMsg' => 'Missing page parameter.']);
            exit();
        }

        requirePrivilege($conn, 'income');
        purgeExpiredSoftDeletedTransactions($conn);

        if((int) $_GET['page'] >= 1){
            $page = $_GET['page'];
        }else{
            throw new Exception("Invalid page number.");//Unauthorized action
        }

        $source = isset($_GET['search']) ? trim((string) $_GET['search']) : '';
        if ($source === '' && isset($_GET['source'])) {
            $source = trim((string) $_GET['source']);
        }
        $hasSource = $source !== ''; // active source search filter
        $likeSource = '%' . $source . '%'; // SQL LIKE pattern
        $limit = RECORDS_PAGE_SIZE;
        $offset = ($page - 1) * RECORDS_PAGE_SIZE; // zero-based row offset

        if ($hasSource) {//checks all records to add pagination opacity if records on page X doesnt exist.
            $countStmt = $conn->prepare(
                'SELECT COUNT(*) AS total FROM income WHERE companyID = ? AND Source LIKE ?'
            );
            $countStmt->bind_param('is', $companyId, $likeSource);
        } else {
            $countStmt = $conn->prepare(
                'SELECT COUNT(*) AS total FROM income WHERE companyID = ?'
            );
            $countStmt->bind_param('i', $companyId);
        }

        if (!$countStmt->execute()) {
            throw new Exception($conn->error);
        }
        $totalRecords = (int) ($countStmt->get_result()->fetch_assoc()['total'] ?? 0);
        $countStmt->close();

        $totalPages = $totalRecords === 0 ? 0 : (int) ceil($totalRecords / RECORDS_PAGE_SIZE);
        if ($totalRecords > 0 && $page > $totalPages) {
            $page = $totalPages;
            $offset = ($page - 1) * RECORDS_PAGE_SIZE;
        }

        if ($hasSource) {
            $stmt = $conn->prepare(
                "SELECT i.id, i.Source, i.Income, i.DateOfIncome, i.Notes, i.deletedAt,
                        DATE_ADD(i.deletedAt, INTERVAL 6 MONTH) AS purgeAt,
                        CASE WHEN a.id IS NOT NULL THEN 1 ELSE 0 END AS hasAttachment
                 FROM income i
                 LEFT JOIN attachments a ON a.incomeID = i.id
                 WHERE i.companyID = ? AND i.Source LIKE ?
                 ORDER BY i.DateOfIncome DESC
                 LIMIT {$limit} OFFSET {$offset}"
            );
            $stmt->bind_param('is', $companyId, $likeSource);
        } else {
            $stmt = $conn->prepare(
                "SELECT i.id, i.Source, i.Income, i.DateOfIncome, i.Notes, i.deletedAt,
                        DATE_ADD(i.deletedAt, INTERVAL 6 MONTH) AS purgeAt,
                        CASE WHEN a.id IS NOT NULL THEN 1 ELSE 0 END AS hasAttachment
                 FROM income i
                 LEFT JOIN attachments a ON a.incomeID = i.id
                 WHERE i.companyID = ?
                 ORDER BY i.DateOfIncome DESC
                 LIMIT {$limit} OFFSET {$offset}"
            );
            $stmt->bind_param('i', $companyId);
        }

        if (!$stmt->execute()) {
            throw new Exception($conn->error);
        }
        $results = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
        $stmt->close();

        if ($results === false) {
            throw new Exception(1);
        }

        $results = array_map('maskSoftDeletedIncomeRow', $results); // hide soft-deleted row fields for UI

        echo json_encode([
            'success' => true,
            'data' => $results,
            'page' => $page,
            'totalPages' => $totalPages,
            'totalRecords' => $totalRecords,
            'pageSize' => RECORDS_PAGE_SIZE,
        ]);
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
