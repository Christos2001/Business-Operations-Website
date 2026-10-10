// requestHandler.js — global spinner, fetch/ajax patching, submit locking

// --- Initialization ---

const SPINNER_MESSAGES = {
    default: 'Loading...',
    forecast: 'Calculating forecast...',
    photoUpload: 'Uploading photo...',
    search: 'Searching...',
};

const SPINNER_URL_MESSAGES = {
    '/php/profile/saveMyProfilePhoto.php': SPINNER_MESSAGES.photoUpload,
    '/php/common/searchUser.php': SPINNER_MESSAGES.search,
    '/php/predictions/GradientBoost/forecastGradientBoost.php': SPINNER_MESSAGES.forecast,
};

const SPINNER_SILENT_URLS = [ // URLs excluded from auto spinner tracking
    '/php/logs/logClientError.php',
    '/php/predictions/GradientBoost/forecastGradientBoost.php',
];

const INTERACTION_LOCK_SELECTORS =
    'input[type="submit"], button[type="submit"], input[data-enter-submit]';

const DELAY_MS = 700; // delay before showing spinner on fast requests

let pendingCount = 0; // in-flight tracked requests (spinner refcount)
let manualLockCount = 0; // manual globalSpinner.start calls (skip ajax auto-track)
let interactionLockCount = 0; // nested submit-lock depth
let showTimerId = null; // DELAY_MS timer before overlay shows
let isVisible = false;
const activeMessages = []; // message stack for nested requests
const interactionLockedElements = []; // submit buttons disabled while locked

let overlayEl = null;
let messageEl = null;
let forecastProgressEl = null;
let forecastCloseEl = null;
let forecastCancelHandler = null;
const forecastBarEls = {
    optuna: { fill: null, pct: null, caption: null, track: null },
    xgboost: { fill: null, pct: null, caption: null, track: null },
};

// --- URL helpers ---

function resolveUrl(input) {
    if (typeof input === 'string') {
        return input;
    }
    if (input && typeof input.url === 'string') {
        return input.url;
    }
    return '';
}

function normalizePath(url) {
    try {
        const parsed = new URL(url, window.location.origin);
        return parsed.pathname;
    } catch {
        const path = String(url).split('?')[0];
        return path.startsWith('/') ? path : '/' + path;
    }
}

function isSilentUrl(url) {
    const path = normalizePath(url);
    return SPINNER_SILENT_URLS.some((silent) => path === silent || path.endsWith(silent));
}

function messageForUrl(url) {
    const path = normalizePath(url);
    for (const [mappedPath, message] of Object.entries(SPINNER_URL_MESSAGES)) {
        if (path === mappedPath || path.endsWith(mappedPath)) {
            return message;
        }
    }
    return SPINNER_MESSAGES.default;
}

// --- Submit locking ---

function lockSubmits() {
    lockPageInteractions();
    return function releaseSubmits() {
        unlockPageInteractions();
    };
}

function lockPageInteractions() {
    interactionLockCount += 1;
    if (interactionLockCount > 1) {
        return;
    }

    document.querySelectorAll(INTERACTION_LOCK_SELECTORS).forEach((el) => {
        if (el.disabled) {
            return;
        }
        el.disabled = true;
        el.dataset.spinnerLocked = '1';
        interactionLockedElements.push(el);
    });
}

function unlockPageInteractions() {
    interactionLockCount = Math.max(0, interactionLockCount - 1);
    if (interactionLockCount > 0) {
        return;
    }

    interactionLockedElements.forEach((el) => {
        if (el.dataset.spinnerLocked === '1') {
            el.disabled = false;
            delete el.dataset.spinnerLocked;
        }
    });
    interactionLockedElements.length = 0;
}

// --- Request tracking ---

function withFinally(promiseLike, onFinally) {
    if (promiseLike != null && typeof promiseLike.finally === 'function') {
        return promiseLike.finally(onFinally);
    }
    if (promiseLike != null && typeof promiseLike.always === 'function') {
        return promiseLike.always(onFinally);
    }
    onFinally();
    return promiseLike;
}

function wrapTrackedRequest(url, options, requestFn) {
    const message = (options && options.spinnerMessage) ? options.spinnerMessage : messageForUrl(url);
    const release = trackStart(message, { immediate: false });

    let result;
    try {
        result = requestFn();
    } catch (error) {
        release();
        throw error;
    }

    return withFinally(result, release);
}

function currentMessage() {
    if (activeMessages.length === 0) {
        return SPINNER_MESSAGES.default;
    }
    return activeMessages[activeMessages.length - 1];
}

function updateMessageText() {
    if (messageEl) {
        messageEl.textContent = currentMessage();
    }
}

function ensureDom() {
    if (overlayEl) {
        return;
    }

    overlayEl = document.createElement('div');
    overlayEl.id = 'globalSpinnerOverlay';
    overlayEl.className = 'global-spinner-overlay';
    overlayEl.hidden = true;
    overlayEl.setAttribute('aria-hidden', 'true');
    overlayEl.setAttribute('aria-live', 'polite');
    overlayEl.innerHTML =
        '<div class="global-spinner-panel">' +
        '<button type="button" id="globalSpinnerClose" class="global-spinner-close" hidden aria-label="Cancel">&times;</button>' +
        '<div class="global-spinner-icon" aria-hidden="true"></div>' +
        '<p id="globalSpinnerMessage" class="global-spinner-message"></p>' +
        '<div id="globalForecastProgress" class="global-forecast-progress" hidden>' +
        forecastBarMarkup('optuna', 'Tuning with Optuna') +
        forecastBarMarkup('xgboost', 'XGBoost') +
        '</div>' +
        '</div>';

    document.body.appendChild(overlayEl);
    messageEl = document.getElementById('globalSpinnerMessage');
    forecastProgressEl = document.getElementById('globalForecastProgress');
    forecastCloseEl = document.getElementById('globalSpinnerClose');
    if (forecastCloseEl) {
        forecastCloseEl.addEventListener('click', (event) => {
            event.preventDefault();
            event.stopPropagation();
            if (typeof forecastCancelHandler === 'function') {
                forecastCancelHandler();
            }
        });
    }
    bindForecastBarEls('optuna');
    bindForecastBarEls('xgboost');
}

function forecastBarMarkup(bar, header) {
    return (
        '<div class="global-forecast-bar-block">' +
        '<div class="global-forecast-bar-header">' +
        '<span>' + header + '</span>' +
        '<span id="globalForecast-' + bar + '-pct">0%</span>' +
        '</div>' +
        '<div class="global-forecast-bar-track" role="progressbar" aria-label="' + header + '" ' +
        'aria-valuemin="0" aria-valuemax="100" aria-valuenow="0" id="globalForecast-' + bar + '-track">' +
        '<div id="globalForecast-' + bar + '-fill" class="global-forecast-bar-fill" style="width:0%"></div>' +
        '</div>' +
        '<p id="globalForecast-' + bar + '-msg" class="global-forecast-bar-caption"></p>' +
        '</div>'
    );
}

function bindForecastBarEls(bar) {
    forecastBarEls[bar] = {
        fill: document.getElementById('globalForecast-' + bar + '-fill'),
        pct: document.getElementById('globalForecast-' + bar + '-pct'),
        caption: document.getElementById('globalForecast-' + bar + '-msg'),
        track: document.getElementById('globalForecast-' + bar + '-track'),
    };
}

function resetForecastBar(bar) {
    applyForecastBar(bar, 0, '');
}

function applyForecastBar(bar, pct, message) {
    const els = forecastBarEls[bar];
    if (!els || !els.fill) {
        return;
    }
    const n = Number(pct) || 0;
    const shown = n >= 100 ? 100 : (Math.floor(n / 10) * 10);
    els.fill.style.width = shown + '%';
    if (els.pct) {
        els.pct.textContent = shown + '%';
    }
    if (els.track) {
        els.track.setAttribute('aria-valuenow', String(shown));
    }
    if (els.caption) {
        els.caption.textContent = message || '';
    }
}

function setForecastCloseVisible(visible) {
    if (!forecastCloseEl) {
        return;
    }
    forecastCloseEl.hidden = !visible;
}

function showForecastProgress() {
    ensureDom();
    resetForecastBar('optuna');
    resetForecastBar('xgboost');
    if (forecastProgressEl) {
        forecastProgressEl.hidden = false;
    }
    setForecastCloseVisible(true);
}

function setForecastProgress(bar, pct, message) {
    if (bar !== 'optuna' && bar !== 'xgboost') {
        return;
    }
    ensureDom();
    if (forecastProgressEl) {
        forecastProgressEl.hidden = false;
    }
    setForecastCloseVisible(true);
    applyForecastBar(bar, pct, message);
}

function hideForecastProgress() {
    if (forecastProgressEl) {
        forecastProgressEl.hidden = true;
    }
    setForecastCloseVisible(false);
    resetForecastBar('optuna');
    resetForecastBar('xgboost');
}

function setForecastCancelHandler(handler) {
    forecastCancelHandler = typeof handler === 'function' ? handler : null;
}

function showOverlay() {
    ensureDom();
    if (isVisible) {
        updateMessageText();
        return;
    }

    isVisible = true;
    document.body.classList.add('is-global-loading');
    overlayEl.hidden = false;
    overlayEl.setAttribute('aria-hidden', 'false');
    updateMessageText();
}

function hideOverlay() {
    if (!isVisible) {
        return;
    }

    isVisible = false;
    document.body.classList.remove('is-global-loading');
    hideForecastProgress();
    if (overlayEl) {
        overlayEl.hidden = true;
        overlayEl.setAttribute('aria-hidden', 'true');
    }
}

function scheduleShow() {
    if (showTimerId !== null || isVisible) {
        return;
    }

    showTimerId = window.setTimeout(() => {
        showTimerId = null;
        if (pendingCount > 0) {
            showOverlay();
        }
    }, DELAY_MS);
}

function clearShowTimer() {
    if (showTimerId !== null) {
        window.clearTimeout(showTimerId);
        showTimerId = null;
    }
}

function trackStart(message, { immediate = false } = {}) {
    const resolvedMessage = message || SPINNER_MESSAGES.default;
    activeMessages.push(resolvedMessage);
    pendingCount += 1;
    updateMessageText();

    if (immediate) {
        clearShowTimer();
        showOverlay();
    } else if (pendingCount === 1) {
        scheduleShow();
    } else if (isVisible) {
        updateMessageText();
    }

    return function release() {
        trackEnd();
    };
}

function trackEnd() {
    if (pendingCount <= 0) {
        return;
    }

    pendingCount -= 1;
    activeMessages.pop();
    updateMessageText();

    if (pendingCount === 0) {
        clearShowTimer();
        hideOverlay();
        return;
    }

    if (isVisible) {
        updateMessageText();
    }
}

function shouldSkipAutoTracking(url, options = {}) {
    if (manualLockCount > 0) {
        return true;
    }
    if (options.skipGlobalSpinner) {
        return true;
    }
    return isSilentUrl(url);
}

function resolveAjaxOptions(args) {
    if (args.length === 0) {
        return {};
    }
    if (typeof args[0] === 'string') {
        return { ...(args[1] || {}), url: args[0] };
    }
    return { ...args[0] };
}

// --- Fetch/ajax patching ---

function patchFetch() {
    const originalFetch = window.fetch.bind(window);

    window.fetch = function patchedFetch(input, init = {}) {
        const url = resolveUrl(input);
        const method = String((init && init.method) || 'GET').toUpperCase();

        if (method !== 'GET' && method !== 'POST') {
            return originalFetch(input, init);
        }

        if (shouldSkipAutoTracking(url, init)) {
            return originalFetch(input, init);
        }

        return wrapTrackedRequest(url, init, () => originalFetch(input, init));
    };
}

function patchJQueryAjax() {
    if (!window.jQuery || !window.jQuery.ajax) {
        return;
    }

    const $ = window.jQuery;
    const originalAjax = $.ajax.bind($);

    $.ajax = function patchedAjax(...args) {
        const options = resolveAjaxOptions(args);
        const url = options.url || '';
        const method = String(options.type || options.method || 'GET').toUpperCase();

        if (method !== 'GET' && method !== 'POST') {
            return originalAjax(...args);
        }

        if (shouldSkipAutoTracking(url, options)) {
            return originalAjax(...args);
        }

        return wrapTrackedRequest(url, options, () => {
            if (typeof args[0] === 'string') {
                return originalAjax(args[0], options);
            }
            return originalAjax(options);
        });
    };
}

function parseStartArgs(messageOrOptions, maybeOptions) {
    if (messageOrOptions && typeof messageOrOptions === 'object' && !Array.isArray(messageOrOptions)) {
        return {
            message: undefined,
            options: messageOrOptions,
        };
    }

    return {
        message: messageOrOptions,
        options: maybeOptions || {},
    };
}

function startManual(messageOrOptions, maybeOptions) {
    const { message, options } = parseStartArgs(messageOrOptions, maybeOptions);
    manualLockCount += 1;
    const release = trackStart(message, options);

    return function releaseManual() {
        manualLockCount = Math.max(0, manualLockCount - 1);
        release();
    };
}

function initSpinnerDom() {
    ensureDom();
}

// --- Page init ---

patchFetch();
patchJQueryAjax();

if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initSpinnerDom);
} else {
    initSpinnerDom();
}

window.globalSpinner = {
    messages: SPINNER_MESSAGES,
    start: startManual,
    showForecastProgress,
    setForecastProgress,
    hideForecastProgress,
    setForecastCancelHandler,
};

window.requestHandler = {
    lockSubmits,
};
