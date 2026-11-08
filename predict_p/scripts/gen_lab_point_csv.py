"""把 peggy_fit_lab_long.csv 压成 original_name -> lab_values(i_point,:) 的查表 CSV。

输入 : <peggy>/peggy_fit_lab_long.csv   （由 MATLAB export_peggy.m 生成）
输出 : <out>/lab_point_by_name.csv      （original_name, lab_L, lab_a, lab_b，23100 行）

说明
----
fit_table 是 MATLAB table（MCOS 对象），scipy.io.loadmat 读不了、云端没有 MATLAB，
所以先用本地 MATLAB 展平成长表；本脚本只做去重与改名，纯 pandas。

lab_values 与 attribute 无关（23100 个 (model, scene, i_point) 组合里跨属性取值不同的数量为 0），
所以直接按 original_name 去重即可，不需要区分属性。

用法
----
python predict_p/scripts/gen_lab_point_csv.py \
    --lab-csv /root/autodl-tmp/peggy/peggy_fit_lab_long.csv \
    --out /root/autodl-tmp/peggy/lab_point_by_name.csv \
    --gt-dir /root/autodl-tmp/gt
"""
from __future__ import annotations

import argparse
from pathlib import Path

import pandas as pd


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--lab-csv", default="/root/autodl-tmp/peggy/peggy_fit_lab_long.csv")
    ap.add_argument("--out", default="/root/autodl-tmp/peggy/lab_point_by_name.csv")
    ap.add_argument("--observer", default="non_model")
    ap.add_argument("--gt-dir", default="/root/autodl-tmp/gt",
                    help="用于核对名字覆盖，可省略")
    a = ap.parse_args()

    df = pd.read_csv(a.lab_csv)
    n0 = len(df)
    df = df[df["observer_type"].astype(str).str.strip().str.lower() == a.observer].copy()
    df["original_name"] = (
        df.model_id.astype(str).str.strip().str.lower()
        + df.scene_ior.astype(str).str.strip().str.lower()
        + df.scene_code.astype(str).str.strip().str.lower()
        + "_" + df.i_point.astype(int).map(lambda x: f"{x:02d}")
    )
    out = (df.drop_duplicates("original_name")[["original_name", "L", "a", "b"]]
             .rename(columns={"L": "lab_L", "a": "lab_a", "b": "lab_b"})
             .sort_values("original_name").reset_index(drop=True))

    Path(a.out).parent.mkdir(parents=True, exist_ok=True)
    out.to_csv(a.out, index=False)

    n_nan = int(out[["lab_L", "lab_a", "lab_b"]].isna().any(axis=1).sum())
    print(f"input rows={n0} (observer={a.observer}) -> unique names={len(out)}  NaN={n_nan}")
    print(f"lab_L [{out.lab_L.min():.3f}, {out.lab_L.max():.3f}]  "
          f"lab_a [{out.lab_a.min():.3f}, {out.lab_a.max():.3f}]  "
          f"lab_b [{out.lab_b.min():.3f}, {out.lab_b.max():.3f}]")
    print(f"wrote {a.out}")

    gt_dir = Path(a.gt_dir)
    if gt_dir.is_dir():
        cand = sorted(gt_dir.glob("toMax_gt_01Preference.xlsx")) or sorted(gt_dir.glob("toMax_gt_*.xlsx"))
        if cand:
            xl = pd.ExcelFile(cand[0])
            names = set()
            for sh in xl.sheet_names:
                s = pd.read_excel(xl, sheet_name=sh).iloc[:, 0].astype(str).str.strip()
                names |= set(s)
            mine = set(out.original_name)
            print(f"[check vs {cand[0].name}] GT names={len(names)} mine={len(mine)}  "
                  f"GT-not-in-mine={len(names - mine)}  mine-not-in-GT={len(mine - names)}")
            if names - mine:
                print("  样例:", sorted(names - mine)[:5])
            if mine - names:
                print("  样例:", sorted(mine - names)[:5])


if __name__ == "__main__":
    main()
