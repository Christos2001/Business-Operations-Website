<?php

// saveEmployeeNotes.php — append employee manager note

// --- Initialization ---

    ini_set('display_errors', 0);
    ini_set('log_errors', 1);
    error_reporting(E_ALL);

    try {
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/secure_cookies.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/connect_to_DB.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/check_session.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/auth_helpers.php';
        require_once __DIR__ . '/employee_notes_helpers.php';

// --- validation ---

        header('Content-Type: application/json');

        $employeeId = isset($_POST['employeeID']) ? (int) $_POST['employeeID'] : 0;
        $note = trim($_POST['note'] ?? '');

        if ($employeeId <= 0) {
            http_response_code(400);
            echo json_encode(['success' => false, 'errorMsg' => 'Invalid employee ID.']);
            exit();
        }

        if ($note === '') {
            http_response_code(400);
            echo json_encode(['success' => false, 'errorMsg' => 'Note cannot be empty.']);
            exit();
        }

        if (mb_strlen($note) > EMPLOYEE_NOTE_BODY_MAX_LENGTH) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'errorMsg' => 'Note exceeds ' . EMPLOYEE_NOTE_BODY_MAX_LENGTH . ' characters.',
            ]);
            exit();
        }

// --- save ---

        $userId = getCurrentUserId($conn);
        if (!canManageEmployee($conn, $employeeId, $userId)) {
            http_response_code(403);
            echo json_encode(['success' => false, 'errorMsg' => 'Access denied.']);
            exit();
        }

        $editorStmt = $conn->prepare('SELECT Name, Surname FROM user WHERE id = ?');
        $editorStmt->bind_param('i', $userId);
        if (!$editorStmt->execute()) {
            throw new Exception(1);
        }
        $editor = $editorStmt->get_result()->fetch_assoc();
        $editorStmt->close();

        if (!$editor) {
            throw new Exception('User not found.');
        }

        $fetchStmt = $conn->prepare('SELECT notes FROM employee WHERE id = ?');
        $fetchStmt->bind_param('i', $employeeId);
        if (!$fetchStmt->execute()) {
            throw new Exception(1);
        }
        $row = $fetchStmt->get_result()->fetch_assoc();
        $fetchStmt->close();

        if (!$row) {
            echo json_encode(['success' => false, 'errorMsg' => 'Employee not found.']);
            exit();
        }

        $entry = buildEmployeeNoteEntry( // timestamped note block for history
            $editor['Name'],
            $editor['Surname'],
            $userId,
            $note
        );
        $updatedNotes = appendEmployeeNote($row['notes'] ?? '', $entry);

        if (mb_strlen($updatedNotes) > EMPLOYEE_NOTES_TOTAL_MAX_LENGTH) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'errorMsg' => 'Notes history is full. Contact an administrator.',
            ]);
            exit();
        }

        $stmt = $conn->prepare('UPDATE employee SET notes = ? WHERE id = ?');
        $stmt->bind_param('si', $updatedNotes, $employeeId);
        if (!$stmt->execute()) {
            throw new Exception(1);
        }
        if ($stmt->affected_rows === 0) {
            $stmt->close();
            echo json_encode(['success' => false, 'errorMsg' => 'Employee not found.']);
            exit();
        }
        $stmt->close();

        echo json_encode(['success' => true, 'notes' => $updatedNotes]);
        exit();
// --- error ---

    } catch (Throwable $e) {
        logAppError($e);
        if (isDbUnavailable($e)) {
            respondDbUnavailable();
        }

        if (!headers_sent()) {
            header('Content-Type: application/json');
        }

        echo json_encode(['success' => false, 'errorMsg' => 'An error occured.']);
        exit();
    }
