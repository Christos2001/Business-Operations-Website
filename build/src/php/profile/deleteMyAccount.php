<?php

// deleteMyAccount.php — account deletion

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

// --- validation ---

        $password = $_POST['password'] ?? '';
        if ($password === '') {
            echo json_encode(['success' => false, 'errorMsg' => 'Password is required.']);
            exit();
        }

        $userId = getCurrentUserId($conn);

        $stmt = $conn->prepare(
            'SELECT u.password, u.profilePhotoFile, u.companyID, c.name AS companyName
             FROM user u
             INNER JOIN company c ON c.id = u.companyID
             WHERE u.id = ?'
        )
        $stmt->bind_param('i', $userId);
        if (!$stmt->execute()) {
            throw new Exception(1);
        }
        $user = $stmt->get_result()->fetch_assoc();
        $stmt->close();

        if (!$user) {
            echo json_encode(['success' => false, 'errorMsg' => 'User not found.']);
            exit();
        }

        if (!password_verify($password, $user['password'])) {
            echo json_encode(['success' => false, 'errorMsg' => 'Incorrect password.']);
            exit();
        }

// --- delete account ---

        if (!empty($user['profilePhotoFile'])) {
            deleteProfilePhotoFile((string) $user['companyName'], $user['profilePhotoFile'], (int) $user['companyID']);
        }

        $stmt = $conn->prepare('DELETE FROM user WHERE id = ?');
        $stmt->bind_param('i', $userId);
        if (!$stmt->execute()) {
            throw new Exception(1);
        }
        $stmt->close();

        $_SESSION = array();
        if (ini_get('session.use_cookies')) {
            $params = session_get_cookie_params();
            setcookie(
                session_name(),
                '',
                time() - 42000, // expire session cookie immediately
                $params['path'],
                $params['domain'],
                $params['secure'],
                $params['httponly']
            );
        }
        session_destroy();

        echo json_encode([
            'success' => true,
            'redirect' => '/html/auth/login.html',
        ]);
        exit();
// --- error ---

    } catch (Throwable $e) {
        logAppError($e);
        if (isDbUnavailable($e)) {
            respondDbUnavailable();
        }

        echo json_encode(['success' => false, 'errorMsg' => 'An error occurred.']);
        exit();
    }
?>
