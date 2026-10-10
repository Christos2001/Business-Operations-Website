<?php

// email_verification_helpers.php — verification tokens, company codes

// --- Initialization ---

require_once __DIR__ . '/../common/mail/MailService.php';

// --- Verification tokens ---

function createVerificationToken($conn, int $userId, ?string $newEmail = null): string // null newEmail = signup verify
{
    $token = bin2hex(random_bytes(32));
    $expiresAt = date('Y-m-d H:i:s', time() + 86400); // 24h token lifetime

    $stmt = $conn->prepare(
        'DELETE FROM email_verification_tokens WHERE userID = ? AND newEmail <=> ?'
    );
    $stmt->bind_param('is', $userId, $newEmail);
    $stmt->execute();
    $stmt->close();

    $stmt = $conn->prepare(
        'INSERT INTO email_verification_tokens (token, userID, newEmail, expiresAt) VALUES (?, ?, ?, ?)'
    );
    $stmt->bind_param('siss', $token, $userId, $newEmail, $expiresAt);
    if (!$stmt->execute()) {
        throw new Exception(1);
    }
    $stmt->close();

    return $token;
}

function verifyEmailToken($conn, string $token): array
{
    $stmt = $conn->prepare(
        'SELECT t.userID, t.newEmail, t.expiresAt, u.username, u.email
         FROM email_verification_tokens t
         INNER JOIN user u ON u.id = t.userID
         WHERE t.token = ?
         LIMIT 1'
    );
    $stmt->bind_param('s', $token);
    if (!$stmt->execute()) {
        throw new Exception(1);
    }
    $row = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    if (!$row) {
        throw new Exception('Invalid verification link.');
    }

    if (strtotime($row['expiresAt']) < time()) {
        throw new Exception('Verification link has expired.');
    }

    return $row;
}

function completeEmailVerification($conn, string $token): void
{
    $row = verifyEmailToken($conn, $token);
    $userId = (int) $row['userID'];
    $newEmail = $row['newEmail']; // non-empty = pending email change

    $conn->begin_transaction();
    try {
        if ($newEmail !== null && $newEmail !== '') {
            $stmt = $conn->prepare('SELECT COUNT(*) AS total FROM user WHERE email = ? AND id <> ?');
            $stmt->bind_param('si', $newEmail, $userId);
            $stmt->execute();
            $count = (int) ($stmt->get_result()->fetch_assoc()['total'] ?? 0);
            $stmt->close();
            if ($count > 0) {
                throw new Exception('Email is already in use.');
            }

            $stmt = $conn->prepare('UPDATE user SET email = ?, emailVerified = 1 WHERE id = ?');
            $stmt->bind_param('si', $newEmail, $userId);
        } else {
            $stmt = $conn->prepare('UPDATE user SET emailVerified = 1 WHERE id = ?');
            $stmt->bind_param('i', $userId);
        }

        if (!$stmt->execute()) {
            throw new Exception(1);
        }
        $stmt->close();

        $stmt = $conn->prepare('DELETE FROM email_verification_tokens WHERE token = ?');
        $stmt->bind_param('s', $token);
        $stmt->execute();
        $stmt->close();

        $conn->commit();
    } catch (Throwable $e) {
        $conn->rollback();
        throw $e;
    }
}

// --- Company codes ---

function generateCompanyCode(int $length = 14): string // company signup invite code length
{
    $alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    $code = '';
    $max = strlen($alphabet) - 1;
    for ($i = 0; $i < $length; $i++) {
        $code .= $alphabet[random_int(0, $max)];
    }
    return $code;
}
