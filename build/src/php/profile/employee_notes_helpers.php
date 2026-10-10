<?php

// employee_notes_helpers.php — employee note formatting, append

// --- Initialization ---

if (!defined('EMPLOYEE_NOTE_BODY_MAX_LENGTH')) {
    define('EMPLOYEE_NOTE_BODY_MAX_LENGTH', 1000); // single note body cap
}

if (!defined('EMPLOYEE_NOTES_TOTAL_MAX_LENGTH')) {
    define('EMPLOYEE_NOTES_TOTAL_MAX_LENGTH', 10000); // full notes history cap
}

// --- Note helpers ---

function buildEmployeeNoteEntry(string $name, string $surname, int $id, string $noteBody): string
{
    $timestamp = date('Y-m-d H:i');
    $noteBody = trim($noteBody);

    return '[' . $timestamp . '] ' . $name . ' ' . $surname . ' (id: ' . $id . "):\n" . $noteBody;
}

function appendEmployeeNote(?string $existingNotes, string $entry): string
{
    $existingNotes = trim((string) $existingNotes);
    if ($existingNotes === '') {
        return $entry;
    }

    return $existingNotes . "\n\n" . $entry;
}

?>
