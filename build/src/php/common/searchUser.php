<?php

// searchUser.php — user search by name, access modes

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
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/profile/profile_photo_helpers.php';

        $q = $_GET['q'] ?? '';
        $mode = $_GET['mode'] ?? '';
        $q = str_replace('%20', ' ', $q);
        $nameANDsurname = explode(' ', $q); // "Name Surname" split for ranked search

// --- validation ---

        if ($q == '') {
            throw new Exception('Empty search query.');
        }

        $userId = getCurrentUserId($conn);
        $companyId = getCurrentCompanyId($conn);

        $accessFilter = ' AND u.companyID = ' . (int) $companyId; // tenant scope SQL fragment

        if ($mode === 'addShift') {
            if (!hasPrivilege($conn, 'shift', $userId)) {
                http_response_code(403);
                echo json_encode(['success' => false, 'errorMsg' => 'Access denied.']);
                exit();
            }

            $fromJoin = 'FROM user u';
        } elseif ($mode === 'viewShifts') {
            if (!hasPrivilege($conn, 'shift', $userId)) {
                http_response_code(403);
                echo json_encode(['success' => false, 'errorMsg' => 'Access denied.']);
                exit();
            }

            $fromJoin = 'FROM user u';
        } elseif ($mode === 'manageEmp') {
            if (!canAccessManagment($conn, $userId)) {
                http_response_code(403);
                echo json_encode(['success' => false, 'errorMsg' => 'Access denied.']);
                exit();
            }

            $fromJoin = 'FROM user u INNER JOIN employee e ON e.id = u.id'; // employees only (privileges UI)
            $accessFilter .= ' AND u.id != ' . (int) $userId;
        } else {
            http_response_code(403);
            echo json_encode(['success' => false, 'errorMsg' => 'Access denied.']);
            exit();
        }

// --- query ---

        $hasPhotoExpr = userHasProfilePhotoExpr();
        $photoSelect = "u.Name AS name, u.Surname AS surname, u.id,
            CASE WHEN {$hasPhotoExpr} THEN 1 ELSE 0 END AS hasPhoto,
            u.profilePhotoFile";

        if (array_key_exists(1, $nameANDsurname) && $nameANDsurname[1] != '') {
            $query = "SELECT $photoSelect
            $fromJoin
            WHERE u.Name LIKE ? AND u.Surname LIKE ?$accessFilter
            ORDER BY
                CASE
                    WHEN u.Name = ? AND u.Surname = ? THEN 1
                    WHEN u.Name LIKE ? AND u.Surname LIKE ? THEN 2
                END,
                u.Name ASC,
                u.Surname ASC
            ";

            $stmt = $conn->prepare($query);
            $name1 = $nameANDsurname[0] . '%';
            $name2 = $nameANDsurname[1] . '%';
            $name3 = $nameANDsurname[0];
            $name4 = $nameANDsurname[1];
            $stmt->bind_param(
                'ssssss',
                $name1,
                $name2,
                $name3,
                $name4,
                $name1,
                $name2
            );
        } else {
            $query = "SELECT $photoSelect
            $fromJoin
            WHERE (u.Name LIKE ? OR u.Surname LIKE ?)$accessFilter
            ORDER BY
                CASE
                    WHEN u.Name = ? THEN 1
                    WHEN u.Surname = ? THEN 3
                    WHEN u.Name LIKE ? THEN 2
                    WHEN u.Surname LIKE ? THEN 4
                END,
                u.Name ASC";

            $stmt = $conn->prepare($query);
            $name1 = $nameANDsurname[0] . '%';
            $name2 = $nameANDsurname[0];
            $stmt->bind_param(
                'ssssss',
                $name1,
                $name1,
                $name2,
                $name2,
                $name1,
                $name1
            );
        }

        if (!$stmt->execute()) {
            throw new Exception(1);
        }

        $result = $stmt->get_result();
        $results = $result->fetch_all(MYSQLI_ASSOC);
        $stmt->close();

        if ($results === false) {
            throw new Exception(1);
        }

        $data = [];
        $noPhotoIndexes = [];
        foreach ($results as $index => $row) {
            $hasPhoto = !empty($row['hasPhoto']);
            $data[] = [
                'name' => $row['name'],
                'surname' => $row['surname'],
                'id' => $row['id'],
                'hasPhoto' => $hasPhoto,
                'photoVersion' => $hasPhoto ? $row['profilePhotoFile'] : null,
            ];
            if (!$hasPhoto) {
                $noPhotoIndexes[] = $index;
            }
        }

        $idsToShow = [];
        if (count($noPhotoIndexes) > 1) {
            $nameCounts = [];
            $nameKeys = [];
            foreach ($noPhotoIndexes as $index) {
                $name = trim((string) $results[$index]['name']);
                $surname = trim((string) $results[$index]['surname']);
                $key = $name . "\0" . $surname;
                $key = function_exists('mb_strtolower') ? mb_strtolower($key) : strtolower($key);
                $nameKeys[$index] = $key;
                $nameCounts[$key] = ($nameCounts[$key] ?? 0) + 1;
            }
            foreach ($noPhotoIndexes as $index) {
                if ($nameCounts[$nameKeys[$index]] > 1) {
                    $idsToShow[] = $results[$index]['id'];
                }
            }
        }

        echo json_encode([
            'success' => true,
            'data' => $data,
            'showId' => [
                'exists' => $idsToShow !== [],
                'ids' => $idsToShow,
            ],
        ]);
        exit();
// --- error ---

    } catch (Throwable $e) {
        $searchContext = 'searchUser';
        if (isset($mode) && $mode !== '') {
            $searchContext .= ' mode=' . $mode;
        }
        logAppError($e, $searchContext);
        if (isDbUnavailable($e)) {
            respondDbUnavailable();
        }

        if ($e->getMessage() == 'Empty search query.') {
            echo json_encode(['success' => false, 'errorMsg' => 'Search query is empty.']);
            exit();
        }

        echo json_encode(['success' => false, 'errorMsg' => $e->getMessage()]);
        exit();
    }
?>
