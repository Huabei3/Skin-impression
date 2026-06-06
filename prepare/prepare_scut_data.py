"""准备 SCUT-FBP 格式数据：从 toMax_gt_01Preference.xlsx 生成 img_path score 文件。
不修改任何原数据。"""
from pathlib import Path
import pandas as pd
import numpy as np

GT = Path("/root/autodl-tmp/gt/toMax_gt_01Preference.xlsx")
FACE = Path("/root/autodl-tmp/rendered_face")
OUT = Path("/root/autodl-tmp/deepskin/prepare/scut_deepskin_train.txt")

rows = []
xl = pd.ExcelFile(GT)
for sheet in xl.sheet_names:
    df = pd.read_excel(xl, sheet_name=sheet)
    for _, row in df.iterrows():
        oname = str(row.iloc[0])
        score = float(row.iloc[1])
        if not np.isfinite(score):
            continue
        img_path = FACE / oname[:4] / f"{oname}_face.jpg"
        if img_path.exists():
            rows.append(f"{img_path} {score:.6f}")

OUT.write_text("\n".join(rows))
print(f"Saved {len(rows)} entries -> {OUT}")
print(f"Example: {rows[0]}")
