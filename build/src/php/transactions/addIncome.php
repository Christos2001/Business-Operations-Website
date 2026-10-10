<?php

// addIncome.php — income record insert, attachment upload

// --- Initialization ---

    try {
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/secure_cookies.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/connect_to_DB.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/check_session.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/auth_helpers.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/transactions/attachment_helpers.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/transactions/transaction_soft_delete_helpers.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/transactions/transaction_input_helpers.php';

        requirePrivilege($conn, 'income');
        $companyId = getCurrentCompanyId($conn);
// --- validation ---

        $userId = getCurrentUserId($conn);

        $source = trim((string) ($_POST['source'] ?? ''));
        $sourceError = validateTransactionSource($source);
        if ($sourceError !== null) {
            respondTransactionInputError($sourceError);
        }

        [$amountError, $income] = validateTransactionAmount((string) ($_POST['income'] ?? ''));
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
            $sql = "INSERT INTO income (Source, Income, DateOfIncome, Notes, companyID) VALUES(?,?,?,?,?)";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("ssssi", $source, $income, $date, $notes, $companyId);
            if (!$stmt->execute()) {
                throw new Exception(1);
            }
            $incomeId = (int) $conn->insert_id;
            $stmt->close();

            if ($upload !== null) {
                $companyName = getAttachmentCompanyNameById($conn, $companyId);
                $savedFileName = saveAttachmentFile($upload, 'income', $companyName);
                insertIncomeAttachment($conn, $companyId, $incomeId, $savedFileName);
            }

            $conn->commit();
    // --- error ---

    } catch (Throwable $e) {
            $conn->rollback();
            if ($savedFileName !== null && $companyName !== null) {
                deleteAttachmentFile('income', $companyName, $savedFileName, $companyId);
            }
            throw $e;
        }

// --- response ---

        echo '<script type="text/javascript">';
        echo 'alert("Income saved successfully!");';
        echo 'window.location.href = "/html/transactions/records.html?type=Income";';
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
