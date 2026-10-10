// graphDisplay.js — plot rendering, totals, download, navigation

// --- Initialization ---

const yearTitle = $('#yearTitle');
const prev = $('#prev');
const next = $('#next');
const thisYearBtn = $('#thisYearBtn');
const plot = $("#MonthlyPlot");
const type = $("#typeOfPlot");

const forecastModal = $('#forecastModal');
const forecastModalTitle = $('#forecastModalTitle');
const forecastModalClose = $('#forecastModalClose');
const forecastCancel = $('#forecastCancel');
const forecastCalculate = $('#forecastCalculate');
const yearsExaminedInput = $('#yearsExamined');
const yearsExaminedHint = $('#yearsExaminedHint');
const forecastHint = $('#forecastHint');
const forecastTrainingSection = $('#forecastTrainingSection');
const forecastTrainingList = $('#forecastTrainingList');
const forecastControls = $('#forecastControls');
const predictionSelect = $('#predictionSelect');
const recalculateForecastBtn = $('#recalculateForecastBtn');
const plotTotal = $('#plotTotal');
const downloadPlotBtn = $('#downloadPlotBtn');
const forecastRemainingBtn = $('#forecastRemainingBtn');

let thisYear = new Date().getFullYear();
let year = null; // currently displayed year (history or forecast)
let forecastTargetYear = null; // year open in forecast modal
let isForecastYear = false; // true when graph shows a forecast, not actuals
let lastForecastParams = null; // params of active forecast (for recalculate)
let activePredictionKey = null; // cache key of forecast shown on graph

// --- Plotly config ---

const xArray = [
  "January", "February", "March", "April",
  "May", "June", "July", "August",
  "September", "October", "November", "December"
];

const data = [{
  x: xArray,
  y: null,
  textposition: 'outside',
  cliponaxis: false,
  type: "bar",
  orientation: "v",
  marker: { color: "#2563eb" },
  textfont: { size: 11, color: '#333' }
}];

const config = {
  displaylogo: false,
  responsive: true,
  staticPlot: true
};

const layout = {
  xaxis: { title: '<b>Months</b>', font: { size: 14 } },
  yaxis: { title: '<b>(€)</b>', rangemode: 'tozero', automargin: true },
  margin: { t: 22, l: 70, r: 40, b: 80 },
  bargap: 0.2,
  barmode: 'overlay',
  showlegend: false,
  autosize: true,
  height: 500,
  font: { family: 'Arial', size: 12, color: '#444' }
};

const ACTUAL_BAR_COLOR = '#2563eb';
const FORECAST_BAR_COLOR = '#f97316';

function formatBarLabel(value) {
  if (value === null || value === undefined) return '';
  return formatEuro(value);
}

function buildPlotTraces(y, isForecast, entryOverride) {
  const barCommon = {
    type: 'bar',
    orientation: 'v',
    textposition: 'outside',
    cliponaxis: false,
    textfont: { size: 11, color: '#333' },
    hovertemplate: '%{x}: €%{y:.2f}<extra></extra>'
  };

  if (!isForecast) {
    return [{
      ...barCommon,
      x: xArray,
      y,
      name: 'Actual',
      marker: { color: ACTUAL_BAR_COLOR },
      text: y.map(formatBarLabel)
    }];
  }

  const entry = entryOverride !== undefined
    ? entryOverride
    : (activePredictionKey ? predictionCache[activePredictionKey] : null);
  const forecastFrom = entry?.forecastFromMonth; // 1-based month where forecast bars begin

  if (forecastFrom != null && forecastFrom > 1) {
    const split = forecastFrom - 1; // 0-based index where forecast bars start
    let actualMonths = y;
    if (entry?.partialYear && entry.targetYear === thisYear) {
      const hasData = dataCache.incomeByYear[thisYear] || dataCache.expenseByYear[thisYear];
      if (hasData) {
        actualMonths = getActualMonthsForPlot(entry.plotType, thisYear);
      }
    }
    const actualY = actualMonths.map((v, i) => (i < split ? v : null));
    const forecastY = y.map((v, i) => (i >= split ? v : null));
    return [
      {
        ...barCommon,
        x: xArray,
        y: actualY,
        name: 'Actual',
        marker: { color: ACTUAL_BAR_COLOR },
        text: actualY.map(formatBarLabel)
      },
      {
        ...barCommon,
        x: xArray,
        y: forecastY,
        name: 'Forecast',
        marker: { color: FORECAST_BAR_COLOR },
        text: forecastY.map(formatBarLabel)
      }
    ];
  }

  return [{
    ...barCommon,
    x: xArray,
    y,
    name: 'Forecast',
    marker: { color: FORECAST_BAR_COLOR },
    text: y.map(formatBarLabel)
  }];
}

// --- Plot rendering ---

function plotMonths(yArray, labelSuffix, cachedTotal) {
  const plotVal = type.val();
  let y = [...yArray];
  if (plotVal === 'Expense') {
    y = y.map(v => (v <= 0 ? v : -Math.abs(v)));
  }
  const isForecast = Boolean(labelSuffix && labelSuffix.includes('Forecast'));
  const total = cachedTotal !== undefined ? cachedTotal : computeYearTotal(y);

  if (!isForecast) {
    dataCache.plotTotals[plotDisplayCacheKey(plotVal, false)] = total;
  }

  const forecastEntry = isForecast && activePredictionKey
    ? predictionCache[activePredictionKey]
    : null;
  const traces = buildPlotTraces(y, isForecast, forecastEntry);
  const plotLayout = {
    ...layout,
    showlegend: isForecast,
    margin: { ...layout.margin, t: isForecast ? 48 : layout.margin.t },
    legend: isForecast
      ? { orientation: 'h', y: 1.14, x: 0.5, xanchor: 'center', font: { size: 11 } }
      : undefined
  };

  yearTitle.text(year + (labelSuffix || ''));
  updatePlotTotalHeader(total, plotVal);
  Plotly.newPlot("MonthlyPlot", traces, plotLayout, config);
  showControls();
}

function plotHistoricalYear(y, plotVal) {
  const inc = dataCache.incomeByYear[y];
  const exp = dataCache.expenseByYear[y];
  const suffix = yearHasData(y, plotVal) ? '' : ' — no transactions';

  if (plotVal === 'Income') {
    plotMonths(inc ? [...inc.months] : new Array(12).fill(0), suffix);
  } else if (plotVal === 'Expense') {
    const months = exp ? exp.months.map(v => -Math.abs(v)) : new Array(12).fill(0);
    plotMonths(months, suffix);
  } else {
    const incomeM = inc ? inc.months : new Array(12).fill(0);
    const expenseM = exp ? exp.months.map(v => -Math.abs(v)) : new Array(12).fill(0);
    const net = incomeM.map((v, i) => v + expenseM[i]);
    plotMonths(net, suffix);
  }
}

// --- Download ---

function downloadZip(filename, blob) {
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  a.remove();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}

function formatDownloadFileTitle(plotVal, yearVal, total, modelType) {
  let category = 'Historic_Data';
  if (modelType === 'growth') category = 'Growth_Rate';
  else if (modelType === 'driver') category = 'Driver_based';
  else if (modelType === 'gb') category = 'Gradient_Boosting';
  if (modelType === 'growth' || modelType === 'driver' || modelType === 'gb') {
    return `${plotVal}_${category}_${yearVal}`;
  }
  return `${plotVal}_${category}_${yearVal}_total_value_Is_${Math.round(total)}`;
}

function getTrainingForecastKeys(entry) {
  if (entry.trainingForecastKeys?.length) return entry.trainingForecastKeys;
  if (entry.params?.trainingForecastKeys?.length) return entry.params.trainingForecastKeys;
  return [];
}

function forecastCacheKey(entry) {
  return entry.cacheKey
    || `${entry.targetYear}|${entry.plotType}|${entry.modelType}|${entry.displayId}`;
}

function getRootScopedForecastId(idMap, entry) {
  const key = forecastCacheKey(entry);
  if (!idMap.has(key)) {
    idMap.set(key, idMap.size + 1); // stable 1-based id per unique forecast in zip
  }
  return idMap.get(key);
}

function buildForecastInfoText(entry, trainingList) {
  const total = predictionEntryTotal(entry);
  const modelLabel = entry.modelType === 'growth'
    ? 'Growth Rate'
    : entry.modelType === 'gb'
      ? 'Gradient Boosting'
      : 'Driver-based';
  const lines = [
    `Graph: ${entry.plotType}`,
    `Year: ${entry.targetYear}`,
    `Model: ${modelLabel}`,
    `Total: €${formatEuro(total)}`,
    `Examined years: ${entry.params?.examinedYears ?? ''}`
  ];

  if (entry.modelType === 'gb') {
    const level = (typeof GB_TUNING_LABELS !== 'undefined' && GB_TUNING_LABELS[entry.params?.tuningLevel]) || 'Fast';
    const pruner = (typeof GB_PRUNER_LABELS !== 'undefined' && GB_PRUNER_LABELS[entry.params?.pruner]) || 'None';
    lines.push(`Optuna trials: ${entry.params?.nTrials ?? ''} (${level})`);
    lines.push(`Optuna pruner: ${pruner}`);
    lines.push(`Time cap: ${typeof formatGbTimeoutLabel === 'function' ? formatGbTimeoutLabel(entry.params?.timeoutSec) : 'no cap'}`);
    if (typeof gbDiagnoseDownloadLines === 'function') {
      gbDiagnoseDownloadLines(entry).forEach((line) => lines.push(line));
    }
  }

  if (entry.partialYear) {
    lines.push('Scope: remaining months');
  }
  if (typeof entry.params?.includeCurrentMonth === 'boolean') {
    lines.push(`Include current month: ${entry.params.includeCurrentMonth ? 'yes' : 'no'}`);
  }

  if (entry.modelType === 'growth') {
    const plotVal = entry.plotType;
    if (plotVal !== 'Expense') {
      lines.push(`Income growth rate: ${entry.params?.grIncome ?? 0}%`);
    }
    if (plotVal !== 'Income') {
      lines.push(`Expense growth rate: ${entry.params?.grExpenses ?? 0}%`);
    }
  } else if (entry.modelType === 'driver') {
    const grMap = entry.params?.grMap || {};
    const incomeSources = new Set(Object.keys(entry.incomeBySource || {}));
    const expenseSources = new Set(Object.keys(entry.expenseBySource || {}));
    const nonZero = Object.entries(grMap)
      .filter(([, gr]) => {
        const n = parseFloat(gr);
        return gr !== '' && gr !== null && gr !== undefined && !isNaN(n) && n !== 0;
      })
      .sort((a, b) => a[0].localeCompare(b[0]));

    const incomeGrs = nonZero.filter(([source]) =>
      incomeSources.has(source) || (entry.plotType === 'Income' && !expenseSources.has(source))
    );
    const expenseGrs = nonZero.filter(([source]) =>
      expenseSources.has(source) || (entry.plotType === 'Expense' && !incomeSources.has(source))
    );

    if (entry.plotType !== 'Expense') {
      lines.push('Income growth rates per source:');
      if (incomeGrs.length === 0) {
        lines.push('(none)');
      } else {
        incomeGrs.forEach(([source, gr]) => {
          lines.push(`${source}: ${gr}%`);
        });
      }
    }

    if (entry.plotType !== 'Income') {
      lines.push('Expense growth rates per source:');
      if (expenseGrs.length === 0) {
        lines.push('(none)');
      } else {
        expenseGrs.forEach(([source, gr]) => {
          lines.push(`${source}: ${gr}%`);
        });
      }
    }
  }

  if (!entry.partialYear) {
    lines.push('Training forecasts used:');
    if (!trainingList || trainingList.length === 0) {
      lines.push('(none)');
    } else {
      trainingList.forEach(item => {
        lines.push(
          `${item.index}: ${item.plotType} ${item.modelLabel} ${item.year} — total €${formatEuro(item.total)}`
        );
      });
    }
  }

  return lines.join('\n') + '\n';
}

function buildTrainingInfo(trainingKeys, idMap) {
  return trainingKeys.map((key) => {
    const child = predictionCache[key];
    return {
      index: getRootScopedForecastId(idMap, child),
      plotType: child.plotType,
      modelLabel: child.modelType === 'growth'
        ? 'Growth Rate'
        : child.modelType === 'gb'
          ? 'Gradient Boosting'
          : 'Driver-based',
      year: child.targetYear,
      total: predictionEntryTotal(child)
    };
  });
}

async function createGraphFromCachedPredictions(entry) {
  const plotVal = entry.plotType;
  let y = [...entry.y];
  if (plotVal === 'Expense') {
    y = y.map(v => (v <= 0 ? v : -Math.abs(v)));
  }

  const traces = buildPlotTraces(y, true, entry);
  const plotLayout = {
    ...layout,
    showlegend: true,
    margin: { ...layout.margin, t: 48 },
    legend: { orientation: 'h', y: 1.14, x: 0.5, xanchor: 'center', font: { size: 11 } }
  };

  const el = document.createElement('div');
  el.style.cssText = 'position:absolute;left:-9999px;top:-9999px;width:1000px;height:500px;';
  document.body.appendChild(el);
  try {
    await Plotly.newPlot(el, traces, plotLayout, config);
    const dataUrl = await Plotly.toImage(el, { format: 'png', width: 1000, height: 500 });
    return await (await fetch(dataUrl)).blob();
  } finally {
    Plotly.purge(el);
    el.remove();
  }
}

async function addForecastToZip(zip, folderPath, entry, pathKeys, idMap, pngBlob) {
  const cacheKey = forecastCacheKey(entry);
  if (pathKeys.has(cacheKey)) return; // skip forecasts already written to zip
  const nextPathKeys = new Set(pathKeys); // copy so recursive zip adds don't mutate caller set
  nextPathKeys.add(cacheKey);

  const total = predictionEntryTotal(entry);
  const baseName = formatDownloadFileTitle(entry.plotType, entry.targetYear, total, entry.modelType);
  const prefix = folderPath ? `${folderPath}/` : '';

  const blob = pngBlob || await createGraphFromCachedPredictions(entry);
  const trainingKeys = getTrainingForecastKeys(entry);
  const trainingList = buildTrainingInfo(trainingKeys, idMap);

  zip.file(`${prefix}${baseName}.png`, blob);
  zip.file(`${prefix}${baseName}.txt`, buildForecastInfoText(entry, trainingList));

  if (trainingKeys.length === 0) return;

  for (let i = 0; i < trainingKeys.length; i++) {
    const child = predictionCache[trainingKeys[i]];
    if (!child) continue;
    const childBase = formatDownloadFileTitle(
      child.plotType, child.targetYear, predictionEntryTotal(child), child.modelType
    );
    const childId = getRootScopedForecastId(idMap, child);
    const childFolder = `${prefix}training_forecasts/forecast_${childId}_${childBase}`;
    await addForecastToZip(zip, childFolder, child, nextPathKeys, idMap);
  }
}

async function downloadPlotImage() {
  const plotVal = type.val();

  const entry = isForecastYear && activePredictionKey
    ? predictionCache[activePredictionKey]
    : null;

  if (!entry || (entry.modelType !== 'growth' && entry.modelType !== 'driver' && entry.modelType !== 'gb')) {
    const total = getHistoricalPlotTotal(year, plotVal) ?? 0;
    const baseName = formatDownloadFileTitle(plotVal, year, total);
    Plotly.downloadImage('MonthlyPlot', {
      format: 'png',
      filename: baseName,
      width: 1000,
      height: 500
    });
    return;
  }

  const releaseSpinner = globalSpinner.start('Preparing download...', { immediate: true });
  try {
    const zip = new JSZip();
    const dataUrl = await Plotly.toImage('MonthlyPlot', {
      format: 'png',
      width: 1000,
      height: 500
    });
    const pngBlob = await (await fetch(dataUrl)).blob();
    await addForecastToZip(zip, '', entry, new Set(), new Map(), pngBlob); // pathKeys/idMap dedupe nested training forecasts

    const zipName = formatDownloadFileTitle(
      entry.plotType, entry.targetYear, predictionEntryTotal(entry), entry.modelType
    );
    const zipBlob = await zip.generateAsync({ type: 'blob' });
    downloadZip(`${zipName}.zip`, zipBlob);
  } catch (err) {
    alert(err.message || 'Could not download forecast zip.');
  } finally {
    releaseSpinner();
  }
}

function showControls() {
  prev.show();
  next.show();
  thisYearBtn.show();
  plot.show();
  updateRemainingMonthsBtn();
  updateForecastControls(activePredictionKey);
}

async function showHistoricalView() {
  if (year > thisYear) {
    year = thisYear;
    yearTitle.text(year);
    next.removeClass('unavailable');
  }
  activePredictionKey = null;
  isForecastYear = false;
  try {
    await ensureYearData(year);
    plotHistoricalYear(year, type.val());
    updateRemainingMonthsBtn();
    updateForecastControls('');
  } catch (err) {
    alert(err.message || 'An error occured.');
  }
}

// --- Totals header ---

function computeYearTotal(yArray) {
  return yArray.reduce((sum, v) => sum + v, 0);
}

function formatEuro(amount) {
  return amount.toLocaleString('en-GB', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

function plotTotalLabel(plotVal) {
  if (plotVal === 'Income') return 'Total income';
  if (plotVal === 'Expense') return 'Total expense';
  return 'Total net income';
}

function getHistoricalPlotTotal(y, plotVal) {
  const cached = dataCache.plotTotals[`${y}|${plotVal}`];
  if (cached !== undefined) return cached;

  const inc = dataCache.incomeByYear[y];
  const exp = dataCache.expenseByYear[y];

  if (plotVal === 'Income') {
    if (!inc) return null;
    return computeYearTotal(inc.months);
  }
  if (plotVal === 'Expense') {
    if (!exp) return null;
    return computeYearTotal(exp.months.map(v => -Math.abs(v)));
  }

  if (!inc && !exp) return null;
  const incomeM = inc ? inc.months : new Array(12).fill(0);
  const expenseM = exp ? exp.months.map(v => -Math.abs(v)) : new Array(12).fill(0);
  return computeYearTotal(incomeM.map((v, i) => v + expenseM[i]));
}

function formatSignedEuro(amount) {
  const sign = amount > 0 ? '+' : amount < 0 ? '−' : '';
  return `${sign}€${formatEuro(Math.abs(amount))}`;
}

function updatePlotTotalHeader(total, plotVal) {
  const main = `${plotTotalLabel(plotVal)}: €${formatEuro(total)}`;

  if (year === thisYear) {
    plotTotal.html(`<span class="plot-total-main">${main}</span>`);
    return;
  }

  const baseline = getHistoricalPlotTotal(thisYear, plotVal);
  if (baseline === null) {
    plotTotal.html(`<span class="plot-total-main">${main}</span>`);
    return;
  }

  const diff = total - baseline;
  let diffClass = 'plot-total-diff-neutral';
  if (diff > 0) diffClass = 'plot-total-diff-positive';
  else if (diff < 0) diffClass = 'plot-total-diff-negative';

  plotTotal.html(
    `<span class="plot-total-main">${main}</span>` +
    `<span class="plot-total-diff ${diffClass}">Change from ${thisYear}: ${formatSignedEuro(diff)}</span>`
  );
}

function plotDisplayCacheKey(plotVal, isForecast) {
  return `${year}|${plotVal}${isForecast ? '|forecast' : ''}`;
}

// --- Year navigation & plot type ---

function prevYearB() {
  prev.on('click', async () => {
    year -= 1;
    isForecastYear = year > thisYear;
    next.removeClass('unavailable');

    if (isForecastYear) {
      const entries = listPredictionsForYearPlot(year, type.val());
      if (entries.length > 0) {
        const key = activePredictionKey && predictionCache[activePredictionKey]
          && predictionCache[activePredictionKey].targetYear === year
          ? activePredictionKey
          : entries[0][0];
        if (await applyPrediction(key)) return;
      }
    }
    activePredictionKey = null;
    displayType();
  });
}

function nextYearB() {
  next.on('click', async () => {
    if (year < thisYear) {
      year += 1;
      yearTitle.text(year);
      next.removeClass('unavailable');
      isForecastYear = false;
      activePredictionKey = null;
      displayType();
      return;
    }

    await goToNextYearForecast();
  });
}

function thisYearB() {
  thisYearBtn.on('click', () => {
    year = thisYear;
    isForecastYear = false;
    activePredictionKey = null;
    yearTitle.text(year);
    next.removeClass('unavailable');
    displayType();
  });
}

function TypeSelect() {
  type.on('change', function () {
    displayType();
  });
}

async function displayType() {
  if (year > thisYear) {
    const entries = listPredictionsForYearPlot(year, type.val());
    if (entries.length > 0) {
      const key = activePredictionKey && predictionCache[activePredictionKey]
        && predictionCache[activePredictionKey].targetYear === year
        && predictionCache[activePredictionKey].plotType === type.val()
        ? activePredictionKey
        : entries[0][0];
      await applyPrediction(key);
      return;
    }
    openForecastModal(year);
    return;
  }

  if (year === thisYear) {
    await ensureYearData(thisYear);
  }

  activePredictionKey = null;
  isForecastYear = false;
  try {
    await ensureYearData(year);
    plotHistoricalYear(year, type.val());
    updateRemainingMonthsBtn();
    updateForecastControls('');
  } catch (err) {
    alert(err.message || 'An error occured.');
  }
}

// --- Page init ---

$(document).ready(function () {
  year = thisYear;
  yearTitle.text(year);

  TypeSelect();
  prevYearB();
  nextYearB();
  thisYearB();
  initForecastModalListeners();
  initLeavePageWarning();
  downloadPlotBtn.on('click', downloadPlotImage);

  void (async () => {
    try {
      await ensureYearData(thisYear);
      plotHistoricalYear(thisYear, 'NetIncome');
      next.removeClass('unavailable');
      updateRemainingMonthsBtn();
      updateForecastControls('');
    } catch (err) {
      alert(err.message || 'An error occured.');
    }
  })();
});
