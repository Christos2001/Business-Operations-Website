<?php

// getUserFullProfile.php — full employee profile query, photo serve

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

        $targetUserId = isset($_GET['i']) ? (int)$_GET['i'] : 0;
        if ($targetUserId <= 0) {
            http_response_code(400);
            echo json_encode(['success' => false, 'errorMsg' => 'Invalid user ID.']);
            exit();
        }

        $sessionUserId = getCurrentUserId($conn);
        assertSameCompany($conn, $targetUserId);

        if (!canAccessManagment($conn, $sessionUserId)) {
            http_response_code(403);
            if (!$isPhotoRequest) {
                echo json_encode(['success' => false, 'errorMsg' => 'Access denied.']);
            }
            exit();
        }

        if (!canViewEmployeeProfile($conn, $targetUserId, $sessionUserId)) {
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

            serveProfilePhotoFile((string) $row['companyName'], $row['profilePhotoFile'], (int) $row['companyID']);
        }

// --- query ---

        $hasPhotoExpr = userHasProfilePhotoExpr(); // SQL fragment for hasPhoto flag
        $stmt = $conn->prepare(
            "SELECT u.Name AS name, u.Surname AS surname, u.username, u.email,
                    COALESCE(e.role, m.role) AS role,
                    COALESCE(e.description, m.description) AS description,
                    e.notes AS notes,
                    CASE WHEN m.id IS NOT NULL THEN 1 ELSE 0 END AS isManager,
                    CASE WHEN {$hasPhotoExpr} THEN 1 ELSE 0 END AS hasPhoto
             FROM user u
             LEFT JOIN employee e ON e.id = u.id
             LEFT JOIN manager m ON m.id = u.id
             WHERE u.id = ? AND (e.id IS NOT NULL OR m.id IS NOT NULL)"
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
        if (!$row) {
            throw new Exception('User not found.');
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
                'notes' => $row['isManager'] ? '' : ($row['notes'] ?? ''),
                'isManager' => (bool) $row['isManager'],
                'hasPhoto' => (bool)$row['hasPhoto'],
                'canManage' => canManageEmployee($conn, $targetUserId, $sessionUserId)
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

        if ($e->getMessage() == 'User not found.') {
            http_response_code(404);
            echo json_encode(['success' => false, 'errorMsg' => 'User not found.']);
            exit();
        }

        echo json_encode(['success' => false, 'errorMsg' => 'An error occured.']);
        exit();
    }
?>
