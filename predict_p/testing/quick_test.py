"""
predict_p quick test (standalone project).

Computes score-only metrics (MAE/RMSE/R2/Pearson).
"""

from __future__ import annotations

import csv
import sys
from pathlib import Path
from typing import Optional, Dict, Any


sys.path.append(str(Path(__file__).resolve().parents[2]))

# =============== User config ===============
checkpoint_path: str = r"F:\Github\deepskin\facial_preference\output\predict_p_v3_oppo_finetune_test_2v\checkpoints\best_model.pth"  # best_model.pth

# Dataset selection / split behavior (same meaning as facial_preference/testing/quick_test.py)
# - TEST_IDS: None/'all' for all IDs; or e.g. ["01", "02"] / [1, 2] / "01,02"
# - TEST_SPLIT_SOURCE:
#   - "subset": build+split test within TEST_IDS subset (may differ from training split)
#   - "base_then_filter": reproduce training-time base test split, then filter by TEST_IDS (recommended)
TEST_IDS = None
TEST_SPLIT_SOURCE = "subset"

TEST_FACE_RGB_ROOT: Optional[str] = r"I:\skin_data_2max\rendered_face"
TEST_GLOBAL_RGB_ROOT: Optional[str] = r"I:\skin_data_2max\rendered_2max" 
TEST_FACE_UV_ROOT: Optional[str] = r"I:\skin_data_2max\rendered_face_uv"
TEST_GT_EXCEL_PATH: Optional[str] = r"I:\skin_data_2max\gt\Preference_non_model_gt.xlsx"
# ==========================================


def _save_score_csv(gt, pred, out_path: Path) -> None:
    gt = list(gt)
    pred = list(pred)
    n = min(len(gt), len(pred))
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with open(out_path, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["gt", "pred", "error", "abs_error"])
        for i in range(n):
            e = float(pred[i]) - float(gt[i])
            w.writerow([float(gt[i]), float(pred[i]), e, abs(e)])


def _save_gt_pred_scatter(gt, pred, out_path: Path, title: str) -> None:
    try:
        import numpy as np
        import matplotlib.pyplot as plt
    except Exception as e:
        print(f"[警告] 无法绘图（缺少依赖？）: {e}")
        return

    x = np.asarray(gt, dtype=float).reshape(-1)
    y = np.asarray(pred, dtype=float).reshape(-1)
    mask = np.isfinite(x) & np.isfinite(y)
    x = x[mask]
    y = y[mask]
    if x.size == 0:
        print("[警告] 无有效数据可绘图")
        return

    x_min = float(min(x.min(), y.min()))
    x_max = float(max(x.max(), y.max()))
    pad = 0.02 * (x_max - x_min) if x_max > x_min else 1.0
    lo = x_min - pad
    hi = x_max + pad

    fig = plt.figure(figsize=(6, 6))
    ax = fig.add_subplot(1, 1, 1)
    ax.scatter(x, y, s=8, alpha=0.5)
    ax.plot([lo, hi], [lo, hi], "--", color="black", linewidth=1, label="y = x")
    ax.set_xlim(lo, hi)
    ax.set_ylim(lo, hi)
    ax.set_xlabel("gt")
    ax.set_ylabel("pred")
    ax.set_title(title)
    ax.grid(True, alpha=0.2)
    ax.legend(loc="best")
    fig.tight_layout()
    out_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(out_path, dpi=150)
    plt.close(fig)


def main() -> None:
    from predict_p.config import Config
    from predict_p.testing.batch_tester import BatchTester

    ckpt = Path(checkpoint_path) if checkpoint_path else None
    if not ckpt or not ckpt.exists():
        raise FileNotFoundError(f"checkpoint_path not found: {checkpoint_path!r}")

    cfg = Config.get_config_dict()
    cfg["TEST_SPLIT_SOURCE"] = TEST_SPLIT_SOURCE
    cfg["TEST_IDS"] = None if TEST_IDS in (None, "all") else TEST_IDS

    data_paths_override: Dict[str, Any] = {}
    if TEST_FACE_RGB_ROOT:
        data_paths_override["FACE_RGB_ROOT"] = str(TEST_FACE_RGB_ROOT)
    if TEST_GLOBAL_RGB_ROOT:
        data_paths_override["GLOBAL_RGB_ROOT"] = str(TEST_GLOBAL_RGB_ROOT)
    if TEST_FACE_UV_ROOT:
        data_paths_override["FACE_UV_ROOT"] = str(TEST_FACE_UV_ROOT)
    if TEST_GT_EXCEL_PATH:
        data_paths_override["GT_EXCEL_PATH"] = str(TEST_GT_EXCEL_PATH)
    if not data_paths_override:
        data_paths_override = None  # type: ignore[assignment]

    tester = BatchTester(
        checkpoint_path=str(ckpt),
        config=cfg,
        device="cuda",
        output_dir=str(ckpt.parent / "test_results_predict_p"),
        data_paths_override=data_paths_override,
    )
    results = tester.run_complete_test()

    metrics = results.get("score_metrics", {}) or {}
    total = (results.get("metadata", {}) or {}).get("total_samples", "N/A")

    print("\n" + "=" * 60)
    print("predict_p - 快速测试结果")
    print("=" * 60)
    print(f"测试样本数: {total}")

    print("\nP 误差统计（|p_pred - p_gt|）：")
    for k, label in (
        ("p_error_mean", "平均值"),
        ("p_error_median", "中位数"),
        ("p_error_trimean", "三均值"),
        ("p_error_best25_mean", "最好 25% 平均"),
        ("p_error_worst25_mean", "最坏 25% 平均"),
        ("p_error_min", "最小值"),
        ("p_error_max", "最大值"),
    ):
        v = metrics.get(k)
        if v is not None:
            try:
                print(f"  - {label}: {float(v):.4f}")
            except Exception:
                pass

    print("\n整体指标：")
    for k, label in (("mae", "MAE"), ("rmse", "RMSE"), ("r2", "R2"), ("pearson", "Pearson")):
        v = metrics.get(k)
        if v is not None:
            try:
                print(f"  - {label}: {float(v):.4f}")
            except Exception:
                pass

    # 额外保存：逐样本预测与散点图
    try:
        out_dir = Path(tester.output_dir)
        _save_score_csv(tester.tgt_scores, tester.pred_scores, out_dir / "test_predictions.csv")
        _save_gt_pred_scatter(tester.tgt_scores, tester.pred_scores, out_dir / "gt_vs_pred.png", title="predict_p: gt vs pred")
        print(f"\n已保存: {out_dir / 'test_predictions.csv'}")
        print(f"已保存: {out_dir / 'gt_vs_pred.png'}")
    except Exception as e:
        print(f"\n[警告] 保存 CSV/图 失败: {e}")


if __name__ == "__main__":
    main()
