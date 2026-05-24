from __future__ import annotations

from typing import Dict

import numpy as np


def _summary_stats(values: np.ndarray) -> Dict[str, float]:
    v = np.asarray(values, dtype=float).reshape(-1)
    v = v[np.isfinite(v)]
    if v.size == 0:
        return {
            "mean": float("nan"),
            "median": float("nan"),
            "trimean": float("nan"),
            "best25_mean": float("nan"),
            "worst25_mean": float("nan"),
            "min": float("nan"),
            "max": float("nan"),
        }

    mean = float(np.mean(v))
    median = float(np.median(v))
    q1 = float(np.percentile(v, 25))
    q3 = float(np.percentile(v, 75))
    trimean = float((q1 + 2.0 * median + q3) / 4.0)

    v_sorted = np.sort(v)
    k = int(np.ceil(0.25 * v_sorted.size))
    k = max(1, k)
    best25_mean = float(np.mean(v_sorted[:k]))
    worst25_mean = float(np.mean(v_sorted[-k:]))
    return {
        "mean": mean,
        "median": median,
        "trimean": trimean,
        "best25_mean": best25_mean,
        "worst25_mean": worst25_mean,
        "min": float(v_sorted[0]),
        "max": float(v_sorted[-1]),
    }


def evaluate_scores(pred_scores: np.ndarray, target_scores: np.ndarray) -> Dict[str, float]:
    ps = np.asarray(pred_scores, dtype=float).reshape(-1)
    ts = np.asarray(target_scores, dtype=float).reshape(-1)
    n = min(len(ps), len(ts))
    ps = ps[:n]
    ts = ts[:n]

    mask = np.isfinite(ps) & np.isfinite(ts)
    ps = ps[mask]
    ts = ts[mask]
    if ps.size == 0:
        return {
            "mae": float("nan"),
            "rmse": float("nan"),
            "r2": float("nan"),
            "pearson": float("nan"),
            "pearson_r": float("nan"),
            "p_error_mean": float("nan"),
            "p_error_median": float("nan"),
            "p_error_trimean": float("nan"),
            "p_error_best25_mean": float("nan"),
            "p_error_worst25_mean": float("nan"),
            "p_error_min": float("nan"),
            "p_error_max": float("nan"),
        }

    abs_err = np.abs(ps - ts)
    mae = float(np.mean(abs_err))
    rmse = float(np.sqrt(np.mean((ps - ts) ** 2)))
    denom = float(np.sum((ts - float(np.mean(ts))) ** 2))
    r2 = float("nan") if denom == 0 else float(1.0 - float(np.sum((ps - ts) ** 2)) / denom)
    pearson = float(np.corrcoef(ps, ts)[0, 1]) if ps.size > 1 else float("nan")

    s = _summary_stats(abs_err)
    return {
        "mae": mae,
        "rmse": rmse,
        "r2": r2,
        "pearson": pearson,
        "pearson_r": pearson,
        "p_error_mean": s["mean"],
        "p_error_median": s["median"],
        "p_error_trimean": s["trimean"],
        "p_error_best25_mean": s["best25_mean"],
        "p_error_worst25_mean": s["worst25_mean"],
        "p_error_min": s["min"],
        "p_error_max": s["max"],
    }
