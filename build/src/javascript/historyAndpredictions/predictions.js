// predictions.js — Growth / Driver forecasts, cache, modal management

// --- Growth / Driver forecasts---

async function buildMultiYearBase(numYears, targetYear) {
  const fetchPromises = [];
  forExaminedYears(numYears, targetYear, y => fetchPromises.push(ensureYearData(y)));
  await Promise.all(fetchPromises);

  const baseIncome = [];
  const baseExpenses = [];
  forExaminedYears(numYears, targetYear, y => {
    baseIncome.push([...dataCache.incomeByYear[y].months]);
    baseExpenses.push([...dataCache.expenseByYear[y].months]);
  });
  return { baseIncome, baseExpenses };
}

async function buildMultiYearSourceMaps(numYears, targetYear) {
  const fetchPromises = [];
  forExaminedYears(numYears, targetYear, y => fetchPromises.push(ensureYearData(y)));
  await Promise.all(fetchPromises);

  const incomePerYear = [];
  const expensePerYear = [];
  forExaminedYears(numYears, targetYear, y => {
    ensureSourceMapsForYear(y);
    incomePerYear.push(copySourceMap(dataCache.sourceByIncome[y] || {}));
    expensePerYear.push(copySourceMap(dataCache.sourceByExpense[y] || {}));
  });
  return { incomePerYear, expensePerYear };
}

function copySourceMap(map) {
  const out = {};
  Object.entries(map || {}).forEach(([name, months]) => {
    out[name] = [...months];
  });
  return out;
}

const TRAINING_HISTORICAL_NONE = '__training_none__'; // sentinel: use historical data only for training year

const forecastError = $('#ForecastError');

const DRIVER_SOURCE_PAGE_SIZE = 10; // API batch (2 visible pages)
const DRIVER_SOURCE_VISIBLE_SIZE = 5; // rows shown per Show more

const driverSourceState = {
  income: { offset: 0, hasMore: false, q: '', requestId: 0, loading: false },
  expense: { offset: 0, hasMore: false, q: '', requestId: 0, loading: false }
};
const driverSourceSearchTimers = { income: null, expense: null };

const GB_FORECAST_URL = '/php/predictions/GradientBoost/forecastGradientBoost.php';
let gbForecastAbort = null; // in-flight Gradient Boost fetch; aborted on leave/reload

function abortGbForecastRequest() {
  if (gbForecastAbort) {
    gbForecastAbort.abort();
    gbForecastAbort = null;
  }
}

const GB_N_TRIALS = { 1: 50, 2: 100, 3: 200, 4: 500 };
const GB_TUNING_LABELS = { 1: 'Fast', 2: 'Mid', 3: 'Advanced', 4: 'Extreme' };
const GB_PRUNER_LABELS = { none: 'None', median: 'MedianPruner', hyperband: 'Hyperband' };

function collectGbTuning() {
  const level = parseInt($('input[name="gbTuningLevel"]:checked').val(), 10) || 1;
  const nTrials = GB_N_TRIALS[level] || 50;
  const pruner = $('input[name="gbPruner"]:checked').val() || 'none';
  const capOn = $('input[name="gbTimeCap"]:checked').val() === 'on';
  let timeoutSec = null;
  if (capOn) {
    const hours = parseInt($('#gbTimeoutHours').val(), 10);
    const minutes = parseInt($('#gbTimeoutMinutes').val(), 10);
    const h = Number.isNaN(hours) ? 0 : hours;
    const m = Number.isNaN(minutes) ? 0 : minutes;
    if (h < 0 || h > 99 || m < 0 || m > 59 || (h === 0 && m === 0)) {
      forecastError.text('Time cap must be at least 1 minute.');
      return null;
    }
    timeoutSec = h * 3600 + m * 60;
  }
  return { tuningLevel: level, nTrials, pruner, timeoutSec };
}

function formatGbScore(value) {
  const n = Number(value);
  if (!Number.isFinite(n)) return '—';
  return n.toFixed(2);
}

function formatGbTimeoutLabel(timeoutSec) {
  if (timeoutSec == null) return 'no cap';
  const h = Math.floor(timeoutSec / 3600);
  const m = Math.floor((timeoutSec % 3600) / 60);
  if (h > 0 && m > 0) return `${h}h ${m}m cap`;
  if (h > 0) return `${h}h cap`;
  return `${m}m cap`;
}

function diagnoseNeedsConfirm(diag) {
  return !!(diag && diag.needsConfirm);
}

function diagnoseForPlot(plotVal, response) {
  if (!response) return null;
  if (plotVal === 'Income') return response.incomeDiagnose || null;
  if (plotVal === 'Expense') return response.expenseDiagnose || null;
  if (diagnoseNeedsConfirm(response.incomeDiagnose)) return response.incomeDiagnose;
  if (diagnoseNeedsConfirm(response.expenseDiagnose)) return response.expenseDiagnose;
  return response.incomeDiagnose || response.expenseDiagnose || null;
}

function formatGbDiagnoseLabel(diag, prefix) {
  if (!diag || !diag.reason || diag.reason === 'ok') return '';
  const head = prefix ? `${prefix} ${diag.reason}` : diag.reason;
  return `, ${head} [train MAE ${formatGbScore(diag.trainMae)}, CV MAE ${formatGbScore(diag.cvMae)}, gap ${formatGbScore(diag.relativeGap)}]`;
}

function formatGbDiagnoseSuffix(entry) {
  if (!entry) return '';
  if (entry.plotType === 'NetIncome') {
    return formatGbDiagnoseLabel(entry.incomeDiagnose, 'income')
      + formatGbDiagnoseLabel(entry.expenseDiagnose, 'expense');
  }
  return formatGbDiagnoseLabel(entry.diagnose);
}

function gbDiagnoseDownloadLines(entry) {
  const lines = [];
  const push = (diag, prefix) => {
    if (!diag || !diag.reason || diag.reason === 'ok') return;
    const label = prefix ? `${prefix} ${diag.reason}` : diag.reason;
    lines.push(`Diagnose: ${label}`);
    lines.push(
      `Scores: train MAE ${formatGbScore(diag.trainMae)}, CV MAE ${formatGbScore(diag.cvMae)}, relative gap ${formatGbScore(diag.relativeGap)}`
    );
  };
  if (entry && entry.plotType === 'NetIncome') {
    push(entry.incomeDiagnose, 'income');
    push(entry.expenseDiagnose, 'expense');
    return lines;
  }
  push(entry && entry.diagnose);
  return lines;
}

function gbDiagnoseReasonWord(diag) {
  return diag && diag.reason === 'underfit' ? 'underfits' : 'overfits';
}

function gbDiagnoseScoreSentence(diag) {
  return `Best trial has scores: train MAE ${formatGbScore(diag.trainMae)}, CV MAE ${formatGbScore(diag.cvMae)}, relative gap ${formatGbScore(diag.relativeGap)}.`;
}

function gbDiagnoseCanTune(diag) {
  const completed = Number(diag.trialsCompleted) || 0;
  const attempted = Number(diag.trialsAttempted);
  const nTrials = Number(diag.nTrials) || 0;
  const ran = Number.isFinite(attempted) && attempted > 0 ? attempted : completed;
  return nTrials > 0 && ran < nTrials;
}

function showGbDiagnoseDialog(items) {
  return new Promise((resolve) => {
    const list = Array.isArray(items) ? items.filter((item) => item && item.diag) : [];
    const reasons = [...new Set(list.map((item) => gbDiagnoseReasonWord(item.diag)))];
    $('#gbDiagnoseTitle').text(`Optuna trials until now ${reasons.join(' / ')}`);

    const parts = list.map((item) => {
      const prefix = item.label ? `${item.label} ${gbDiagnoseReasonWord(item.diag)}. ` : '';
      let block = prefix + gbDiagnoseScoreSentence(item.diag);
      const completed = Number(item.diag.trialsCompleted) || 0;
      const nTrials = Number(item.diag.nTrials) || 0;
      if (nTrials > 0) {
        const trialBit = item.label
          ? `${item.label}: ${completed} of ${nTrials} Optuna trials finished.`
          : `${completed} of ${nTrials} Optuna trials finished.`;
        block += `\n${trialBit}`;
      }
      return block;
    });
    $('#gbDiagnoseBody').text(
      `${parts.join('\n')}\nDo you want to keep the best trial so far or keep tuning?`
    );
    $('#gbDiagnoseTune').toggle(list.some((item) => gbDiagnoseCanTune(item.diag)));

    const cleanup = (choice) => {
      $('#gbDiagnoseKeep').off('click.gbDiagnose');
      $('#gbDiagnoseTune').off('click.gbDiagnose');
      $('#gbDiagnoseModal').removeClass('forecast-modal-open');
      resolve(choice);
    };
    $('#gbDiagnoseKeep').off('click.gbDiagnose').on('click.gbDiagnose', () => cleanup('keep'));
    $('#gbDiagnoseTune').off('click.gbDiagnose').on('click.gbDiagnose', () => cleanup('tune'));
    $('#gbDiagnoseModal').addClass('forecast-modal-open');
  });
}

async function confirmGbDiagnoseIfNeeded(response, plotVal) {
  const items = [];
  const net = plotVal === 'NetIncome';
  if (plotVal === 'Income' || net) {
    if (diagnoseNeedsConfirm(response.incomeDiagnose)) {
      items.push({ diag: response.incomeDiagnose, label: net ? 'Income' : '' });
    }
  }
  if (plotVal === 'Expense' || net) {
    if (diagnoseNeedsConfirm(response.expenseDiagnose)) {
      items.push({ diag: response.expenseDiagnose, label: net ? 'Expense' : '' });
    }
  }
  if (items.length === 0) return 'keep';
  return showGbDiagnoseDialog(items);
}

function cacheGbNetSiblings(netEntry, response) {
  if (!netEntry || netEntry.plotType !== 'NetIncome' || netEntry.modelType !== 'gb') return;
  const shared = {
    createdAt: netEntry.createdAt,
    params: { ...(netEntry.params || {}) },
    modelType: 'gb',
    targetYear: netEntry.targetYear,
    partialYear: netEntry.partialYear,
    forecastFromMonth: netEntry.forecastFromMonth,
    trainingForecastKeys: netEntry.trainingForecastKeys,
    incomeMonths: netEntry.incomeMonths ? [...netEntry.incomeMonths] : null,
    expenseMonths: netEntry.expenseMonths ? [...netEntry.expenseMonths] : null,
    incomeBySource: null,
    expenseBySource: null
  };
  if (netEntry.incomeMonths) {
    const incKey = makeCacheKey(netEntry.targetYear, 'Income', 'gb', netEntry.params);
    const incY = [...netEntry.incomeMonths];
    predictionCache[incKey] = {
      ...shared,
      cacheKey: incKey,
      displayId: nextForecastDisplayId++,
      plotType: 'Income',
      y: incY,
      total: computeYearTotal(incY),
      diagnose: response?.incomeDiagnose || null,
      incomeDiagnose: response?.incomeDiagnose || null,
      expenseDiagnose: null
    };
  }
  if (netEntry.expenseMonths) {
    const expKey = makeCacheKey(netEntry.targetYear, 'Expense', 'gb', netEntry.params);
    const expY = netEntry.expenseMonths.map(v => -Math.abs(v));
    predictionCache[expKey] = {
      ...shared,
      cacheKey: expKey,
      displayId: nextForecastDisplayId++,
      plotType: 'Expense',
      y: expY,
      total: computeYearTotal(expY),
      diagnose: response?.expenseDiagnose || null,
      incomeDiagnose: null,
      expenseDiagnose: response?.expenseDiagnose || null
    };
  }
}

if (window.globalSpinner && typeof window.globalSpinner.setForecastCancelHandler === 'function') {
  window.globalSpinner.setForecastCancelHandler(abortGbForecastRequest);
}

function applyGbProgressLine(msg) {
  if (!msg || msg.type !== 'progress') {
    return;
  }
  if (window.globalSpinner && typeof window.globalSpinner.setForecastProgress === 'function') {
    window.globalSpinner.setForecastProgress(msg.bar, msg.pct, msg.message);
  }
}

async function requestGradientBoostForecast(payload) {
  abortGbForecastRequest();
  const controller = new AbortController();
  gbForecastAbort = controller;

  let response;
  try {
    const res = await fetch(GB_FORECAST_URL, {
      method: 'POST',
      credentials: 'include',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
      signal: controller.signal,
      skipGlobalSpinner: true,
    });

    if (!res.ok) {
      await window.parseFetchJsonResponse(res);
      const handled = new Error('handled');
      handled.gbHandled = true;
      throw handled;
    }

    if (!res.body) {
      throw new Error(window.API_MESSAGES.connectionError);
    }

    const reader = res.body.getReader();
    const decoder = new TextDecoder();
    let buffer = '';
    let result = null;

    const consumeLine = (line) => {
      const trimmed = line.trim();
      if (!trimmed) {
        return;
      }
      let msg;
      try {
        msg = JSON.parse(trimmed);
      } catch {
        return;
      }
      if (msg.type === 'progress') {
        applyGbProgressLine(msg);
        return;
      }
      if (msg.type === 'result') {
        result = msg;
      }
    };

    while (true) {
      const { value, done } = await reader.read();
      if (done) {
        break;
      }
      buffer += decoder.decode(value, { stream: true });
      const lines = buffer.split('\n');
      buffer = lines.pop();
      lines.forEach(consumeLine);
    }
    buffer += decoder.decode();
    if (buffer.trim()) {
      consumeLine(buffer);
    }

    if (!result) {
      throw new Error(window.API_MESSAGES.invalidResponse || window.API_MESSAGES.defaultError);
    }
    response = result;
  } catch (err) {
    if (gbForecastAbort === controller) {
      gbForecastAbort = null;
    }
    throw err;
  }

  if (gbForecastAbort === controller) {
    gbForecastAbort = null;
  }
  return response;
}

function getExaminedYearRange(numYears, targetYear) {
  const endYear = targetYear - 1;
  const startYear = targetYear - numYears;
  const years = [];
  for (let y = startYear; y <= endYear; y++) {
    years.push(y);
  }
  return years;
}

async function ensureExaminedYearsData(numYears, targetYear) {
  const years = getExaminedYearRange(numYears, targetYear);
  await Promise.all(years.map(y => ensureYearData(y)));
}

function formatExaminedYearsPreview(numYears, targetYear) {
  return examinedYears(numYears, targetYear);
}

function getForecastIncomeMonths(entry) {
  if (!entry) return null;
  if (entry.incomeMonths) return entry.incomeMonths;
  if (entry.incomeBySource) return sumSourceMapToMonths(entry.incomeBySource);
  return null;
}

function getForecastExpenseMonths(entry) {
  if (!entry) return null;
  if (entry.expenseMonths) return entry.expenseMonths;
  if (entry.expenseBySource) return sumSourceMapToMonths(entry.expenseBySource);
  return null;
}

function hasRequiredForecastData(entry, plotTypeInternal) {
  if (!entry) return false;
  if (plotTypeInternal === 'income') return !!getForecastIncomeMonths(entry);
  if (plotTypeInternal === 'expenses') return !!getForecastExpenseMonths(entry);
  return !!getForecastIncomeMonths(entry) && !!getForecastExpenseMonths(entry);
}

function hasHistoricalDataForYear(y, plotTypeInternal) {
  const inc = dataCache.incomeByYear[y]?.rows?.length > 0;
  const exp = dataCache.expenseByYear[y]?.rows?.length > 0;
  if (plotTypeInternal === 'income') return inc;
  if (plotTypeInternal === 'expenses') return exp;
  return inc || exp;
}

function listForecastsInWindow(targetYear, plotVal, numYears, trainingModelType) {
  const windowYears = new Set(getExaminedYearRange(numYears, targetYear)); // years in the training window
  return Object.entries(predictionCache)
    .filter(([, entry]) => {
      if (entry.plotType !== plotVal || !windowYears.has(entry.targetYear)) return false;
      if (trainingModelType && entry.modelType !== trainingModelType) return false;
      return true;
    })
    .sort((a, b) => {
      if (a[1].targetYear !== b[1].targetYear) return a[1].targetYear - b[1].targetYear;
      const byId = (b[1].displayId || 0) - (a[1].displayId || 0);
      if (byId !== 0) return byId;
      return (b[1].createdAt || 0) - (a[1].createdAt || 0);
    });
}

function getSelectedForecastModelType() {
  return $('input[name="forecastModel"]:checked').val() || 'growth';
}

function hasRequiredDriverSourceData(entry, plotTypeInternal) {
  if (!entry || entry.modelType !== 'driver') return false;
  if (plotTypeInternal === 'income') {
    return !!(entry.incomeBySource && Object.keys(entry.incomeBySource).length > 0);
  }
  if (plotTypeInternal === 'expenses') {
    return !!(entry.expenseBySource && Object.keys(entry.expenseBySource).length > 0);
  }
  const hasInc = entry.incomeBySource && Object.keys(entry.incomeBySource).length > 0;
  const hasExp = entry.expenseBySource && Object.keys(entry.expenseBySource).length > 0;
  return !!(hasInc || hasExp);
}

function getSelectedTrainingForecastKeys() {
  const keys = [];
  $('#forecastTrainingList input.forecast-training-pick:checked').each(function () {
    const val = $(this).val();
    if (val && val !== TRAINING_HISTORICAL_NONE) {
      keys.push(val);
    }
  });
  return keys;
}

function hasTrainingSelectionForYear(yearNum, selectedKeys) {
  return selectedKeys.some(k => predictionCache[k]?.targetYear === yearNum);
}

function canUseHistoricalTrainingForYear(yearNum, plotTypeInternal) {
  return yearNum <= thisYear && hasHistoricalDataForYear(yearNum, plotTypeInternal);
}

function getHistoricalMonthsForYear(y, side) {
  if (side === 'income') {
    return [...(dataCache.incomeByYear[y]?.months || new Array(12).fill(0))];
  }
  return [...(dataCache.expenseByYear[y]?.months || new Array(12).fill(0))];
}

function mergeHistoricalWithForecastMonths(historical, forecast) {
  const hist = historical || new Array(12).fill(0);
  const fcst = forecast || new Array(12).fill(0);
  return hist.map((h, i) => (h !== 0 ? h : (fcst[i] || 0)));
}

function mergeHistoricalWithForecastSourceMaps(histMap, forecastMap, histMonths) {
  const merged = copySourceMap(histMap || {});
  const fcstMap = forecastMap || {};

  for (let m = 0; m < 12; m++) {
    if (histMonths[m] !== 0) continue;

    Object.entries(fcstMap).forEach(([source, months]) => {
      if (!merged[source]) merged[source] = new Array(12).fill(0);
      merged[source][m] = months[m] || 0;
    });
  }
  return merged;
}

async function resolveTrainingYearData(y, pickedKey, plotTypeInternal, trainingModelType, includeCurrentMonth = true) {
  await ensureYearData(y);
  ensureSourceMapsForYear(y);

  const histInc = getHistoricalMonthsForYear(y, 'income');
  const histExp = getHistoricalMonthsForYear(y, 'expense');
  const histIncMap = copySourceMap(dataCache.sourceByIncome[y] || {});
  const histExpMap = copySourceMap(dataCache.sourceByExpense[y] || {});

  let result;
  if (!pickedKey) {
    if (!hasHistoricalDataForYear(y, plotTypeInternal)) {
      throw new Error(`No historical data for ${y}. Select a forecast or reduce years examined.`);
    }
    result = {
      incomeMonths: histInc,
      expenseMonths: histExp,
      incomeSourceMap: histIncMap,
      expenseSourceMap: histExpMap
    };
  } else {
    const entry = predictionCache[pickedKey];
    await refreshForecastEntryIfPartial(entry);

    if (entry.modelType !== trainingModelType) {
      throw new Error(
        `Forecast #${entry.displayId} is ${entry.modelType}-based and cannot be used for ${trainingModelType} training.`
      );
    }

    if (trainingModelType === 'growth') {
      if (!hasRequiredForecastData(entry, plotTypeInternal)) {
        throw new Error(`Forecast #${entry.displayId} is missing data for this plot type.`);
      }
      const fcstInc = getForecastIncomeMonths(entry) || new Array(12).fill(0);
      const fcstExp = (getForecastExpenseMonths(entry) || new Array(12).fill(0)).map(v => Math.abs(v));
      result = {
        incomeMonths: mergeHistoricalWithForecastMonths(histInc, fcstInc),
        expenseMonths: mergeHistoricalWithForecastMonths(histExp, fcstExp),
        incomeSourceMap: histIncMap,
        expenseSourceMap: histExpMap
      };
    } else if (trainingModelType === 'gb') {
      if (!hasRequiredForecastData(entry, plotTypeInternal)) {
        throw new Error(`Forecast #${entry.displayId} is missing data for this plot type.`);
      }
      const fcstInc = getForecastIncomeMonths(entry) || new Array(12).fill(0);
      const fcstExp = (getForecastExpenseMonths(entry) || new Array(12).fill(0)).map(v => Math.abs(v));
      const fcstIncMap = copySourceMap(entry.incomeBySource || {});
      const fcstExpMap = copySourceMap(entry.expenseBySource || {});
      result = {
        incomeMonths: mergeHistoricalWithForecastMonths(histInc, fcstInc),
        expenseMonths: mergeHistoricalWithForecastMonths(histExp, fcstExp),
        incomeSourceMap: Object.keys(fcstIncMap).length
          ? mergeHistoricalWithForecastSourceMaps(histIncMap, fcstIncMap, histInc)
          : histIncMap,
        expenseSourceMap: Object.keys(fcstExpMap).length
          ? mergeHistoricalWithForecastSourceMaps(histExpMap, fcstExpMap, histExp)
          : histExpMap
      };
    } else {
      if (!hasRequiredDriverSourceData(entry, plotTypeInternal)) {
        throw new Error(`Forecast #${entry.displayId} has no driver source data for this plot type.`);
      }

      const fcstIncMap = copySourceMap(entry.incomeBySource || {});
      const fcstExpMap = copySourceMap(entry.expenseBySource || {});

      result = {
        incomeMonths: histInc,
        expenseMonths: histExp,
        incomeSourceMap: mergeHistoricalWithForecastSourceMaps(histIncMap, fcstIncMap, histInc),
        expenseSourceMap: mergeHistoricalWithForecastSourceMaps(histExpMap, fcstExpMap, histExp)
      };
    }
  }

  return applyCurrentMonthTrainingFilter(y, result, includeCurrentMonth);
}

function zeroMonthInArray(months, monthIdx) {
  const out = [...(months || new Array(12).fill(0))];
  out[monthIdx] = 0;
  return out;
}

function zeroMonthInSourceMap(sourceMap, monthIdx) {
  const out = copySourceMap(sourceMap);
  Object.keys(out).forEach(src => {
    out[src] = zeroMonthInArray(out[src], monthIdx);
  });
  return out;
}

// When y is thisYear: Include keeps the current month; Exclude zeroes it so models ignore it.
function applyCurrentMonthTrainingFilter(y, data, includeCurrentMonth) {
  if (y !== thisYear || includeCurrentMonth) return data;
  const idx = getCurrentCalendarMonth() - 1;
  return {
    incomeMonths: zeroMonthInArray(data.incomeMonths, idx),
    expenseMonths: zeroMonthInArray(data.expenseMonths, idx),
    incomeSourceMap: zeroMonthInSourceMap(data.incomeSourceMap, idx),
    expenseSourceMap: zeroMonthInSourceMap(data.expenseSourceMap, idx)
  };
}

function appendForecastTrainingOption($options, name, value, checked, labelText) {
  const safeId = `${name}_${String(value).replace(/[^a-zA-Z0-9]/g, '_')}`;
  const $option = $('<div class="forecast-training-option"></div>');
  const $input = $('<input type="radio" class="forecast-training-pick">')
    .attr('id', safeId)
    .attr('name', name)
    .val(value)
    .prop('checked', checked);
  const $text = $('<label class="forecast-training-option-text"></label>')
    .attr('for', safeId)
    .text(labelText);
  $option.append($input, $text);
  $options.append($option);
}

async function validateTrainingForecastSelection(targetYear, numYears, plotVal, trainingModelType) {
  if (targetYear <= thisYear) return true;

  try {
    await ensureExaminedYearsData(numYears, targetYear);
  } catch (err) {
    forecastError.text(err.message || 'Could not load historical data.');
    return false;
  }

  const plotTypeInternal = mapPlotType(plotVal);
  const examinedYears = getExaminedYearRange(numYears, targetYear);
  const selectedKeys = getSelectedTrainingForecastKeys();
  const yearsWithForecasts = new Set( // examined years that already have saved forecasts
    listForecastsInWindow(targetYear, plotVal, numYears, trainingModelType)
      .map(([, entry]) => entry.targetYear)
  );

  const missingForecastYears = [];
  const noDataYears = [];
  const wrongTypeYears = [];

  selectedKeys.forEach(k => {
    const entry = predictionCache[k];
    if (entry && entry.modelType !== trainingModelType) {
      wrongTypeYears.push(entry.targetYear);
    }
  });

  examinedYears.forEach(y => {
    if (yearsWithForecasts.has(y)) {
      const hasSelection = hasTrainingSelectionForYear(y, selectedKeys);
      if (!hasSelection && !canUseHistoricalTrainingForYear(y, plotTypeInternal)) {
        missingForecastYears.push(y);
      }
    } else if (!hasHistoricalDataForYear(y, plotTypeInternal)) {
      noDataYears.push(y);
    }
  });

  if (wrongTypeYears.length > 0) {
    forecastError.text(
      `Selected forecasts for ${wrongTypeYears.join(', ')} do not match the ${trainingModelType} model.`
    );
    return false;
  }
  if (missingForecastYears.length > 0) {
    forecastError.text(`Select a ${trainingModelType} forecast for: ${missingForecastYears.join(', ')}.`);
    return false;
  }
  if (noDataYears.length > 0) {
    forecastError.text(
      `No data for ${noDataYears.join(', ')}. Select a different forecast or forecast a previous year.`
    );
    return false;
  }
  return true;
}

function updateForecastHint() {
  const $hint = $('#forecastHint');
  if (!$hint.length || !forecastTargetYear || forecastTargetYear === thisYear) {
    if ($hint.length) $hint.text('');
    updateForecastPanelTrainingSummary();
    return;
  }
  const ids = getSelectedTrainingForecastKeys()
    .map(key => predictionCache[key])
    .filter(Boolean)
    .map(entry => assignForecastDisplayId(entry));
  if (ids.length === 0) {
    $hint.text('');
  } else {
    $hint.text(`You will forecast along with data from forecasts ${ids.map(id => `#${id}`).join(', ')}`);
  }
  updateForecastPanelTrainingSummary();
}

function updateForecastPanelTrainingSummary() {
  const $el = $('#forecastPanelTrainingSummary');
  if (!$el.length) return;
  if (!$('#forecastPanel').is(':visible') || !forecastTargetYear || forecastTargetYear === thisYear) {
    $el.text('').hide();
    return;
  }
  const keys = getSelectedTrainingForecastKeys();
  if (keys.length === 0) {
    $el.text('Training forecasts: (none — historical data only)').show();
    return;
  }
  const labels = keys.map(key => {
    const entry = predictionCache[key];
    if (!entry) return null;
    return `#${assignForecastDisplayId(entry)} (${entry.targetYear})`;
  }).filter(Boolean);
  $el.text(`Training forecasts: ${labels.join(', ')}`).show();
}

function renderForecastTrainingPickers(targetYear, plotVal, numYears) {
  const $section = $('#forecastTrainingSection');
  const $list = $('#forecastTrainingList');
  if (!$section.length || targetYear <= thisYear) {
    $section.hide();
    $list.empty();
    updateForecastHint();
    return;
  }

  const trainingModelType = getSelectedForecastModelType();
  const previousSelection = getSelectedTrainingForecastKeys().filter( // preserve picks when re-rendering
    k => predictionCache[k]?.modelType === trainingModelType
  );
  const inWindow = listForecastsInWindow(targetYear, plotVal, numYears, trainingModelType);
  if (inWindow.length === 0) {
    $section.hide();
    $list.empty();
    updateForecastHint();
    return;
  }

  $section.show();
  $list.empty();

  const byYear = {}; // forecasts grouped by target year for radio groups
  inWindow.forEach(([key, entry]) => {
    assignForecastDisplayId(entry);
    if (!byYear[entry.targetYear]) byYear[entry.targetYear] = [];
    byYear[entry.targetYear].push([key, entry]);
  });

  Object.keys(byYear).sort((a, b) => Number(a) - Number(b)).forEach(yearKey => {
    const yearNum = Number(yearKey);
    const plotTypeInternal = mapPlotType(plotVal);
    const group = $(`<div class="forecast-training-year-group" data-year="${yearKey}"></div>`);
    group.append(`<p class="forecast-training-year-label">${yearKey}</p>`);
    const $options = $('<div class="forecast-training-options"></div>');
    const yearForecasts = byYear[yearKey];
    const hasYearSelection = hasTrainingSelectionForYear(yearNum, previousSelection);
    const allowHistoricalNone = canUseHistoricalTrainingForYear(yearNum, plotTypeInternal);

    if (allowHistoricalNone) {
      appendForecastTrainingOption(
        $options,
        `forecastTrainingYear_${yearKey}`,
        TRAINING_HISTORICAL_NONE,
        !hasYearSelection,
        'None (historical data)'
      );
    }

    yearForecasts.forEach(([key, entry]) => {
      const checked = previousSelection.includes(key)
        || (!hasYearSelection && !allowHistoricalNone && activePredictionKey === key)
        || (!hasYearSelection && !allowHistoricalNone && yearForecasts.length === 1);
      appendForecastTrainingOption(
        $options,
        `forecastTrainingYear_${yearKey}`,
        key,
        checked,
        formatPredictionLabel(entry)
      );
    });
    group.append($options);
    $list.append(group);
  });

  updateForecastHint();
}

async function refreshForecastTrainingSection(targetYear, plotVal, numYears) {
  if (targetYear <= thisYear) return;
  await ensureExaminedYearsData(numYears, targetYear);
  renderForecastTrainingPickers(targetYear, plotVal, numYears);
}

async function refreshForecastEntryIfPartial(entry) {
  if (entry.partialYear && entry.targetYear === thisYear) {
    await ensureYearData(thisYear);
    refreshPartialPredictionEntry(entry);
  }
}

async function buildMixedTrainingBase(numYears, targetYear, plotVal, selectedKeys, plotTypeInternal, includeCurrentMonth = true) {
  await ensureExaminedYearsData(numYears, targetYear);
  const baseIncome = [];
  const baseExpenses = [];
  const years = getExaminedYearRange(numYears, targetYear);

  for (const y of years) {
    const pickedKey = selectedKeys.find(k => predictionCache[k]?.targetYear === y); // forecast for this training year
    const data = await resolveTrainingYearData(y, pickedKey, plotTypeInternal, 'growth', includeCurrentMonth);
    baseIncome.push([...data.incomeMonths]);
    baseExpenses.push([...data.expenseMonths]);
  }
  return { baseIncome, baseExpenses };
}

async function buildMixedDriverTrainingData(numYears, targetYear, plotVal, selectedKeys, plotTypeInternal, includeCurrentMonth = true) {
  await ensureExaminedYearsData(numYears, targetYear);
  const incomePerYear = [];
  const expensePerYear = [];
  const years = getExaminedYearRange(numYears, targetYear);

  for (const y of years) {
    const pickedKey = selectedKeys.find(k => predictionCache[k]?.targetYear === y); // forecast for this training year
    const data = await resolveTrainingYearData(y, pickedKey, plotTypeInternal, 'driver', includeCurrentMonth);
    incomePerYear.push(data.incomeSourceMap);
    expensePerYear.push(data.expenseSourceMap);
  }
  return { incomePerYear, expensePerYear };
}

function unpackDriverResult(result, plotTypeInternal) {
  if (plotTypeInternal === 'netincome') {
    return {
      y: result[0],
      expenseBySource: result[1],
      incomeBySource: result[2]
    };
  }
  if (plotTypeInternal === 'income') {
    return { y: result[0], incomeBySource: result[1], expenseBySource: null };
  }
  return { y: result[0], expenseBySource: result[1], incomeBySource: null };
}

function runDriverForecast(years, incomeBase, expenseBase, grMap, plotTypeInternal) {
  const result = new Driver_Based_Growth_Rate_Forecast(
    years, incomeBase, expenseBase, grMap, plotTypeInternal
  ).calculateNet();
  return unpackDriverResult(result, plotTypeInternal);
}

function runSimpleGrowthForecast(trainYears, baseIncome, baseExpenses, grIncome, grExpenses, plotTypeInternal) {
  if (plotTypeInternal === 'netincome') {
    const incomeMonths = new Simple_Growth_Rate_Forecast(
      trainYears, baseIncome, baseExpenses, grIncome, grExpenses, 'income'
    ).calculateNet();
    const expenseMonths = new Simple_Growth_Rate_Forecast(
      trainYears, baseIncome, baseExpenses, grIncome, grExpenses, 'expenses'
    ).calculateNet();
    return {
      y: computePlottedY(incomeMonths, expenseMonths, 'netincome'),
      incomeMonths,
      expenseMonths
    };
  }
  if (plotTypeInternal === 'income') {
    const incomeMonths = new Simple_Growth_Rate_Forecast(
      trainYears, baseIncome, baseExpenses, grIncome, grExpenses, 'income'
    ).calculateNet();
    return { y: incomeMonths, incomeMonths, expenseMonths: null };
  }
  const expenseMonths = new Simple_Growth_Rate_Forecast(
    trainYears, baseIncome, baseExpenses, grIncome, grExpenses, 'expenses'
  ).calculateNet();
  return {
    y: expenseMonths.map(v => -Math.abs(v)),
    incomeMonths: null,
    expenseMonths
  };
}

function buildForecastParams(modelType, numYears, trainingForecastKeys) {
  const yearsLabel = examinedYears(numYears, forecastTargetYear);
  const sortedKeys = [...(trainingForecastKeys || [])].sort(); // stable order for cache key
  // Checked = Exclude → includeCurrentMonth false; unchecked → true
  const includeCurrentMonth = !isCurrentMonthExcluded();
  if (modelType === 'growth') {
    const { grIncome, grExpenses } = collectGrowthRates();
    return {
      numYears,
      examinedYears: yearsLabel,
      grIncome,
      grExpenses,
      trainingForecastKeys: sortedKeys,
      includeCurrentMonth
    };
  }
  if (modelType === 'gb') {
    const tuning = collectGbTuning();
    if (!tuning) return null;
    return {
      numYears,
      examinedYears: yearsLabel,
      trainingForecastKeys: sortedKeys,
      includeCurrentMonth,
      tuningLevel: tuning.tuningLevel,
      nTrials: tuning.nTrials,
      pruner: tuning.pruner,
      timeoutSec: tuning.timeoutSec
    };
  }
  return {
    numYears,
    examinedYears: yearsLabel,
    grMap: collectDriverGrs(),
    trainingForecastKeys: sortedKeys,
    includeCurrentMonth
  };
}

async function hasPriorYearData(priorYear) {
  try {
    await ensureYearData(priorYear);
  } catch {
    return false;
  }
  const inc = dataCache.incomeByYear[priorYear]?.rows?.length > 0;
  const exp = dataCache.expenseByYear[priorYear]?.rows?.length > 0;
  return inc || exp;
}

function setCalculateBtnInactive(inactive) {
  recalculateForecastBtn.prop('disabled', !!inactive);
  recalculateForecastBtn.toggleClass('forecast-btn--inactive', !!inactive);
}

async function updateRemainingMonthsBtn() {
  forecastRemainingBtn.show();
  setCalculateBtnInactive(year < thisYear);
  if (year !== thisYear) {
    forecastRemainingBtn.prop('disabled', true);
    forecastRemainingBtn.addClass('forecast-remaining-btn--inactive');
    return;
  }
  forecastRemainingBtn.prop('disabled', false);
  forecastRemainingBtn.removeClass('forecast-remaining-btn--inactive');
  try {
    await ensureYearData(thisYear);
  } catch {
    forecastRemainingBtn.prop('disabled', true);
    forecastRemainingBtn.addClass('forecast-remaining-btn--inactive');
  }
}

// 0-based index of the first month to forecast.
// includeCurrentMonth true → current month stays actual; false → forecast from current month.
function getFirstForecastMonthIndex(includeCurrentMonth = true) {
  const current1Based = getCurrentCalendarMonth();
  if (includeCurrentMonth) {
    return current1Based;
  }
  return current1Based - 1;
}

// Checkbox checked = Exclude current month from training / partial actuals.
function isCurrentMonthExcluded() {
  return $('#includeCurrentMonth').is(':checked');
}

function mergePartialYear(actualMonths, predictedMonths, firstForecastMonthIndex) {
  return predictedMonths.map((v, i) => (i < firstForecastMonthIndex ? actualMonths[i] : v));
}

function refreshPartialPredictionEntry(entry) {
  if (!entry.partialYear || entry.targetYear !== thisYear) return;
  const includeCurrentMonth = entry.params?.includeCurrentMonth !== false;
  const firstForecastIdx = getFirstForecastMonthIndex(includeCurrentMonth); // 0-based; months before this stay actual
  const actuals = getActualMonthsForPlot(entry.plotType, thisYear);
  entry.y = mergePartialYear(actuals, entry.y, firstForecastIdx);
  if (entry.incomeMonths) {
    const incActual = dataCache.incomeByYear[thisYear]?.months || new Array(12).fill(0);
    entry.incomeMonths = mergePartialYear(incActual, entry.incomeMonths, firstForecastIdx);
  }
  if (entry.expenseMonths) {
    const expActual = dataCache.expenseByYear[thisYear]?.months || new Array(12).fill(0);
    entry.expenseMonths = mergePartialYear(expActual, entry.expenseMonths, firstForecastIdx);
  }
  entry.forecastFromMonth = firstForecastIdx + 1;
  entry.total = computeYearTotal(entry.y);
}

const MIN_PARTIAL_TRAINING_ROWS = 5; // min completed-month rows before partial-year forecast

function countCompletedMonthRows(plotVal, includeCurrentMonth = true) {
  const currentMonth = getCurrentCalendarMonth();
  const maxMonth = includeCurrentMonth ? currentMonth : currentMonth - 1;
  if (maxMonth < 1) return 0;

  let count = 0;
  if (plotVal !== 'Expense') {
    const inc = dataCache.incomeByYear[thisYear];
    if (inc) {
      inc.rows.forEach(row => {
        const m = parseInt(row.DateOfIncome.split('-')[1], 10);
        if (m >= 1 && m <= maxMonth) count++;
      });
    }
  }
  if (plotVal !== 'Income') {
    const exp = dataCache.expenseByYear[thisYear];
    if (exp) {
      exp.rows.forEach(row => {
        const m = parseInt(row.DateOfExpense.split('-')[1], 10);
        if (m >= 1 && m <= maxMonth) count++;
      });
    }
  }
  return count;
}

function canForecastRemainingMonths(includeCurrentMonth = true) {
  return countCompletedMonthRows(type.val(), includeCurrentMonth) >= MIN_PARTIAL_TRAINING_ROWS;
}

function findPartialPredictionKey(plotVal, preferredKey) {
  const entries = listPredictionsForYearPlot(thisYear, plotVal)
    .filter(([, entry]) => entry.partialYear);
  if (entries.length === 0) return null;

  if (preferredKey) {
    const preferred = predictionCache[preferredKey];
    if (preferred?.partialYear && preferred.targetYear === thisYear && preferred.plotType === plotVal) {
      return preferredKey;
    }
  }
  if (activePredictionKey) {
    const active = predictionCache[activePredictionKey];
    if (active?.partialYear && active.targetYear === thisYear && active.plotType === plotVal) {
      return activePredictionKey;
    }
  }
  return entries[0][0];
}

async function applyCachedPartialPredictionIfAny(plotVal) {
  const key = findPartialPredictionKey(plotVal, activePredictionKey);
  if (!key) return false;
  return applyPrediction(key);
}

async function buildGbTrainingOverlays(numYears, targetYear, selectedKeys, plotTypeInternal, includeCurrentMonth) {
  const overlays = {};
  const years = getExaminedYearRange(numYears, targetYear);
  for (const y of years) {
    const pickedKey = selectedKeys.find(k => predictionCache[k]?.targetYear === y);
    if (!pickedKey) continue;
    const data = await resolveTrainingYearData(y, pickedKey, plotTypeInternal, 'gb', includeCurrentMonth);
    overlays[String(y)] = {
      incomeBySource: data.incomeSourceMap,
      expenseBySource: data.expenseSourceMap,
      incomeMonths: data.incomeMonths,
      expenseMonths: data.expenseMonths
    };
  }
  return overlays;
}

async function runForecastModel(modelType, targetYear) {
  const plotVal = type.val();
  const plotTypeInternal = mapPlotType(plotVal);
  const isPartialYear = targetYear === thisYear;
  const includeCurrentMonth = !isCurrentMonthExcluded();

  if (isPartialYear) {
    await ensureYearData(thisYear);
    if (!canForecastRemainingMonths(includeCurrentMonth)) {
      forecastError.text(
        includeCurrentMonth
          ? 'Not enough data in completed months of this year to forecast.'
          : 'Not enough data in completed months before the current month to forecast.'
      );
      return;
    }
    if (!(await hasPriorYearData(thisYear - 1))) {
      forecastError.text('Prior year data is required for Growth, Driver, and Gradient Boosting.');
      return;
    }
  }

  const numYears = collectYearsExamined(modelType);
  if (numYears === null) return;

  if (!isPartialYear && !(await validateTrainingForecastSelection(targetYear, numYears, plotVal, modelType))) {
    return;
  }

  const trainingForecastKeys = isPartialYear ? [] : getSelectedTrainingForecastKeys();
  const params = buildForecastParams(modelType, numYears, trainingForecastKeys);
  if (!params) return;

  const cacheKey = makeCacheKey(targetYear, plotVal, modelType, params);
  const existing = predictionCache[cacheKey];
  if (existing) {
    if (existing.partialYear) {
      await ensureYearData(thisYear);
      refreshPartialPredictionEntry(existing);
    } else if (existing.total === undefined) {
      existing.total = computeYearTotal(existing.y);
    }
    if (!isPartialYear && year === thisYear) {
      year = targetYear;
    }
    closeForecastModal();
    await applyPrediction(cacheKey);
    return;
  }

  closeForecastModal();
  const releaseSpinner = globalSpinner.start(globalSpinner.messages.forecast, { immediate: true });
  let spinnerReleased = false;

  try {
    let y;
    let incomeMonths = null;
    let expenseMonths = null;
    let incomeBySource = null;
    let expenseBySource = null;
    let gbResponse = null;

    if (modelType === 'growth') {
      const { baseIncome, baseExpenses } = await buildMixedTrainingBase(
        numYears, targetYear, plotVal, trainingForecastKeys, plotTypeInternal, params.includeCurrentMonth
      );
      const trainYears = baseIncome.length;
      const growthResult = runSimpleGrowthForecast(
        trainYears, baseIncome, baseExpenses, params.grIncome, params.grExpenses, plotTypeInternal
      );
      y = growthResult.y;
      incomeMonths = growthResult.incomeMonths;
      expenseMonths = growthResult.expenseMonths;

    } else if (modelType === 'driver') {
      const { incomePerYear, expensePerYear } = await buildMixedDriverTrainingData(
        numYears, targetYear, plotVal, trainingForecastKeys, plotTypeInternal, params.includeCurrentMonth
      );
      const trainYears = incomePerYear.length;
      const out = runDriverForecast(
        trainYears, incomePerYear, expensePerYear, params.grMap, plotTypeInternal
      );
      y = plotTypeInternal === 'expenses' ? out.y.map(v => -Math.abs(v)) : out.y;
      incomeBySource = out.incomeBySource;
      expenseBySource = out.expenseBySource;

    } else if (modelType === 'gb') {
      if (window.globalSpinner && typeof window.globalSpinner.showForecastProgress === 'function') {
        window.globalSpinner.showForecastProgress();
      }
      const trainingOverlays = isPartialYear
        ? {}
        : await buildGbTrainingOverlays(
          numYears, targetYear, trainingForecastKeys, plotTypeInternal, params.includeCurrentMonth
        );
      let response;
      try {
        response = await requestGradientBoostForecast({
          targetYear,
          numYears: params.numYears,
          plotType: plotVal,
          includeCurrentMonth: params.includeCurrentMonth,
          trainingOverlays,
          nTrials: params.nTrials,
          pruner: params.pruner,
          timeoutSec: params.timeoutSec
        });
      } catch (err) {
        if (err && (err.name === 'AbortError' || err.gbHandled)) {
          return;
        }
        window.handleFetchError(err, window.API_MESSAGES.connectionError);
        return;
      }
      if (!window.handleAjaxResult(response)) {
        return;
      }
      y = response.months;
      incomeMonths = response.incomeMonths;
      expenseMonths = response.expenseMonths;
      gbResponse = response;

      releaseSpinner();
      spinnerReleased = true;
      const confirmChoice = await confirmGbDiagnoseIfNeeded(response, plotVal);
      if (confirmChoice === 'tune') {
        $('input[name="forecastModel"][value="gb"]').prop('checked', true);
        await openForecastModal(targetYear);
        toggleModelPanels('gb');
        return;
      }

    } else {
      throw new Error('Unknown forecast model.');
    }

    const cacheEntry = {
      cacheKey,
      displayId: nextForecastDisplayId++,
      createdAt: Date.now(),
      y: [...y],
      total: computeYearTotal(y),
      params,
      modelType,
      plotType: plotVal,
      targetYear,
      partialYear: isPartialYear,
      forecastFromMonth: isPartialYear ? getFirstForecastMonthIndex(includeCurrentMonth) + 1 : null,
      trainingForecastKeys,
      incomeMonths: incomeMonths ? [...incomeMonths] : null,
      expenseMonths: expenseMonths ? [...expenseMonths] : null,
      incomeBySource: incomeBySource ? JSON.parse(JSON.stringify(incomeBySource)) : null,
      expenseBySource: expenseBySource ? JSON.parse(JSON.stringify(expenseBySource)) : null,
      diagnose: modelType === 'gb' ? diagnoseForPlot(plotVal, gbResponse) : null,
      incomeDiagnose: modelType === 'gb' ? (gbResponse?.incomeDiagnose || null) : null,
      expenseDiagnose: modelType === 'gb' ? (gbResponse?.expenseDiagnose || null) : null
    };

    if (isPartialYear) {
      await ensureYearData(thisYear);
      refreshPartialPredictionEntry(cacheEntry);
    }

    predictionCache[cacheKey] = cacheEntry;
    if (modelType === 'gb' && plotVal === 'NetIncome') {
      cacheGbNetSiblings(cacheEntry, gbResponse);
    }

    if (!isPartialYear && year === thisYear) {
      year = targetYear;
    }
    await applyPrediction(cacheKey);
  } catch (err) {
    alert(err.message || 'An error occured.');
  } finally {
    if (!spinnerReleased) {
      releaseSpinner();
    }
  }
}

function examinedYears(numYears, targetYear) {
  if (numYears === 0) {
    return String(targetYear);
  }
  const endYear = targetYear - 1;
  const startYear = targetYear - numYears;
  return startYear === endYear ? String(startYear) : `${startYear}-${endYear}`;
}

function forExaminedYears(numYears, targetYear, fn) {
  const endYear = targetYear - 1;
  const startYear = targetYear - numYears;
  for (let y = startYear; y <= endYear; y++) {
    fn(y);
  }
}

function rowsToSourceMap(rows, sourceField, dateField, amountField) {
  const map = {};
  rows.forEach(row => {
    const name = row[sourceField];
    const month = parseInt(row[dateField].split('-')[1], 10) - 1;
    if (!map[name]) map[name] = new Array(12).fill(0);
    map[name][month] += parseFloat(row[amountField]);
  });
  return map;
}

function ensureSourceMapsForYear(y) {
  if (!dataCache.sourceByIncome[y] && dataCache.incomeByYear[y]) {
    dataCache.sourceByIncome[y] = rowsToSourceMap(
      dataCache.incomeByYear[y].rows, 'Source', 'DateOfIncome', 'Income'
    );
  }
  if (!dataCache.sourceByExpense[y] && dataCache.expenseByYear[y]) {
    dataCache.sourceByExpense[y] = rowsToSourceMap(
      dataCache.expenseByYear[y].rows, 'source', 'DateOfExpense', 'expense'
    );
  }
}

function sortSourcesByTotal(sourceMap) {
  return Object.entries(sourceMap).map(([name, months]) => {
    const total = months.reduce((s, v) => s + Math.abs(v), 0);
    return { name, months, total };
  }).sort((a, b) => b.total - a.total);
}

function getCurrentCalendarMonth() {
  return new Date().getMonth() + 1;
}

function getActualMonthsForPlot(plotVal, y) {
  const inc = dataCache.incomeByYear[y];
  const exp = dataCache.expenseByYear[y];
  if (plotVal === 'Income') {
    return inc ? [...inc.months] : new Array(12).fill(0);
  }
  if (plotVal === 'Expense') {
    return exp ? exp.months.map(v => -Math.abs(v)) : new Array(12).fill(0);
  }
  const incomeM = inc ? inc.months : new Array(12).fill(0);
  const expenseM = exp ? exp.months.map(v => -Math.abs(v)) : new Array(12).fill(0);
  return incomeM.map((v, i) => v + expenseM[i]);
}

function mapPlotType(plotVal) {
  if (plotVal === 'Income') return 'income';
  if (plotVal === 'Expense') return 'expenses';
  return 'netincome';
}

function computePlottedY(incomeMonths, expenseMonths, plotTypeInternal) {
  if (plotTypeInternal === 'income') return [...incomeMonths];
  if (plotTypeInternal === 'expenses') {
    return expenseMonths.map(v => -Math.abs(v));
  }
  return incomeMonths.map((v, m) => v - expenseMonths[m]);
}

function sumSourceMapToMonths(sourceMap) {
  const months = new Array(12).fill(0);
  if (!sourceMap) return months;
  Object.values(sourceMap).forEach(sourceMonths => {
    sourceMonths.forEach((v, i) => { months[i] += v; });
  });
  return months;
}

function collectYearsExamined(modelType) {
  const raw = yearsExaminedInput.val();
  const val = parseInt(raw, 10);
  forecastError.text('');
  if (raw === '' || isNaN(val) || val < 1) {
    forecastError.text('Years examined must be >= 1.');
    return null;
  }
  return val;
}

function collectGrowthRates() {
  return {
    grIncome: parseFloat($('#growthRateIncome').val()) || 0,
    grExpenses: parseFloat($('#growthRateExpense').val()) || 0
  };
}

function collectDriverGrs() {
  const grMap = {};
  $('.driver-gr-input').each(function () {
    const source = $(this).data('source');
    const val = $(this).val();
    grMap[source] = val === '' ? 0 : (parseFloat(val) || 0);
  });
  return grMap;
}

// --- Cache ---

let predictionCache = {}; // in-memory forecast cache (lost on page leave)

let nextForecastDisplayId = 1; // monotonic id for forecast labels in this session

function assignForecastDisplayId(entry) {
  if (entry.displayId) return entry.displayId;
  entry.displayId = nextForecastDisplayId++;
  return entry.displayId;
}

async function applyPrediction(cacheKey) {
  const entry = predictionCache[cacheKey];
  if (!entry) return false;
  if (entry.partialYear && entry.targetYear === thisYear) {
    await ensureYearData(thisYear);
    refreshPartialPredictionEntry(entry);
  }
  activePredictionKey = cacheKey;
  lastForecastParams = {
    modelType: entry.modelType,
    params: entry.params,
    plotType: entry.plotType
  };
  year = entry.targetYear;
  isForecastYear = true;
  plotMonths(entry.y, ' (Forecast)', entry.total);
  updateForecastControls(cacheKey);
  updateForecastSavedSummary();
  updateRemainingMonthsBtn();
  next.removeClass('unavailable');
  return true;
}

function updateForecastControls(selectKey) {
  forecastControls.css('display', 'flex');
  let entries = listPredictionsForYearPlot(year, type.val());
  if (year === thisYear) {
    entries = entries.filter(([, entry]) => entry.partialYear);
  }
  predictionSelect.empty();

  if (entries.length === 0) {
    predictionSelect.append($('<option>').val('').text('(No forecasts yet)'));
    predictionSelect.prop('disabled', true);
    activePredictionKey = null;
    updateForecastSavedSummary();
    return;
  }

  predictionSelect.prop('disabled', false);

  // thisYear: always allow clearing back to historical actuals
  if (year === thisYear) {
    predictionSelect.append($('<option>').val('').text('(History)'));
  }

  entries.forEach(([key, entry]) => {
    assignForecastDisplayId(entry);
    predictionSelect.append($('<option>').val(key).text(formatPredictionLabel(entry)));
  });

  const keyToSelect = resolveForecastSelectKey(selectKey, entries);
  if (keyToSelect && predictionCache[keyToSelect]) {
    const inList = entries.some(([k]) => k === keyToSelect);
    if (!inList) {
      const entry = predictionCache[keyToSelect];
      assignForecastDisplayId(entry);
      predictionSelect.append($('<option>').val(keyToSelect).text(formatPredictionLabel(entry)));
    }
  }

  predictionSelect.val(keyToSelect || '');
  if (keyToSelect && predictionCache[keyToSelect]) {
    activePredictionKey = keyToSelect;
    isForecastYear = true;
  } else {
    activePredictionKey = null;
    if (year >= thisYear) isForecastYear = false;
  }
  updateForecastSavedSummary();
}

function resolveForecastSelectKey(selectKey, entries) {
  const plotVal = type.val();
  const isValidKey = key => {
    const entry = predictionCache[key];
    if (!entry || entry.targetYear !== year || entry.plotType !== plotVal) return false;
    if (year === thisYear && !entry.partialYear) return false;
    return true;
  };

  if (selectKey && isValidKey(selectKey)) {
    return selectKey;
  }
  if (isForecastYear && activePredictionKey && isValidKey(activePredictionKey)) {
    return activePredictionKey;
  }
  if (year >= thisYear && !isForecastYear) {
    return '';
  }
  if (entries.length > 0) {
    return entries[0][0];
  }
  return '';
}

function getSelectedForecastEntry() {
  const plotVal = type.val();
  const isValidEntry = entry => entry && entry.targetYear === year && entry.plotType === plotVal;

  const selectKey = predictionSelect.val();
  if (selectKey && predictionCache[selectKey]) {
    const entry = predictionCache[selectKey];
    if (isValidEntry(entry)) return entry;
  }
  if (activePredictionKey && predictionCache[activePredictionKey]) {
    const entry = predictionCache[activePredictionKey];
    if (isValidEntry(entry)) return entry;
  }
  return null;
}

function driverGrMapForSummary(grMap) {
  return Object.entries(grMap || {})
    .filter(([, q]) => q !== '' && q !== null && q !== undefined && !isNaN(parseFloat(q)))
    .filter(([, q]) => parseFloat(q) !== 0)
    .sort((a, b) => a[0].localeCompare(b[0]));
}

function formatTrainingForecastsSummaryHtml(entry) {
  if (entry.partialYear) return '';
  const keys = entry.trainingForecastKeys?.length
    ? entry.trainingForecastKeys
    : (entry.params?.trainingForecastKeys || []);
  if (!keys.length) {
    return '<p class="forecast-summary-title">Training forecasts used</p><div class="driver-gr-row"><span class="driver-gr-source">(none)</span></div>';
  }
  const rows = keys.map((key, i) => {
    const child = predictionCache[key];
    if (!child) return null;
    const id = assignForecastDisplayId(child);
    const label = `#${id} — ${
      child.modelType === 'growth' ? 'Growth Rate'
        : child.modelType === 'gb' ? 'Gradient Boosting'
          : 'Driver-based'
    } ${child.targetYear}`
      + (child.partialYear ? ' (remaining months)' : '');
    return `<div class="driver-gr-row"><span class="driver-gr-source">${label}</span><span class="driver-gr-value">€${formatEuro(predictionEntryTotal(child))}</span></div>`;
  }).filter(Boolean).join('');
  return `<p class="forecast-summary-title">Training forecasts used</p>${rows || '<div class="driver-gr-row"><span class="driver-gr-source">(none)</span></div>'}`;
}

function renderForecastSavedSummary($el, entry) {
  const parts = [];

  if (entry.modelType === 'growth') {
    const plotVal = entry.plotType;
    const rows = [];
    if (plotVal !== 'Expense') {
      rows.push(`<div class="driver-gr-row"><span class="driver-gr-source">Income growth rate</span><span class="driver-gr-value">${entry.params?.grIncome ?? 0}%</span></div>`);
    }
    if (plotVal !== 'Income') {
      rows.push(`<div class="driver-gr-row"><span class="driver-gr-source">Expense growth rate</span><span class="driver-gr-value">${entry.params?.grExpenses ?? 0}%</span></div>`);
    }
    parts.push(`<p class="forecast-summary-title">Growth rates</p>${rows.join('')}`);
  } else if (entry.modelType === 'driver') {
    const plotVal = entry.plotType;
    const items = driverGrMapForSummary(entry.params?.grMap || {});
    const incomeSources = new Set(Object.keys(entry.incomeBySource || {}));
    const expenseSources = new Set(Object.keys(entry.expenseBySource || {}));
    const noneRow = '<div class="driver-gr-row"><span class="driver-gr-source">(none)</span></div>';
    const rowsHtml = (pairs) => {
      if (!pairs.length) {
        return noneRow;
      }
      return pairs.map(([name, q]) =>
        `<div class="driver-gr-row"><span class="driver-gr-source">${name}</span><span class="driver-gr-value">${q}%</span></div>`
      ).join('');
    };

    if (plotVal !== 'Expense') {
      const incomeGrs = items.filter(([source]) =>
        incomeSources.has(source) || (plotVal === 'Income' && !expenseSources.has(source))
      );
      parts.push(`<p class="forecast-summary-title">Income growth rates per source</p>${rowsHtml(incomeGrs)}`);
    }
    if (plotVal !== 'Income') {
      const expenseGrs = items.filter(([source]) =>
        expenseSources.has(source) || (plotVal === 'Expense' && !incomeSources.has(source))
      );
      parts.push(`<p class="forecast-summary-title">Expense growth rates per source</p>${rowsHtml(expenseGrs)}`);
    }
  }

  const trainingHtml = formatTrainingForecastsSummaryHtml(entry);
  if (trainingHtml) parts.push(trainingHtml);

  if (parts.length === 0) {
    $el.empty().hide();
    return;
  }
  $el.html(parts.join('')).show();
}

function updateForecastSavedSummary() {
  const $el = $('#forecastSavedSummary');
  if (!$el.length) return;
  const entry = getSelectedForecastEntry();
  if (!entry || (entry.modelType !== 'growth' && entry.modelType !== 'driver' && entry.modelType !== 'gb')) {
    $el.empty().hide();
    return;
  }
  renderForecastSavedSummary($el, entry);
}

function getCachedPrediction(targetYear, plotType, modelType, params) {
  if (!modelType || !params) return null;
  const key = makeCacheKey(targetYear, plotType, modelType, params);
  return predictionCache[key] || null;
}

function listPredictionsForYearPlot(targetYear, plotVal) {
  return Object.entries(predictionCache)
    .filter(([, entry]) => entry.targetYear === targetYear && entry.plotType === plotVal)
    .sort((a, b) => {
      const byId = (b[1].displayId || 0) - (a[1].displayId || 0);
      if (byId !== 0) return byId;
      return (b[1].createdAt || 0) - (a[1].createdAt || 0);
    });
}

async function goToNextYearForecast() {
  const targetYear = year + 1;
  const plotVal = type.val();
  const entries = listPredictionsForYearPlot(targetYear, plotVal);
  if (entries.length > 0) {
    year = targetYear;
    const key = activePredictionKey && predictionCache[activePredictionKey]
      && predictionCache[activePredictionKey].targetYear === targetYear
      && predictionCache[activePredictionKey].plotType === plotVal
      ? activePredictionKey
      : entries[0][0];
    await applyPrediction(key);
    return;
  }
  openForecastModal(targetYear);
}

const LEAVE_PAGE_MESSAGE = 'All saved forecasts will be lost if you leave or refresh this page.\n\nUse "Download" to save a forecast (ZIP with graph and info) if you need it.';

let leaveWarningEnabled = true; // beforeunload guard; disabled after confirmed leave

function hasCachedForecasts() {
  return Object.keys(predictionCache).length > 0;
}

function confirmLeavePage() {
  return window.confirm(LEAVE_PAGE_MESSAGE);
}

function leaveWithoutWarning(action) {
  leaveWarningEnabled = false;
  abortGbForecastRequest();
  action();
}

function isLeavingPage(href) {
  if (!href || href.startsWith('#') || href.startsWith('javascript:')) return false;
  try {
    const target = new URL(href, window.location.href);
    const current = window.location;
    return target.pathname !== current.pathname || target.search !== current.search;
  } catch {
    return true;
  }
}

function initLeavePageWarning() {
  window.addEventListener('pagehide', abortGbForecastRequest);

  window.addEventListener('beforeunload', (event) => {
    if (!leaveWarningEnabled || !hasCachedForecasts()) return;
    event.preventDefault();
    event.returnValue = '';
  });

  document.addEventListener('click', (event) => {
    if (!leaveWarningEnabled || !hasCachedForecasts()) return;
    const link = event.target.closest('a[href]');
    if (!link || link.target === '_blank') return;
    const href = link.getAttribute('href') || '';
    if (link.hasAttribute('download') || href.startsWith('blob:')) return;
    if (!isLeavingPage(href)) return;
    if (!confirmLeavePage()) {
      event.preventDefault();
      event.stopImmediatePropagation();
    } else {
      leaveWarningEnabled = false;
      abortGbForecastRequest();
    }
  }, true);

  window.addEventListener('keydown', (event) => {
    if (!leaveWarningEnabled || !hasCachedForecasts()) return;
    const isReloadKey = event.key === 'F5'
      || (event.key.toLowerCase() === 'r' && (event.ctrlKey || event.metaKey));
    if (!isReloadKey) return;
    event.preventDefault();
    if (confirmLeavePage()) {
      leaveWithoutWarning(() => location.reload());
    }
  });
}

function makeParamsFingerprint(modelType, params) {
  if (modelType === 'growth') {
    return `g:${params.grIncome}:${params.grExpenses}`;
  }
  if (modelType === 'gb') {
    const cap = params.timeoutSec == null ? 'nocap' : String(params.timeoutSec);
    return `gb:${params.examinedYears}:${params.nTrials}:${params.pruner}:${cap}`;
  }
  const keys = Object.keys(params.grMap || {}).sort();
  const parts = keys.map(k => `${k}=${params.grMap[k]}`); // sorted source=gr pairs for cache key
  return `d:${parts.join(',')}`;
}

function makeCacheKey(targetYear, plotType, modelType, params) {
  const partial = targetYear === thisYear ? '|partial' : ''; // partial-year forecast suffix
  const includePart = params.includeCurrentMonth === false ? '|excur' : '';
  const trainPart = params.trainingForecastKeys?.length // selected training forecasts in cache key
    ? `|train:${params.trainingForecastKeys.join(',')}`
    : '';
  return `${targetYear}|${plotType}|${modelType}|${params.examinedYears}|${makeParamsFingerprint(modelType, params)}${partial}${includePart}${trainPart}`;
}

function predictionEntryTotal(entry) {
  if (entry.total !== undefined) return entry.total;
  return computeYearTotal(entry.y);
}

function formatPredictionLabel(entry) {
  assignForecastDisplayId(entry);
  const examined = entry.params.examinedYears;
  const idPrefix = `#${entry.displayId} — `;
  let base;
  if (entry.modelType === 'growth') {
    base = `${idPrefix}Growth: ${entry.params.grIncome}% / ${entry.params.grExpenses}% (${examined})`;
  } else if (entry.modelType === 'gb') {
    const level = GB_TUNING_LABELS[entry.params.tuningLevel] || 'Fast';
    const pruner = GB_PRUNER_LABELS[entry.params.pruner] || 'None';
    const timeLabel = formatGbTimeoutLabel(entry.params.timeoutSec);
    base = `${idPrefix}Gradient Boosting — ${level} (${entry.params.nTrials} Optuna trials), ${pruner}, ${timeLabel} (${examined})`;
    base += formatGbDiagnoseSuffix(entry);
  } else {
    base = `${idPrefix}Driver-based (${examined})`;
  }
  if (entry.partialYear) {
    base += ' — remaining months';
  }
  if (entry.params?.includeCurrentMonth === false) {
    base += ', excl. current month';
  } else if (entry.params?.includeCurrentMonth) {
    base += ', incl. current month';
  }
  return `${base} — €${formatEuro(predictionEntryTotal(entry))}`;
}

// --- Modal management ---

async function populateDriverLists(numYears, targetYear) {
  const plotVal = type.val();
  driverSourceState.income.q = ($('#driverIncomeSearch').val() || '').trim();
  driverSourceState.expense.q = ($('#driverExpenseSearch').val() || '').trim();
  if (plotVal !== 'Expense') {
    await loadDriverSources('income', { reset: true, numYears, targetYear });
  } else {
    $('#driverIncomeList').empty();
    $('#driverIncomeShowMore').hide();
  }
  if (plotVal !== 'Income') {
    await loadDriverSources('expense', { reset: true, numYears, targetYear });
  } else {
    $('#driverExpenseList').empty();
    $('#driverExpenseShowMore').hide();
  }
}

async function openForecastModal(targetYear) {
  const isPartial = targetYear === thisYear;
  forecastTargetYear = targetYear;
  const selected = $('input[name="forecastModel"]:checked').val() || 'growth';

  if (isPartial) {
    forecastModalTitle.text(`Forecast remaining months of ${targetYear}`);
  } else {
    forecastModalTitle.text(`Forecast for ${targetYear}`);
  }
  yearsExaminedInput.val(yearsExaminedInput.val() || 1);

  $('#includeCurrentMonthLabel').show();
  $('#includeCurrentMonth').prop('checked', false);

  forecastError.text('');
  updateYearsExaminedConstraints();

  const numYears = parseInt(yearsExaminedInput.val(), 10) || 1;
  if (!isPartial) {
    await refreshForecastTrainingSection(targetYear, type.val(), numYears);
  } else {
    $('#forecastTrainingSection').hide();
    $('#forecastTrainingList').empty();
    $('#forecastHint').text('');
  }

  toggleModelPanels(selected);

  if (selected === 'driver') {
    $('#driverIncomeSearch, #driverExpenseSearch').val('');
    populateDriverLists(numYears, targetYear);
  }

  forecastModal.addClass('forecast-modal-open');
}

function closeForecastModal() {
  forecastModal.removeClass('forecast-modal-open');
  forecastTargetYear = null;
  yearsExaminedInput.prop('disabled', false);
  $('#yearsExaminedHint').text('');
  $('#forecastHint').text('');
  $('#forecastTrainingSection').hide();
  $('#forecastTrainingList').empty();
  $('#includeCurrentMonthLabel').hide();
  $('#includeCurrentMonth').prop('checked', false);
  $('label[for="yearsExamined"]').text('Previous years to examine:');
}

function initForecastModalListeners() {
  forecastModalClose.on('click', closeForecastModal);
  forecastCancel.on('click', closeForecastModal);

  $('input[name="forecastModel"]').on('change', function () {
    const val = $(this).val();
    updateYearsExaminedConstraints();
    toggleModelPanels(val);
    if (!forecastTargetYear) return;
    const numYears = parseInt(yearsExaminedInput.val(), 10) || 1;
    if (forecastTargetYear > thisYear) {
      void refreshForecastTrainingSection(forecastTargetYear, type.val(), numYears);
    }
    if (val === 'driver') {
      populateDriverLists(numYears, forecastTargetYear);
    }
  });

  yearsExaminedInput.on('input', function () {
    forecastError.text('');
    updateYearsExaminedPreview();
    if (!forecastTargetYear) return;
    const numYears = parseInt(yearsExaminedInput.val(), 10);
    if (forecastTargetYear > thisYear && numYears >= 1) {
      void refreshForecastTrainingSection(forecastTargetYear, type.val(), numYears);
    }
    if ($('input[name="forecastModel"]:checked').val() === 'driver' && numYears >= 1) {
      populateDriverLists(numYears, forecastTargetYear);
    }
  });

  yearsExaminedInput.on('change', function () {
    const raw = yearsExaminedInput.val();
    const val = parseInt(raw, 10);
    if (raw === '' || Number.isNaN(val) || val < 1) {
      yearsExaminedInput.val(1);
    }
    updateYearsExaminedConstraints();
  });

  $('#forecastTrainingList').on('change', '.forecast-training-pick', function () {
    forecastError.text('');
    updateForecastHint();
    if ($('input[name="forecastModel"]:checked').val() === 'driver' && forecastTargetYear) {
      const numYears = parseInt(yearsExaminedInput.val(), 10) || 1;
      populateDriverLists(numYears, forecastTargetYear);
    }
  });

  $('#includeCurrentMonth').on('change', function () {
    if (!forecastTargetYear || forecastTargetYear <= thisYear) return;
    if ($('input[name="forecastModel"]:checked').val() !== 'driver') return;
    const numYears = parseInt(yearsExaminedInput.val(), 10) || 1;
    populateDriverLists(numYears, forecastTargetYear);
  });

  forecastCalculate.on('click', function () {
    const modelType = $('input[name="forecastModel"]:checked').val();
    if (!modelType) return;
    if (!forecastTargetYear) return;
    runForecastModel(modelType, forecastTargetYear);
  });

  $('input[name="gbTimeCap"]').on('change', function () {
    forecastError.text('');
    updateGbTimeCapFields();
  });

  forecastModal.on('click', function (e) {
    if (e.target === forecastModal[0]) closeForecastModal();
  });

  predictionSelect.on('change', function () {
    const key = $(this).val();
    if (!key) {
      if (year === thisYear) {
        void showHistoricalView();
      }
      return;
    }
    applyPrediction(key);
  });

  recalculateForecastBtn.on('click', async function () {
    if (recalculateForecastBtn.prop('disabled') || year < thisYear) {
      return;
    }
    if (year === thisYear) {
      await goToNextYearForecast();
      return;
    }
    if (year > thisYear) {
      openForecastModal(year);
    }
  });

  forecastRemainingBtn.on('click', function () {
    openForecastModal(thisYear);
  });

  $('#driverIncomeSearch').on('input', function () {
    scheduleDriverSourceSearch('income', $(this).val());
  });
  $('#driverExpenseSearch').on('input', function () {
    scheduleDriverSourceSearch('expense', $(this).val());
  });
  $('#driverIncomeShowMore').on('click', function () {
    showMoreDriverSources('income');
  });
  $('#driverExpenseShowMore').on('click', function () {
    showMoreDriverSources('expense');
  });
}

function updateYearsExaminedPreview() {
  const hintEl = $('#yearsExaminedHint');
  if (!forecastTargetYear) {
    hintEl.text('');
    return;
  }
  const numYears = parseInt(yearsExaminedInput.val(), 10) || 1;
  hintEl.text('Examined period: ' + formatExaminedYearsPreview(numYears, forecastTargetYear));
}

function updateYearsExaminedConstraints() {
  yearsExaminedInput.attr('min', 1);
  yearsExaminedInput.prop('disabled', false);
  $('label[for="yearsExamined"]').text('Previous years to examine:');
  updateYearsExaminedPreview();
}

function updateGbTimeCapFields() {
  const on = $('input[name="gbTimeCap"]:checked').val() === 'on';
  $('#gbTimeCapFields').css('display', on ? 'flex' : 'none');
}

function toggleModelPanels(selectedModel) {
  const plotVal = type.val();
  const isGrowth = selectedModel === 'growth';
  const isDriver = selectedModel === 'driver';
  const isGb = selectedModel === 'gb';

  if (isGrowth) {
    $('#forecastPanel').show();
  } else {
    $('#forecastPanel').hide();
  }
  if (isDriver) {
    $('#driverPanel').show();
  } else {
    $('#driverPanel').hide();
  }
  if (isGb) {
    $('#gbPanel').show();
    updateGbTimeCapFields();
  } else {
    $('#gbPanel').hide();
  }

  $('label[for="growthRateIncome"]').toggle(isGrowth && plotVal !== 'Expense');
  $('#growthRateIncome').toggle(isGrowth && plotVal !== 'Expense');
  $('label[for="growthRateExpense"]').toggle(isGrowth && plotVal !== 'Income');
  $('#growthRateExpense').toggle(isGrowth && plotVal !== 'Income');
  $('#driverIncomeSection').toggle(isDriver && plotVal !== 'Expense');
  $('#driverExpenseSection').toggle(isDriver && plotVal !== 'Income');
  updateForecastPanelTrainingSummary();
}

function driverSourceListId(side) {
  return side === 'income' ? 'driverIncomeList' : 'driverExpenseList';
}

function driverSourceShowMoreId(side) {
  return side === 'income' ? 'driverIncomeShowMore' : 'driverExpenseShowMore';
}

function escapeDriverSourceName(name) {
  return String(name).replace(/&/g, '&amp;').replace(/"/g, '&quot;').replace(/</g, '&lt;');
}

function appendDriverSourceRows(side, sources) {
  const $list = $(`#${driverSourceListId(side)}`);
  $list.find('.driver-empty').remove();
  sources.forEach((src) => {
    const safe = escapeDriverSourceName(src.name);
    const row = $(`
      <div class="driver-source-row driver-hidden" data-source-name="${safe}">
        <span class="driver-source-name" title="${safe}">${safe}</span>
        <input type="number" class="driver-gr-input driver-gr-default" data-source="${safe}"
          placeholder="Default / 0%" step="0.01">
      </div>
    `);
    $list.append(row);
  });
  $list.off('input', '.driver-gr-input').on('input', '.driver-gr-input', function () {
    const v = $(this).val();
    if (v === '' || parseFloat(v) === 0) {
      $(this).addClass('driver-gr-default');
    } else {
      $(this).removeClass('driver-gr-default');
    }
  });
}

function hiddenDriverSourceRows(side) {
  return $(`#${driverSourceListId(side)}`).find('.driver-source-row.driver-hidden');
}

function revealDriverSourceChunk(side) {
  hiddenDriverSourceRows(side).slice(0, DRIVER_SOURCE_VISIBLE_SIZE).removeClass('driver-hidden');
  updateDriverShowMoreButton(side);
}

function updateDriverShowMoreButton(side) {
  const $btn = $(`#${driverSourceShowMoreId(side)}`);
  if (hiddenDriverSourceRows(side).length > 0 || driverSourceState[side].hasMore) {
    $btn.show();
  } else {
    $btn.hide();
  }
}

function showMoreDriverSources(side) {
  if (hiddenDriverSourceRows(side).length > 0) {
    revealDriverSourceChunk(side);
    return;
  }
  if (!driverSourceState[side].hasMore || !forecastTargetYear) {
    updateDriverShowMoreButton(side);
    return;
  }
  const numYears = parseInt(yearsExaminedInput.val(), 10) || 1;
  loadDriverSources(side, { reset: false, numYears, targetYear: forecastTargetYear });
}

async function loadDriverSources(side, { reset, numYears, targetYear }) {
  if (!targetYear) {
    return;
  }
  const state = driverSourceState[side];
  if (state.loading && !reset) {
    return;
  }
  const $list = $(`#${driverSourceListId(side)}`);
  if (reset) {
    $list.empty();
    state.offset = 0;
    state.hasMore = false;
  }
  const requestId = ++state.requestId;
  state.loading = true;
  const offset = state.offset;
  const params = new URLSearchParams({
    side,
    targetYear: String(targetYear),
    numYears: String(numYears),
    offset: String(offset),
    limit: String(DRIVER_SOURCE_PAGE_SIZE)
  });
  if (state.q) {
    params.set('q', state.q);
  }

  try {
    const response = await fetch('/php/transactions/getDriverSources.php?' + params.toString(), {
      credentials: 'same-origin',
      headers: { Accept: 'application/json' }
    });
    const results = await window.parseFetchJsonResponse(response);
    if (requestId !== state.requestId) {
      return;
    }
    if (!results || results.denied || !results.success) {
      return;
    }
    const rows = results.data || [];
    if (reset && rows.length === 0) {
      $list.append('<p class="driver-empty">No sources for examined years.</p>');
    } else {
      appendDriverSourceRows(side, rows);
      revealDriverSourceChunk(side);
    }
    state.offset = offset + rows.length;
    state.hasMore = !!results.hasMore;
    updateDriverShowMoreButton(side);
  } catch (err) {
    if (requestId !== state.requestId) {
      return;
    }
    window.handleFetchError(err);
  } finally {
    if (requestId === state.requestId) {
      state.loading = false;
    }
  }
}

function scheduleDriverSourceSearch(side, searchQuery) {
  driverSourceState[side].q = (searchQuery || '').trim();
  if (driverSourceSearchTimers[side]) {
    clearTimeout(driverSourceSearchTimers[side]);
  }
  driverSourceSearchTimers[side] = setTimeout(() => {
    driverSourceSearchTimers[side] = null;
    if (!forecastTargetYear) {
      return;
    }
    const numYears = parseInt(yearsExaminedInput.val(), 10) || 1;
    loadDriverSources(side, { reset: true, numYears, targetYear: forecastTargetYear });
  }, 300);
}
