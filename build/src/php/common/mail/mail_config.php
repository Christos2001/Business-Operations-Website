<?php

// mail_config.php — email env configuration

// --- Initialization ---

$baseUrl = getenv('APP_BASE_URL');

return [
    'host' => getenv('EMAIL_HOST'),
    'port' => (int) getenv('EMAIL_PORT'),
    'user' => getenv('EMAIL_USER'),
    'pass' => getenv('EMAIL_APP_PASS'),
    'from_name' => getenv('MAIL_FROM_NAME'),
    'base_url' => $baseUrl !== false ? rtrim($baseUrl, '/') : false, // absolute URL base for email links
];
