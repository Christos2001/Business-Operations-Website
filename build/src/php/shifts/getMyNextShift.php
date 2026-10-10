<?php

// getMyNextShift.php — next shift lookup, coworkers

// --- Initialization ---

    header('Content-Type: application/json');
    ini_set('display_errors', 0);
    ini_set('log_errors', 1);
    error_reporting(E_ALL);

// --- helpers ---

    function weekdayToNumber(string $dayName): ?int {
        $map = [ // ISO weekday number (1=Mon … 7=Sun)
            'Monday' => 1,
            'Tuesday' => 2,
            'Wednesday' => 3,
            'Thursday' => 4,
            'Friday' => 5,
            'Saturday' => 6,
            'Sunday' => 7,
        ];

        return $map[$dayName] ?? null;
    }

    function buildShiftDateTime(string $date, string $startTime): ?DateTime {
        $dt = DateTime::createFromFormat('Y-m-d H:i:s', $date . ' ' . $startTime);
        if ($dt === false) {
            $dt = DateTime::createFromFormat('Y-m-d H:i', $date . ' ' . substr($startTime, 0, 5));
        }
        return $dt ?: null;
    }

    function findNextWeeklyOccurrence(string $dayName, string $startTime, DateTime $now): ?DateTime {
        $targetDay = weekdayToNumber($dayName); // ISO weekday (1=Mon … 7=Sun)
        if ($targetDay === null) {
            return null;
        }

        $check = (clone $now)->setTime(0, 0, 0); // scan next 14 days for weekly match
        for ($i = 0; $i < 14; $i++) {
            if ((int) $check->format('N') === $targetDay) {
                $occurrence = buildShiftDateTime($check->format('Y-m-d'), $startTime);
                if ($occurrence && $occurrence > $now) {
                    return $occurrence;
                }
            }
            $check->modify('+1 day');
        }

        return null;
    }

    function shiftTimesOverlap(string $startA, string $endA, string $startB, string $endB): bool {
        $toMinutes = static function (string $time): int {
            [$hours, $minutes] = array_map('intval', explode(':', substr($time, 0, 5)));
            return ($hours * 60) + $minutes;
        };

        $startAMinutes = $toMinutes($startA);
        $endAMinutes = $toMinutes($endA);
        $startBMinutes = $toMinutes($startB);
        $endBMinutes = $toMinutes($endB);

        if ($endAMinutes < $startAMinutes) {
            $endAMinutes += 24 * 60;
        }
        if ($endBMinutes < $startBMinutes) {
            $endBMinutes += 24 * 60;
        }

        return ($startAMinutes < $endBMinutes && $startBMinutes < $endAMinutes)
            || ($startAMinutes < ($endBMinutes + 24 * 60)
                && ($startBMinutes + 24 * 60) < $endAMinutes)
            || (($startAMinutes + 24 * 60) < $endBMinutes
                && $startBMinutes < ($endAMinutes + 24 * 60));
    }

    function getCoworkersOnShift($conn, int $companyId, int $userId, array $shift): array {
        if (!empty($shift['date'])) {
            $stmt = $conn->prepare(
                "SELECT u.id, u.Name, u.Surname, s.startTime, s.endTime,
                        CASE WHEN u.profilePhotoFile IS NOT NULL AND u.profilePhotoFile <> '' THEN 1 ELSE 0 END AS hasPhoto
                 FROM shifts s
                 INNER JOIN user u ON u.id = s.userID
                 WHERE u.companyID = ? AND s.Date = ? AND s.userID != ?"
            );
            $stmt->bind_param('isi', $companyId, $shift['date'], $userId);
        } elseif (!empty($shift['day'])) {
            $stmt = $conn->prepare(
                "SELECT u.id, u.Name, u.Surname, s.startTime, s.endTime,
                        CASE WHEN u.profilePhotoFile IS NOT NULL AND u.profilePhotoFile <> '' THEN 1 ELSE 0 END AS hasPhoto
                 FROM shifts s
                 INNER JOIN user u ON u.id = s.userID
                 WHERE u.companyID = ? AND s.Day = ? AND s.userID != ?"
            );
            $stmt->bind_param('isi', $companyId, $shift['day'], $userId);
        } else {
            return [];
        }

        if (!$stmt->execute()) {
            throw new Exception(1);
        }

        $rows = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
        $stmt->close();

        $coworkers = [];
        $seen = []; // dedupe overlapping shift rows per coworker

        foreach ($rows as $row) {
            if (!shiftTimesOverlap($shift['startTime'], $shift['endTime'], $row['startTime'], $row['endTime'])) {
                continue;
            }

            $id = (int) $row['id'];
            if (isset($seen[$id])) {
                continue;
            }

            $seen[$id] = true;
            $coworkers[] = [
                'id' => $id,
                'name' => $row['Name'],
                'surname' => $row['Surname'],
                'hasPhoto' => !empty($row['hasPhoto']),
            ];
        }

        usort($coworkers, static function ($a, $b) {
            $left = $a['name'] . ' ' . $a['surname'];
            $right = $b['name'] . ' ' . $b['surname'];
            return strcasecmp($left, $right);
        });

        return $coworkers;
    }

// --- Initialization ---

    try {
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/secure_cookies.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/connect_to_DB.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/check_session.php';
        require_once $_SERVER['DOCUMENT_ROOT'] . '/php/common/auth_helpers.php';

// --- query ---

        $userId = getCurrentUserId($conn);
        $companyId = getCurrentCompanyId($conn);
        $stmt = $conn->prepare(
            'SELECT Date, Day, startTime, endTime FROM shifts WHERE userID = ?'
        );
        $stmt->bind_param('i', $userId);
        if (!$stmt->execute()) {
            throw new Exception(1);
        }
        $rows = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
        $stmt->close();

        $now = new DateTime();
        $candidates = []; // upcoming one-time + weekly occurrences

        foreach ($rows as $row) {
            if (!empty($row['Date'])) {
                $occurrence = buildShiftDateTime($row['Date'], $row['startTime']);
                if ($occurrence && $occurrence > $now) {
                    $candidates[] = [
                        'at' => $occurrence,
                        'startTime' => $row['startTime'],
                        'endTime' => $row['endTime'],
                        'date' => $row['Date'],
                        'day' => null,
                    ];
                }
                continue;
            }

            if (!empty($row['Day'])) {
                $occurrence = findNextWeeklyOccurrence($row['Day'], $row['startTime'], $now);
                if ($occurrence) {
                    $candidates[] = [
                        'at' => $occurrence,
                        'startTime' => $row['startTime'],
                        'endTime' => $row['endTime'],
                        'date' => null,
                        'day' => $row['Day'],
                    ];
                }
            }
        }

        if (count($candidates) === 0) {
            echo json_encode(['success' => true, 'shift' => null, 'coworkers' => []]);
            exit();
        }

        usort($candidates, static function ($a, $b) {
            return $a['at'] <=> $b['at'];
        });

        $next = $candidates[0]; // earliest upcoming shift
        $formatTime = static function ($timeStr) {
            return $timeStr ? substr($timeStr, 0, 5) : '';
        };

        echo json_encode([
            'success' => true,
            'shift' => [
                'dateLabel' => $next['at']->format('l, F j, Y'),
                'timeLabel' => $formatTime($next['startTime']) . ' – ' . $formatTime($next['endTime']),
                'profileDate' => $next['at']->format('Y-m-d'),
            ],
            'coworkers' => getCoworkersOnShift($conn, $companyId, $userId, $next),
        ]);
        exit();
    } catch (Throwable $e) {

// --- error ---

        logAppError($e);
        if (isDbUnavailable($e)) {
            respondDbUnavailable();
        }

        echo json_encode(['success' => false, 'errorMsg' => 'An error occured.']);
        exit();
    }
?>
