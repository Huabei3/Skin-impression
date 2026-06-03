"""检查每个 race 下每个 attribute GT 文件的 NaN 模式。"""
import pandas as pd
from pathlib import Path
import numpy as np

GT_DIR = Path("/root/autodl-tmp/gt")

# 种族→subject 映射（与 config.py 一致）
RACE_CONFIG = {
    "CA": {"model_ids": ["01", "02", "03"]},  # f01-f03, m01-m03
    "AS": {"model_ids": ["01", "02", "03", "04", "05", "06"]},  # f01-f06, m01-m06
    "SA": {"model_ids": ["01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11"]},
    "AF": {"model_ids": ["01", "02", "03", "04", "05"]},
}

ATTRS = [
    "01Preference", "02Attractiveness", "03Feminine",
    "04Cooperative", "05Youth", "06Healthy",
    "07Fidelity", "08Harmony", "09Fair", "10Ruddy",
]

for attr in ATTRS:
    fpath = GT_DIR / f"toMax_gt_{attr}.xlsx"
    if not fpath.exists():
        print(f"⚠️  {attr}: FILE NOT FOUND")
        continue

    xl = pd.ExcelFile(fpath)
    all_names = set()
    all_scores = {}

    for sheet in xl.sheet_names:
        df = pd.read_excel(fpath, sheet_name=sheet)
        if "original_name" not in df.columns or "score" not in df.columns:
            continue
        for _, row in df.iterrows():
            name = str(row["original_name"])
            score = row["score"]
            all_names.add(name)
            all_scores[name] = score

    print(f"\n=== {attr} ===  total entries: {len(all_scores)}")

    for race, cfg in RACE_CONFIG.items():
        model_ids = cfg["model_ids"]
        nan_count = 0
        valid_count = 0
        total = 0
        for mid in model_ids:
            f_prefix = f"f{mid}"
            m_prefix = f"m{mid}"
            for name, score in all_scores.items():
                if f_prefix in name.lower() or m_prefix in name.lower():
                    total += 1
                    if np.isfinite(score):
                        valid_count += 1
                    else:
                        nan_count += 1
        if total == 0:
            print(f"  {race}: (no data)")
        elif nan_count == total:
            print(f"  {race}: ALL NaN ({nan_count}/{total})")
        elif nan_count == 0:
            print(f"  {race}: all valid ({valid_count}/{total})")
        else:
            print(f"  {race}: {valid_count} valid, {nan_count} NaN / {total} total")
