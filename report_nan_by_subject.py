"""生成 loss_mask NaN 报告：每人种、每属性、哪些模特/scene 被标记为 0 (NaN)"""
import pandas as pd
from pathlib import Path
import numpy as np
from collections import defaultdict

GT_DIR = Path("/root/autodl-tmp/gt")

RACE_PREFIXES = {
    "CA": ["f01", "f02", "f03", "m01", "m02", "m03"],
    "AS": ["f01", "f02", "f03", "f04", "f05", "f06",
           "m01", "m02", "m03", "m04", "m05", "m06"],
    "SA": ["f01", "f02", "f03", "f04", "f05", "f06", "f07", "f08", "f09", "f10", "f11",
           "m01", "m02", "m03", "m04", "m05", "m06", "m07", "m08", "m09", "m10"],
    "AF": ["f01", "f02", "f03", "f04", "f05"],
}

ATTRS = [
    "01Preference", "02Attractiveness", "03Feminine",
    "04Cooperative", "05Youth", "06Healthy",
    "07Fidelity", "08Harmony", "09Fair", "10Ruddy",
]

# ========== 收集 ==========
# { attr: { (race, subject, scene): score } }
all_data: dict = defaultdict(dict)

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
            all_data[attr][oname] = score

# ========== 按 race 统计 ==========
def extract_subject(oname: str) -> str:
    """从 original_name 提取 subject_id, e.g. f04ih3k_01 -> f04"""
    return oname[:3] if len(oname) >= 3 else oname

def extract_scene(oname: str) -> str:
    """从 original_name 提取 scene, e.g. f04ih3k_01 -> ih3k"""
    prefix = oname[:3]
    rest = oname[3:]
    parts = rest.rsplit("_", 1)
    return parts[0] if len(parts) == 2 else rest

# ========== 生成 Excel ==========
out_dir = Path("/root/autodl-tmp/deepskin")
output_path = out_dir / "nan_mask_report.xlsx"
writer = pd.ExcelWriter(str(output_path), engine="openpyxl")

for race, prefixes in RACE_PREFIXES.items():
    # Sheet 1: 每人种·每属性·每 subject 的 NaN 比例
    rows = []
    for attr in ATTRS:
        for prefix in prefixes:
            total = 0
            nan_count = 0
            for oname, score in all_data[attr].items():
                if oname.lower().startswith(prefix):
                    total += 1
                    if not np.isfinite(score):
                        nan_count += 1
            if total > 0:
                sex = "F" if prefix.startswith("f") else "M"
                rows.append({
                    "Race": race,
                    "Attribute": attr,
                    "Sex": sex,
                    "Subject": prefix,
                    "Total": total,
                    "Valid": total - nan_count,
                    "NaN": nan_count,
                    "NaN%": f"{nan_count / total * 100:.1f}%",
                })

    df_subject = pd.DataFrame(rows)
    df_subject.to_excel(writer, sheet_name=f"{race}_by_subject", index=False)

    # Sheet 2: 每人种·每属性·每 subject 下默认 scene 的 NaN 详情
    # 这里按 subject+scene 分组
    detail_rows = []
    for attr in ATTRS:
        for prefix in prefixes:
            scene_stats: dict = {}
            for oname, score in all_data[attr].items():
                if oname.lower().startswith(prefix):
                    scene = extract_scene(oname)
                    if scene not in scene_stats:
                        scene_stats[scene] = {"total": 0, "nan": 0}
                    scene_stats[scene]["total"] += 1
                    if not np.isfinite(score):
                        scene_stats[scene]["nan"] += 1
            for scene, st in scene_stats.items():
                detail_rows.append({
                    "Attribute": attr,
                    "Subject": prefix,
                    "Scene": scene,
                    "Total": st["total"],
                    "NaN": st["nan"] if st["nan"] > 0 else "",
                })

    df_detail = pd.DataFrame(detail_rows)
    df_detail.to_excel(writer, sheet_name=f"{race}_detail", index=False)

writer.close()
print(f"Report saved to: {output_path}")

# ========== 终端 Summary ==========
print("\n" + "=" * 60)
print("SUMMARY: mask=0 (NaN) 属性 × 人种")
print("=" * 60)
for race, prefixes in RACE_PREFIXES.items():
    print(f"\n>>> {race}")
    for attr in ATTRS:
        total = 0
        nan_total = 0
        nan_subjects = []
        for prefix in prefixes:
            subj_total = 0
            subj_nan = 0
            for oname, score in all_data[attr].items():
                if oname.lower().startswith(prefix):
                    subj_total += 1
                    total += 1
                    if not np.isfinite(score):
                        subj_nan += 1
                        nan_total += 1
            if subj_nan > 0:
                nan_subjects.append(f"{prefix}({subj_nan}/{subj_total})")
        if nan_total == 0:
            print(f"  {attr}: all valid ✅")
        elif nan_total == total:
            print(f"  {attr}: ALL NaN ❌  subjects={nan_subjects}")
        else:
            print(f"  {attr}: {nan_total}/{total} NaN ({nan_total/total*100:.0f}%)  subjects={nan_subjects}")
