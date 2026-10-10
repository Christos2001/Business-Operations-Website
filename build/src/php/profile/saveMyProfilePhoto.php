<?php

// saveMyProfilePhoto.php — profile photo upload, validation, storage

// --- Initialization ---

    $photoMaxBytes = 150 * 1024 * 1024; // reject oversized body before parsing multipart

// --- helpers ---

    function respondPhotoUploadJson(array $payload, int $status = 200): void {
        if (ob_get_level() > 0) {
            ob_end_clean();
        }
        if (!headers_sent()) {
            header('Content-Type: application/json; charset=UTF-8');
            http_response_code($status);
        }
        echo json_encode($payload);
        exit();
    }

// --- validation ---

    $contentLength = (int) ($_SERVER['CONTENT_LENGTH'] ?? 0);
    if ($contentLength > $photoMaxBytes) {
        error_log('Profile photo upload rejected: ' . $contentLength . ' bytes exceeds ' . $photoMaxBytes . ' byte limit.');
        respondPhotoUploadJson(['success' => false, 'errorMsg' => 'Photo must be 150 MB or smaller.'], 413);
    }

// --- Initialization ---

    ob_start();
    ini_set('display_errors', '0');
    ini_set('log_errors', '1');
    error_reporting(E_ALL);

    try {
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/secure_cookies.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/connect_to_DB.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/check_session.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/auth_helpers.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/profile/profile_photo_helpers.php';

        $sessionUserId = getCurrentUserId($conn);
        $companyId = getCurrentCompanyId($conn);
        $companyName = getCompanyNameById($conn, $companyId);

        if (!isset($_FILES['photo'])) {
            if ($contentLength > 0) {
                respondPhotoUploadJson(['success' => false, 'errorMsg' => 'Photo must be 150 MB or smaller.'], 413);
            }
            respondPhotoUploadJson(['success' => false, 'errorMsg' => 'No photo uploaded.'], 400);
        }

// --- save photo ---

        $oldFileName = getProfilePhotoFileName($conn, $sessionUserId); // replace-on-success cleanup target
        $upload = validateUploadedProfilePhoto($_FILES['photo']);
        $storedName = saveProfilePhotoFile($upload, $companyName, $sessionUserId, $companyId);

        try {
            $stmt = $conn->prepare('UPDATE user SET profilePhotoFile = ? WHERE id = ?');
            $stmt->bind_param('si', $storedName, $sessionUserId);
            if (!$stmt->execute()) {
                throw new Exception(1);
            }
            $stmt->close();
        } catch (Throwable $e) {
            deleteProfilePhotoFile($companyName, $storedName, $companyId);
            throw $e;
        }

        if ($oldFileName !== null) {
            deleteProfilePhotoFile($companyName, $oldFileName, $companyId);
        }

        respondPhotoUploadJson(['success' => true]);
    } catch (Throwable $e) {

// --- error ---

        logAppError($e);
        if (isDbUnavailable($e)) {
            if (ob_get_level() > 0) {
                ob_end_clean();
            }
            respondDbUnavailable();
        }

        $knownMessages = [
            'No photo uploaded.',
            'Photo must be 150 MB or smaller.',
            PROFILE_PHOTO_INVALID_TYPE_MSG,
            'Upload was interrupted. Please try again.',
            'Upload failed.',
        ];
        if (in_array($e->getMessage(), $knownMessages, true)) {
            respondPhotoUploadJson(['success' => false, 'errorMsg' => $e->getMessage()], 400);
        }

        respondPhotoUploadJson(['success' => false, 'errorMsg' => 'An error occured.'], 500);
    }
