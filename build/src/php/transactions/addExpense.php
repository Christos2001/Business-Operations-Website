<?php

// addExpense.php — expense record insert, attachment upload

// --- Initialization ---

    try {
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/secure_cookies.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/connect_to_DB.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/check_session.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/auth_helpers.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/transactions/attachment_helpers.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/transactions/transaction_soft_delete_helpers.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/transactions/transaction_input_helpers.php';

        requirePrivilege($conn, 'expenses');
        $companyId = getCurrentCompanyId($conn);
// --- validation ---

        $userId = getCurrentUserId($conn);

        $source = trim((string) ($_POST['source'] ?? ''));
        $sourceError = validateTransactionSource($source);
        if ($sourceError !== null) {
            respondTransactionInputError($sourceError);
        }

        [$amountError, $expense] = validateTransactionAmount((string) ($_POST['expense'] ?? ''));
        if ($amountError !== null) {
            respondTransactionInputError($amountError);
        }

        $date = $_POST['date'];
        $userNotes = trim((string) ($_POST['notes'] ?? ''));
        $notesError = validateTransactionNotes($userNotes);
        if ($notesError !== null) {
            respondTransactionInputError($notesError);
        }

        $upload = validateUploadedAttachment($_FILES['attachment'] ?? []); // null = no file attached

        $user = getUserNameAndId($conn, $userId);
        if ($user === null) {
            throw new Exception(1);
        }
        $notes = buildTransactionNotesOnCreate(
            $user['Name'],
            $user['Surname'],
            (int) $user['id'],
            $userNotes
        );

        $savedFileName = null; // rollback orphan file on DB failure
        $companyName = null;
// --- save ---

        $conn->begin_transaction();

        try {
            $sql = "INSERT INTO expenses (source, expense, DateOfExpense, Notes, companyID) VALUES(?,?,?,?,?)";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("ssssi", $source, $expense, $date, $notes, $companyId);
            if (!$stmt->execute()) {
                throw new Exception(1);
            }
            $expenseId = (int) $conn->insert_id;
            $stmt->close();

            if ($upload !== null) {
                $companyName = getAttachmentCompanyNameById($conn, $companyId);
                $savedFileName = saveAttachmentFile($upload, 'expense', $companyName);
                insertExpenseAttachment($conn, $companyId, $expenseId, $savedFileName);
            }

            $conn->commit();
    // --- error ---

    } catch (Throwable $e) {
            $conn->rollback();
            if ($savedFileName !== null && $companyName !== null) {
                deleteAttachmentFile('expense', $companyName, $savedFileName, $companyId);
            }
            throw $e;
        }

// --- response ---

        echo '<script type="text/javascript">';
        echo 'alert("Expense saved successfully!");';
        echo 'window.location.href = "/html/transactions/records.html?type=Expense";';
        echo '</script>';
        exit();
    } catch (Throwable $e) {
        logAppError($e);
        if (isDbUnavailable($e)) {
            respondDbUnavailable('html');
        }

        if ($e->getMessage() === 'Invalid file upload.' || $e->getMessage() === 'File must be 150 MB or smaller.' || $e->getMessage() === ATTACHMENT_INVALID_TYPE_MSG) {
            echo '<script type="text/javascript">';
            echo 'alert(' . json_encode($e->getMessage()) . ');';
            echo 'window.history.back()';
            echo '</script>';
            exit();
        }

        echo '<script type="text/javascript">';
        echo 'alert("An error occured.");';
        echo 'window.history.back()';
        echo '</script>';
        exit();
    }
?>
