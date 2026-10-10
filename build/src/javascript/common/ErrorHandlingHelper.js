// ErrorHandlingHelper.js — API messages, JSON parsing, fetch/ajax error handling

// --- Initialization ---

const API_LOGIN_URL = '/html/auth/login.html'; // redirect target on 401

window.API_MESSAGES = {
    defaultError: 'An error occured.',
    connectionError: 'Connection error. Please try again.',
    invalidResponse: 'Unexpected server response. Please try again.',
};

// --- JSON response handling ---

window.handleAjaxJsonFailure = function handleAjaxJsonFailure(xhr, fallbackMessage) {
    if (xhr.status === 401) {
        window.location.href = API_LOGIN_URL;
        return true;
    }

    const data = xhr.responseJSON;
    if (xhr.status === 403) {
        alert((data && data.errorMsg) || 'Access denied.');
        return true;
    }
    if (data && data.success === false) {
        alert(data.errorMsg || window.API_MESSAGES.defaultError);
        return true;
    }

    if (fallbackMessage) {
        alert(fallbackMessage);
        return true;
    }

    return false;
};

window.parseFetchJsonResponse = async function parseFetchJsonResponse(response, options = {}) {
    const suppressAlertForErrors = options.suppressAlertForErrors || []; // errorMsg values that skip alert
    const contentType = response.headers.get('content-type') || '';
    const rawText = await response.text();

    function parseJsonBody(text) {
        const trimmed = text.trim();
        if (!trimmed) {
            return null;
        }
        try {
            return JSON.parse(trimmed);
        } catch (parseError) {
            const start = trimmed.indexOf('{');
            const end = trimmed.lastIndexOf('}'); // salvage JSON embedded in HTML/error output
            if (start >= 0 && end > start) {
                return JSON.parse(trimmed.slice(start, end + 1));
            }
            throw parseError;
        }
    }

    const looksLikeJson = contentType.includes('application/json')
        || /^\s*[{[]/.test(rawText);

    if (!looksLikeJson) {
        if (response.status === 401) {
            window.location.href = API_LOGIN_URL;
        } else {
            alert(window.API_MESSAGES.invalidResponse);
        }
        return null;
    }

    let data;
    try {
        data = parseJsonBody(rawText);
    } catch (parseError) {
        alert(window.API_MESSAGES.invalidResponse);
        return null;
    }

    if (response.status === 401) {
        window.location.href = API_LOGIN_URL;
        return null;
    }
    if (response.status === 403) {
        alert(data.errorMsg || 'Access denied.');
        return { denied: true, data };
    }
    if (data && data.success === false) {
        if (suppressAlertForErrors.includes(data.errorMsg)) {
            return data;
        }
        alert(data.errorMsg || window.API_MESSAGES.defaultError);
        return null;
    }

    return data;
};

// --- Error alerts ---

window.handleFetchError = function handleFetchError(error, fallbackMessage) {
    console.error(error);
    alert(fallbackMessage || window.API_MESSAGES.connectionError);
};

window.handleAjaxResult = function handleAjaxResult(response) {
    if (response && response.success === false) {
        alert(response.errorMsg || window.API_MESSAGES.defaultError);
        return false;
    }
    return true;
};

window.handleAjaxRequestError = function handleAjaxRequestError(xhr, fallbackMessage) {
    if (xhr && typeof xhr.status === 'number') {
        if (window.handleAjaxJsonFailure(xhr, fallbackMessage)) {
            return;
        }
    }
    window.handleFetchError(xhr, fallbackMessage);
};
