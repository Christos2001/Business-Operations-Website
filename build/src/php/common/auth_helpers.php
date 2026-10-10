<?php

// auth_helpers.php — privileges, company scope, access checks

// --- Initialization ---

require_once __DIR__ . '/../logs/log_helpers.php';

// --- Error handling ---

function authRethrowOrFail(Throwable $e) {
    logAppError($e);
    $known = ['0', '1', 'User not found.', 'Role not found.', 'Employee not found.', 'Photo not found.']; // pass through opaque/known errors
    if (in_array($e->getMessage(), $known, true)) {
        throw $e;
    }
    throw new Exception(1);
}

function denyAccess(): void {
    http_response_code(403);
    header('Content-Type: application/json');
    echo json_encode(['success' => false, 'errorMsg' => 'Access denied.']);
    exit();
}

// --- User and company context ---

function getCurrentCompanyId($conn) {
    try {
        $userId = getCurrentUserId($conn);
        $stmt = $conn->prepare('SELECT companyID FROM user WHERE id = ?');
        $stmt->bind_param('i', $userId);
        if (!$stmt->execute()) {
            throw new Exception(1);
        }
        $result = $stmt->get_result();
        $row = $result->fetch_assoc();
        $stmt->close();
        if ($row === false) {
            throw new Exception(1);
        }
        if (!$row) {
            throw new Exception('User not found.');
        }
        return (int) $row['companyID'];
    } catch (Throwable $e) {
        authRethrowOrFail($e);
    }
}

// --- Privileges ---

function requirePrivilege($conn, $key) {
    if (!hasPrivilege($conn, $key)) {
        denyAccess();
    }
}

function requireManager($conn, $userId = null): void {
    if (!isManager($conn, $userId)) {
        denyAccess();
    }
}

function requireAnyPrivilege($conn, array $keys) {
    foreach ($keys as $key) {
        if (hasPrivilege($conn, $key)) {
            return;
        }
    }
    denyAccess();
}

function assertSameCompany($conn, $targetUserId) {
    try {
        $companyId = getCurrentCompanyId($conn);
        $stmt = $conn->prepare('SELECT companyID FROM user WHERE id = ?');
        $stmt->bind_param('i', $targetUserId);
        if (!$stmt->execute()) {
            throw new Exception(1);
        }
        $result = $stmt->get_result();
        $row = $result->fetch_assoc();
        $stmt->close();
        if ($row === false) {
            throw new Exception(1);
        }
        if (!$row || (int) $row['companyID'] !== $companyId) {
            denyAccess();
        }
    } catch (Throwable $e) {
        authRethrowOrFail($e);
    }
}

function getCurrentUserId($conn) {
    try {
        $username = $_SESSION['username'];
        $stmt = $conn->prepare('SELECT id FROM user WHERE username = ?');
        $stmt->bind_param('s', $username);
        if (!$stmt->execute()) {
            throw new Exception(1);
        }
        $result = $stmt->get_result();
        $row = $result->fetch_assoc();
        $stmt->close();
        if ($row === false) {
            throw new Exception(1);
        }
        if (!$row) {
            throw new Exception('User not found.');
        }
        return (int)$row['id'];
    } catch (Throwable $e) {
        authRethrowOrFail($e);
    }
}

function isManager($conn, $userId = null) {
    try {
        if ($userId === null) {
            $userId = getCurrentUserId($conn);
        }

        $stmt = $conn->prepare('SELECT id FROM manager WHERE id = ?');
        $stmt->bind_param('i', $userId);
        if (!$stmt->execute()) {
            throw new Exception(1);
        }
        $result = $stmt->get_result();
        $row = $result->fetch_assoc();
        $stmt->close();
        if ($row === false) {
            throw new Exception(1);
        }
        return $row !== null;
    } catch (Throwable $e) {
        authRethrowOrFail($e);
    }
}

function getPrivilegeRow($conn, $employeeId) {
    try {
        $stmt = $conn->prepare(
            'SELECT `income`, `expenses`, `money-tracker`, `shift`, `manage-employees`
             FROM privileges WHERE employeeID = ?'
        );
        $stmt->bind_param('i', $employeeId);
        if (!$stmt->execute()) {
            throw new Exception(1);
        }
        $result = $stmt->get_result();
        $row = $result->fetch_assoc();
        $stmt->close();
        if ($row === false) {
            throw new Exception(1);
        }
        return $row ?: null;
    } catch (Throwable $e) {
        authRethrowOrFail($e);
    }
}

function getGrantedPrivileges($conn, $employeeId) {
    try {
        $row = getPrivilegeRow($conn, $employeeId);
        if (!$row) {
            return [];
        }

        $privilegeKeys = ['income', 'expenses', 'money-tracker', 'shift', 'manage-employees']; // DB privilege bit columns
        $granted = [];
        foreach ($privilegeKeys as $key) {
            if (!empty($row[$key])) {
                $granted[] = $key;
            }
        }
        return $granted;
    } catch (Throwable $e) {
        authRethrowOrFail($e);
    }
}

function getUserAccessPayload($conn) {
    $userId = getCurrentUserId($conn);

    if (isManager($conn, $userId)) {
        return [
            'role' => 'manager',
            'userId' => $userId,
            'privileges' => ['income', 'expenses', 'money-tracker', 'shift', 'manage-employees'], // managers get all bits
        ];
    }

    $stmt = $conn->prepare('SELECT id FROM employee WHERE id = ?');
    $stmt->bind_param('i', $userId);
    if (!$stmt->execute()) {
        throw new Exception(1);
    }
    $result = $stmt->get_result();
    $row = $result->fetch_assoc();
    $stmt->close();

    if ($row === false) {
        throw new Exception(1);
    }
    if ($row === null) {
        throw new Exception('Role not found.');
    }

    return [
        'role' => 'employee',
        'userId' => $userId,
        'privileges' => getGrantedPrivileges($conn, $userId),
    ];
}

function hasPrivilege($conn, $privilege, $userId = null) {
    try {
        if ($userId === null) {
            $userId = getCurrentUserId($conn);
        }
        if (isManager($conn, $userId)) {
            return true;
        }

        $row = getPrivilegeRow($conn, $userId);
        if (!$row) {
            return false;
        }
        return !empty($row[$privilege]);
    } catch (Throwable $e) {
        authRethrowOrFail($e);
    }
}

function isEligiblePrivilegeTarget($conn, $targetId, $userId = null) {
    try {
        if ($userId === null) {
            $userId = getCurrentUserId($conn);
        }
        if ((int)$targetId === (int)$userId) {
            return false;
        }
        if (isManager($conn, $targetId)) {
            return false;
        }
        return true;
    } catch (Throwable $e) {
        authRethrowOrFail($e);
    }
}

function canManageEmployee($conn, $targetId, $userId = null) {
    try {
        if ($userId === null) {
            $userId = getCurrentUserId($conn);
        }
        if (isManager($conn, $targetId)) {
            return false;
        }
        if (isManager($conn, $userId)) {
            return true;
        }
        if (!hasPrivilege($conn, 'manage-employees', $userId)) {
            return false;
        }
        return isEligiblePrivilegeTarget($conn, $targetId, $userId);
    } catch (Throwable $e) {
        authRethrowOrFail($e);
    }
}

// --- Shift and profile access ---

function userHasShiftOnDate($conn, $userId, $date) {
    try {
        if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $date)) {
            return false;
        }

        $weekday = date('l', strtotime($date)); // match recurring weekly shifts (Day column)
        $stmt = $conn->prepare(
            'SELECT 1 FROM shifts
             WHERE userID = ? AND (Date = ? OR (Date IS NULL AND Day = ?))
             LIMIT 1'
        );
        $stmt->bind_param('iss', $userId, $date, $weekday);
        if (!$stmt->execute()) {
            throw new Exception(1);
        }
        $result = $stmt->get_result();
        $row = $result->fetch_assoc();
        $stmt->close();
        if ($row === false) {
            throw new Exception(1);
        }
        return $row !== null;
    } catch (Throwable $e) {
        authRethrowOrFail($e);
    }
}

function shareShiftOnDate($conn, $userId, $targetId, $date) {
    try {
        return userHasShiftOnDate($conn, $userId, $date)
            && userHasShiftOnDate($conn, $targetId, $date);
    } catch (Throwable $e) {
        authRethrowOrFail($e);
    }
}

function canViewProfile($conn, $targetId, $userId = null, $shiftDate = null) {
    try {
        if ($userId === null) {
            $userId = getCurrentUserId($conn);
        }

        if ((int) $targetId === (int) $userId) {
            return true;
        }
        if (canAccessManagment($conn, $userId)) {
            return true;
        }

        assertSameCompany($conn, $targetId);
        return true;
    } catch (Throwable $e) {
        authRethrowOrFail($e);
    }
}

function canViewEmployeeProfile($conn, $targetId, $userId = null) {
    try {
        if ($userId === null) {
            $userId = getCurrentUserId($conn);
        }
        if (!canAccessManagment($conn, $userId)) {
            return false;
        }
        return (int)$targetId !== (int)$userId;
    } catch (Throwable $e) {
        authRethrowOrFail($e);
    }
}

function canAccessManagment($conn, $userId = null) {
    try {
        if ($userId === null) {
            $userId = getCurrentUserId($conn);
        }
        return isManager($conn, $userId) || hasPrivilege($conn, 'manage-employees', $userId);
    } catch (Throwable $e) {
        authRethrowOrFail($e);
    }
}


