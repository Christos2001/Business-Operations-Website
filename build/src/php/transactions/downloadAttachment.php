<?php

// downloadAttachment.php — attachment file download

// --- Initialization ---

    try {
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/secure_cookies.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/connect_to_DB.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/check_session.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/auth_helpers.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/transactions/attachment_helpers.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/transactions/transaction_soft_delete_helpers.php';

// --- validation ---

        purgeExpiredSoftDeletedTransactions($conn);

        if (!isset($_GET['id']) || !isset($_GET['type'])) {
            http_response_code(400);
            exit('Missing parameters.');
        }

        $recordId = (int) $_GET['id'];
        $recordType = $_GET['type']; // income | expense attachment lookup
        $companyId = getCurrentCompanyId($conn);

// --- query ---

        if ($recordType === 'income') {
            requirePrivilege($conn, 'income');
            $stmt = $conn->prepare(
                'SELECT a.fileName
                 FROM attachments a
                 INNER JOIN income i ON i.id = a.incomeID
                 WHERE a.incomeID = ? AND a.companyID = ? AND i.companyID = ? AND i.deletedAt IS NULL'
            );
        } elseif ($recordType === 'expense') {
            requirePrivilege($conn, 'expenses');
            $stmt = $conn->prepare(
                'SELECT a.fileName
                 FROM attachments a
                 INNER JOIN expenses e ON e.id = a.expenseID
                 WHERE a.expenseID = ? AND a.companyID = ? AND e.companyID = ? AND e.deletedAt IS NULL'
            );
        } else {
            http_response_code(400);
            exit('Invalid record type.');
        }

        if (!$stmt) {
            throw new Exception(1);
        }

        $stmt->bind_param('iii', $recordId, $companyId, $companyId);
        if (!$stmt->execute()) {
            throw new Exception(1);
        }
        $row = $stmt->get_result()->fetch_assoc();
        $stmt->close();

        if (!$row) {
            http_response_code(404);
            exit('Attachment not found.');
        }

        $companyName = getAttachmentCompanyNameById($conn, $companyId);
        $path = getAttachmentPath($recordType, $companyName, $row['fileName'], $companyId);
        if (!is_file($path)) {
            http_response_code(404);
            exit('File not found.');
        }

        $finfo = new finfo(FILEINFO_MIME_TYPE);
        $mime = $finfo->file($path) ?: 'application/octet-stream';

        header('Content-Type: ' . $mime);
        header('Content-Disposition: inline; filename="' . basename($row['fileName']) . '"');
        header('Content-Length: ' . filesize($path));
// --- response ---

        readfile($path);
        exit();
// --- error ---

    } catch (Throwable $e) {
        logAppError($e);
        if (isDbUnavailable($e)) {
            respondDbUnavailable();
        }
        http_response_code(500);
        exit('An error occurred.');
    }
?>
