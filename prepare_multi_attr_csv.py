"""
prepare_multi_attr_csv.py - 从 toMax_gt_{attr}.xlsx 生成 multi-head 训练用的 meta_info CSV

用法: python prepare_multi_attr_csv.py --race SA --output datasets/deepskin_multi/
"""
import os, argparse, pandas as pd, numpy as np
from pathlib import Path

GT_DIR = "/root/autodl-tmp/gt"
IMAGE_ROOT = "/root/autodl-tmp/rendered_2max"
EXISTING_CSV = "/root/autodl-tmp/iqa_pytorch_train/datasets/deepskin/{race}/meta_info.csv"

_ALL_ATTRIBUTES = [
    "01Preference", "02Attractiveness", "03Feminine",
    "04Cooperative", "05Youth", "06Healthy",
    "07Fidelity", "08Harmony", "09Fair", "10Ruddy",
]


def load_attribute_gt(attr_name: str) -> dict:
    """从 toMax_gt_{attr_name}.xlsx 加载 {original_name: score}"""
    xlsx_path = os.path.join(GT_DIR, f"toMax_gt_{attr_name}.xlsx")
    if not os.path.exists(xlsx_path):
        print(f"  [WARN] Missing: {xlsx_path}")
        return {}
    lookup = {}
    try:
        xl = pd.ExcelFile(xlsx_path)
        for sheet in xl.sheet_names:
            df = pd.read_excel(xl, sheet_name=sheet)
            for _, row in df.iterrows():
                oname = str(row.iloc[0])
                score = float(row.iloc[1])
                if np.isfinite(score):
                    lookup[oname] = score
    except Exception as e:
        print(f"  [ERROR] {attr_name}: {e}")
    return lookup


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--race", required=True, choices=["SA","CA","AS","AF"])
    parser.add_argument("--output", default=None)
    args = parser.parse_args()
    race = args.race
    out_dir = args.output or f"datasets/deepskin_multi/{race}"
    os.makedirs(out_dir, exist_ok=True)

    # 1. 读取现有 meta_info.csv 获取图像列表和 split
    csv_path = EXISTING_CSV.format(race=race)
    if not os.path.exists(csv_path):
        print(f"[ERROR] Not found: {csv_path}")
        return
    meta = pd.read_csv(csv_path)
    print(f"[INFO] Loaded {len(meta)} rows from {csv_path}")

    # 2. 加载所有 10 个属性的 GT
    print("[INFO] Loading 10 attribute GTs...")
    attr_gts = {}
    for attr in _ALL_ATTRIBUTES:
        attr_gts[attr] = load_attribute_gt(attr)
        print(f"  {attr}: {len(attr_gts[attr])} entries")

    # 3. 为每个图像填充属性值
    attr_cols = []
    mask_cols = []
    for attr in _ALL_ATTRIBUTES:
        attr_cols.append(f"attr_{attr}")
        mask_cols.append(f"mask_{attr}")

    # 从 name 列提取 original_name (去掉路径前缀和后缀)
    # name 格式: "f07i/f07ih3k_01.jpg"
    def extract_oname(path):
        fname = os.path.basename(str(path))
        return os.path.splitext(fname)[0]

    for attr_col in attr_cols:
        meta[attr_col] = np.nan
    for mask_col in mask_cols:
        meta[mask_col] = 0

    nan_count = 0
    for idx, row in meta.iterrows():
        oname = extract_oname(row["name"])
        all_valid = True
        for attr in _ALL_ATTRIBUTES:
            val = attr_gts[attr].get(oname, np.nan)
            if np.isfinite(val):
                meta.at[idx, f"attr_{attr}"] = val
                meta.at[idx, f"mask_{attr}"] = 1
            else:
                meta.at[idx, f"attr_{attr}"] = 0.0
                meta.at[idx, f"mask_{attr}"] = 0
                all_valid = False
        if not all_valid:
            nan_count += 1

    # 4. 保存
    out_path = os.path.join(out_dir, "meta_info.csv")
    meta.to_csv(out_path, index=False)
    print(f"[DONE] Saved {len(meta)} rows to {out_path}")
    print(f"  NaN samples (at least one attribute missing): {nan_count}/{len(meta)}")


if __name__ == "__main__":
    main()
