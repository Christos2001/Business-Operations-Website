// navbar.js — privilege-based nav, user access, client error reporting

// --- Initialization ---

const ACCESS_CACHE_KEY = 'navbarUserAccess';

const linkPrivilegeMap = { // nav element id -> required privilege key
    'income-link': 'income',
    'expenses-link': 'expenses',
    'money-tracker-link': 'money-tracker',
    'privileges-link': 'manage-employees'
};

// --- Access cache ---

function readCachedAccess() {
    try {
        const parsed = JSON.parse(sessionStorage.getItem(ACCESS_CACHE_KEY) || 'null');
        if (!parsed || (parsed.role !== 'manager' && parsed.role !== 'employee')) {
            return null;
        }
        if (!Array.isArray(parsed.privileges)) {
            return null;
        }
        return parsed;
    } catch {
        return null;
    }
}

function writeCachedAccess(access) {
    try {
        sessionStorage.setItem(ACCESS_CACHE_KEY, JSON.stringify({
            role: access.role,
            userId: access.userId,
            privileges: access.privileges || []
        }));
    } catch {
        // ignore quota / private mode
    }
}

function clearCachedAccess() {
    try {
        sessionStorage.removeItem(ACCESS_CACHE_KEY);
    } catch {
        // ignore
    }
}

function applyAccessToNavbar(access) {
    if (!access) {
        hideAllMappedLinks();
        return;
    }
    if (access.role === 'manager') {
        showAllMappedLinks();
        return;
    }
    applyPrivilegeVisibility(access.privileges || []);
}

function applyCachedAccess() {
    const cached = readCachedAccess();
    if (!cached) {
        return null;
    }
    applyAccessToNavbar(cached);
    window.userAccess = cached;
    return cached;
}

// --- Nav visibility ---

function hideAllMappedLinks() {
    Object.keys(linkPrivilegeMap).forEach((id) => {
        $('#' + id).hide();
    });
    $('#transactions-dropdown').hide();
}

function showAllMappedLinks() {
    Object.keys(linkPrivilegeMap).forEach((id) => {
        $('#' + id).show();
    });
    $('#transactions-dropdown').show();
}

function updateTransactionsDropdownVisibility(privileges) {
    const granted = privileges || [];
    const hasTransactions = granted.includes('income') || granted.includes('expenses');
    if (hasTransactions) {
        $('#transactions-dropdown').show();
    } else {
        $('#transactions-dropdown').hide();
    }
}

function applyPrivilegeVisibility(privileges) {
    hideAllMappedLinks();
    privileges.forEach((privilege) => {
        const linkId = Object.keys(linkPrivilegeMap).find(
            (id) => linkPrivilegeMap[id] === privilege
        );
        if (linkId) {
            $('#' + linkId).show();
        }
    });
    updateTransactionsDropdownVisibility(privileges);
}

// --- User access ---

function canUsePrivilege(access, privilege) {
    return access.role === 'manager'
        || (access.privileges || []).includes(privilege);
}

async function loadUserAccess() {
    applyCachedAccess();

    try {
        const response = await fetch('/php/common/getUserAccess.php', {
            credentials: 'same-origin',
            headers: { Accept: 'application/json' }
        });
        const results = await window.parseFetchJsonResponse(response);
        if (!results || results.denied) {
            if (!window.userAccess) {
                window.userAccess = null;
            }
            return;
        }

        applyAccessToNavbar(results);
        window.userAccess = results;
        writeCachedAccess(results);
    } catch (error) {
        window.handleFetchError(error);
        if (!readCachedAccess()) {
            window.userAccess = null;
        }
    } finally {
        document.dispatchEvent(new CustomEvent('userAccessReady', { detail: window.userAccess }));
    }
}

loadUserAccess();

function setTransactionsDropdownOpen(open) {
    const dropdown = document.getElementById('transactions-dropdown');
    if (!dropdown) {
        return;
    }
    dropdown.classList.toggle('open', open);
    const trigger = dropdown.querySelector('.nav-dropdown-trigger');
    if (trigger) {
        trigger.setAttribute('aria-expanded', open ? 'true' : 'false');
    }
}

document.addEventListener('click', (event) => {
    const dropdown = document.getElementById('transactions-dropdown');
    const trigger = dropdown && dropdown.querySelector('.nav-dropdown-trigger');
    if (trigger && trigger.contains(event.target)) {
        setTransactionsDropdownOpen(!dropdown.classList.contains('open'));
    } else if (dropdown && !dropdown.contains(event.target)) {
        setTransactionsDropdownOpen(false);
    }

    const link = event.target.closest('a[href]');
    if (!link) {
        return;
    }
    try {
        const url = new URL(link.href, window.location.origin);
        if (url.pathname === '/php/auth/logout.php') {
            clearCachedAccess();
        }
    } catch {
        // ignore invalid href
    }
});

document.addEventListener('keydown', (event) => {
    const dropdown = document.getElementById('transactions-dropdown');
    const trigger = dropdown && dropdown.querySelector('.nav-dropdown-trigger');
    if (!trigger) {
        return;
    }
    if (event.key === 'Escape') {
        setTransactionsDropdownOpen(false);
        return;
    }
    if (event.target !== trigger) {
        return;
    }
    if (event.key === 'Enter' || event.key === ' ') {
        event.preventDefault();
        setTransactionsDropdownOpen(!dropdown.classList.contains('open'));
    }
});

// --- Client error reporting ---

function reportClientError(message, source = '') {
    if (!message) {
        return;
    }
    fetch('/php/logs/logClientError.php', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'same-origin',
        body: JSON.stringify({
            message: String(message).slice(0, 2000),
            source: String(source).slice(0, 500)
        })
    }).catch(() => {});
}

window.reportClientError = reportClientError;
window.canUsePrivilege = canUsePrivilege;

window.addEventListener('error', (event) => {
    reportClientError(
        event.message || 'Unknown client error',
        `${event.filename || ''}:${event.lineno || 0}`
    );
});

window.addEventListener('unhandledrejection', (event) => {
    const reason = event.reason;
    const message = reason?.message || String(reason || 'Unhandled rejection');
    reportClientError(message, 'unhandledrejection');
});
