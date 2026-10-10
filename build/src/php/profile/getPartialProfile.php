<?php

// getPartialProfile.php — partial profile query, photo serve

// --- Initialization ---

    ini_set('display_errors', 0);
    ini_set('log_errors', 1);
    error_reporting(E_ALL);

    try {
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/secure_cookies.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/connect_to_DB.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/check_session.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/auth_helpers.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/profile/profile_photo_helpers.php';

        $isPhotoRequest = isset($_GET['photo']); // binary photo vs JSON profile
        if (!$isPhotoRequest) {
            header('Content-Type: application/json');
        }

// --- validation ---

        $sessionUserId = getCurrentUserId($conn);
        $targetUserId = (isset($_GET['i']) && $_GET['i'] !== '') ? (int) $_GET['i'] : $sessionUserId;
        if ($targetUserId <= 0) {
            http_response_code(400);
            echo json_encode(['success' => false, 'errorMsg' => 'Invalid user ID.']);
            exit();
        }

        assertSameCompany($conn, $targetUserId);

        $shiftDate = $_GET['date'] ?? null; // coworker profile access on shared shift day
        if (!canViewProfile($conn, $targetUserId, $sessionUserId, $shiftDate)) {
            http_response_code(403);
            if (!$isPhotoRequest) {
                echo json_encode(['success' => false, 'errorMsg' => 'Access denied.']);
            }
            exit();
        }

// --- photo ---

        if ($isPhotoRequest) {
            $stmt = $conn->prepare(
                'SELECT u.profilePhotoFile, u.companyID, c.name AS companyName
                 FROM user u
                 INNER JOIN company c ON c.id = u.companyID
                 WHERE u.id = ?'
            );
            $stmt->bind_param('i', $targetUserId);
            if (!$stmt->execute()) {
                throw new Exception(1);
            }
            $result = $stmt->get_result();
            $row = $result->fetch_assoc();
            $stmt->close();

            if ($row === false) {
                throw new Exception(1);
            }
            if (!$row || empty($row['profilePhotoFile'])) {
                throw new Exception('Photo not found.');
            }

            $companyName = (string) $row['companyName'];
            $companyId = (int) $row['companyID'];
            $profileFileName = $row['profilePhotoFile'];

            if (isset($_GET['list'])) {
                $searchFileName = ensureSearchProfilePhotoFile($companyName, $profileFileName, $companyId);
                serveProfilePhotoFile($companyName, $searchFileName, $companyId, true);
            }

            serveProfilePhotoFile($companyName, $profileFileName, $companyId);
        }

// --- query ---

        $hasPhotoExpr = userHasProfilePhotoExpr();
        if (isManager($conn, $targetUserId)) {
            $stmt = $conn->prepare(
                "SELECT u.Name AS name, u.Surname AS surname, u.username, u.email,
                        m.role, m.description,
                        CASE WHEN {$hasPhotoExpr} THEN 1 ELSE 0 END AS hasPhoto
                 FROM user u
                 INNER JOIN manager m ON m.id = u.id
                 WHERE u.id = ?"
            );
            $roleType = 'manager'; // which role table supplied profile fields
        } else {
            $stmt = $conn->prepare(
                "SELECT u.Name AS name, u.Surname AS surname, u.username, u.email,
                        e.role, e.description,
                        CASE WHEN {$hasPhotoExpr} THEN 1 ELSE 0 END AS hasPhoto
                 FROM user u
                 INNER JOIN employee e ON e.id = u.id
                 WHERE u.id = ?"
            );
            $roleType = 'employee';
        }

        $stmt->bind_param('i', $targetUserId);
        if (!$stmt->execute()) {
            throw new Exception(1);
        }
        $result = $stmt->get_result();
        $row = $result->fetch_assoc();
        $stmt->close();

        if ($row === false) {
            throw new Exception(1);
        }
        if (!$row) {
            throw new Exception('Profile not found.');
        }

        echo json_encode([
            'success' => true,
            'data' => [
                'id' => $targetUserId,
                'name' => $row['name'],
                'surname' => $row['surname'],
                'username' => $row['username'],
                'email' => $row['email'],
                'role' => $row['role'],
                'description' => $row['description'],
                'hasPhoto' => (bool)$row['hasPhoto'],
                'roleType' => $roleType,
                'isOwnProfile' => $targetUserId === $sessionUserId,
            ]
        ]);
        exit();
// --- error ---

    } catch (Throwable $e) {
        logAppError($e);
        if (isset($_GET['photo'])) {
            http_response_code(404);
            exit();
        }

        header('Content-Type: application/json');

        if (isDbUnavailable($e)) {
            respondDbUnavailable();
        }

        if ($e->getMessage() == 'Profile not found.' || $e->getMessage() == 'User not found.') {
            echo json_encode(['success' => false, 'errorMsg' => 'Profile not found.']);
            exit();
        }

        echo json_encode(['success' => false, 'errorMsg' => 'An error occured.']);
        exit();
    }
?>
