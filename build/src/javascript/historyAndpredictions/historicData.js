// historicData.js — cache, getIncome, getExpenses

// --- Cache ---

const dataCache = {
  incomeByYear: {},
  expenseByYear: {},
  sourceByIncome: {},
  sourceByExpense: {},
  plotTotals: {},
  inFlight: {} // pending fetch promises keyed by income/expense-year
};

// --- getIncome / getExpenses ---

async function fetchIncomeYear(y) {
  if (dataCache.incomeByYear[y]) {
    return dataCache.incomeByYear[y];
  }
  const key = `income-${y}`;
  if (dataCache.inFlight[key]) return dataCache.inFlight[key];

  dataCache.inFlight[key] = (async () => {
    try {
      const response = await $.ajax({
        url: '/php/transactions/getIncome.php',
        data: { year: y },
        dataType: 'json',
        xhrFields: { withCredentials: true }
      });
      if (!window.handleAjaxResult(response)) {
        throw new Error(response.errorMsg || window.API_MESSAGES.defaultError);
      }
      const months = rowsToMonths(response.data, 'DateOfIncome', 'Income', true);
      dataCache.incomeByYear[y] = { rows: response.data, months };
      return dataCache.incomeByYear[y];
    } catch (err) {
      if (err && typeof err.status === 'number') {
        window.handleAjaxRequestError(err, window.API_MESSAGES.connectionError);
      }
      throw err;
    } finally {
      delete dataCache.inFlight[key];
    }
  })();

  return dataCache.inFlight[key];
}

async function fetchExpenseYear(y) {
  if (dataCache.expenseByYear[y]) {
    return dataCache.expenseByYear[y];
  }
  const key = `expense-${y}`;
  if (dataCache.inFlight[key]) return dataCache.inFlight[key];

  dataCache.inFlight[key] = (async () => {
    try {
      const response = await $.ajax({
        url: '/php/transactions/getExpenses.php',
        data: { year: y },
        dataType: 'json',
        xhrFields: { withCredentials: true }
      });
      if (!window.handleAjaxResult(response)) {
        throw new Error(response.errorMsg || window.API_MESSAGES.defaultError);
      }
      const months = rowsToPositiveMonths(response.data, 'DateOfExpense', 'expense');
      dataCache.expenseByYear[y] = { rows: response.data, months };
      return dataCache.expenseByYear[y];
    } catch (err) {
      if (err && typeof err.status === 'number') {
        window.handleAjaxRequestError(err, window.API_MESSAGES.connectionError);
      }
      throw err;
    } finally {
      delete dataCache.inFlight[key];
    }
  })();

  return dataCache.inFlight[key];
}

function ensureYearData(y) {
  return Promise.all([fetchIncomeYear(y), fetchExpenseYear(y)]);
}

function yearHasData(y, plotVal) {
  const inc = dataCache.incomeByYear[y];
  const exp = dataCache.expenseByYear[y];
  const hasInc = inc && inc.rows.length > 0;
  const hasExp = exp && exp.rows.length > 0;
  if (plotVal === 'Income') return hasInc;
  if (plotVal === 'Expense') return hasExp;
  return hasInc || hasExp;
}

// --- helpers ---

function rowsToMonths(rows, dateField, amountField, positive) {
  const months = new Array(12).fill(0);
  rows.forEach(row => {
    const month = parseInt(row[dateField].split('-')[1], 10) - 1;
    const amount = parseFloat(row[amountField]);
    months[month] += positive ? amount : -amount;
  });
  return months;
}

function rowsToPositiveMonths(rows, dateField, amountField) {
  const months = new Array(12).fill(0);
  rows.forEach(row => {
    const month = parseInt(row[dateField].split('-')[1], 10) - 1;
    months[month] += parseFloat(row[amountField]);
  });
  return months;
}
