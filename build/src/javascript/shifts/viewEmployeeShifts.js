// viewEmployeeShifts.js — shift listing, delete, access verification

// --- Initialization ---

const params = new URLSearchParams(window.location.search);
const employeeId = params.get('i'); // employee whose shifts are listed

if (!employeeId) {
    window.location.href = '/html/searchEmployee.html?q=viewShifts';
}

const employeeTitleEl = document.getElementById('employeeTitle');
const oneTimeListEl = document.getElementById('oneTimeList');
const weeklyListEl = document.getElementById('weeklyList');
const oneTimeEmptyEl = document.getElementById('oneTimeEmpty');
const weeklyEmptyEl = document.getElementById('weeklyEmpty');

const WEEKDAY_ORDER = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']; // sort key for recurring shifts

// --- Helpers ---

function formatTime(timeStr) {
    return timeStr ? timeStr.slice(0, 5) : '';
}

async function fetchJson(url, options = {}) {
    try {
        const response = await fetch(url, {
            credentials: 'same-origin',
            headers: { Accept: 'application/json', ...(options.headers || {}) },
            ...options
        });

        const data = await window.parseFetchJsonResponse(response);
        if (!data) {
            return null;
        }
        if (data.denied) {
            return { denied: true };
        }

        return data;
    } catch (error) {
        window.handleFetchError(error);
        return null;
    }
}

function canManageShifts(access) {
    return access.role === 'manager' || (access.privileges || []).includes('shift');
}

// --- Access verification ---

async function verifyAccess() {
    const access = await fetchJson('/php/common/getUserAccess.php');
    if (!access || access.denied || !access.success || !canManageShifts(access)) {
        window.location.href = '/html/shifts/calendar.html';
        return false;
    }
    return true;
}

async function loadEmployeeName(employee) {
    if (employee && employee.name) {
        employeeTitleEl.textContent = employee.name + ' ' + employee.surname + ' — Shifts';
    }
}

// --- Shift listing ---

function createShiftItem(shift, shiftType, label) {
    const li = document.createElement('li');
    li.className = 'shift-item';

    const info = document.createElement('div');
    info.className = 'shift-item-info';

    const labelEl = document.createElement('div');
    labelEl.className = 'shift-item-label';
    labelEl.textContent = label;

    const timesEl = document.createElement('div');
    timesEl.className = 'shift-item-times';
    timesEl.textContent = formatTime(shift.startTime) + ' – ' + formatTime(shift.endTime);

    info.appendChild(labelEl);
    info.appendChild(timesEl);

    const deleteBtn = document.createElement('button');
    deleteBtn.type = 'button';
    deleteBtn.className = 'shift-delete-btn';
    deleteBtn.textContent = 'Delete';

    deleteBtn.addEventListener('click', async () => {
        const confirmMsg = shiftType === 'weekly'
            ? 'Delete this weekly shift on ' + label + '?'
            : 'Delete this one-time shift on ' + label + '?';

        if (!window.confirm(confirmMsg)) {
            return;
        }

        const body = new URLSearchParams();
        body.append('userID', employeeId);
        body.append('shiftType', shiftType);
        body.append('startTime', shift.startTime);
        body.append('endTime', shift.endTime);

        if (shiftType === 'weekly') {
            body.append('day', shift.Day);
        } else {
            body.append('date', shift.Date);
        }

        const result = await fetchJson('/php/shifts/deleteShift.php', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: body.toString()
        });

        if (!result) {
            return;
        }

        if (result.success) {
            li.remove();
            updateEmptyStates();
            if (result.successMsg) {
                alert(result.successMsg);
            }
        } else {
            alert(result.errorMsg || 'Could not delete shift.');
        }
    });

    li.appendChild(info);
    li.appendChild(deleteBtn);
    return li;
}

function updateEmptyStates() {
    oneTimeEmptyEl.style.display = oneTimeListEl.children.length === 0 ? 'block' : 'none';
    weeklyEmptyEl.style.display = weeklyListEl.children.length === 0 ? 'block' : 'none';
}

function renderShifts(shifts) {
    oneTimeListEl.innerHTML = '';
    weeklyListEl.innerHTML = '';

    const oneTimeShifts = shifts
        .filter((s) => s.Date)
        .sort((a, b) => a.Date.localeCompare(b.Date));

    const weeklyShifts = shifts
        .filter((s) => s.Day)
        .sort((a, b) => WEEKDAY_ORDER.indexOf(a.Day) - WEEKDAY_ORDER.indexOf(b.Day));

    oneTimeShifts.forEach((shift) => {
        oneTimeListEl.appendChild(createShiftItem(shift, 'oneTime', shift.Date));
    });

    weeklyShifts.forEach((shift) => {
        weeklyListEl.appendChild(createShiftItem(shift, 'weekly', shift.Day));
    });

    updateEmptyStates();
}

async function loadShifts() {
    const result = await fetchJson('/php/shifts/getShiftsData.php?user=' + encodeURIComponent(employeeId));
    if (!result || result.denied) {
        window.location.href = '/html/shifts/calendar.html';
        return;
    }

    if (!result.success) {
        alert(result.errorMsg || 'Could not load shifts.');
        return;
    }

    const shifts = result.data || [];
    loadEmployeeName(result.employee);
    renderShifts(shifts);
}

// --- Page init ---

async function init() {
    const allowed = await verifyAccess();
    if (!allowed) {
        return;
    }
    await loadShifts();
}

init();
