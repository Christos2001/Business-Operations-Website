<?php

// attachment_helpers.php — file upload validation, storage

// --- Initialization ---


define('ATTACHMENT_UPLOAD_DIR', dirname(__DIR__, 3) . '/uploads'); // {income|expense}/{companyName}/{hex}_{sanitizedName}.ext
const ATTACHMENT_MAX_BYTES = 150 * 1024 * 1024; // per-file upload cap
const ATTACHMENT_INVALID_TYPE_MSG = 'Only pdf, jpg, png, xml, csv, json, eml, txt, docx, and zip files are allowed.';
const ATTACHMENT_ACCEPT_EXTENSIONS = '.pdf,.jpg,.jpeg,.png,.xml,.csv,.json,.eml,.txt,.docx,.zip'; // HTML input accept list
const ATTACHMENT_ALLOWED_TYPES = ['income', 'expense']; // folder names under uploads/
const ATTACHMENT_ALLOWED_MIMES = [ // mime → stored extension
    'application/pdf' => 'pdf',
    'image/jpeg' => 'jpg',
    'image/png' => 'png',
    'application/xml' => 'xml',
    'text/xml' => 'xml',
    'text/csv' => 'csv',
    'application/csv' => 'csv',
    'application/json' => 'json',
    'message/rfc822' => 'eml',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document' => 'docx',
];
const ATTACHMENT_EXTENSION_MAP = [ // filename ext → normalized ext
    'pdf' => 'pdf',
    'jpg' => 'jpg',
    'jpeg' => 'jpg',
    'png' => 'png',
    'xml' => 'xml',
    'csv' => 'csv',
    'json' => 'json',
    'eml' => 'eml',
    'txt' => 'txt',
    'docx' => 'docx',
    'zip' => 'zip',
];
const ATTACHMENT_ZIP_MIMES = [ // finfo reports both .zip and .docx as zip
    'application/zip',
    'application/x-zip-compressed',
];
const ATTACHMENT_FALLBACK_MIMES = [ // allow ext match when finfo is generic
    'text/plain',
    'application/octet-stream',
];

// --- Validation ---

function attachmentZipIsDocx(string $path): bool
{
    if (!class_exists(ZipArchive::class)) {
        return false;
    }

    $zip = new ZipArchive();
    if ($zip->open($path) !== true) {
        return false;
    }

    $isDocx = $zip->locateName('word/document.xml') !== false;
    $zip->close();
    return $isDocx;
}

function resolveAttachmentExtension(array $file, string $mime): ?string
{
    if (in_array($mime, ATTACHMENT_ZIP_MIMES, true)) {
        $path = $file['tmp_name'] ?? '';
        if ($path !== '' && attachmentZipIsDocx($path)) {
            return 'docx';
        }
        return 'zip';
    }

    if (isset(ATTACHMENT_ALLOWED_MIMES[$mime])) {
        return ATTACHMENT_ALLOWED_MIMES[$mime];
    }

    $ext = strtolower(pathinfo($file['name'] ?? '', PATHINFO_EXTENSION));
    if (!isset(ATTACHMENT_EXTENSION_MAP[$ext])) {
        return null;
    }

    if (!in_array($mime, ATTACHMENT_FALLBACK_MIMES, true)) {
        return null;
    }

    return ATTACHMENT_EXTENSION_MAP[$ext];
}

function validateUploadedAttachment(array $file): ?array
{
    if (!isset($file['error']) || $file['error'] === UPLOAD_ERR_NO_FILE) {
        return null;
    }

    if ($file['error'] !== UPLOAD_ERR_OK) {
        throw new Exception('Invalid file upload.');
    }

    if (($file['size'] ?? 0) > ATTACHMENT_MAX_BYTES) {
        throw new Exception('File must be 150 MB or smaller.');
    }

    $finfo = new finfo(FILEINFO_MIME_TYPE);
    $mime = $finfo->file($file['tmp_name']);
    $extension = resolveAttachmentExtension($file, $mime);
    if ($extension === null) {
        throw new Exception(ATTACHMENT_INVALID_TYPE_MSG);
    }

    return [
        'tmp_name' => $file['tmp_name'],
        'extension' => $extension,
        'original_name' => $file['name'] ?? 'attachment',
    ];
}

function sanitizeAttachmentOriginalName(string $name): string
{
    $base = basename($name);
    $base = preg_replace('/[^a-zA-Z0-9._-]/', '_', $base) ?? 'attachment';
    $base = trim($base, '._-');
    if ($base === '') {
        return 'attachment';
    }
    return substr($base, 0, 100);
}

// --- Paths ---

function normalizeAttachmentType(string $type): string
{
    $type = strtolower(trim($type));
    if (!in_array($type, ATTACHMENT_ALLOWED_TYPES, true)) {
        throw new Exception('Invalid attachment type.');
    }
    return $type;
}

function sanitizeAttachmentCompanyDirName(string $companyName): string
{
    $name = trim($companyName);
    $name = preg_replace('/[\\\\\/\:\*\?\"\<\>\|\x00-\x1F]+/', '_', $name) ?? '';
    $name = trim($name, " .");
    if ($name === '' || $name === '.' || $name === '..') {
        throw new Exception('Could not create upload directory.');
    }
    return $name;
}

function getAttachmentCompanyNameById($conn, int $companyId): string
{
    $stmt = $conn->prepare('SELECT name FROM company WHERE id = ?');
    $stmt->bind_param('i', $companyId);
    if (!$stmt->execute()) {
        throw new Exception(1);
    }
    $row = $stmt->get_result()->fetch_assoc();
    $stmt->close();
    if (!$row || empty($row['name'])) {
        throw new Exception(1);
    }
    return (string) $row['name'];
}

function ensureAttachmentCompanyDir(string $type, string $companyName): string
{
    $type = normalizeAttachmentType($type);
    $dirName = sanitizeAttachmentCompanyDirName($companyName);
    $companyDir = ATTACHMENT_UPLOAD_DIR . '/' . $type . '/' . $dirName; // type + company-scoped folder

    if (!is_dir($companyDir) && !mkdir($companyDir, 0755, true) && !is_dir($companyDir)) {
        throw new Exception('Could not create upload directory.');
    }
    return $companyDir;
}

// --- Storage ---

function saveAttachmentFile(array $upload, string $type, string $companyName): string
{
    $companyDir = ensureAttachmentCompanyDir($type, $companyName);

    $storedName = bin2hex(random_bytes(16)) . '_' . sanitizeAttachmentOriginalName($upload['original_name']); // random prefix + safe original name
    if (!str_ends_with(strtolower($storedName), '.' . $upload['extension'])) {
        $storedName .= '.' . $upload['extension'];
    }

    $destination = $companyDir . '/' . $storedName;
    if (!move_uploaded_file($upload['tmp_name'], $destination)) {
        throw new Exception('Could not save uploaded file.');
    }

    return $storedName;
}

function getAttachmentPath(string $type, string $companyName, string $fileName, ?int $legacyCompanyId = null): string
{
    $type = normalizeAttachmentType($type);
    $fileName = basename($fileName);
    $byName = ATTACHMENT_UPLOAD_DIR . '/' . $type . '/' . sanitizeAttachmentCompanyDirName($companyName) . '/' . $fileName;
    if (is_file($byName) || $legacyCompanyId === null) {
        return $byName;
    }

    // legacy layout: uploads/{companyId}/...
    $byId = ATTACHMENT_UPLOAD_DIR . '/' . $legacyCompanyId . '/' . $fileName;
    if (is_file($byId)) {
        return $byId;
    }

    return $byName;
}

function deleteAttachmentFile(string $type, string $companyName, string $fileName, ?int $legacyCompanyId = null): void
{
    if ($fileName === '') {
        return;
    }

    $path = getAttachmentPath($type, $companyName, $fileName, $legacyCompanyId);
    if (is_file($path)) {
        unlink($path);
    }
}

// --- Database ---

function insertIncomeAttachment($conn, int $companyId, int $incomeId, string $fileName): void
{
    $stmt = $conn->prepare('INSERT INTO attachments (companyID, fileName, incomeID) VALUES (?, ?, ?)');
    if (!$stmt) {
        throw new Exception(1);
    }
    $stmt->bind_param('isi', $companyId, $fileName, $incomeId);
    if (!$stmt->execute()) {
        throw new Exception(1);
    }
    $stmt->close();
}

function insertExpenseAttachment($conn, int $companyId, int $expenseId, string $fileName): void
{
    $stmt = $conn->prepare('INSERT INTO attachments (companyID, fileName, expenseID) VALUES (?, ?, ?)');
    if (!$stmt) {
        throw new Exception(1);
    }
    $stmt->bind_param('isi', $companyId, $fileName, $expenseId);
    if (!$stmt->execute()) {
        throw new Exception(1);
    }
    $stmt->close();
}

function getAttachmentFileNameForIncome($conn, int $incomeId, int $companyId): ?string
{
    $stmt = $conn->prepare('SELECT fileName FROM attachments WHERE incomeID = ? AND companyID = ? LIMIT 1');
    if (!$stmt) {
        throw new Exception(1);
    }
    $stmt->bind_param('ii', $incomeId, $companyId);
    if (!$stmt->execute()) {
        throw new Exception(1);
    }
    $row = $stmt->get_result()->fetch_assoc();
    $stmt->close();
    return $row ? $row['fileName'] : null;
}

function getAttachmentFileNameForExpense($conn, int $expenseId, int $companyId): ?string
{
    $stmt = $conn->prepare('SELECT fileName FROM attachments WHERE expenseID = ? AND companyID = ? LIMIT 1');
    if (!$stmt) {
        throw new Exception(1);
    }
    $stmt->bind_param('ii', $expenseId, $companyId);
    if (!$stmt->execute()) {
        throw new Exception(1);
    }
    $row = $stmt->get_result()->fetch_assoc();
    $stmt->close();
    return $row ? $row['fileName'] : null;
}
