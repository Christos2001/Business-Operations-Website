// home.js — dashboard welcome, next shift, coworkers, recent transactions

// --- Initialization ---

const DEFAULT_PHOTO = 'data:image/svg+xml,' + encodeURIComponent(
    '<svg xmlns="http://www.w3.org/2000/svg" width="120" height="120" viewBox="0 0 120 120">' +
    '<rect width="120" height="120" fill="#e9ecef"/>' +
    '<circle cx="60" cy="45" r="22" fill="#adb5bd"/>' +
    '<ellipse cx="60" cy="95" rx="35" ry="28" fill="#adb5bd"/>' +
    '</svg>'
);

const welcomeTitleEl = document.getElementById('welcomeTitle');
const shiftWidgetValueEl = document.getElementById('shiftWidgetValue');
const shiftCoworkersListEl = document.getElementById('shiftCoworkersList');
const recentTransactionsPanelEl = document.getElementById('recentTransactionsPanel');
const recentTransactionsListEl = document.getElementById('recentTransactionsList');

const NO_SHIFT_TEXT = 'No upcoming shifts scheduled';
const NO_COWORKERS_TEXT = 'No coworkers on this shift';
const NO_TRANSACTIONS_TEXT = 'No recent transactions';

let shiftProfileDate = ''; // date query for profile links from next-shift widget

// --- Helpers ---

async function fetchJson(url) {
    try {
        const response = await fetch(url, {
            credentials: 'same-origin',
            headers: { Accept: 'application/json' }
        });
        const data = await window.parseFetchJsonResponse(response);
        if (!data || data.denied) {
            return null;
        }
        return data;
    } catch (error) {
        window.handleFetchError(error);
        return null;
    }
}

function canShowRecentTransactions(access) {
    if (!access || access.denied) {
        return false;
    }
    if (access.role === 'manager') {
        return true;
    }
    const privileges = access.privileges || [];
    return privileges.includes('money-tracker')
        || privileges.includes('income')
        || privileges.includes('expenses');
}

function showRecentTransactionsPanel() {
    recentTransactionsPanelEl.removeAttribute('hidden');
}

function profileHref(userId) {
    let href = '/html/profile/profile.html?i=' + encodeURIComponent(userId);
    if (shiftProfileDate) {
        href += '&date=' + encodeURIComponent(shiftProfileDate);
    }
    return href;
}

function profilePhotoUrl(userId, hasPhoto) {
    if (!hasPhoto) {
        return DEFAULT_PHOTO;
    }
    let url = '/php/profile/getPartialProfile.php?i=' + encodeURIComponent(userId) + '&photo=1';
    if (shiftProfileDate) {
        url += '&date=' + encodeURIComponent(shiftProfileDate);
    }
    url += '&t=' + Date.now(); // cache-bust profile photo
    return url;
}

function formatTransactionAmount(amount) {
    const value = Number(amount);
    if (Number.isNaN(value)) {
        return String(amount);
    }
    return value.toLocaleString(undefined, { minimumFractionDigits: 0, maximumFractionDigits: 2 });
}

// --- Welcome and next shift ---

function renderWelcome(profile) {
    const name = profile.name || '';
    welcomeTitleEl.textContent = 'Welcome, ' + name;
}

function renderShift(shiftData) {
    shiftProfileDate = '';

    if (!shiftData || !shiftData.success || !shiftData.shift) {
        shiftWidgetValueEl.textContent = NO_SHIFT_TEXT;
        return;
    }

    shiftProfileDate = shiftData.shift.profileDate || '';
    shiftWidgetValueEl.textContent =
        shiftData.shift.dateLabel + ' · ' + shiftData.shift.timeLabel;
}

// --- Coworkers ---

const COWORKERS_SCROLL_MIN = 4; // enable horizontal scroll at this many coworkers

function updateCoworkersListLayout() {
    const count = shiftCoworkersListEl.querySelectorAll('li:not(.coworkers-empty)').length;

    shiftCoworkersListEl.classList.remove('coworkers-list--scrollable');

    if (count < COWORKERS_SCROLL_MIN) {
        return;
    }

    shiftCoworkersListEl.classList.add('coworkers-list--scrollable');
    if (shiftCoworkersListEl.scrollWidth <= shiftCoworkersListEl.clientWidth + 1) {
        shiftCoworkersListEl.classList.remove('coworkers-list--scrollable');
    }
}

function scheduleCoworkersListLayout() {
    requestAnimationFrame(() => {
        updateCoworkersListLayout();
        requestAnimationFrame(updateCoworkersListLayout);
    });
}

function createCoworkerItem(coworker) {
    const item = document.createElement('li');
    const link = document.createElement('a');
    link.className = 'coworker-link';
    link.href = profileHref(coworker.id);

    const photoWrap = document.createElement('span');
    photoWrap.className = 'coworker-photo-wrap';

    const photo = document.createElement('img');
    photo.className = 'coworker-photo';
    photo.alt = coworker.name + ' ' + coworker.surname;
    photo.src = profilePhotoUrl(coworker.id, coworker.hasPhoto);
    photo.onerror = () => {
        photo.src = DEFAULT_PHOTO;
    };
    photo.addEventListener('load', updateCoworkersListLayout);

    const name = document.createElement('span');
    name.textContent = coworker.name + ' ' + coworker.surname + "  ↗";

    photoWrap.appendChild(photo);
    link.appendChild(photoWrap);
    link.appendChild(name);
    item.appendChild(link);
    return item;
}

function renderCoworkers(shiftData) {
    shiftCoworkersListEl.classList.remove('coworkers-list--scrollable');
    shiftCoworkersListEl.innerHTML = '';

    if (!shiftData || !shiftData.success || !shiftData.shift) {
        const item = document.createElement('li');
        item.className = 'coworkers-empty';
        item.textContent = NO_COWORKERS_TEXT;
        shiftCoworkersListEl.appendChild(item);
        scheduleCoworkersListLayout();
        return;
    }

    const coworkers = shiftData.coworkers || [];
    if (coworkers.length === 0) {
        const item = document.createElement('li');
        item.className = 'coworkers-empty';
        item.textContent = NO_COWORKERS_TEXT;
        shiftCoworkersListEl.appendChild(item);
        scheduleCoworkersListLayout();
        return;
    }

    coworkers.forEach((coworker) => {
        shiftCoworkersListEl.appendChild(createCoworkerItem(coworker));
    });
    scheduleCoworkersListLayout();
}

// --- Recent transactions ---

function renderRecentTransactions(transactionsData) {
    recentTransactionsListEl.innerHTML = '';

    const rows = transactionsData && transactionsData.success
        ? (transactionsData.data || [])
        : [];

    if (rows.length === 0) {
        const item = document.createElement('li');
        item.className = 'recent-transactions-empty';
        item.textContent = NO_TRANSACTIONS_TEXT;
        recentTransactionsListEl.appendChild(item);
        return;
    }

    rows.forEach((row) => {
        const item = document.createElement('li');
        item.className = 'recent-transaction-item recent-transaction-item--' + row.type;

        const typeLabel = row.type === 'income' ? 'Income' : 'Expense';
        item.textContent = typeLabel + ' · ' + row.source + ' · '
            + formatTransactionAmount(row.amount) + ' · ' + row.date;

        recentTransactionsListEl.appendChild(item);
    });
}

async function loadRecentTransactions() {
    const result = await fetchJson('/php/transactions/getHomeRecentTransactions.php');
    renderRecentTransactions(result);
}

// --- Page init ---

async function loadDashboard() {
    const [profileResult, shiftResult, accessResult] = await Promise.all([
        fetchJson('/php/profile/getPartialProfile.php'),
        fetchJson('/php/shifts/getMyNextShift.php'),
        fetchJson('/php/common/getUserAccess.php')
    ]);

    if (!profileResult || !profileResult.success || !profileResult.data) {
        window.location.href = '/html/auth/login.html';
        return;
    }

    renderWelcome(profileResult.data);
    renderShift(shiftResult);
    renderCoworkers(shiftResult);

    if (canShowRecentTransactions(accessResult)) {
        showRecentTransactionsPanel();
        await loadRecentTransactions();
    }
}

loadDashboard();

window.addEventListener('resize', updateCoworkersListLayout);
