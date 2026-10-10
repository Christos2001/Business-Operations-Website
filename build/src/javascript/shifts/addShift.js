// addShift.js — weekly/one-time shift forms, date/time validation

// --- Initialization ---

const params = new URLSearchParams(window.location.search);
const employeeId = params.get("i"); // target employee from search flow

if (!employeeId) {
    window.location.href = '/html/searchEmployee.html?q=addShift';
}

document.querySelectorAll(".userID").forEach((input) => {
    input.value = employeeId;
});

function getLocalTodayString() {
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, "0");
    const day = String(now.getDate()).padStart(2, "0");
    return `${year}-${month}-${day}`;
}

const today = getLocalTodayString(); // local YYYY-MM-DD floor for one-time shifts
const oneTimeDate = document.getElementById("oneTimeDate");
oneTimeDate.min = today;
oneTimeDate.value = today;

// --- Date/time validation ---

function enforceMinDate() {
    if (oneTimeDate.value && oneTimeDate.value < today) {
        alert("Cannot pick a past date.");
        oneTimeDate.value = today;
    }
}

oneTimeDate.addEventListener("change", enforceMinDate);
oneTimeDate.addEventListener("input", enforceMinDate);

function getShiftHours(startTime, endTime) {
    const [startHour, startMinute] = startTime.split(":").map(Number);
    const [endHour, endMinute] = endTime.split(":").map(Number);
    const startTotal = startHour * 60 + startMinute;
    let endTotal = endHour * 60 + endMinute;

    if (endTotal < startTotal) {
        endTotal += 24 * 60;
    }

    return (endTotal - startTotal) / 60;
}

function validateShiftDuration(startTime, endTime) {
    if (!startTime || !endTime || startTime === endTime) {
        alert("Check-out must be after check-in.");
        return false;
    }

    const hours = getShiftHours(startTime, endTime);

    if (hours > 12) {
        alert("Shift cannot exceed 12 hours.");
        return false;
    }

    return true;
}

function startSubmitSpinner() {
    globalSpinner.start({ immediate: true });
}

// --- Form submission ---

document.getElementById("weeklyShiftForm").addEventListener("submit", (event) => {
    const startTime = document.querySelector(".weekly-start").value;
    const endTime = document.querySelector(".weekly-end").value;

    if (!validateShiftDuration(startTime, endTime)) {
        event.preventDefault();
        return;
    }

    startSubmitSpinner();
});

document.getElementById("oneTimeShiftForm").addEventListener("submit", (event) => {
    if (oneTimeDate.value < today) {
        alert("Cannot pick a past date.");
        event.preventDefault();
        return;
    }

    const startTime = document.querySelector(".onetime-start").value;
    const endTime = document.querySelector(".onetime-end").value;

    if (!validateShiftDuration(startTime, endTime)) {
        event.preventDefault();
        return;
    }

    startSubmitSpinner();
});
