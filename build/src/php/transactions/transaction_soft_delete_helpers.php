<?php

// transaction_soft_delete_helpers.php — soft delete purge, notes masking

// --- Initialization ---

require_once __DIR__ . '/attachment_helpers.php';

// --- Purge ---

function purgeExpiredSoftDeletedTransactions($conn): void
{
    $incomeStmt = $conn->prepare(
        'SELECT id, companyID FROM income
         WHERE deletedAt IS NOT NULL AND deletedAt < NOW() - INTERVAL 6 MONTH'
    );
    if (!$incomeStmt) {
        throw new Exception($conn->error);
    }
    if (!$incomeStmt->execute()) {
        throw new Exception($conn->error);
    }
    $incomeRows = $incomeStmt->get_result()->fetch_all(MYSQLI_ASSOC);
    $incomeStmt->close();

    foreach ($incomeRows as $row) {
        $id = (int) $row['id'];
        $companyId = (int) $row['companyID'];
        $fileName = getAttachmentFileNameForIncome($conn, $id, $companyId);
        $companyName = $fileName !== null ? getAttachmentCompanyNameById($conn, $companyId) : null;

        $deleteStmt = $conn->prepare('DELETE FROM income WHERE id = ? AND companyID = ?');
        if (!$deleteStmt) {
            throw new Exception($conn->error);
        }
        $deleteStmt->bind_param('ii', $id, $companyId);
        if (!$deleteStmt->execute()) {
            throw new Exception($conn->error);
        }
        $deleteStmt->close();

        if ($fileName !== null && $companyName !== null) {
            deleteAttachmentFile('income', $companyName, $fileName, $companyId);
        }
    }

    $expenseStmt = $conn->prepare(
        'SELECT id, companyID FROM expenses
         WHERE deletedAt IS NOT NULL AND deletedAt < NOW() - INTERVAL 6 MONTH'
    );
    if (!$expenseStmt) {
        throw new Exception($conn->error);
    }
    if (!$expenseStmt->execute()) {
        throw new Exception($conn->error);
    }
    $expenseRows = $expenseStmt->get_result()->fetch_all(MYSQLI_ASSOC);
    $expenseStmt->close();

    foreach ($expenseRows as $row) {
        $id = (int) $row['id'];
        $companyId = (int) $row['companyID'];
        $fileName = getAttachmentFileNameForExpense($conn, $id, $companyId);
        $companyName = $fileName !== null ? getAttachmentCompanyNameById($conn, $companyId) : null;

        $deleteStmt = $conn->prepare('DELETE FROM expenses WHERE id = ? AND companyID = ?');
        if (!$deleteStmt) {
            throw new Exception($conn->error);
        }
        $deleteStmt->bind_param('ii', $id, $companyId);
        if (!$deleteStmt->execute()) {
            throw new Exception($conn->error);
        }
        $deleteStmt->close();

        if ($fileName !== null && $companyName !== null) {
            deleteAttachmentFile('expense', $companyName, $fileName, $companyId);
        }
    }
}

// --- Notes helpers ---

function getUserNameAndId($conn, int $userId): ?array
{
    $stmt = $conn->prepare('SELECT Name, Surname, id FROM user WHERE id = ? LIMIT 1');
    if (!$stmt) {
        throw new Exception($conn->error);
    }
    $stmt->bind_param('i', $userId);
    if (!$stmt->execute()) {
        throw new Exception($conn->error);
    }
    $row = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    return $row ?: null;
}

function buildActionLogNotesLine(string $action, string $name, string $surname, int $id, ?string $at = null): string
{
    if ($at === null) {
        $at = date('Y-m-d H:i:s');
    }
    return $action . ' by ' . $name . ' ' . $surname . ' (id: ' . $id . ') at ' . $at . "\n";
}

function buildRetrieveNotesSuffix(string $name, string $surname, int $id, ?string $at = null): string
{
    return buildActionLogNotesLine('Retrieved', $name, $surname, $id, $at);
}

function buildDeleteNotesSuffix(string $name, string $surname, int $id, ?string $at = null): string
{
    return buildActionLogNotesLine('Deleted', $name, $surname, $id, $at);
}

function buildCreateNotesSuffix(string $name, string $surname, int $id, ?string $at = null): string
{
    return buildActionLogNotesLine('Created', $name, $surname, $id, $at);
}

function appendNotesSuffix(string $notes, string $suffix): string
{
    $notes = rtrim((string) $notes);
    if ($notes === '') {
        return $suffix;
    }
    return $notes . "\n" . $suffix;
}

function buildTransactionNotesOnCreate(string $name, string $surname, int $id, string $userNotes, ?string $at = null): string
{
    $suffix = buildCreateNotesSuffix($name, $surname, $id, $at);
    return appendNotesSuffix(trim($userNotes), $suffix);
}

// --- Row masking ---

function maskSoftDeletedIncomeRow(array $row): array
{
    if ($row['deletedAt'] !== null) { // soft-delete: hide amounts/notes/attachment flag
        $row['Income'] = null;
        $row['Notes'] = null;
        $row['hasAttachment'] = 0;
    }
    return $row;
}

function maskSoftDeletedExpenseRow(array $row): array
{
    if ($row['deletedAt'] !== null) { // soft-delete: hide amounts/notes/attachment flag
        $row['expense'] = null;
        $row['Notes'] = null;
        $row['hasAttachment'] = 0;
    }
    return $row;
}
