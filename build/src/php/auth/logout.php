<?php

// logout.php — session clear, cookie destroy, redirect

// --- Initialization ---

    require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/secure_cookies.php';
    require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/connect_to_DB.php';
    require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/check_session.php';

    $_SESSION = array();

// --- logout ---

if (ini_get("session.use_cookies")) {
    $params = session_get_cookie_params();
    setcookie(session_name(), '', time() - 42000, // expire session cookie immediately
        $params["path"], $params["domain"],
        $params["secure"], $params["httponly"]
    );
}

session_destroy();

header("Location: /html/auth/login.html");
exit();
?>