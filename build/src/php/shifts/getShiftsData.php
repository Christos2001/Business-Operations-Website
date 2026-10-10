<?php

// getShiftsData.php — shifts calendar data query

// --- Initialization ---

    header('Content-Type: application/json');
    ini_set('display_errors', 0);
    ini_set('log_errors', 1);
    error_reporting(E_ALL);

    try {
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/secure_cookies.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/connect_to_DB.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/check_session.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/auth_helpers.php';

// --- query ---

        $companyId = getCurrentCompanyId($conn);
        $userFilter = isset($_GET['user']) ? (int) $_GET['user'] : null; // optional single-employee calendar view, used for delete shift / manage shift 

        if ($userFilter !== null && $userFilter > 0) {
            requirePrivilege($conn, 'shift');
            assertSameCompany($conn, $userFilter);
            $stmt = $conn->prepare(
                "SELECT s.userID, s.Date, s.Day, u.Name, u.Surname, u.username, s.startTime, s.endTime
                 FROM shifts s
                 INNER JOIN user u ON u.id = s.userID
                 WHERE u.companyID = ? AND s.userID = ?
                ");
            $stmt->bind_param('ii', $companyId, $userFilter);
            if (!$stmt->execute()) {
                throw new Exception(1);
            }
            $result = $stmt->get_result();
            $data = $result->fetch_all(MYSQLI_ASSOC);
            $stmt->close();

            $employeeStmt = $conn->prepare(
                'SELECT Name AS name, Surname AS surname FROM user WHERE id = ? AND companyID = ?'
            );
            $employeeStmt->bind_param('ii', $userFilter, $companyId);
            if (!$employeeStmt->execute()) {
                throw new Exception(1);
            }
            $employeeRow = $employeeStmt->get_result()->fetch_assoc();
            $employeeStmt->close();

            if ($employeeRow === false || !$employeeRow) {
                throw new Exception(1);
            }

            echo json_encode([
                'success' => true,
                'employee' => $employeeRow,
                'data' => $data,
            ]);
            exit();
        } else {
            $dateSearched = $_GET['date'] ?? null;
            $from = $dateSearched . '-01';
            $to = date('Y-m-d', strtotime($from . ' +1 month'));

            $firstFetch = filter_var($_GET['first'] ?? false, FILTER_VALIDATE_BOOLEAN);

            if ($dateSearched != null && $firstFetch){
                $stmt = $conn->prepare(
                    "SELECT s.userID, s.Date, s.Day, u.Name, u.Surname, u.username, s.startTime, s.endTime
                     FROM shifts s
                     INNER JOIN user u ON u.id = s.userID
                     WHERE u.companyID = ? AND (s.Date  IS NULL OR (s.Date > ? AND s.Date < ?)) 
                     "
                );
                $stmt->bind_param('iss', $companyId, $from,$to);
            }else if($dateSearched != null && !$firstFetch){
                $stmt = $conn->prepare(
                    "SELECT s.userID, s.Date, u.Name, u.Surname, u.username, s.startTime, s.endTime
                     FROM shifts s
                     INNER JOIN user u ON u.id = s.userID
                     WHERE u.companyID = ? AND (s.Date > ? AND s.Date < ?) 
                     "
                );
                $stmt->bind_param('iss', $companyId, $from,$to);
            }
            else
            {
                throw new Exception("$dataSearch was null.");
            }

            if (!$stmt->execute()) {
                throw new Exception(1);
            }
            $result = $stmt->get_result();
            $data = $result->fetch_all(MYSQLI_ASSOC);
            $stmt->close();
        }

        if ($data === false) {
            throw new Exception(1);
        }

        echo json_encode(["success" => true, "data" => $data]);
        exit();
// --- error ---

    } catch (Throwable $e) {
        logAppError($e);
        if (isDbUnavailable($e)) {
            respondDbUnavailable();
        }

        echo json_encode(["success" => false, "errorMsg" => "An error occured."]);
        exit();
    }
?>
