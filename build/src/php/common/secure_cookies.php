<?php

// secure_cookies.php — session cookie security settings

    // JS cannot read the session cookie (reduces XSS session theft).
    ini_set('session.cookie_httponly', 1);

    // Session id is sent only via cookie, not in the URL (session fixation / leakage).
    ini_set('session.use_only_cookies', 1);

    // Lax: cookie is sent on normal navigation; not on cross-site POST/embed (CSRF mitigation).
    ini_set('session.cookie_samesite', 'Lax');

    // Secure only on HTTPS; stays off for local HTTP.
    if (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on') {
        ini_set('session.cookie_secure', 1);
    }
