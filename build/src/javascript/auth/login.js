// login.js — forgot username/password recovery modal

// --- Initialization ---

const forgotUsernameLink = document.getElementById('forgotUsernameLink');
const forgotPasswordLink = document.getElementById('forgotPasswordLink');
const recoveryModal = document.getElementById('recoveryModal');
const recoveryModalTitle = document.getElementById('recoveryModalTitle');
const recoveryModalText = document.getElementById('recoveryModalText');
const recoveryEmail = document.getElementById('recoveryEmail');
const recoverySubmitBtn = document.getElementById('recoverySubmitBtn');
const recoveryCancelBtn = document.getElementById('recoveryCancelBtn');

let recoveryType = null; // active modal: 'username' or 'password'

const recoveryConfig = {
    username: {
        title: 'Forgot username',
        text: 'Enter your email address. We will send you a link to change your username.',
        endpoint: '/php/auth/forgotUsername.php',
        successAlert: 'An email was sent to change your username.',
    },
    password: {
        title: 'Forgot password',
        text: 'Enter your email address. We will send you a link to change your password.',
        endpoint: '/php/auth/forgotPassword.php',
        successAlert: 'An email was sent to change your password.',
    },
};

// --- Recovery modal ---

function openRecoveryModal(type) {
    recoveryType = type;
    const config = recoveryConfig[type];
    recoveryModalTitle.textContent = config.title;
    recoveryModalText.textContent = config.text;
    recoveryEmail.value = '';
    recoveryModal.hidden = false;
    recoveryEmail.focus();
}

function closeRecoveryModal() {
    recoveryModal.hidden = true;
    recoveryType = null;
}

forgotUsernameLink.addEventListener('click', (event) => {
    event.preventDefault();
    openRecoveryModal('username');
});

forgotPasswordLink.addEventListener('click', (event) => {
    event.preventDefault();
    openRecoveryModal('password');
});

recoveryCancelBtn.addEventListener('click', closeRecoveryModal);

recoveryModal.addEventListener('click', (event) => {
    if (event.target === recoveryModal) {
        closeRecoveryModal();
    }
});

recoverySubmitBtn.addEventListener('click', async () => {
    if (!recoveryType) {
        return;
    }

    const email = recoveryEmail.value.trim();
    if (!email) {
        alert('Enter your email address.');
        return;
    }

    const config = recoveryConfig[recoveryType];

    try {
        const body = new URLSearchParams();
        body.append('email', email);

        const response = await fetch(config.endpoint, {
            method: 'POST',
            credentials: 'same-origin',
            headers: {
                Accept: 'application/json',
                'Content-Type': 'application/x-www-form-urlencoded'
            },
            body: body.toString(),
        });

        const data = await window.parseFetchJsonResponse(response);
        if (!data || data.denied) {
            return;
        }

        closeRecoveryModal();
        alert(data.successMsg || config.successAlert);
    } catch (error) {
        window.handleFetchError(error);
    }
});

recoveryEmail.addEventListener('keydown', (event) => {
    if (event.key === 'Enter') {
        event.preventDefault();
        recoverySubmitBtn.click();
    }
});
