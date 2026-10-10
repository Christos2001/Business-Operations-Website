// searchEmployee.js — employee search, mode routing, results display

// --- Initialization ---

const mode = new URLSearchParams(window.location.search).get('q');

let searchMode; // API mode: manageEmp | viewShifts | addShift
if (mode === 'manageEmp') {
    searchMode = 'manageEmp';
} else if (mode === 'viewShifts') {
    searchMode = 'viewShifts';
} else {
    searchMode = 'addShift';
}

const pageHeader = document.getElementById('pageHeader');

if (pageHeader) {
    if (mode === 'manageEmp') {
        pageHeader.textContent = ' Manage-Employee';
        document.title = ' Manage-Employee';
    } else if (mode === 'viewShifts') {
        pageHeader.textContent = 'View employee shifts';
        document.title = 'View employee shifts';
    } else {
        pageHeader.textContent = 'Add Shift';
        document.title = 'Add Shift';
    }
}

const resultsMessage = document.getElementById('resultsMessage');

const DEFAULT_PHOTO = 'data:image/svg+xml,' + encodeURIComponent(
    '<svg xmlns="http://www.w3.org/2000/svg" width="120" height="120" viewBox="0 0 120 120">' +
    '<rect width="120" height="120" fill="#e9ecef"/>' +
    '<circle cx="60" cy="45" r="22" fill="#adb5bd"/>' +
    '<ellipse cx="60" cy="95" rx="35" ry="28" fill="#adb5bd"/>' +
    '</svg>'
);

// --- Results display ---

function itemHasPhoto(item) {
    return (item.hasPhoto === true || item.hasPhoto === 1 || item.hasPhoto === '1') && !!item.photoVersion;
}

function searchPhotoUrl(item) {
    return '/php/profile/getPartialProfile.php?i=' + encodeURIComponent(item.id)
        + '&photo=1&list=1&v=' + encodeURIComponent(item.photoVersion);
}

function resultLabelText(item, includeId) {
    const name = item.name + ' ' + item.surname;
    return includeId ? name + ' ' + item.id : name;
}

function idsToShowSet(showId) {
    if (!showId || !showId.exists || !Array.isArray(showId.ids) || showId.ids.length === 0) {
        return null;
    }
    return new Set(showId.ids.map(String));
}

function createResultButton(item, idsToShow) {
    const btn = document.createElement('button');
    btn.type = 'button';

    const photo = document.createElement('img');
    photo.className = 'search-employee-result-photo';
    photo.alt = '';

    const label = document.createElement('span');
    label.className = 'search-employee-result-label';

    if (itemHasPhoto(item)) {
        photo.src = searchPhotoUrl(item);
        photo.addEventListener('error', () => {
            photo.src = DEFAULT_PHOTO;
        });
    } else {
        photo.src = DEFAULT_PHOTO;
    }
    label.textContent = resultLabelText(item, !!(idsToShow && idsToShow.has(String(item.id))));

    btn.appendChild(photo);
    btn.appendChild(label);
    btn.addEventListener('click', (e) => {
        e.preventDefault();
        let targetPage;
        if (mode === 'manageEmp') {
            targetPage = '/html/profile/ManageProfileAndPreveliges.html';
        } else if (mode === 'viewShifts') {
            targetPage = '/html/shifts/viewEmployeeShifts.html';
        } else {
            targetPage = '/html/shifts/addShift.html';
        }
        window.location = targetPage + '?i=' + item.id;
    });

    return btn;
}

function clearResults() {
    const buttons = document.querySelectorAll('#resultsDiv button');

    buttons.forEach(button => {
        button.remove();
    });
}

const SEARCH_DEBOUNCE_MS = 300;
let searchDebounceTimer = null;
let searchAbortController = null;
let searchRequestId = 0;

function isAbortError(error) {
    return !!error && (error.name === 'AbortError' || error.code === 20);
}

function showResultsMessage(text) {
    resultsMessage.textContent = text;
    resultsMessage.style.display = 'block';
}

async function runEmployeeSearch(query) {
    if (searchAbortController) {
        searchAbortController.abort();
        searchAbortController = null;
    }

    const requestId = ++searchRequestId;

    if (query === '') {
        clearResults();
        showResultsMessage('Search query is empty.');
        return;
    }

    searchAbortController = new AbortController();
    const { signal } = searchAbortController;

    try {
        const response = await fetch(
            "/php/common/searchUser.php?q=" + encodeURIComponent(query) + "&mode=" + encodeURIComponent(searchMode),
            {
                credentials: 'same-origin',
                headers: { Accept: 'application/json' },
                signal
            }
        );

        const results = await window.parseFetchJsonResponse(response, {
            suppressAlertForErrors: ['Search query is empty.']
        });
        if (requestId !== searchRequestId) {
            return;
        }
        if (!results || results.denied) {
            return;
        }

        clearResults();

        if (!results.success && results.errorMsg === 'Search query is empty.') {
            showResultsMessage(results.errorMsg);
            return;
        }

        if (results.data.length === 0) {
            resultsMessage.style.display = 'block';
            return;
        }

        resultsMessage.style.display = 'none';
        const resultsDiv = document.getElementById("resultsDiv");
        const idsToShow = idsToShowSet(results.showId);
        results.data.forEach(item => {
            resultsDiv.appendChild(createResultButton(item, idsToShow));
        });
    } catch (error) {
        if (isAbortError(error) || requestId !== searchRequestId) {
            return;
        }
        window.handleFetchError(error);
    }
}

document.querySelector("#searchEmp").addEventListener('input', () => {
    const query = document.querySelector("#searchEmp").value;

    clearTimeout(searchDebounceTimer);
    searchDebounceTimer = setTimeout(() => {
        runEmployeeSearch(query);
    }, SEARCH_DEBOUNCE_MS);
});
