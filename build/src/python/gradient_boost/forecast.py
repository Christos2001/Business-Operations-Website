#!/usr/bin/env python3
"""Gradient Boost monthly forecast (Optuna + XGBoost). JSON stdin → JSON stdout."""

from __future__ import annotations

import json
import sys
import time
from typing import Any, Callable, Dict, List, Optional, Tuple

import numpy as np
import optuna
import pandas as pd
from sklearn.base import clone
from sklearn.metrics import mean_absolute_error
from sklearn.model_selection import KFold
from xgboost import XGBRegressor
from xgboost.callback import EarlyStopping, TrainingCallback

MIN_TRAINING_ROWS = 5
N_ESTIMATORS = 1000
EARLY_STOPPING_ROUNDS = 50
ALLOWED_N_TRIALS = (50, 100, 200, 500)
ALLOWED_PRUNERS = ("none", "median", "hyperband")
MAX_TIMEOUT_SEC = 99 * 3600 + 59 * 60
TOTAL_SOURCE = "__total__"


# --- progress (stderr JSON lines; stdout stays the forecast result) ---

class ForecastProgress:
    """Throttled 10% Optuna (search) + XGBoost (final fit after tuning)."""

    def __init__(self, n_sides: int, n_trials: int) -> None:
        self.n_sides = max(1, n_sides)
        self.n_trials = max(1, n_trials)
        self.last = {"optuna": -1, "xgboost": -1}
        self.side_index = 0

    def maybe_emit(self, bar: str, pct: int, message: str) -> None:
        stepped = (pct // 10) * 10
        last = self.last[bar]
        shown = 100 if pct == 100 else stepped
        if shown == last:
            return
        if shown > last or pct == 100:
            self.last[bar] = shown
            sys.stderr.write(json.dumps({"bar": bar, "pct": shown, "message": message}) + "\n")
            sys.stderr.flush()

    def on_optuna_trial(self, trial: optuna.trial.FrozenTrial) -> None:
        done = self.side_index * self.n_trials + trial.number + 1
        total = self.n_sides * self.n_trials
        pct = 100 * done // total
        self.maybe_emit("optuna", pct, f"Trial {trial.number + 1}/{self.n_trials}")

    def finish_optuna_side(self) -> None:
        done = (self.side_index + 1) * self.n_trials
        total = self.n_sides * self.n_trials
        pct = 100 * done // total
        self.maybe_emit("optuna", pct, f"Trial {self.n_trials}/{self.n_trials}")

    def reset_xgb(self) -> None:
        self.last["xgboost"] = -1
        self.maybe_emit("xgboost", 0, "")

    def begin_xgb_fit(self, n_estimators: int) -> None:
        self.last["xgboost"] = -1
        self.maybe_emit("xgboost", 0, f"Trees 0/{n_estimators}")

    def on_xgb_round(self, epoch: int, n_estimators: int) -> None:
        done = epoch + 1
        pct = 100 * done // max(1, n_estimators)
        self.maybe_emit("xgboost", pct, f"Trees {done}/{n_estimators}")

    def finish_xgb(self, n_estimators: int) -> None:
        self.maybe_emit("xgboost", 100, f"Trees {n_estimators}/{n_estimators}")


class FinalFitRoundProgress(TrainingCallback):
    def __init__(self, progress: ForecastProgress, n_estimators: int) -> None:
        super().__init__()
        self.progress = progress
        self.n_estimators = n_estimators

    def after_iteration(self, model, epoch: int, evals_log) -> bool:
        self.progress.on_xgb_round(epoch, self.n_estimators)
        return False


def _attach_xgb_progress(est: XGBRegressor, progress: ForecastProgress) -> XGBRegressor:
    n_estimators = int(est.get_params().get("n_estimators") or N_ESTIMATORS)
    return est.set_params(callbacks=[FinalFitRoundProgress(progress, n_estimators)])


def _fit_tuned(est: XGBRegressor, X: pd.DataFrame, y: np.ndarray, progress: ForecastProgress) -> XGBRegressor:
    n_estimators = int(est.get_params().get("n_estimators") or N_ESTIMATORS)
    progress.begin_xgb_fit(n_estimators)
    est = _attach_xgb_progress(est, progress)
    est.fit(X, y, verbose=False)
    progress.finish_xgb(n_estimators)
    return est


# --- history store ---

class History:
    """year -> month(1-12) -> source -> amount"""

    def __init__(self) -> None:
        self.data: Dict[int, Dict[int, Dict[str, float]]] = {}
        self.sources: List[str] = []

    def add(self, source: str, year: int, month: int, amount: float) -> None:
        if month < 1 or month > 12:
            return
        self.data.setdefault(year, {}).setdefault(month, {})
        self.data[year][month][source] = self.data[year][month].get(source, 0.0) + float(amount)
        if source not in self.sources and source != TOTAL_SOURCE:
            self.sources.append(source)

    def set(self, source: str, year: int, month: int, amount: float) -> None:
        if month < 1 or month > 12:
            return
        self.data.setdefault(year, {}).setdefault(month, {})
        self.data[year][month][source] = float(amount)
        if source not in self.sources and source != TOTAL_SOURCE:
            self.sources.append(source)

    def get_source(self, year: int, month: int, source: str) -> Optional[float]:
        if year not in self.data or month not in self.data[year]:
            return None
        if source not in self.data[year][month]:
            return None
        return float(self.data[year][month][source])

    def aggregate(self, year: int, month: int) -> float:
        if year not in self.data or month not in self.data[year]:
            return 0.0
        return float(sum(self.data[year][month].values()))

    def has_month(self, year: int, month: int) -> bool:
        if year not in self.data or month not in self.data[year]:
            return False
        return any(v != 0.0 for v in self.data[year][month].values())

    def has_year(self, year: int) -> bool:
        if year not in self.data:
            return False
        return any(self.has_month(year, m) for m in range(1, 13))

    def sorted_sources(self) -> List[str]:
        return sorted(s for s in self.sources if s != TOTAL_SOURCE)

    def creation_year(self) -> Optional[int]:
        years = [y for y in self.data if self.has_year(y)]
        return min(years) if years else None


def load_rows(history: History, rows: List[dict], source_f: str, date_f: str, amount_f: str) -> None:
    for row in rows or []:
        date = str(row.get(date_f, ""))
        parts = date.split("-")
        if len(parts) < 2:
            continue
        year, month = int(parts[0]), int(parts[1])
        history.add(str(row.get(source_f, "")), year, month, float(row.get(amount_f, 0) or 0))


def apply_overlay(history: History, year: int, by_source: Optional[dict]) -> None:
    if not by_source:
        return
    for source, months in by_source.items():
        for i, val in enumerate(months or []):
            v = float(val or 0)
            if v != 0.0:
                history.set(str(source), year, i + 1, v)


# --- features ---

def _shift(year: int, month: int, back: int) -> Tuple[int, int]:
    y, m = year, month
    for _ in range(back):
        m -= 1
        if m < 1:
            m = 12
            y -= 1
    return y, m


def _get(
    getter: Callable[[int, int], Optional[float]],
    year: int,
    month: int,
) -> Optional[float]:
    v = getter(year, month)
    if v is None or v == 0.0:
        return None
    return float(v)


def _mean(vals: List[Optional[float]]) -> float:
    nums = [v for v in vals if v is not None]
    return float(sum(nums) / len(nums)) if nums else 0.0


def insufficient_history(
    has_creation: bool,
    has_this_year: bool,
) -> int:
    """Same calendar month in creation year vs this year.

    Creation year is the only edge case: a company that opened in March has
    no January/February then; later years are assumed to have values while open.

    0: present in creation year and this year.
    1: only creation year (missing this year).
    2: this year only — not creation year (opened later in the year).
    3: missing in both.
    """
    if has_creation and has_this_year:
        return 0
    if has_creation:
        return 1
    if has_this_year:
        return 2
    return 3


def lag_block(
    getter: Callable[[int, int], Optional[float]],
    year: int,
    month: int,
    hist_years: List[int],
    creation_year: int,
    this_year: int,
    prefix: str = "",
) -> Dict[str, float]:
    out: Dict[str, float] = {}

    for lag in (1, 2, 3):
        y, m = _shift(year, month, lag)
        out[f"{prefix}value_Of_Prev_{lag}_Month"] = _get(getter, y, m) or 0.0

    series = [_get(getter, *_shift(year, month, i)) for i in range(1, 12)]

    out[f"{prefix}Mean_Of_3_Last_Months"] = _mean(series[0:3])
    out[f"{prefix}Mean_Of_4-6_Last_Months"] = _mean(series[3:6])
    out[f"{prefix}Mean_Of_7-9_Last_Months"] = _mean(series[6:9])
    out[f"{prefix}Mean_Of_10-11_Last_Months"] = _mean(series[9:11])

    for hy in hist_years:
        key = f"{prefix}value_Of_Month_In_Year_{hy}"
        if hy >= year:
            out[key] = 0.0
        else:
            out[key] = _get(getter, hy, month) or 0.0

    all_vals: List[float] = []
    years_for_mean = set(hist_years) | {year - 1}
    for hy in sorted(years_for_mean):
        if hy > year:
            continue
        for mm in range(1, 13):
            if hy == year and mm >= month:
                continue
            v = _get(getter, hy, mm)
            if v is not None:
                all_vals.append(v)
    out[f"{prefix}Historical_Mean"] = float(sum(all_vals) / len(all_vals)) if all_vals else 0.0

    has_creation = _get(getter, creation_year, month) is not None
    has_this = _get(getter, this_year, month) is not None
    out[f"{prefix}Insufficient_History"] = float(
        insufficient_history(has_creation, has_this)
    )
    return out


def build_features(
    history: History,
    year: int,
    month: int,
    hist_years: List[int],
    this_year: int,
    sources: List[str],
) -> Dict[str, float]:
    creation = history.creation_year() or hist_years[0]

    def agg_get(y: int, m: int) -> Optional[float]:
        if not history.has_month(y, m):
            return None
        v = history.aggregate(y, m)
        return None if v == 0.0 else v

    feats: Dict[str, float] = {
        "Year": float(year),
        "Month": float(month),
    }
    feats.update(lag_block(agg_get, year, month, hist_years, creation, this_year))

    for source in sources:
        def src_get(y: int, m: int, s=source) -> Optional[float]:
            v = history.get_source(y, m, s)
            if v is None or v == 0.0:
                return None
            return v

        prefix = f"src_{source}__"
        feats.update(lag_block(src_get, year, month, hist_years, creation, this_year, prefix))

    return feats


def build_training(
    history: History,
    years: List[int],
    hist_years: List[int],
    this_year: int,
    sources: List[str],
    partial_year: Optional[int] = None,
    max_month: Optional[int] = None,
) -> Tuple[pd.DataFrame, np.ndarray]:
    rows: List[Dict[str, float]] = []
    labels: List[float] = []
    for year in years:
        end = max_month if partial_year is not None and year == partial_year and max_month else 12
        for month in range(1, end + 1):
            if not history.has_month(year, month):
                continue
            rows.append(build_features(history, year, month, hist_years, this_year, sources))
            labels.append(history.aggregate(year, month))
    if not rows:
        return pd.DataFrame(), np.array([], dtype=float)
    return pd.DataFrame(rows).fillna(0.0), np.asarray(labels, dtype=float)


# --- Optuna / XGBoost (notebook-style, regression, no prints) ---

def _remaining(deadline: Optional[float]) -> Optional[float]:
    if deadline is None:
        return None
    return max(0.0, deadline - time.monotonic())


def _make_pruner(pruner_name: str):
    if pruner_name == "median":
        return optuna.pruners.MedianPruner(n_startup_trials=10, n_warmup_steps=1)
    if pruner_name == "hyperband":
        return optuna.pruners.HyperbandPruner(min_resource=1, max_resource="auto", reduction_factor=3)
    return optuna.pruners.NopPruner()


def _base_estimator() -> XGBRegressor:
    return XGBRegressor(
        random_state=42,
        verbosity=0,
        tree_method="hist",
        objective="reg:squarederror",
        eval_metric="mae",
        n_estimators=N_ESTIMATORS,
    )


def _suggest_params(trial: optuna.Trial) -> dict:
    return {
        "learning_rate": trial.suggest_float("learning_rate", 0.01, 0.1, log=True),
        "max_depth": trial.suggest_int("max_depth", 2, 4),
        "min_child_weight": trial.suggest_float("min_child_weight", 1.0, 10.0),
        "reg_lambda": trial.suggest_float("reg_lambda", 1.0, 10.0),
        "subsample": trial.suggest_float("subsample", 0.6, 1.0),
        "colsample_bytree": trial.suggest_float("colsample_bytree", 0.6, 1.0),
        "n_estimators": N_ESTIMATORS,
    }


def _fit_fold(
    est: XGBRegressor,
    X_tr: pd.DataFrame,
    y_tr: np.ndarray,
    X_va: Optional[pd.DataFrame] = None,
    y_va: Optional[np.ndarray] = None,
    early_stopping_rounds: int = EARLY_STOPPING_ROUNDS,
) -> XGBRegressor:
    if X_va is not None and y_va is not None:
        est.set_params(callbacks=[EarlyStopping(rounds=early_stopping_rounds, save_best=True)])
        est.fit(X_tr, y_tr, eval_set=[(X_va, y_va)], verbose=False)
    else:
        est.set_params(callbacks=[])
        est.fit(X_tr, y_tr, verbose=False)
    return est


def _best_iteration(est: XGBRegressor) -> int:
    bi = getattr(est, "best_iteration", None)
    if bi is None:
        bi = getattr(est, "best_iteration_", None)
    if bi is None:
        bi = est.get_params().get("n_estimators", 1)
    return max(int(bi), 0)


def _locked_tree_count(best_iterations: List[int]) -> int:
    if not best_iterations:
        return 1
    return max(int(np.mean(best_iterations)) + 1, 1)


def cross_fold_with_early_stopping(
    est: XGBRegressor,
    X: pd.DataFrame,
    y: np.ndarray,
    use_early_stopping: bool = True,
    trial: Optional[optuna.Trial] = None,
    prune: bool = False,
) -> Tuple[np.ndarray, List[int]]:
    n = len(y)
    if n < 3:
        fold = clone(est)
        fold.set_params(callbacks=[])
        fold.fit(X, y, verbose=False)
        mae = float(mean_absolute_error(y, fold.predict(X)))
        return np.asarray([mae], dtype=float), [_best_iteration(fold)]

    splits = min(5, n)
    kf = KFold(n_splits=splits, shuffle=True, random_state=42)
    scores: List[float] = []
    best_iterations: List[int] = []
    for i, (tr, va) in enumerate(kf.split(X)):
        fold = clone(est)
        X_tr, X_va = X.iloc[tr], X.iloc[va]
        y_tr, y_va = y[tr], y[va]
        if use_early_stopping:
            _fit_fold(fold, X_tr, y_tr, X_va, y_va)
            best_iterations.append(_best_iteration(fold))
        else:
            fold.set_params(callbacks=[])
            fold.fit(X_tr, y_tr, verbose=False)
            best_iterations.append(int(fold.get_params().get("n_estimators") or N_ESTIMATORS))
        mae = float(mean_absolute_error(y_va, fold.predict(X_va)))
        scores.append(mae)
        if prune and trial is not None:
            trial.report(mae, step=i)
            if trial.should_prune():
                raise optuna.TrialPruned()
    return np.asarray(scores, dtype=float), best_iterations


def _cv_mae(
    est: XGBRegressor,
    X: pd.DataFrame,
    y: np.ndarray,
    use_early_stopping: bool = False,
    trial: Optional[optuna.Trial] = None,
    prune: bool = False,
) -> Tuple[float, List[int]]:
    scores, best_iterations = cross_fold_with_early_stopping(
        est, X, y, use_early_stopping=use_early_stopping, trial=trial, prune=prune
    )
    return float(np.mean(scores)), best_iterations


def diagnose_model(est: XGBRegressor, X: pd.DataFrame, y: np.ndarray, cv_mae: float) -> Dict[str, Any]:
    train_mae = float(mean_absolute_error(y, est.predict(X)))
    scale = max(float(np.mean(np.abs(y))), 1e-8)
    relative_gap = (cv_mae - train_mae) / scale
    if train_mae / scale > 1.5 and cv_mae / scale > 1.5:
        reason = "underfit"
        passed = False
    elif relative_gap > 0.5:
        reason = "overfit"
        passed = False
    else:
        reason = "ok"
        passed = True
    return {
        "passed": passed,
        "reason": reason,
        "trainMae": train_mae,
        "cvMae": cv_mae,
        "relativeGap": float(relative_gap),
    }


def _side_meta(
    needs_confirm: bool,
    diagnose: Dict[str, Any],
    trials_completed: int,
    n_trials: int,
    timed_out: bool,
    trials_attempted: int,
) -> Dict[str, Any]:
    return {
        "needsConfirm": bool(needs_confirm),
        "reason": diagnose.get("reason") or "ok",
        "trainMae": float(diagnose.get("trainMae") or 0.0),
        "cvMae": float(diagnose.get("cvMae") or 0.0),
        "relativeGap": float(diagnose.get("relativeGap") or 0.0),
        "trialsCompleted": int(trials_completed),
        "trialsAttempted": int(trials_attempted),
        "nTrials": int(n_trials),
        "timedOut": bool(timed_out),
    }


def run_model(
    X: pd.DataFrame,
    y: np.ndarray,
    progress: ForecastProgress,
    side_index: int,
    n_trials: int,
    pruner_name: str,
    deadline: Optional[float],
) -> Tuple[XGBRegressor, Dict[str, Any]]:
    optuna.logging.set_verbosity(optuna.logging.WARNING)
    base = _base_estimator()
    progress.side_index = side_index
    progress.reset_xgb()
    prune = pruner_name in ("median", "hyperband")

    def objective(trial: optuna.Trial) -> float:
        params = _suggest_params(trial)
        est = clone(base).set_params(**params)
        mae, best_iterations = _cv_mae(
            est, X, y, use_early_stopping=True, trial=trial if prune else None, prune=prune
        )
        trial.set_user_attr("best_iterations", [int(x) for x in best_iterations])
        return mae

    def on_trial(_study: optuna.Study, trial: optuna.trial.FrozenTrial) -> None:
        progress.on_optuna_trial(trial)

    remaining = _remaining(deadline)
    if remaining is not None and remaining <= 0:
        raise ValueError("Forecast timed out before any trial finished.")

    study = optuna.create_study(direction="minimize", pruner=_make_pruner(pruner_name))
    study.optimize(
        objective,
        n_trials=n_trials,
        timeout=remaining,
        callbacks=[on_trial],
    )
    progress.finish_optuna_side()

    trials = sorted(
        [t for t in study.trials if t.state.name == "COMPLETE" and t.value is not None],
        key=lambda t: t.value,
    )
    trials_attempted = len(study.trials)
    timed_out = remaining is not None and trials_attempted < n_trials
    trials_completed = len(trials)
    if trials_completed < 1:
        raise ValueError("No Optuna trial finished.")

    last_fail: Optional[Tuple[dict, Dict[str, Any]]] = None
    for trial in trials:
        left = _remaining(deadline)
        if left is not None and left <= 0 and last_fail is not None:
            break
        best_iterations = trial.user_attrs.get("best_iterations") or []
        n_trees = _locked_tree_count([int(x) for x in best_iterations])
        params_out = dict(trial.params)
        params_out["n_estimators"] = n_trees
        est = clone(base).set_params(**params_out)
        est.set_params(callbacks=[])
        cv, _ = _cv_mae(est, X, y, use_early_stopping=False)
        est = clone(base).set_params(**params_out)
        est.set_params(callbacks=[])
        est.fit(X, y, verbose=False)
        diag = diagnose_model(est, X, y, cv)
        if diag["passed"]:
            chosen = clone(base).set_params(**params_out)
            chosen.set_params(callbacks=[])
            chosen = _fit_tuned(chosen, X, y, progress)
            return chosen, _side_meta(
                False, diag, trials_completed, n_trials, timed_out, trials_attempted
            )
        if last_fail is None:
            last_fail = (params_out, diag)

    if last_fail is None:
        best = trials[0]
        best_iterations = best.user_attrs.get("best_iterations") or []
        n_trees = _locked_tree_count([int(x) for x in best_iterations])
        params_out = dict(best.params)
        params_out["n_estimators"] = n_trees
        est = clone(base).set_params(**params_out)
        est.set_params(callbacks=[])
        cv, _ = _cv_mae(est, X, y, use_early_stopping=False)
        est = clone(base).set_params(**params_out)
        est.set_params(callbacks=[])
        est = _fit_tuned(est, X, y, progress)
        diag = diagnose_model(est, X, y, cv)
        return est, _side_meta(
            not diag["passed"], diag, trials_completed, n_trials, timed_out, trials_attempted
        )

    params_out, diag = last_fail
    chosen = clone(base).set_params(**params_out)
    chosen.set_params(callbacks=[])
    chosen = _fit_tuned(chosen, X, y, progress)
    return chosen, _side_meta(True, diag, trials_completed, n_trials, timed_out, trials_attempted)


# --- forecast ---

def _predict_months(
    model: XGBRegressor,
    history: History,
    X_cols,
    hist_years: List[int],
    this_year: int,
    target_year: int,
    sources: List[str],
    start_month: int,
    months: List[float],
) -> List[float]:
    for month in range(start_month, 13):
        feats = pd.DataFrame([build_features(history, target_year, month, hist_years, this_year, sources)]).fillna(0.0)
        feats = feats.reindex(columns=X_cols, fill_value=0.0)
        pred = max(0.0, float(model.predict(feats)[0]))
        history.set(TOTAL_SOURCE, target_year, month, pred)
        months[month - 1] = pred
    return months


def forecast_side(
    history: History,
    start_year: int,
    this_year: int,
    target_year: int,
    current_month: int,
    is_partial: bool,
    include_current_month: bool,
    progress: ForecastProgress,
    side_index: int,
    n_trials: int,
    pruner_name: str,
    deadline: Optional[float],
) -> Tuple[List[float], Dict[str, Any]]:
    sources = history.sorted_sources()
    hist_years = list(range(start_year, this_year + 1))

    if is_partial:
        max_month = current_month if include_current_month else current_month - 1
        if max_month < 1:
            raise ValueError("Not enough completed months before the current month.")
        X, y = build_training(history, [this_year], hist_years, this_year, sources, this_year, max_month)
        if len(y) < MIN_TRAINING_ROWS:
            raise ValueError("Not enough data in completed months of this year for Gradient Boosting.")
        model, meta = run_model(X, y, progress, side_index, n_trials, pruner_name, deadline)
        months = [0.0] * 12
        for m in range(1, max_month + 1):
            months[m - 1] = history.aggregate(this_year, m)
        months = _predict_months(
            model, history, X.columns, hist_years, this_year, target_year, sources, max_month + 1, months
        )
        return months, meta

    end_train = target_year - 1
    train_years = list(range(start_year, end_train + 1))
    if not train_years:
        raise ValueError("Not enough history for Gradient Boosting.")

    partial_year = this_year if end_train == this_year else None
    max_month = None
    if partial_year is not None:
        max_month = current_month if include_current_month else current_month - 1
        if max_month < 1:
            max_month = None
            partial_year = None

    X, y = build_training(history, train_years, hist_years, this_year, sources, partial_year, max_month)
    if len(y) < MIN_TRAINING_ROWS:
        raise ValueError("Not enough history for Gradient Boosting.")

    model, meta = run_model(X, y, progress, side_index, n_trials, pruner_name, deadline)
    months = _predict_months(model, history, X.columns, hist_years, this_year, target_year, sources, 1, [0.0] * 12)
    return months, meta


def compose_plot(
    plot_type: str,
    income: Optional[List[float]],
    expense: Optional[List[float]],
) -> List[float]:
    if plot_type == "Income" and income is not None:
        return income
    if plot_type == "Expense" and expense is not None:
        return [-abs(v) for v in expense]
    if income is not None and expense is not None:
        return [income[i] - expense[i] for i in range(12)]
    return [0.0] * 12


def _parse_n_trials(body: dict) -> int:
    n_trials = int(body.get("nTrials") or 0)
    if n_trials not in ALLOWED_N_TRIALS:
        raise ValueError("Invalid Optuna trial count.")
    return n_trials


def _parse_pruner(body: dict) -> str:
    pruner = str(body.get("pruner") or "none").strip().lower()
    if pruner not in ALLOWED_PRUNERS:
        raise ValueError("Invalid Optuna pruner.")
    return pruner


def _parse_timeout_sec(body: dict) -> Optional[int]:
    if "timeoutSec" not in body or body.get("timeoutSec") is None:
        return None
    timeout_sec = int(body.get("timeoutSec"))
    if timeout_sec < 60 or timeout_sec > MAX_TIMEOUT_SEC:
        raise ValueError("Invalid time cap.")
    return timeout_sec


def main() -> None:
    raw = sys.stdin.read()
    body = json.loads(raw)

    plot_type = body["plotType"]
    target_year = int(body["targetYear"])
    num_years = int(body["numYears"])
    n_trials = _parse_n_trials(body)
    pruner_name = _parse_pruner(body)
    timeout_sec = _parse_timeout_sec(body)
    this_year = int(body.get("thisYear") or pd.Timestamp.today().year)
    current_month = int(body.get("currentMonth") or pd.Timestamp.today().month)
    include_current_month = bool(body.get("includeCurrentMonth", True))
    is_partial = target_year == this_year
    start_year = target_year - num_years
    deadline = (time.monotonic() + timeout_sec) if timeout_sec is not None else None

    income_h = History()
    expense_h = History()
    load_rows(income_h, body.get("incomeRows") or [], "Source", "DateOfIncome", "Income")
    load_rows(expense_h, body.get("expenseRows") or [], "source", "DateOfExpense", "expense")

    for year_s, overlay in (body.get("trainingOverlays") or {}).items():
        year = int(year_s)
        apply_overlay(income_h, year, (overlay or {}).get("incomeBySource"))
        apply_overlay(expense_h, year, (overlay or {}).get("expenseBySource"))
        # month-total overlays (growth forecasts without sources)
        inc_m = (overlay or {}).get("incomeMonths")
        exp_m = (overlay or {}).get("expenseMonths")
        if inc_m and not (overlay or {}).get("incomeBySource"):
            for i, v in enumerate(inc_m):
                if float(v or 0) != 0.0:
                    income_h.set(TOTAL_SOURCE, year, i + 1, float(v))
        if exp_m and not (overlay or {}).get("expenseBySource"):
            for i, v in enumerate(exp_m):
                if float(v or 0) != 0.0:
                    expense_h.set(TOTAL_SOURCE, year, i + 1, abs(float(v)))

    income_months = None
    expense_months = None
    income_diagnose = None
    expense_diagnose = None
    n_sides = int(plot_type in ("Income", "NetIncome")) + int(plot_type in ("Expense", "NetIncome"))
    progress = ForecastProgress(n_sides, n_trials)
    side_index = 0

    if plot_type in ("Income", "NetIncome"):
        income_months, income_diagnose = forecast_side(
            income_h,
            start_year,
            this_year,
            target_year,
            current_month,
            is_partial,
            include_current_month,
            progress,
            side_index,
            n_trials,
            pruner_name,
            deadline,
        )
        side_index += 1
    if plot_type in ("Expense", "NetIncome"):
        expense_months, expense_diagnose = forecast_side(
            expense_h,
            start_year,
            this_year,
            target_year,
            current_month,
            is_partial,
            include_current_month,
            progress,
            side_index,
            n_trials,
            pruner_name,
            deadline,
        )

    months = compose_plot(plot_type, income_months, expense_months)
    if is_partial:
        first = current_month if include_current_month else current_month - 1
        # keep actuals already filled inside forecast_side; forecastFromMonth is 1-based
        forecast_from = first + 1
    else:
        forecast_from = None

    out: Dict[str, Any] = {
        "success": True,
        "months": months,
        "incomeMonths": income_months,
        "expenseMonths": expense_months,
        "partialYear": is_partial,
        "forecastFromMonth": forecast_from,
        "incomeDiagnose": income_diagnose,
        "expenseDiagnose": expense_diagnose,
    }
    sys.stdout.write(json.dumps(out))


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        sys.stdout.write(json.dumps({"success": False, "errorMsg": str(e) or "Gradient Boost failed."}))
        sys.exit(0)
