<?php

// account_recovery_helpers.php — recovery tokens, password/username reset

// --- Initialization ---

require_once __DIR__ . '/../common/mail/MailService.php';

// --- User lookup ---

function findUserByEmail($conn, string $email): ?array
{
    $stmt = $conn->prepare('SELECT id, username, email FROM user WHERE email = ? LIMIT 1');
    $stmt->bind_param('s', $email);
    if (!$stmt->execute()) {
        throw new Exception(1);
    }
    $row = $stmt->get_result()->fetch_assoc();
    $stmt->close();
    return $row ?: null;
}

// --- Recovery tokens ---

function createRecoveryToken($conn, int $userId, string $type): string
{
    if ($type !== 'password' && $type !== 'username') { // recovery token kind
        throw new Exception('Invalid recovery type.');
    }

    $token = bin2hex(random_bytes(32));
    $expiresAt = date('Y-m-d H:i:s', time() + 86400); // 24h token lifetime

    $stmt = $conn->prepare('DELETE FROM account_recovery_tokens WHERE userID = ? AND type = ?');
    $stmt->bind_param('is', $userId, $type);
    $stmt->execute();
    $stmt->close();

    $stmt = $conn->prepare(
        'INSERT INTO account_recovery_tokens (token, userID, type, expiresAt) VALUES (?, ?, ?, ?)'
    );
    $stmt->bind_param('siss', $token, $userId, $type, $expiresAt);
    if (!$stmt->execute()) {
        throw new Exception(1);
    }
    $stmt->close();

    return $token;
}

function getRecoveryToken($conn, string $token, string $type): array
{
    $stmt = $conn->prepare(
        'SELECT t.userID, t.type, t.expiresAt, u.username, u.email
         FROM account_recovery_tokens t
         INNER JOIN user u ON u.id = t.userID
         WHERE t.token = ? AND t.type = ?
         LIMIT 1'
    );
    $stmt->bind_param('ss', $token, $type);
    if (!$stmt->execute()) {
        throw new Exception(1);
    }
    $row = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    if (!$row) {
        throw new Exception('Invalid or expired recovery link.');
    }

    if (strtotime($row['expiresAt']) < time()) {
        throw new Exception('Recovery link has expired.');
    }

    return $row;
}

function deleteRecoveryToken($conn, string $token): void
{
    $stmt = $conn->prepare('DELETE FROM account_recovery_tokens WHERE token = ?');
    $stmt->bind_param('s', $token);
    $stmt->execute();
    $stmt->close();
}

// --- Reset completion ---

function completePasswordReset($conn, string $token, string $password): void
{
    $row = getRecoveryToken($conn, $token, 'password');
    $userId = (int) $row['userID'];

    
    if (strlen($password) < 8 || !preg_match('/(?=.*[A-Za-z])(?=.*\d)/', $password)) {
        throw new Exception('Password must be at least 8 characters with one letter and one number.');
    }

    $hashedPassword = password_hash($password, PASSWORD_DEFAULT);

    $conn->begin_transaction();
    try {
        $stmt = $conn->prepare('UPDATE user SET password = ? WHERE id = ?');
        $stmt->bind_param('si', $hashedPassword, $userId);
        if (!$stmt->execute()) {
            throw new Exception(1);
        }
        $stmt->close();

        deleteRecoveryToken($conn, $token);
        $conn->commit();
    } catch (Throwable $e) {
        $conn->rollback();
        throw $e;
    }
}

function completeUsernameReset($conn, string $token, string $newUsername): void
{
    $row = getRecoveryToken($conn, $token, 'username');
    $userId = (int) $row['userID'];

    if (strlen($newUsername) < 7) {
        throw new Exception('Username must be at least 7 characters.');
    }

    $stmt = $conn->prepare('SELECT COUNT(*) AS total FROM user WHERE username = ? AND id <> ?');
    $stmt->bind_param('si', $newUsername, $userId);
    $stmt->execute();
    if ((int) ($stmt->get_result()->fetch_assoc()['total'] ?? 0) > 0) {
        $stmt->close();
        throw new Exception('Username is already taken.');
    }
    $stmt->close();

    $conn->begin_transaction();
    try {
        $stmt = $conn->prepare('UPDATE user SET username = ? WHERE id = ?');
        $stmt->bind_param('si', $newUsername, $userId);
        if (!$stmt->execute()) {
            throw new Exception(1);
        }
        $stmt->close();

        deleteRecoveryToken($conn, $token);
        $conn->commit();
    } catch (Throwable $e) {
        $conn->rollback();
        throw $e;
    }
}
