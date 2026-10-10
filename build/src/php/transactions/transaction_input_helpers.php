<?php

// transaction_input_helpers.php — source / amount / notes validation for income & expenses

// --- Initialization ---

if (!defined('TRANSACTION_SOURCE_MAX_LENGTH')) {
    define('TRANSACTION_SOURCE_MAX_LENGTH', 300);
}

if (!defined('TRANSACTION_NOTE_BODY_MAX_LENGTH')) {
    define('TRANSACTION_NOTE_BODY_MAX_LENGTH', 1000);
}

if (!defined('TRANSACTION_AMOUNT_MAX')) {
    define('TRANSACTION_AMOUNT_MAX', 999999.99); //upper bound
}

// --- validation ---

function validateTransactionSource(string $source): ?string
{
    $source = trim($source);
    if ($source === '') {
        return 'Source cannot be empty.';
    }
    if (mb_strlen($source) > TRANSACTION_SOURCE_MAX_LENGTH) {
        return 'Source exceeds ' . TRANSACTION_SOURCE_MAX_LENGTH . ' characters.';
    }
    return null;
}

function validateTransactionNotes(string $notes): ?string
{
    if (mb_strlen($notes) > TRANSACTION_NOTE_BODY_MAX_LENGTH) {
        return 'Notes exceed ' . TRANSACTION_NOTE_BODY_MAX_LENGTH . ' characters.';
    }
    return null;
}

/**
 * Positive amount, at most two decimal places, within DECIMAL(10,2).
 *
 * @return array{0: ?string, 1: ?string} [errorMsg, normalized amount string for bind]
 */
function validateTransactionAmount(string $raw): array
{
    $raw = trim($raw);
    if ($raw === '' || !preg_match('/^\d+(\.\d{1,2})?$/', $raw)) {
        return ['Amount must be a positive number with at most two decimal places.', null];
    }

    $value = (float) $raw;
    if ($value <= 0 || $value > TRANSACTION_AMOUNT_MAX) {
        return ['Amount must be a positive number with at most two decimal places.', null];
    }

    return [null, $raw];
}

function respondTransactionInputError(string $message): void
{
    echo '<script type="text/javascript">';
    echo 'alert(' . json_encode($message) . ');';
    echo 'window.history.back()';
    echo '</script>';
    exit();
}

?>
