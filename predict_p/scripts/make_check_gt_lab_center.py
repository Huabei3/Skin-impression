"""生成 check_GT_lab_center_{attribute}.xlsx：逐 sheet 核对 GT 的 L*a*b* 与 fit_table.lab_center。

输出结构
--------
每个 {attribute} 一个 xlsx；每个 sheet = 一个 `{model}{i/r}`（如 f04i）；
每行 = 一个 `{scene}{i_point}`（如 h3k_01）；列：

    scene_point | GT_L | GT_a | GT_b | center_L | center_a | center_b | dL(L*-center)

center_* 来自 Peggy_VIVO_table.mat 的 fit_table.lab_center
（observer_type=non_model，按 attribute/model_id/scene 定位；同一 scene 的 33 行共享同一个 center）。

数据来源
--------
- GT: <gt-dir>/toMax_gt_{i_attribute}{Attribute}.xlsx
- center: 由 MATLAB 展平得到的 peggy_fit_centers.csv
  （脚本 export_peggy_centers.m，见 simple_ml/改动清单.md 附录）

用法
----
python predict_p/scripts/make_check_gt_lab_center.py \
    --gt-dir /root/autodl-tmp/gt \
    --center-csv /root/autodl-tmp/peggy/peggy_fit_centers.csv \
    --out-dir /root/autodl-tmp/gt/check_GT_lab_center
"""
from __future__ import annotations

import argparse
import re
from pathlib import Path

import numpy as np
import pandas as pd
from openpyxl.styles import Alignment, Border, Font, PatternFill, Side

SHEET_RE = re.compile(r"^([fm]\d{2})([ir])$", re.IGNORECASE)
ROW_RE = re.compile(r"^[fm]\d{2}[ir]([a-z0-9]+?)_(\d+)$", re.IGNORECASE)

HEADERS = ["scene_point", "GT_L", "GT_a", "GT_b",
           "center_L", "center_a", "center_b", "dL(L*-center)"]


def load_centers(csv_path: Path, observer: str) -> dict:
    """(attribute, model, scene) -> (L, a, b)"""
    df = pd.read_csv(csv_path)
    df = df[df["observer_type"].astype(str).str.strip().str.lower() == observer]
    out = {}
    for r in df.itertuples(index=False):
        out[(str(r.attribute).strip(), str(r.model_id).strip().lower(),
             str(r.scene_code).strip().lower())] = (
            float(r.center_L), float(r.center_a), float(r.center_b))
    return out


def style_sheet(ws, n_cols: int) -> None:
    head_font = Font(bold=True, color="FFFFFF", size=11)
    head_fill = PatternFill(start_color="4472C4", end_color="4472C4", fill_type="solid")
    thin = Side(style="thin", color="BFBFBF")
    border = Border(left=thin, right=thin, top=thin, bottom=thin)
    for ci in range(1, n_cols + 1):
        c = ws.cell(row=1, column=ci)
        c.font = head_font
        c.fill = head_fill
        c.alignment = Alignment(horizontal="center", vertical="center")
        c.border = border
        ws.column_dimensions[ws.cell(row=1, column=ci).column_letter].width = 16
    ws.column_dimensions["A"].width = 14
    ws.freeze_panes = "A2"


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--gt-dir", default="/root/autodl-tmp/gt")
    ap.add_argument("--center-csv", default="/root/autodl-tmp/peggy/peggy_fit_centers.csv")
    ap.add_argument("--out-dir", default="/root/autodl-tmp/gt/check_GT_lab_center")
    ap.add_argument("--observer", default="non_model")
    ap.add_argument("--attr", default=None, help="只处理某个属性，如 01Preference")
    a = ap.parse_args()

    gt_dir = Path(a.gt_dir)
    out_dir = Path(a.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    files = sorted(gt_dir.glob("toMax_gt_*.xlsx"))
    if a.attr:
        files = [f for f in files if a.attr in f.stem]
    if not files:
        raise SystemExit(f"no GT xlsx under {gt_dir}")

    centers = load_centers(Path(a.center_csv), a.observer)
    print(f"center LUT: {len(centers)} (attribute, model, scene) entries "
          f"[observer={a.observer}]")

    summary = []
    for f in files:
        attr_full = f.stem.replace("toMax_gt_", "")          # 01Preference
        attr = re.sub(r"^\d+", "", attr_full)                # Preference
        xl = pd.ExcelFile(f)
        out_path = out_dir / f"check_GT_lab_center_{attr_full}.xlsx"

        n_sheet = n_row = n_missing = 0
        dL_all = []
        with pd.ExcelWriter(out_path, engine="openpyxl") as w:
            for sheet in xl.sheet_names:
                m = SHEET_RE.match(str(sheet).strip())
                if not m:
                    continue
                model = m.group(1).lower()
                df = pd.read_excel(xl, sheet_name=sheet)
                cols = [str(c).strip().replace(" ", "") for c in df.columns]

                def find(*names):
                    for t in names:
                        if t in cols:
                            return cols.index(t)
                    return None

                iL, iA, iB = find("L*", "L"), find("a*", "a"), find("b*", "b")
                if iL is None:
                    continue

                rows = []
                for r in df.itertuples(index=False, name=None):
                    name = str(r[0]).strip()
                    mm = ROW_RE.match(name)
                    if not mm:
                        continue
                    scene, ip = mm.group(1).lower(), int(mm.group(2))
                    ctr = centers.get((attr, model, scene))
                    if ctr is None:
                        n_missing += 1
                        ctr = (np.nan, np.nan, np.nan)
                    gL = float(r[iL]) if pd.notna(r[iL]) else np.nan
                    gA = float(r[iA]) if (iA is not None and pd.notna(r[iA])) else np.nan
                    gB = float(r[iB]) if (iB is not None and pd.notna(r[iB])) else np.nan
                    dL_all.append(gL - ctr[0])
                    rows.append({
                        "scene_point": f"{scene}_{ip:02d}",
                        "GT_L": gL, "GT_a": gA, "GT_b": gB,
                        "center_L": ctr[0], "center_a": ctr[1], "center_b": ctr[2],
                        "dL(L*-center)": gL - ctr[0],
                    })

                if not rows:
                    continue
                t = pd.DataFrame(rows, columns=HEADERS)
                t = t.sort_values("scene_point", kind="stable")
                t.to_excel(w, sheet_name=sheet, index=False)
                style_sheet(w.sheets[sheet], len(HEADERS))
                n_sheet += 1
                n_row += len(t)

        dL = np.asarray(dL_all, dtype=float)
        dL = dL[np.isfinite(dL)]
        summary.append({
            "file": out_path.name, "attribute": attr_full,
            "n_sheets": n_sheet, "n_rows": n_row, "n_missing_center": n_missing,
            "dL_abs_mean": float(np.abs(dL).mean()) if dL.size else np.nan,
            "dL_abs_max": float(np.abs(dL).max()) if dL.size else np.nan,
            "n_nonzero(>1e-9)": int((np.abs(dL) > 1e-9).sum()),
        })
        print(f"  {out_path.name}: sheets={n_sheet} rows={n_row} "
              f"missing_center={n_missing} max|dL|={summary[-1]['dL_abs_max']}")

    sdf = pd.DataFrame(summary)
    print("\n=== 汇总 ===")
    print(sdf.round(6).to_string(index=False))
    sdf.to_csv(out_dir / "summary.csv", index=False, encoding="utf-8-sig")
    print(f"\n输出目录: {out_dir}")


if __name__ == "__main__":
    main()
