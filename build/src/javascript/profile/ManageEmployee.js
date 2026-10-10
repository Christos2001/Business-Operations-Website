// ManageEmployee.js — employee profile, notes, privilege management

// --- Initialization ---

const DEFAULT_PHOTO = 'data:image/svg+xml,' + encodeURIComponent(
    '<svg xmlns="http://www.w3.org/2000/svg" width="120" height="120" viewBox="0 0 120 120">' +
    '<rect width="120" height="120" fill="#e9ecef"/>' +
    '<circle cx="60" cy="45" r="22" fill="#adb5bd"/>' +
    '<ellipse cx="60" cy="95" rx="35" ry="28" fill="#adb5bd"/>' +
    '</svg>'
);

const params = new URLSearchParams(window.location.search);
const employeeId = params.get('i'); // employee being managed

if (!employeeId) {
    window.location.href = '/html/searchEmployee.html?q=manageEmp';
}

const employeeNameEl = document.getElementById('employeeName');
const profilePhotoEl = document.getElementById('profilePhoto');
const employeeEmailEl = document.getElementById('employeeEmail');
const employeeRoleEl = document.getElementById('employeeRole');
const employeeDescriptionEl = document.getElementById('employeeDescription');
const notesTitleEl = document.getElementById('notesTitle');
const employeeNotesHistoryEl = document.getElementById('employeeNotesHistory');
const newEmployeeNoteEl = document.getElementById('newEmployeeNote');
const addNoteBtn = document.getElementById('addNoteBtn');
const addNoteSectionEl = document.getElementById('addNoteSection');
const notesSectionEl = document.getElementById('notesSection');
const notesPrivilegesSeparatorEl = document.getElementById('notesPrivilegesSeparator');
const manageSectionEl = document.getElementById('manageSection');
const grantBtn = document.getElementById('grantBtn');

const privilegeCheckboxes = { // privilege key -> checkbox element
    income: document.getElementById('priv-income'),
    expenses: document.getElementById('priv-expenses'),
    'money-tracker': document.getElementById('priv-money-tracker'),
    shift: document.getElementById('priv-shift'),
    'manage-employees': document.getElementById('priv-manage-employees')
};

profilePhotoEl.src = DEFAULT_PHOTO;

// --- Helpers ---

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
            return { response, data: data.data, denied: true };
        }

        return { response, data };
    } catch (error) {
        window.handleFetchError(error);
        return null;
    }
}

function loadProfilePhoto(hasPhoto) {
    if (!hasPhoto) {
        profilePhotoEl.src = DEFAULT_PHOTO;
        return;
    }

    const photoUrl = '/php/profile/getUserFullProfile.php?i=' + encodeURIComponent(employeeId) + '&photo=1&t=' + Date.now();
    const img = new Image();
    img.onload = () => {
        profilePhotoEl.src = photoUrl;
    };
    img.onerror = () => {
        profilePhotoEl.src = DEFAULT_PHOTO;
    };
    img.src = photoUrl;
}

// --- Profile loading ---

async function loadPrivileges() {
    const result = await fetchJson('/php/profile/getEmployeePrivileges.php?i=' + encodeURIComponent(employeeId));
    if (!result || result.denied) {
        return;
    }

    const privileges = result.data.data;
    Object.keys(privilegeCheckboxes).forEach((key) => {
        privilegeCheckboxes[key].checked = !!privileges[key];
    });
}

function setNotesHistory(notes) {
    employeeNotesHistoryEl.value = notes || '';
    employeeNotesHistoryEl.scrollTop = employeeNotesHistoryEl.scrollHeight;
}

function populateProfile(profile) {
    employeeNameEl.textContent = profile.name + ' ' + profile.surname;
    employeeEmailEl.textContent = profile.email;
    employeeRoleEl.textContent = profile.role || 'No role provided.';
    employeeDescriptionEl.textContent = profile.description || 'No description provided.';
    loadProfilePhoto(profile.hasPhoto);

    if (profile.isManager) {
        notesSectionEl.style.display = 'none';
        notesPrivilegesSeparatorEl.style.display = 'none';
    } else {
        notesSectionEl.style.display = '';
        notesPrivilegesSeparatorEl.style.display = profile.canManage ? '' : 'none';
        notesTitleEl.textContent = 'Notes for ' + profile.name + ' ' + profile.surname;
        setNotesHistory(profile.notes);
        addNoteSectionEl.style.display = profile.canManage ? '' : 'none';
        newEmployeeNoteEl.value = '';
    }

    if (profile.canManage) {
        manageSectionEl.style.display = 'block';
        loadPrivileges();
    } else {
        manageSectionEl.style.display = 'none';
    }
}

async function loadProfile() {
    const result = await fetchJson('/php/profile/getUserFullProfile.php?i=' + encodeURIComponent(employeeId));
    if (!result) {
        return;
    }

    if (result.denied) {
        window.location.href = '/html/Starter/home.html';
        return;
    }

    populateProfile(result.data.data);
}

// --- Notes ---

addNoteBtn.addEventListener('click', async () => {
    const note = newEmployeeNoteEl.value.trim();
    if (!note) {
        alert('Write a note before adding.');
        return;
    }

    const body = new URLSearchParams();
    body.append('employeeID', employeeId);
    body.append('note', note);

    const result = await fetchJson('/php/profile/saveEmployeeNotes.php', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: body.toString()
    });

    if (!result) {
        return;
    }

    if (result.data.success) {
        setNotesHistory(result.data.notes || '');
        newEmployeeNoteEl.value = '';
        alert('Note added successfully!');
    } else {
        alert(result.data.errorMsg || 'Could not add note.');
    }
});

// --- Privileges ---

grantBtn.addEventListener('click', async () => {
    const body = new URLSearchParams();
    body.append('employeeID', employeeId);

    Object.keys(privilegeCheckboxes).forEach((key) => {
        if (privilegeCheckboxes[key].checked) {
            body.append(key, '1');
        }
    });

    const result = await fetchJson('/php/profile/saveEmployeePrivileges.php', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: body.toString()
    });

    if (!result) {
        return;
    }

    if (result.data.success) {
        alert('Privileges granted successfully!');
    }
});

// --- Page init ---

(async () => {
    await loadProfile();
})();
