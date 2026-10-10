// profile.js — profile view/edit, photo upload, email change, account deletion

// --- Initialization ---

const DEFAULT_PHOTO = 'data:image/svg+xml,' + encodeURIComponent(
    '<svg xmlns="http://www.w3.org/2000/svg" width="120" height="120" viewBox="0 0 120 120">' +
    '<rect width="120" height="120" fill="#e9ecef"/>' +
    '<circle cx="60" cy="45" r="22" fill="#adb5bd"/>' +
    '<ellipse cx="60" cy="95" rx="35" ry="28" fill="#adb5bd"/>' +
    '</svg>'
);

const params = new URLSearchParams(window.location.search);
const profileUserId = params.get('i'); // omitted = own profile
const shiftDate = params.get('date'); // calendar day context for profile photo/links

const profileNameEl = document.getElementById('profileName');
const profilePhotoEl = document.getElementById('profilePhoto');
const profileEmailEl = document.getElementById('profileEmail');
const profileRoleEl = document.getElementById('profileRole');
const saveRoleBtn = document.getElementById('saveRoleBtn');
const profileDescriptionEl = document.getElementById('profileDescription');
const saveDescriptionBtn = document.getElementById('saveDescriptionBtn');
const changeEmailBtn = document.getElementById('changeEmailBtn');
const photoActionsEl = document.getElementById('photoActions');
const photoInputEl = document.getElementById('photoInput');
const changePhotoBtn = document.getElementById('changePhotoBtn');
const emailModal = document.getElementById('emailModal');
const emailModalClose = document.getElementById('emailModalClose');
const cancelEmailBtn = document.getElementById('cancelEmailBtn');
const changeEmailForm = document.getElementById('changeEmailForm');
const newEmailInput = document.getElementById('newEmailInput');
const deleteAccountSection = document.getElementById('deleteAccountSection');
const deleteAccountBtn = document.getElementById('deleteAccountBtn');
const deleteAccountModal = document.getElementById('deleteAccountModal');
const deleteAccountModalClose = document.getElementById('deleteAccountModalClose');
const cancelDeleteAccountBtn = document.getElementById('cancelDeleteAccountBtn');
const deleteAccountForm = document.getElementById('deleteAccountForm');
const deleteAccountPassword = document.getElementById('deleteAccountPassword');

profilePhotoEl.src = DEFAULT_PHOTO;

const ALLOWED_PHOTO_EXTENSIONS = ['jpg', 'jpeg', 'png'];
const ALLOWED_PHOTO_TYPES = ['image/jpeg', 'image/png'];
const ALLOWED_PHOTO_MSG = 'Only JPG and PNG files are allowed.';
const PHOTO_MAX_BYTES = 150 * 1024 * 1024;
const PHOTO_MAX_MSG = 'Photo must be 150 MB or smaller.';

// --- Helpers ---

function profileApiUrl(withPhoto, cacheBust) {
    let url;
    if (profileUserId) {
        url = '/php/profile/getPartialProfile.php?i=' + encodeURIComponent(profileUserId);
    } else {
        url = '/php/profile/getPartialProfile.php';
    }
    if (shiftDate) {
        url += (url.indexOf('?') === -1 ? '?' : '&') + 'date=' + encodeURIComponent(shiftDate);
    }
    if (withPhoto) {
        url += (url.indexOf('?') === -1 ? '?' : '&') + 'photo=1&t=' + Date.now();
    }
    return url;
}

async function fetchJson(url, options = {}) {
    const { headers: customHeaders, ...restOptions } = options;
    try {
        const response = await fetch(url, {
            ...restOptions,
            credentials: 'same-origin',
            headers: {
                Accept: 'application/json',
                ...(customHeaders || {}),
            },
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

function loadProfilePhoto(hasPhoto, cacheBust) {
    if (!hasPhoto) {
        profilePhotoEl.src = DEFAULT_PHOTO;
        return Promise.resolve();
    }

    const releaseSpinner = globalSpinner.start({ immediate: true });
    const photoUrl = profileApiUrl(true, cacheBust);
    return new Promise((resolve) => {
        const img = new Image();
        img.onload = () => {
            profilePhotoEl.src = photoUrl;
            releaseSpinner();
            resolve();
        };
        img.onerror = () => {
            profilePhotoEl.src = DEFAULT_PHOTO;
            releaseSpinner();
            resolve();
        };
        img.src = photoUrl;
    });
}

function populateProfile(profile) {
    profileNameEl.textContent = profile.name + ' ' + profile.surname;
    profileEmailEl.textContent = 'Email: ' + profile.email;
    profileRoleEl.value = profile.role || '';
    profileDescriptionEl.value = profile.description || '';
    loadProfilePhoto(profile.hasPhoto);
    if (profile.isOwnProfile) {
        changeEmailBtn.style.display = '';
        saveRoleBtn.style.display = '';
        saveDescriptionBtn.style.display = '';
        photoActionsEl.style.display = '';
        deleteAccountSection.style.display = '';
        profileRoleEl.readOnly = false;
        profileRoleEl.classList.remove('profile-role--readonly');
        profileDescriptionEl.readOnly = false;
        profileDescriptionEl.removeAttribute('tabindex');
        profileDescriptionEl.classList.remove('profile-description--readonly');
    } else {
        changeEmailBtn.style.display = 'none';
        saveRoleBtn.style.display = 'none';
        saveDescriptionBtn.style.display = 'none';
        photoActionsEl.style.display = 'none';
        deleteAccountSection.style.display = 'none';
        profileRoleEl.readOnly = true;
        profileRoleEl.classList.add('profile-role--readonly');
        profileDescriptionEl.readOnly = true;
        profileDescriptionEl.tabIndex = -1;
        profileDescriptionEl.classList.add('profile-description--readonly');
    }
}

async function loadProfile() {
    const result = await fetchJson(profileApiUrl(false));
    if (!result) {
        return;
    }

    if (result.denied) {
        window.location.href = '/html/Starter/home.html';
        return;
    }

    populateProfile(result.data.data);
}

function isAllowedPhotoFile(file) {
    const ext = (file.name.split('.').pop() || '').toLowerCase();
    return ALLOWED_PHOTO_TYPES.includes(file.type) || ALLOWED_PHOTO_EXTENSIONS.includes(ext);
}

// --- Email change ---

function openEmailModal() {
    const currentEmail = profileEmailEl.textContent.replace(/^Email:\s*/, '');
    newEmailInput.value = currentEmail;
    emailModal.style.display = 'block';
}

function closeEmailModal() {
    emailModal.style.display = 'none';
    changeEmailForm.reset();
}

changeEmailBtn.addEventListener('click', openEmailModal);
emailModalClose.addEventListener('click', closeEmailModal);
cancelEmailBtn.addEventListener('click', closeEmailModal);

emailModal.addEventListener('click', (event) => {
    if (event.target === emailModal) {
        closeEmailModal();
    }
});

changeEmailForm.addEventListener('submit', async (event) => {
    event.preventDefault();

    const newEmail = newEmailInput.value.trim();
    if (!newEmail) {
        alert('Enter a new email address.');
        return;
    }

    const body = new URLSearchParams();
    body.append('newEmail', newEmail);

    const result = await fetchJson('/php/profile/changeMyEmail.php', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: body.toString()
    });

    if (!result) {
        return;
    }

    if (result.data.success) {
        closeEmailModal();
        alert(
            result.data.successMsg ||
            'A verification email was sent to ' + newEmail + '.'
        );
    } else {
        alert(result.data.errorMsg || 'Could not send verification email.');
    }
});

// --- Account deletion ---

function openDeleteAccountModal() {
    deleteAccountPassword.value = '';
    deleteAccountModal.style.display = 'block';
    deleteAccountPassword.focus();
}

function closeDeleteAccountModal() {
    deleteAccountModal.style.display = 'none';
    deleteAccountForm.reset();
}

deleteAccountBtn.addEventListener('click', openDeleteAccountModal);
deleteAccountModalClose.addEventListener('click', closeDeleteAccountModal);
cancelDeleteAccountBtn.addEventListener('click', closeDeleteAccountModal);

deleteAccountModal.addEventListener('click', (event) => {
    if (event.target === deleteAccountModal) {
        closeDeleteAccountModal();
    }
});

deleteAccountForm.addEventListener('submit', async (event) => {
    event.preventDefault();

    const password = deleteAccountPassword.value;
    if (!password) {
        alert('Enter your password.');
        return;
    }

    if (!window.confirm('This will permanently delete your account. Continue?')) {
        return;
    }

    const body = new URLSearchParams();
    body.append('password', password);

    const result = await fetchJson('/php/profile/deleteMyAccount.php', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: body.toString()
    });

    if (!result) {
        return;
    }

    if (result.data.success) {
        window.location.href = result.data.redirect || '/html/auth/login.html';
        return;
    }

    alert(result.data.errorMsg || 'Could not delete account.');
});

// --- Profile save ---

saveDescriptionBtn.addEventListener('click', async () => {
    const body = new URLSearchParams();
    body.append('description', profileDescriptionEl.value);

    const result = await fetchJson('/php/profile/saveMyDescription.php', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: body.toString()
    });

    if (!result) {
        return;
    }

    if (result.data.success) {
        alert('Description saved successfully!');
    }
});

saveRoleBtn.addEventListener('click', async () => {
    const role = profileRoleEl.value.trim();

    const body = new URLSearchParams();
    body.append('role', role);

    const result = await fetchJson('/php/profile/saveMyRole.php', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: body.toString()
    });

    if (!result) {
        return;
    }

    if (result.data.success) {
        alert(result.data.successMsg || 'Role saved successfully!');
    } else {
        alert(result.data.errorMsg || 'Could not save role.');
    }
});

// --- Photo upload ---

changePhotoBtn.addEventListener('click', () => photoInputEl.click());

photoInputEl.addEventListener('change', async () => {
    const file = photoInputEl.files[0];
    photoInputEl.value = '';
    if (!file) {
        return;
    }

    if (!isAllowedPhotoFile(file)) {
        alert(ALLOWED_PHOTO_MSG);
        return;
    }

    if (file.size > PHOTO_MAX_BYTES) {
        alert(PHOTO_MAX_MSG);
        return;
    }

    const formData = new FormData();
    formData.append('photo', file);

    const result = await fetchJson('/php/profile/saveMyProfilePhoto.php', {
        method: 'POST',
        body: formData
    });

    if (!result || result.denied) {
        return;
    }

    if (result.data.success) {
        await loadProfilePhoto(true, true);
    }
});

// --- Page init ---

loadProfile();
