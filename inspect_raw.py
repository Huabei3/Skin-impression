import os
import sys
from pathlib import Path
import pandas as pd
import numpy as np

try:
    from scipy.io import loadmat
except ImportError:
    print("scipy not installed, install with: pip install scipy")
    sys.exit(1)

# 1. Inspect target Excel format
xlsx_path = Path(r"D:\work\secondYearMaster\thesis\reference\appeal\algorithms\preference_evaluate\deepskin\OPPOskinExpe\oppo_preference_gt.xlsx")
if xlsx_path.exists():
    xl = pd.ExcelFile(xlsx_path)
    print("=== Target Excel sheets:", xl.sheet_names)
    for sheet in xl.sheet_names[:3]:
        df = pd.read_excel(xl, sheet_name=sheet)
        print(f"\n--- Sheet: {sheet} ---")
        print(df.head(5))
        print(df.columns.tolist())
else:
    print("Target Excel not found")

# 2. Inspect mat files in toMax/f01i
tomax = Path(r"D:\work\secondYearMaster\thesis\reference\appeal\datasets\toMax\f01i")

mat_files = [
    tomax / "non_model" / "01Preference" / "labNscore" / "labNscore_groupf01ih3k.mat",
    tomax / "non_model" / "01Preference" / "ellipPara" / "fitRes.mat",
    tomax / "model_group" / "01Preference" / "labNscore" / "labNscore_groupf01ih3k.mat",
    tomax / "model_group" / "01Preference" / "ellipPara" / "fitRes.mat",
]

for p in mat_files:
    print(f"\n=== Mat file: {p} ===")
    if not p.exists():
        print("  Not found")
        continue
    m = loadmat(p)
    print("  Variables:", [k for k in m.keys() if not k.startswith('__')])
    for k in sorted(m.keys()):
        if k.startswith('__'):
            continue
        v = m[k]
        print(f"    {k}: shape={v.shape}, dtype={v.dtype}")
        if v.size <= 10:
            print(f"      value={v}")
        else:
            print(f"      first few={v.flat[:5]}")
