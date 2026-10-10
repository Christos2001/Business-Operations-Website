// records.js — income/expense records, pagination, search, delete/retrieve

// --- Initialization ---

const input = $("#searchSource")
const table = $("#incomes")
const pageButtons = $(".page-btn")
const noRecordsHeading = $("#noRecords")
const pagination = $("#pagination")

const modal = $("#notes_modal")
const closeBtn = $("#close")
const modalInfo = $("#info")
const modalContent = $("#modal-content-p")

const type = new URLSearchParams(window.location.search).get('type'); // Income or Expense page mode

let currentPage = 1
let currentSearch = '' // persists search query across pagination
let totalPages = 1

if (type == "Income") {
    url = "/html/transactions/addIncome.html"
} else if (type == "Expense") {
    url = "/html/transactions/addExpense.html"
}

$("#insertLink").attr("href", url)

let trashImg = $("<img>", {
    src: "/imgs/trashcan.jpg",
    css: {
        "width": "40px",
        "height": "40px",
        "cursor": "pointer"
    },
});

// --- Record display ---

function getRecordFields(item) {
    const deletedAt = item.deletedAt ?? null;
    const isDeleted = deletedAt != null && deletedAt !== '';

    if (type === "Income") {
        return {
            id: item.id,
            source: item.Source ?? item.source,
            amount: item.Income ?? item.income,
            date: item.DateOfIncome ?? item.dateofincome,
            notes: item.Notes ?? item.notes,
            hasAttachment: Number(item.hasAttachment) === 1,
            isDeleted
        };
    }
    return {
        id: item.id,
        source: item.source ?? item.Source,
        amount: item.expense ?? item.Expense,
        date: item.DateOfExpense ?? item.dateofexpense,
        notes: item.Notes ?? item.notes,
        hasAttachment: Number(item.hasAttachment) === 1,
        isDeleted
    };
}

function clearDataRows() {
    while (table.find('tr').length > 2) {
        table.find('tr').eq(2).remove();
    }
}

function DisplayModal(source, transaction, date, notes) {
    modalInfo.text("Source: " + source + "\n" + type + ": " + transaction + "\nDate: " + date + "\n\nNotes:")
    modalContent.text(notes)
    modal.fadeIn();
}

function DisplayRecords(id, source, transaction, date, notes, hasAttachment, isDeleted) {
    const row = $('<tr>');

    if (isDeleted) {
        row.addClass('row-deleted');
        row.append($('<td>').text(source));
        row.append($('<td>').text('—'));
        row.append($('<td>').text(date));
        row.append($('<td>').text('—'));
        row.append($('<td>').text('—'));
        row.append(
            $('<td>').append(
                $('<button>', {
                    class: 'retrieve-btn',
                    'data-id': id,
                    text: 'Retrieve'
                })
            )
        );
        table.append(row);
        return;
    }

    row.append($('<td>').text(source));
    row.append($('<td>').text(transaction));
    row.append($('<td>').text(date))

    if (notes == null) {
        notes = "—"
    }
    row.append($('<td>').text(notes))

    const attachedFileCell = $('<td>');
    if (hasAttachment) {
        const recordType = type === "Income" ? "income" : "expense";
        attachedFileCell.append(
            $('<a>', {
                href: `/php/transactions/downloadAttachment.php?id=${encodeURIComponent(id)}&type=${recordType}`,
                target: '_blank',
                rel: 'noopener noreferrer',
                text: 'View file',
                class: 'attachedFile-link'
            })
        );
    } else {
        attachedFileCell.text('—');
    }
    row.append(attachedFileCell);

    row.on('mouseenter mouseleave', function () {
        $(this).toggleClass("row-hover-effect");
    });

    row.append(
        $('<td>').append(
            trashImg.clone().attr("data-id", id).addClass("delete-btn")
        )
    );

    row.css('cursor', 'pointer').on('click', (e) => {
        if ($(e.target).closest('.delete-btn, .attachedFile-link').length == 0) {
            DisplayModal(source, transaction, date, notes)
        }
    })

    table.append(row);
}

// --- Pagination ---

function getPaginationTargets(page, pages) {
    if (page <= 4 && !(page === 4 && pages > 4)) {
        return [1, 2, 3, 4];
    }
    if (page === 4 && pages > 4) {
        return [1, 3, 4, 5];
    }
    return [1, page - 1, page, page + 1];
}

function isPaginationDisabled(targetPage, pages) {
    return targetPage < 1 || targetPage > pages;
}

function updateEmptyState(totalRecords, search) {
    const isEmpty = totalRecords === 0;
    if (isEmpty) {
        noRecordsHeading
            .text(search.trim() ? "No matching records" : "No Records yet")
            .prop("hidden", false)
            .show();
        pagination.hide();
    } else {
        noRecordsHeading.prop("hidden", true).hide();
        pagination.show();
    }
}

function updateSearchPlaceholder(hasActiveSearch) {
    const base = "Search " + type;
    if (hasActiveSearch) {
        input.attr("placeholder", base + " / Type '/all' to display all records");
    } else {
        input.attr("placeholder", base);
    }
}

function updatePaginationButtons(page, pages) {
    if (pages === 0) {
        return;
    }
    totalPages = pages;
    currentPage = page;
    const targets = getPaginationTargets(page, pages); // four slot page numbers for button row

    pageButtons.each(function (slot) {
        const $btn = $(this);
        const targetPage = targets[slot];
        const disabled = isPaginationDisabled(targetPage, pages);

        $btn.text(targetPage);
        $btn.data("page", targetPage);
        $btn.toggleClass("page-btn--active", targetPage === page && !disabled);
        $btn.toggleClass("page-btn--disabled", disabled);
    });
}

// --- Data loading ---

async function loadPage(page = 1, search = currentSearch) {
    if (type !== "Income" && type !== "Expense") {
        return;
    }

    const endpoint = type === "Income" ? "/php/transactions/getIncome.php" : "/php/transactions/getExpenses.php";
    const params = new URLSearchParams({ page: String(page) });
    if (search.trim()) {
        params.set("search", search.trim());
    }

    try {
        const response = await fetch(`${endpoint}?${params.toString()}`, {
            credentials: 'same-origin',
            headers: { Accept: 'application/json' }
        });
        const results = await window.parseFetchJsonResponse(response);
        if (!results || results.denied) {
            return;
        }

        currentSearch = search;
        updateSearchPlaceholder(search.trim() !== '');
        clearDataRows();

        (results.data || []).forEach(item => {
            const fields = getRecordFields(item);
            DisplayRecords(
                fields.id,
                fields.source,
                fields.amount,
                fields.date,
                fields.notes,
                fields.hasAttachment,
                fields.isDeleted
            );
        });

        const totalRecords = results.totalRecords ?? (results.data || []).length;
        updateEmptyState(totalRecords, search);
        updatePaginationButtons(results.page || page, results.totalPages ?? 0);
    } catch (err) {
        window.handleFetchError(err);
    }
}

// --- Delete/retrieve ---

closeBtn.on('click', () => {
    modal.hide();
});

$(document).on('click', '.delete-btn', async function (e) {
    e.stopPropagation();
    const idToDelete = $(this).attr("data-id");

    if (!confirm("Are you sure, you want to delete this record?")) {
        return;
    }

    let deleteUrl;
    if (type == "Income") {
        deleteUrl = '/php/transactions/deleteIncome.php';
    } else if (type == "Expense") {
        deleteUrl = '/php/transactions/deleteExpense.php';
    } else {
        return;
    }

    try {
        const response = await $.ajax({
            url: deleteUrl,
            type: 'POST',
            xhrFields: { withCredentials: true },
            data: { id: idToDelete },
            dataType: 'json'
        });
        if (!window.handleAjaxResult(response)) {
            return;
        }
        alert(response.successMsg || (type + " marked for deletion."));
        loadPage(currentPage, currentSearch);
    } catch (xhr) {
        window.handleAjaxRequestError(xhr, window.API_MESSAGES.connectionError);
    }
});

$(document).on('click', '.retrieve-btn', async function (e) {
    e.stopPropagation();
    const idToRetrieve = $(this).attr("data-id");

    if (!confirm("Are you sure you want to retrieve this record?")) {
        return;
    }

    let retrieveUrl;
    if (type == "Income") {
        retrieveUrl = '/php/transactions/retrieveIncome.php';
    } else if (type == "Expense") {
        retrieveUrl = '/php/transactions/retrieveExpense.php';
    } else {
        return;
    }

    try {
        const response = await $.ajax({
            url: retrieveUrl,
            type: 'POST',
            xhrFields: { withCredentials: true },
            data: { id: idToRetrieve },
            dataType: 'json'
        });
        if (!window.handleAjaxResult(response)) {
            return;
        }
        alert(response.successMsg || (type + " restored successfully."));
        loadPage(currentPage, currentSearch);
    } catch (xhr) {
        window.handleAjaxRequestError(xhr, window.API_MESSAGES.connectionError);
    }
});

pageButtons.on("click", function () {
    const $btn = $(this);
    if ($btn.hasClass("page-btn--disabled")) {
        return;
    }
    const targetPage = parseInt($btn.data("page"), 10);
    if (!isNaN(targetPage) && targetPage !== currentPage) {
        loadPage(targetPage, currentSearch);
    }
});

// --- Search ---

input.on("keydown", (event) => {
    if (event.key !== "Enter") {
        return;
    }

    const query = input.val().trim();

    if (query.toLowerCase() === "/all") {
        input.val("");
        loadPage(1, "");
        return;
    }

    loadPage(1, query);
    input.val("");
});

// --- Page init ---

$(document).ready(function () {
    if (type === "Income") {
        $("#amountColumnHeader").text("Income");
        document.title = "Records - Income";
    } else if (type === "Expense") {
        $("#amountColumnHeader").text("Expense");
        document.title = "Records - Expenses";
    }
    updateSearchPlaceholder(false);
    loadPage(1);
});
