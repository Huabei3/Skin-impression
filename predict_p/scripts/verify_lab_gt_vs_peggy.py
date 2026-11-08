"""验证 toMax_gt_{i}{Attribute}.xlsx 里的 L*a*b* 到底对应 fit_table 的哪个字段。

两个候选
--------
1. `lab_values(i_point, :)`  —— 该场景第 i_point 个采样点（即这张 stimulus 本身）的 Lab
2. `lab_center`             —— 该 (model, scene, observer_type, attribute) 拟合出的偏好中心 Lab

预期结论（实测）：GT 的 L*a*b* == `lab_center`；`lab_values(i_point,1)` 在大多数场景下
与 lab_center 的 L 几乎相同（因为 33 个采样点 L 变化极小），但在少数场景差异很大。

数据准备
--------
fit_table 是 MATLAB table（MCOS 对象），scipy.io.loadmat 读不了，云端也没有 MATLAB，
所以先用 MATLAB 展平成两个 CSV（脚本见 simple_ml/改动清单.md 附录）：

    export_peggy.m          -> peggy_fit_lab_long.csv   (每行 × 33 点：L/a/b)
    export_peggy_centers.m  -> peggy_fit_centers.csv    (每行：center_L/a/b, avg_L/a/b)

用法
----
python predict_p/scripts/verify_lab_gt_vs_peggy.py \
    --gt-dir /root/autodl-tmp/gt \
    --lab-csv /root/autodl-tmp/peggy/peggy_fit_lab_long.csv \
    --center-csv /root/autodl-tmp/peggy/peggy_fit_centers.csv \
    --out /root/autodl-tmp/gt/lab_verify_report.xlsx
"""
from __future__ import annotations

import argparse
import re
from pathlib import Path

import numpy as np
import pandas as pd

SHEET_RE = re.compile(r"^([fm]\d{2})([ir])$", re.IGNORECASE)
ROW_RE = re.compile(r"^[fm]\d{2}[ir]([a-z0-9]+?)_(\d+)$", re.IGNORECASE)

RACE_OF_MODEL = {}
for _m in range(1, 11):
    _race = "CA" if _m <= 3 else "AS" if _m <= 6 else "SA" if _m <= 8 else "AF"
    RACE_OF_MODEL[f"m{_m:02d}"] = _race
    RACE_OF_MODEL[f"f{_m:02d}"] = _race


def attr_name_from_file(stem: str) -> str:
    m = re.match(r"^toMax_gt_\d{2}([A-Za-z]+)$", stem)
    return m.group(1) if m else stem


def load_point_lut(csv_path: Path) -> dict:
    """(attr, model, scene, i_point) -> (L, a, b)，只取 observer_type=non_model"""
    df = pd.read_csv(csv_path)
    df = df[df["observer_type"].astype(str).str.strip().str.lower() == "non_model"]
    out = {}
    for r in df.itertuples(index=False):
        out[(str(r.attribute).strip(), str(r.model_id).strip().lower(),
             str(r.scene_code).strip().lower(), int(r.i_point))] = (
            float(r.L), float(r.a), float(r.b))
    return out


def load_center_lut(csv_path: Path) -> dict:
    """(attr, model, scene) -> (center_L, center_a, center_b, n_points)"""
    df = pd.read_csv(csv_path)
    df = df[df["observer_type"].astype(str).str.strip().str.lower() == "non_model"]
    out = {}
    for r in df.itertuples(index=False):
        out[(str(r.attribute).strip(), str(r.model_id).strip().lower(),
             str(r.scene_code).strip().lower())] = (
            float(r.center_L), float(r.center_a), float(r.center_b), int(r.n_points))
    return out


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--gt-dir", default="/root/autodl-tmp/gt")
    ap.add_argument("--lab-csv", default="/root/autodl-tmp/peggy/peggy_fit_lab_long.csv")
    ap.add_argument("--center-csv", default="/root/autodl-tmp/peggy/peggy_fit_centers.csv")
    ap.add_argument("--out", default="/root/autodl-tmp/gt/lab_verify_report.xlsx")
    ap.add_argument("--tol", type=float, default=1.0)
    ap.add_argument("--attr", default=None, help="只验证某个属性，如 01Preference")
    a = ap.parse_args()

    gt_dir = Path(a.gt_dir)
    files = sorted(gt_dir.glob("toMax_gt_*.xlsx"))
    if a.attr:
        files = [f for f in files if a.attr in f.stem]
    if not files:
        raise SystemExit(f"no GT xlsx under {gt_dir}")

    print(f"loading point LUT : {a.lab_csv}")
    pl = load_point_lut(Path(a.lab_csv))
    print(f"  {len(pl)} entries")
    print(f"loading center LUT: {a.center_csv}")
    cl = load_center_lut(Path(a.center_csv))
    print(f"  {len(cl)} entries")

    detail = []
    for f in files:
        attr = attr_name_from_file(f.stem)
        xl = pd.ExcelFile(f)
        for sheet in xl.sheet_names:
            m = SHEET_RE.match(str(sheet).strip())
            if not m:
                continue
            model, ior = m.group(1).lower(), m.group(2).lower()
            race = RACE_OF_MODEL.get(model, "?")
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
            for row in df.itertuples(index=False, name=None):
                name = str(row[0]).strip()
                mm = ROW_RE.match(name)
                if not mm:
                    continue
                scene, ip = mm.group(1).lower(), int(mm.group(2))
                gL = float(row[iL]) if pd.notna(row[iL]) else np.nan
                gA = float(row[iA]) if (iA is not None and pd.notna(row[iA])) else np.nan
                gB = float(row[iB]) if (iB is not None and pd.notna(row[iB])) else np.nan
                pv = pl.get((attr, model, scene, ip))
                ct = cl.get((attr, model, scene))
                if pv is None or ct is None or not np.isfinite(gL):
                    continue
                detail.append({
                    "attribute": attr, "sheet": sheet, "race": race, "model": model,
                    "ior": ior, "scene": scene, "i_point": ip, "original_name": name,
                    "GT_L": gL, "GT_a": gA, "GT_b": gB,
                    "center_L": ct[0], "center_a": ct[1], "center_b": ct[2],
                    "point_L": pv[0], "point_a": pv[1], "point_b": pv[2],
                })

    if not detail:
        raise SystemExit("没有可比对的行，检查 --gt-dir / CSV")
    d = pd.DataFrame(detail)
    d["dL_center"] = d.GT_L - d.center_L
    d["da_center"] = d.GT_a - d.center_a
    d["db_center"] = d.GT_b - d.center_b
    d["dL_point"] = d.GT_L - d.point_L
    d["da_point"] = d.GT_a - d.point_a
    d["db_point"] = d.GT_b - d.point_b

    def agg(g):
        return pd.Series({
            "n": len(g),
            "dL_ctr_absmean": g.dL_center.abs().mean(),
            "dL_ctr_absmax": g.dL_center.abs().max(),
            "da_ctr_absmean": g.da_center.abs().mean(),
            "db_ctr_absmean": g.db_center.abs().mean(),
            "dL_pt_absmean": g.dL_point.abs().mean(),
            "dL_pt_absmax": g.dL_point.abs().max(),
            f"pass_ctr_{a.tol:g}": (g.dL_center.abs() <= a.tol).mean(),
            f"pass_pt_{a.tol:g}": (g.dL_point.abs() <= a.tol).mean(),
        })

    by_attr = (d.groupby("attribute").apply(agg, include_groups=False)
                 .reset_index().sort_values("attribute"))
    by_attr_ior = (d.groupby(["attribute", "ior"]).apply(agg, include_groups=False)
                     .reset_index().sort_values(["attribute", "ior"]))
    by_sheet = (d.groupby(["attribute", "sheet", "race", "ior"]).apply(agg, include_groups=False)
                  .reset_index().sort_values(["attribute", "sheet"]))

    print("\n=== GT L* vs fit_table.lab_center.L （每个属性）===")
    print(by_attr[["attribute", "n", "dL_ctr_absmean", "dL_ctr_absmax",
                   f"pass_ctr_{a.tol:g}"]].round(6).to_string(index=False))
    print("\n=== GT L* vs fit_table.lab_values(i_point,1) （每个属性）===")
    print(by_attr[["attribute", "n", "dL_pt_absmean", "dL_pt_absmax",
                   f"pass_pt_{a.tol:g}"]].round(4).to_string(index=False))
    print("\n=== 按 i/r 拆分：|GT - center| 与 |GT - point| ===")
    print(by_attr_ior[["attribute", "ior", "n", "dL_ctr_absmean", "dL_pt_absmean",
                       "dL_pt_absmax"]].round(4).to_string(index=False))

    print("\n=== a*/b* 是否也等于 lab_center ===")
    print(by_attr[["attribute", "da_ctr_absmean", "db_ctr_absmean"]].round(6).to_string(index=False))

    # 场景级别：GT 与 center 完全一致的比例
    sc = (d.groupby(["attribute", "sheet", "scene"])
            .agg(GT_L=("GT_L", "first"), center_L=("center_L", "first"),
                 point_L=("point_L", "mean"))
            .reset_index())
    sc["d_ctr"] = (sc.GT_L - sc.center_L).abs()
    sc["d_pt"] = (sc.GT_L - sc.point_L).abs()
    print(f"\n场景数 = {len(sc)}")
    print(f"  |GT_L - center_L| <= 0.01 的场景比例 : {(sc.d_ctr <= 0.01).mean():.4f}")
    print(f"  |GT_L - point_L | <= 1.00 的场景比例 : {(sc.d_pt <= 1.0).mean():.4f}")
    print(f"  |GT_L - point_L | 中位数            : {sc.d_pt.median():.5f}")
    bad = sc.sort_values("d_pt", ascending=False).head(10)
    print("\n  与 lab_values 差异最大的 10 个场景：")
    print(bad.round(3).to_string(index=False))

    out = Path(a.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    with pd.ExcelWriter(out, engine="openpyxl") as w:
        by_attr.to_excel(w, sheet_name="Summary_by_attribute", index=False)
        by_attr_ior.to_excel(w, sheet_name="Summary_by_attr_ior", index=False)
        by_sheet.to_excel(w, sheet_name="Per_sheet", index=False)
        sc.to_excel(w, sheet_name="Per_scene", index=False)
        d.to_excel(w, sheet_name="Raw_compare", index=False)
    print(f"\nreport -> {out}")


if __name__ == "__main__":
    main()
