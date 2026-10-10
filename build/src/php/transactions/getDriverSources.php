<?php

// getDriverSources.php — paginated distinct sources for driver forecast settings

header('Content-Type: application/json');
ini_set('display_errors', 0);
ini_set('log_errors', 1);
error_reporting(E_ALL);

const DRIVER_SOURCE_PAGE_SIZE = 10;

try {
    require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/secure_cookies.php';
    require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/connect_to_DB.php';
    require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/check_session.php';
    require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/auth_helpers.php';

    requirePrivilege($conn, 'money-tracker');
    $companyId = getCurrentCompanyId($conn);

    $side = $_GET['side'] ?? '';
    $targetYear = (int) ($_GET['targetYear'] ?? 0);
    $numYears = (int) ($_GET['numYears'] ?? 0);
    $offset = (int) ($_GET['offset'] ?? 0);
    $limit = (int) ($_GET['limit'] ?? DRIVER_SOURCE_PAGE_SIZE);
    $q = trim((string) ($_GET['q'] ?? ''));

    if ($side !== 'income' && $side !== 'expense') {
        echo json_encode(['success' => false, 'errorMsg' => 'Invalid side.']);
        exit();
    }
    if ($targetYear < 1 || $numYears < 1) {
        echo json_encode(['success' => false, 'errorMsg' => 'Invalid year range.']);
        exit();
    }
    if ($offset < 0) {
        $offset = 0;
    }
    if ($limit < 1 || $limit > DRIVER_SOURCE_PAGE_SIZE) {
        $limit = DRIVER_SOURCE_PAGE_SIZE;
    }

    $endYear = $targetYear - 1;
    $startYear = $targetYear - $numYears;
    if ($startYear < 1) {
        $startYear = 1;
    }
    if ($endYear < $startYear) {
        echo json_encode(['success' => true, 'data' => [], 'hasMore' => false]);
        exit();
    }

    $fetchLimit = $limit + 1; // extra row to know if another page exists
    $like = '%' . $q . '%';
    $hasSearch = $q !== '';

    if ($side === 'income') {
        $sql = 'SELECT i.Source AS name, SUM(i.Income) AS total
            FROM income i
            WHERE i.companyID = ? AND i.deletedAt IS NULL
              AND YEAR(i.DateOfIncome) BETWEEN ? AND ?';
        if ($hasSearch) {
            $sql .= ' AND i.Source LIKE ?';
        }
        $sql .= ' GROUP BY i.Source
            ORDER BY total DESC, i.Source ASC
            LIMIT ' . $fetchLimit . ' OFFSET ' . $offset;
    } else {
        $sql = 'SELECT e.source AS name, SUM(e.expense) AS total
            FROM expenses e
            WHERE e.companyID = ? AND e.deletedAt IS NULL
              AND YEAR(e.DateOfExpense) BETWEEN ? AND ?';
        if ($hasSearch) {
            $sql .= ' AND e.source LIKE ?';
        }
        $sql .= ' GROUP BY e.source
            ORDER BY total DESC, e.source ASC
            LIMIT ' . $fetchLimit . ' OFFSET ' . $offset;
    }

    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        throw new Exception($conn->error);
    }

    if ($hasSearch) {
        $stmt->bind_param('iiis', $companyId, $startYear, $endYear, $like);
    } else {
        $stmt->bind_param('iii', $companyId, $startYear, $endYear);
    }

    if (!$stmt->execute()) {
        throw new Exception($conn->error);
    }

    $rows = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
    $stmt->close();

    if ($rows === false) {
        throw new Exception(1);
    }

    $hasMore = count($rows) > $limit;
    if ($hasMore) {
        array_pop($rows);
    }

    $data = array_map(static function (array $row): array {
        return [
            'name' => (string) $row['name'],
            'total' => (float) $row['total'],
        ];
    }, $rows);

    echo json_encode([
        'success' => true,
        'data' => $data,
        'hasMore' => $hasMore,
    ]);
    exit();
} catch (Throwable $e) {
    logAppError($e);
    if (isDbUnavailable($e)) {
        respondDbUnavailable();
    }

    echo json_encode(['success' => false, 'errorMsg' => 'An error occured.']);
    exit();
}
