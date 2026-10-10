<?php

// validate_shift.php — shift date, time, day validation

// --- Shift date ---

    function validateShiftDate($date) {
        $today = date('Y-m-d');

        if ($date < $today) {
            throw new Exception("Cannot pick a past date.");
        }
    }

// --- Shift duration ---

    function validateShiftDuration($startTime, $endTime) {
        $start = strtotime($startTime);
        $end = strtotime($endTime);

        if ($start === false || $end === false) {
            throw new Exception("Invalid time.");
        }

        if ($end === $start) {
            throw new Exception("Check-out must be after check-in.");
        }

        if ($end < $start) {
            $end += 24 * 60 * 60;
        }

        $hours = ($end - $start) / 3600; // shift length for 12h cap

        if ($hours > 12) {
            throw new Exception("Shift cannot exceed 12 hours.");
        }
    }

// --- Shift day ---

    function validateShiftDay($day) {
        $days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]; // allowed Day column values

        if (!in_array($day, $days, true)) {
            throw new Exception("No day found.");
        }
    }
?>
