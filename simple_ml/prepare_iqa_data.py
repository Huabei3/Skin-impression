"""
为外部 IQA 项目准备数据 —— 从 deepskin 数据集中导出图像和 CSV 标注文件。

支持的输出格式：
  1. HyperIQA:  images/ + train.csv / test.csv (含图像路径 + 分数)
  2. DN-PIQA:   按 NTIRE24 格式组织（Overall 场景级）
  3. SCUT-FBP5500: 直接使用数据库

用法（在云实例上）:
  python simple_ml/prepare_iqa_data.py \
      --face-root /root/autodl-tmp/rendered_face \
      --global-root /root/autodl-tmp/rendered_2max \
      --gt-excel /root/autodl-tmp/gt/toMax_gt_01Preference.xlsx \
      --output-dir /root/autodl-tmp/iqa_prepared \
      --format hyperiqa \
      --race SA
"""

from __future__ import annotations

import argparse
import logging
import os
import shutil
from pathlib import Path
from typing import Dict, List, Tuple

import pandas as pd
import numpy as np
from tqdm import tqdm

logger = logging.getLogger(__name__)

_I_SCENES = ["h3k", "h4k", "h5k", "h6k", "h7k", "h8k", "hd65",
             "l3k", "l4k", "l5k", "l6k", "l7k", "l8k", "ld65",
             "m3k", "m4k", "m5k", "m6k", "m7k", "m8k", "md65"]
_R_SCENES = [f"rs{s:02d}" for s in range(1, 15)]

_RACE_CONFIG = {
    "CA": {"test_male": "m02", "valid_f_r": ["f02rrs02", "f02rrs04"], "model_ids": ["01", "02", "03"]},
    "AS": {"test_male": "m05", "valid_f_r": ["f05rrs02", "f05rrs04"], "model_ids": ["04", "05", "06"]},
    "SA": {"test_male": "m08", "valid_f_r": ["f08rrs02", "f08rrs04"], "model_ids": ["07", "08"]},
    "AF": {"test_male": "m09", "valid_f_r": ["f09rrs02", "f09rrs04"], "model_ids": ["09", "10"]},
}


def load_gt(gt_path: str) -> List[Dict]:
    """加载 GT Excel。"""
    xl = pd.ExcelFile(gt_path)
    items = []
    for sheet in xl.sheet_names:
        df = xl.parse(sheet)
        for _, row in df.iterrows():
            name = str(row.iloc[0])
            score = float(row.iloc[1])
            if pd.isna(score) or np.isinf(score):
                continue
            items.append({
                "original_name": name,
                "preference_score": score,
                "scene_person": sheet,
            })
    return items


def split_by_race(items: List[Dict], race: str) -> Tuple[List[Dict], List[Dict], List[Dict]]:
    """按人种划分。"""
    rc = _RACE_CONFIG[race]
    test_male = rc["test_male"]
    valid_f_r = set(rc["valid_f_r"])
    model_ids = set(rc["model_ids"])

    test_prefixes = set()
    for s in _I_SCENES:
        test_prefixes.add(f"{test_male}i{s}")
    for s in _R_SCENES:
        test_prefixes.add(f"{test_male}r{s}")

    train, val, test = [], [], []
    for item in items:
        name = item["original_name"]
        prefix = name.rsplit("_", 1)[0] if "_" in name else name
        model_id = name[:2]
        if model_id not in model_ids:
            if len(name) >= 3 and name[0] == "m":
                model_id = name[1:3]
            if model_id not in model_ids:
                continue
        if prefix in test_prefixes:
            test.append(item)
        elif prefix in valid_f_r:
            val.append(item)
        else:
            train.append(item)
    return train, val, test


# ============================================================
# HyperIQA 格式
# ============================================================

def prepare_hyperiqa(
    items: List[Dict],
    face_root: str,
    global_root: str,
    output_dir: str,
    tag: str,
    use_global: bool = False,
) -> str:
    """
    HyperIQA 格式:
      output_dir/
        images/  (symlink or copy)
        {tag}.csv  (image_name, score)

    如果 use_global=True，使用全局图像；否则使用人脸图像。
    """
    out = Path(output_dir)
    out.mkdir(parents=True, exist_ok=True)
    img_dir = out / "images"
    img_dir.mkdir(parents=True, exist_ok=True)

    root = global_root if use_global else face_root
    suffix = ".jpg" if use_global else "_face.jpg"

    csv_rows = []
    for item in tqdm(items, desc=f"Preparing {tag}"):
        name = item["original_name"]
        prefix = name[:4]
        src = os.path.join(root, prefix, f"{name}{suffix}")
        dst = os.path.join(str(img_dir), f"{name}{suffix}")

        if not os.path.exists(src):
            logger.warning(f"Image not found: {src}")
            continue

        if not os.path.exists(dst):
            os.symlink(src, dst) if hasattr(os, "symlink") else shutil.copy2(src, dst)

        csv_rows.append({"image_name": f"{name}{suffix}", "score": item["preference_score"]})

    csv_path = str(out / f"{tag}.csv")
    pd.DataFrame(csv_rows).to_csv(csv_path, index=False)
    logger.info(f"  {tag}: {len(csv_rows)} samples -> {csv_path}")
    return csv_path


# ============================================================
# DN-PIQA / NTIRE24 格式
# ============================================================

def prepare_dnpiqa(
    train_items: List[Dict],
    test_items: List[Dict],
    face_root: str,
    output_dir: str,
) -> Tuple[str, str]:
    """
    DN-PIQA 使用的 NTIRE24 格式:
      database_dir/
        Overall/
          train/
            {scene_name}/
              {image_name}_face.jpg
          test/
            {scene_name}/
              {image_name}_face.jpg
      csvfiles/
        train.csv  (image_path, score)
        test.csv   (image_path, score)
    """
    out = Path(output_dir)
    out.mkdir(parents=True, exist_ok=True)

    csv_dir = out / "csvfiles"
    csv_dir.mkdir(parents=True, exist_ok=True)

    def _copy_images(items, subset, tag):
        rows = []
        for item in tqdm(items, desc=f"DN-PIQA {tag}"):
            name = item["original_name"]
            prefix = name[:4]
            scene = item["scene_person"]
            src = os.path.join(face_root, prefix, f"{name}_face.jpg")
            if not os.path.exists(src):
                logger.warning(f"Image not found: {src}")
                continue

            # 按场景组织
            scene_dir = out / tag / scene
            scene_dir.mkdir(parents=True, exist_ok=True)
            dst = str(scene_dir / f"{name}_face.jpg")
            if not os.path.exists(dst):
                shutil.copy2(src, dst)

            rel_path = f"{tag}/{scene}/{name}_face.jpg"
            rows.append({"image_path": rel_path, "score": item["preference_score"]})

        csv_path = str(csv_dir / f"{tag}.csv")
        pd.DataFrame(rows).to_csv(csv_path, index=False)
        logger.info(f"  DN-PIQA {tag}: {len(rows)} samples -> {csv_path}")
        return csv_path

    train_csv = _copy_images(train_items, "Overall", "train")
    test_csv = _copy_images(test_items, "Overall", "test")
    return train_csv, test_csv


# ============================================================
# Main
# ============================================================

def main():
    parser = argparse.ArgumentParser(description="Prepare data for external IQA projects")
    parser.add_argument("--face-root", type=str, required=True)
    parser.add_argument("--global-root", type=str, default=None)
    parser.add_argument("--gt-excel", type=str, required=True)
    parser.add_argument("--output-dir", type=str, required=True)
    parser.add_argument("--format", type=str, choices=["hyperiqa", "dnpiqa"], default="hyperiqa")
    parser.add_argument("--race", type=str, choices=["CA", "AS", "SA", "AF"], required=True)
    parser.add_argument("--use-global", action="store_true", help="Use global images instead of face crops")
    args = parser.parse_args()

    logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

    items = load_gt(args.gt_excel)
    logger.info(f"Loaded {len(items)} total items")

    train_items, val_items, test_items = split_by_race(items, args.race)
    logger.info(f"Race={args.race}: train={len(train_items)}, val={len(val_items)}, test={len(test_items)}")

    if args.format == "hyperiqa":
        out = Path(args.output_dir) / "hyperIQA"
        for tag, items_subset in [("train", train_items), ("val", val_items), ("test", test_items)]:
            prepare_hyperiqa(
                items_subset,
                args.face_root,
                args.global_root or args.face_root,
                str(out),
                tag,
                use_global=bool(args.use_global),
            )
    elif args.format == "dnpiqa":
        out = Path(args.output_dir) / "dnpiqa"
        prepare_dnpiqa(train_items, test_items, args.face_root, str(out))

    logger.info("Done!")


if __name__ == "__main__":
    main()
