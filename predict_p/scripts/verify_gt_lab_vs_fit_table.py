"""验证 toMax_gt_{i}{Attribute}.xlsx 的 L* 是否等于 Peggy_VIVO_table.mat 里
fit_table.lab_values(i_point, 1)（即该 stimulus 采样点本身的 L*）。

对应关系
--------
GT 行名 : {model}{i/r}{scene}_{i_point}    例如 m02ih3k_01
GT sheet: {model}{i/r}                     例如 m02i
fit_table 行筛选条件（4 个 AND）:
    model_id      == {model}      (m01..m10 / f01..f10)
    scene         LIKE '*{scene}'  (如 'inLab h3k' / 'night rs01')
    observer_type == 'non_model'
    attribute     == {attribute}   (Preference / Attractiveness / ...)
取该行的 lab_values(i_point, 1) 作为比对对象（lab_values 是 33x3 double）。

数据来源
--------
fit_table 是 MATLAB table 对象（MCOS），scipy.io.loadmat 读不出来（会得到
MatlabOpaque），所以由 export_peggy_lab_values.m 在 MATLAB 里从
Peggy_VIVO_table.mat 导出成 CSV，本脚本只读 CSV。CSV 列：
    attribute, model_id, observer_type, scene, scene_code, scene_ior,
    i_point, L, a, b
centers CSV（可选，仅作对照）:
    attribute, model_id, observer_type, scene, scene_code, center_L,
    center_a, center_b

用法
----
python predict_p/scripts/verify_gt_lab_vs_fit_table.py \
    --gt-dir /root/autodl-tmp/gt \
    --lab-csv /root/autodl-tmp/deepskin/peggy/peggy_lab_values.csv \
    --center-csv /root/autodl-tmp/deepskin/peggy/peggy_lab_centers.csv \
    --out /root/autodl-tmp/gt/lab_verify_report.xlsx \
    --tol 1.0
"""
from __future__ import annotations

import argparse
import re
from pathlib import Path

import numpy as np
import pandas as pd

SHEET_RE = re.compile(r"^([fm]\d{2})([ir])$", re.IGNORECASE)
ROW_RE = re.compile(r"^[fm]\d{2}[ir]([a-z0-9]+?)_(\d+)$", re.IGNORECASE)
FILE_RE = re.compile(r"^toMax_gt_\d{2}([A-Za-z]+)$")

RACE_OF_MODEL = {}
for _i in range(1, 11):
    _race = "CA" if _i <= 3 else "AS" if _i <= 6 else "SA" if _i <= 8 else "AF"
    RACE_OF_MODEL[f"m{_i:02d}"] = _race
    RACE_OF_MODEL[f"f{_i:02d}"] = _race


def norm_scene(s: str) -> str:
    """把 'inLab h3k' / 'night rs01' 归一成可匹配的 token。"""
    t = str(s).strip().lower()
    t = re.sub(r"^(inlab|outlab|night)\s+", "", t)
    return t.strip()


def ior_of_scene(s: str) -> str:
    t = str(s).strip().lower()
    if t.startswith("inlab"):
        return "i"
    if t.startswith(("night", "outlab")):
        return "r"
    return "?"


def load_lab_long(path: Path) -> pd.DataFrame:
    df = pd.read_csv(path)
    df.columns = [c.strip() for c in df.columns]
    df["attribute"] = df["attribute"].astype(str).str.strip()
    df["model_id"] = df["model_id"].astype(str).str.strip().str.lower()
    df["observer_type"] = df["observer_type"].astype(str).str.strip().str.lower()
    df["scene_code"] = df["scene"].map(norm_scene)
    df["scene_ior"] = df["scene"].map(ior_of_scene)
    df["i_point"] = df["i_point"].astype(int)
    return df


def load_centers(path: Path) -> pd.DataFrame:
    df = pd.read_csv(path)
    df.columns = [c.strip() for c in df.columns]
    df["attribute"] = df["attribute"].astype(str).str.strip()
    df["model_id"] = df["model_id"].astype(str).str.strip().str.lower()
    df["observer_type"] = df["observer_type"].astype(str).str.strip().str.lower()
    df["scene_code"] = df["scene"].map(norm_scene)
    df["scene_ior"] = df["scene"].map(ior_of_scene)
    return df


def collect_gt(gt_dir: Path, only_attr: str | None) -> pd.DataFrame:
    files = sorted(gt_dir.glob("toMax_gt_*.xlsx"))
    if only_attr:
        files = [f for f in files if only_attr.lower() in f.stem.lower()]
    if not files:
        raise SystemExit(f"在 {gt_dir} 下没找到 toMax_gt_*.xlsx")

    recs = []
    for f in files:
        m = FILE_RE.match(f.stem)
        attr = m.group(1) if m else f.stem
        xl = pd.ExcelFile(f)
        for sheet in xl.sheet_names:
            sm = SHEET_RE.match(str(sheet).strip())
            if not sm:
                continue
            model, ior = sm.group(1).lower(), sm.group(2).lower()
            df = pd.read_excel(xl, sheet_name=sheet)
            cols = [str(c).strip().replace(" ", "") for c in df.columns]
            if "L*" not in cols:
                continue
            iL = cols.index("L*")
            ia = cols.index("a*") if "a*" in cols else None
            ib = cols.index("b*") if "b*" in cols else None
            isc = cols.index("preference_score") if "preference_score" in cols else None
            for row in df.itertuples(index=False, name=None):
                name = str(row[0]).strip()
                rm = ROW_RE.match(name)
                if not rm:
                    continue
                recs.append({
                    "attribute": attr, "sheet": str(sheet).strip(), "race": RACE_OF_MODEL.get(model, "?"),
                    "model_id": model, "ior": ior, "scene": rm.group(1).lower(),
                    "i_point": int(rm.group(2)), "original_name": name,
                    "GT_L": float(row[iL]),
                    "GT_a": float(row[ia]) if ia is not None and pd.notna(row[ia]) else np.nan,
                    "GT_b": float(row[ib]) if ib is not None and pd.notna(row[ib]) else np.nan,
                    "GT_score": float(row[isc]) if isc is not None and pd.notna(row[isc]) else np.nan,
                })
    return pd.DataFrame(recs)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--gt-dir", default="/root/autodl-tmp/gt")
    ap.add_argument("--lab-csv", default="/root/autodl-tmp/deepskin/peggy/peggy_lab_values.csv")
    ap.add_argument("--center-csv", default="/root/autodl-tmp/deepskin/peggy/peggy_lab_centers.csv")
    ap.add_argument("--out", default="/root/autodl-tmp/gt/lab_verify_report.xlsx")
    ap.add_argument("--tol", type=float, default=1.0, help="判定 '大体相等' 的 |dL| 阈值")
    ap.add_argument("--attr", default=None, help="只验证某个属性文件，如 01Preference")
    ap.add_argument("--model", default=None, help="只验证某个 model，如 m02")
    a = ap.parse_args()

    gt_dir = Path(a.gt_dir)
    print(f"[1/4] 读取 GT: {gt_dir}")
    gt = collect_gt(gt_dir, a.attr)
    if a.model:
        gt = gt[gt.model_id == a.model.lower()]
    print(f"      GT 行数 = {len(gt)}，sheet 数 = {gt.sheet.nunique()}，属性数 = {gt.attribute.nunique()}")

    print(f"[2/4] 读取 fit_table lab_values: {a.lab_csv}")
    lab = load_lab_long(Path(a.lab_csv))
    lab = lab[lab.observer_type == "non_model"]
    print(f"      lab_values 行数 = {len(lab)}（observer_type=non_model）")

    cen = None
    if a.center_csv and Path(a.center_csv).exists():
        print(f"      读取 lab_center（对照）: {a.center_csv}")
        cen = load_centers(Path(a.center_csv))
        cen = cen[cen.observer_type == "non_model"]

    print("[3/4] 按 (attribute, model_id, scene, i_point) 匹配 ...")
    key = ["attribute", "model_id", "scene", "i_point"]
    lab_k = lab[["attribute", "model_id", "scene_code", "i_point", "scene_ior", "L", "a", "b"]].rename(
        columns={"scene_code": "scene", "L": "point_L", "a": "point_a", "b": "point_b"})
    lab_k = lab_k.drop_duplicates(subset=key)
    d = gt.merge(lab_k, on=key, how="left", suffixes=("", "_lab"))
    # 只保留 i/r 一致的匹配（防止同 token 跨实景/实验室误配）
    d = d[(d.scene_ior.isna()) | (d.scene_ior == d.ior)]

    if cen is not None:
        cen_k = cen[["attribute", "model_id", "scene_code", "center_L", "center_a", "center_b"]].rename(
            columns={"scene_code": "scene"})
        d = d.merge(cen_k, on=["attribute", "model_id", "scene"], how="left")

    n_miss = int(d.point_L.isna().sum()) if "point_L" in d else len(d)
    print(f"      匹配成功 {len(d) - n_miss} / {len(d)} 行；未匹配 {n_miss} 行")
    if n_miss:
        bad = d[d.point_L.isna()].head(10)
        print("      未匹配样例：")
        print(bad[["attribute", "sheet", "original_name", "scene", "i_point"]].to_string(index=False))

    d = d[d.point_L.notna()].copy()
    if d.empty:
        raise SystemExit("没有可比对的行，检查 --lab-csv 与 GT 行名格式")

    d["dL_point"] = d.GT_L - d.point_L
    d["da_point"] = d.GT_a - d.point_a
    d["db_point"] = d.GT_b - d.point_b
    d["abs_dL"] = d.dL_point.abs()
    d["pass_point"] = d.abs_dL <= a.tol
    if "center_L" in d:
        d["dL_center"] = d.GT_L - d.center_L
        d["abs_dL_center"] = d.dL_center.abs()
        d["pass_center"] = d.abs_dL_center <= a.tol

    def agg(g: pd.DataFrame) -> pd.Series:
        out = {
            "n": len(g),
            "absdL_point_mean": g.abs_dL.mean(),
            "absdL_point_median": g.abs_dL.median(),
            "absdL_point_p90": g.abs_dL.quantile(0.90),
            "absdL_point_max": g.abs_dL.max(),
            f"pass_point_{a.tol:g}": g.pass_point.mean(),
        }
        if "abs_dL_center" in g:
            out.update({
                "absdL_center_mean": g.abs_dL_center.mean(),
                f"pass_center_{a.tol:g}": g.pass_center.mean(),
            })
        return pd.Series(out)

    by_attr = d.groupby("attribute").apply(agg, include_groups=False).reset_index()
    by_attr_ior = d.groupby(["attribute", "ior"]).apply(agg, include_groups=False).reset_index()
    by_sheet = (d.groupby(["attribute", "sheet", "race", "ior", "model_id"])
                 .apply(agg, include_groups=False).reset_index()
                 .sort_values(["attribute", "sheet"]))

    scene = (d.groupby(["attribute", "sheet", "scene", "model_id", "ior"])
              .agg(n_row=("abs_dL", "size"),
                   GT_L=("GT_L", "first"),
                   point_L_mean=("point_L", "mean"),
                   point_L_min=("point_L", "min"),
                   point_L_max=("point_L", "max"),
                   absdL_mean=("abs_dL", "mean"),
                   absdL_max=("abs_dL", "max"),
                   pass_frac=("pass_point", "mean"))
              .reset_index())
    scene["dif_span"] = scene.point_L_max - scene.point_L_min

    worst = d.sort_values("abs_dL", ascending=False).head(50)

    print("\n=== 每个属性：|GT_L - lab_values(i_point,1)| ===")
    cols = ["attribute", "n", "absdL_point_mean", "absdL_point_median",
            "absdL_point_p90", "absdL_point_max", f"pass_point_{a.tol:g}"]
    if "absdL_center_mean" in by_attr:
        cols += ["absdL_center_mean", f"pass_center_{a.tol:g}"]
    print(by_attr[cols].round(4).to_string(index=False))

    print("\n=== 按 i/r 拆分 ===")
    cols2 = ["attribute", "ior", "n", "absdL_point_mean", "absdL_point_p90",
             "absdL_point_max", f"pass_point_{a.tol:g}"]
    print(by_attr_ior[cols2].round(4).to_string(index=False))

    print(f"\n=== 场景级（共 {len(scene)} 个 scene×sheet×attr）===")
    print(f"  场景内 33 点 L* 极差 mean = {scene.dif_span.mean():.4f}, max = {scene.dif_span.max():.4f}")
    print(f"  |dL| 场景均值 <= {a.tol:g} 的占比 : {(scene.absdL_mean <= a.tol).mean():.4f}")
    print(f"  |dL| 场景最大 <= {a.tol:g} 的占比 : {(scene.absdL_max <= a.tol).mean():.4f}")
    print(f"  |dL| 全局中位数 : {d.abs_dL.median():.4f}")
    print("\n  差异最大的 10 个场景：")
    print(scene.sort_values("absdL_max", ascending=False).head(10)[
        ["attribute", "sheet", "scene", "GT_L", "point_L_mean", "absdL_mean", "absdL_max"]
    ].round(3).to_string(index=False))

    out = Path(a.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    with pd.ExcelWriter(out, engine="openpyxl") as w:
        by_attr.to_excel(w, sheet_name="Summary_by_attribute", index=False)
        by_attr_ior.to_excel(w, sheet_name="Summary_by_attr_ior", index=False)
        by_sheet.to_excel(w, sheet_name="Per_sheet", index=False)
        scene.to_excel(w, sheet_name="Per_scene", index=False)
        worst.to_excel(w, sheet_name="Worst50_rows", index=False)
        pd.DataFrame([{
            "gt_dir": str(gt_dir), "lab_csv": str(a.lab_csv),
            "n_gt_rows": int(len(gt)), "n_matched": int(len(d)),
            "n_unmatched": int(n_miss), "tol": a.tol,
            "absdL_mean": float(d.abs_dL.mean()),
            "absdL_median": float(d.abs_dL.median()),
            "absdL_p90": float(d.abs_dL.quantile(0.90)),
            "pass_frac": float(d.pass_point.mean()),
        }]).to_excel(w, sheet_name="Meta", index=False)
    print(f"\n报告 -> {out}")


if __name__ == "__main__":
    main()
