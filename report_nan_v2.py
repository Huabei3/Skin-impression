"""NaN 报告 v2: 每 sheet 一个 attribute，每行一个模特，每列一个 scene，True=NaN"""
import pandas as pd
from pathlib import Path
import numpy as np

GT_DIR = Path("/root/autodl-tmp/gt")
ATTRS = [
    "01Preference", "02Attractiveness", "03Feminine",
    "04Cooperative", "05Youth", "06Healthy",
    "07Fidelity", "08Harmony", "09Fair", "10Ruddy",
]

# ========== 与 train.py _RACE_CONFIG 一致 ==========
_RACE_CONFIG = {
    "CA": ["01", "02", "03"],
    "AS": ["04", "05", "06"],
    "SA": ["07", "08"],
    "AF": ["09", "10"],
}

def get_race(subj: str) -> str:
    """与 train.py _RACE_CONFIG 一致的 race 映射。"""
    sid = subj[1:]  # e.g. "f04" → "04"
    for race, ids in _RACE_CONFIG.items():
        if sid in ids:
            return race
    return "??"

# ========== 读取所有 GT 数据 ==========
# { (subject, scene_key): {attr: score} }
all_data: dict = {}

for attr in ATTRS:
    fpath = GT_DIR / f"toMax_gt_{attr}.xlsx"
    if not fpath.exists():
        continue
    xl = pd.ExcelFile(fpath)
    for sheet in xl.sheet_names:
        df = pd.read_excel(xl, sheet_name=sheet)
        for _, row in df.iterrows():
            oname = str(row.iloc[0])
            score = float(row.iloc[1])

            if len(oname) < 4:
                continue
            subject = oname[:3]
            scene_key = oname[3:].rsplit("_", 1)[0]  # "ih3k" or "rh3k"

            key = (subject, scene_key)
            if key not in all_data:
                all_data[key] = {}
            all_data[key][attr] = score

# ========== 收集所有 subject 和 scene ==========
subjects = sorted(set(k[0] for k in all_data.keys()))
i_scenes = sorted(set(k[1] for k in all_data.keys() if k[1].startswith("i")))
r_scenes = sorted(set(k[1] for k in all_data.keys() if k[1].startswith("r")))
all_scenes = i_scenes + r_scenes

print(f"Subjects ({len(subjects)}): {subjects}")
print(f"i-scenes ({len(i_scenes)}): {i_scenes}")
print(f"r-scenes ({len(r_scenes)}): {r_scenes}")
print(f"Race mapping:")
for subj in subjects:
    print(f"  {subj} → {get_race(subj)}")

# ========== 生成 Excel ==========
out_path = Path("/root/autodl-tmp/deepskin/nan_mask_report_v2.xlsx")
writer = pd.ExcelWriter(str(out_path), engine="openpyxl")

for attr in ATTRS:
    rows = []
    for subj in subjects:
        row = {"Subject": subj, "Race": get_race(subj)}
        for sc in all_scenes:
            key = (subj, sc)
            if key in all_data:
                score = all_data[key].get(attr, float("nan"))
                row[sc] = not np.isfinite(score)
            else:
                row[sc] = "N/A"
        rows.append(row)

    df = pd.DataFrame(rows)
    df.to_excel(writer, sheet_name=attr, index=False)

    nan_count = sum(1 for r in rows for sc in all_scenes if r.get(sc) is True)
    valid_count = sum(1 for r in rows for sc in all_scenes if r.get(sc) is False)
    print(f"  {attr}: NaN={nan_count}, valid={valid_count}")

writer.close()
print(f"\nSaved: {out_path}")
