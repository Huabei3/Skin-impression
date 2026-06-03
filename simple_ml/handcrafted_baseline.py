"""
简单机器学习基线方法：SVR / 线性回归 + hand-crafted 特征

特征工程：
  - 皮肤区域的 L*a*b* 均值、标准差、中位数、分位数
  - C*ab = sqrt(a*^2 + b*^2)  色度
  - h_ab = atan2(b*, a*)      色相角
  - ITA° 肤色分类指数

用法（在云实例上）:
  cd /root/autodl-tmp/deepskin
  python simple_ml/handcrafted_baseline.py \
      --face-root /root/autodl-tmp/rendered_face \
      --gt-excel /root/autodl-tmp/gt/toMax_gt_01Preference.xlsx \
      --output-dir /root/autodl-tmp/deepskin/simple_ml/output \
      --race SA
"""

from __future__ import annotations

import argparse
import json
import logging
import os
import warnings
from pathlib import Path
from typing import Dict, List, Tuple

import numpy as np
import pandas as pd
from PIL import Image
from sklearn.linear_model import LinearRegression, Ridge
from sklearn.svm import SVR
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import KFold
from sklearn.metrics import mean_absolute_error
from scipy.stats import pearsonr
from tqdm import tqdm

warnings.filterwarnings("ignore")
logger = logging.getLogger(__name__)

# ============================================================
# 数据加载（复用 deepskin 的 dataset 逻辑但只取 GT 信息）
# ============================================================

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
    """从 GT Excel 加载所有样本的元数据。"""
    xl = pd.ExcelFile(gt_path)
    items = []
    for sheet in xl.sheet_names:
        df = xl.parse(sheet)
        for _, row in df.iterrows():
            name = str(row.iloc[0])
            score = float(row.iloc[1])
            if pd.isna(score) or np.isinf(score):
                continue
            L_val = float(row.iloc[2]) if len(row) > 2 and not pd.isna(row.iloc[2]) else 50.0
            a_val = float(row.iloc[3]) if len(row) > 3 and not pd.isna(row.iloc[3]) else 0.0
            b_val = float(row.iloc[4]) if len(row) > 4 and not pd.isna(row.iloc[4]) else 0.0
            items.append({
                "original_name": name,
                "preference_score": score,
                "preference_L": L_val,
                "preference_center": (a_val, b_val),
                "scene_person": sheet,
            })
    return items


def split_by_race(items: List[Dict], race: str) -> Tuple[List[Dict], List[Dict], List[Dict]]:
    """按人种划分 train/val/test。"""
    rc = _RACE_CONFIG[race]
    test_male = rc["test_male"]
    valid_f_r = set(rc["valid_f_r"])
    model_ids = set(rc["model_ids"])

    # 构建 test 前缀
    test_prefixes = set()
    for s in _I_SCENES:
        test_prefixes.add(f"{test_male}i{s}")
    for s in _R_SCENES:
        test_prefixes.add(f"{test_male}r{s}")

    train, val, test = [], [], []

    for item in items:
        name = item["original_name"]
        prefix = name.rsplit("_", 1)[0] if "_" in name else name

        # 检查 model_id 是否在范围内
        model_id = name[:2] if len(name) >= 2 else ""
        if model_id not in model_ids:
            # 允许 mXX 开头
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
# 特征提取
# ============================================================

def extract_lab_features_from_image(image_path: str) -> Dict[str, float]:
    """从单张图像提取 L*a*b* 统计特征。"""
    img = Image.open(image_path).convert("RGB")
    arr = np.array(img, dtype=np.float32) / 255.0

    # RGB → XYZ → LAB (使用标准 D65 illuminant)
    # 简化版 sRGB → LAB
    lab = rgb_to_lab(arr)

    L = lab[:, :, 0].flatten()
    a = lab[:, :, 1].flatten()
    b = lab[:, :, 2].flatten()
    Cab = np.sqrt(a ** 2 + b ** 2)
    hab = np.arctan2(b, a)  # 弧度

    # ITA° (Individual Typology Angle)
    # ITA° = arctan((L* - 50) / b*) * 180/pi
    L_mean = np.mean(L)
    b_mean = np.mean(b)
    ITA = np.degrees(np.arctan2(L_mean - 50.0, b_mean + 1e-8))

    feats = {
        "L_mean": float(np.mean(L)),
        "L_std": float(np.std(L)),
        "L_median": float(np.median(L)),
        "L_p25": float(np.percentile(L, 25)),
        "L_p75": float(np.percentile(L, 75)),
        "a_mean": float(np.mean(a)),
        "a_std": float(np.std(a)),
        "a_median": float(np.median(a)),
        "a_p25": float(np.percentile(a, 25)),
        "a_p75": float(np.percentile(a, 75)),
        "b_mean": float(np.mean(b)),
        "b_std": float(np.std(b)),
        "b_median": float(np.median(b)),
        "b_p25": float(np.percentile(b, 25)),
        "b_p75": float(np.percentile(b, 75)),
        "Cab_mean": float(np.mean(Cab)),
        "Cab_std": float(np.std(Cab)),
        "hab_mean": float(np.mean(hab)),
        "ITA": float(ITA),
        # GT 给出的 preference_center 也会在 build_dataset 中加入
    }
    return feats


def rgb_to_lab(rgb: np.ndarray) -> np.ndarray:
    """sRGB → CIE L*a*b* (D65). 向量化实现。"""
    # sRGB → linear RGB
    mask = rgb > 0.04045
    rgb_lin = np.where(mask, ((rgb + 0.055) / 1.055) ** 2.4, rgb / 12.92)

    # linear RGB → XYZ (D65)
    M = np.array([
        [0.4124564, 0.3575761, 0.1804375],
        [0.2126729, 0.7151522, 0.0721750],
        [0.0193339, 0.1191920, 0.9503041],
    ])
    xyz = rgb_lin @ M.T

    # XYZ → LAB
    ref = np.array([0.95047, 1.0, 1.08883])  # D65 reference
    xyz_norm = xyz / ref
    delta = 6.0 / 29.0
    delta3 = delta ** 3

    def f(t):
        return np.where(t > delta3, np.cbrt(t), t / (3 * delta ** 2) + 4.0 / 29.0)

    fx = f(xyz_norm[:, :, 0])
    fy = f(xyz_norm[:, :, 1])
    fz = f(xyz_norm[:, :, 2])

    L = 116.0 * fy - 16.0
    a = 500.0 * (fx - fy)
    b = 200.0 * (fy - fz)
    return np.stack([L, a, b], axis=-1)


# ============================================================
# 特征构建
# ============================================================

def build_feature_matrix(
    items: List[Dict],
    face_root: str,
    cache_path: str = None,
) -> Tuple[np.ndarray, np.ndarray]:
    """
    构建特征矩阵 X 和目标向量 y。
    支持缓存以避免重复计算。
    """
    if cache_path and os.path.exists(cache_path):
        logger.info(f"Loading cached features from {cache_path}")
        data = np.load(cache_path)
        return data["X"], data["y"]

    X_list, y_list = [], []
    for item in tqdm(items, desc="Extracting features"):
        name = item["original_name"]
        # 图像路径: rendered_face/{prefix}/{name}_face.jpg
        prefix = name[:4]  # e.g. f01r, m08i
        img_path = os.path.join(face_root, prefix, f"{name}_face.jpg")
        if not os.path.exists(img_path):
            continue

        try:
            lab_feats = extract_lab_features_from_image(img_path)
        except Exception as e:
            logger.warning(f"Failed to extract features from {img_path}: {e}")
            continue

        # 加入 GT 中已有的 L* 和 preference_center
        lab_feats["preference_L"] = item["preference_L"]
        lab_feats["preference_a"] = item["preference_center"][0]
        lab_feats["preference_b"] = item["preference_center"][1]

        X_list.append(list(lab_feats.values()))
        y_list.append(item["preference_score"])

    X = np.array(X_list, dtype=np.float32)
    y = np.array(y_list, dtype=np.float32)

    if cache_path:
        os.makedirs(os.path.dirname(cache_path) or ".", exist_ok=True)
        np.savez_compressed(cache_path, X=X, y=y)
        logger.info(f"Features cached to {cache_path}")

    return X, y


def get_feature_names() -> List[str]:
    """返回特征名称列表（与 extract_lab_features_from_image 顺序一致）。"""
    return [
        "L_mean", "L_std", "L_median", "L_p25", "L_p75",
        "a_mean", "a_std", "a_median", "a_p25", "a_p75",
        "b_mean", "b_std", "b_median", "b_p25", "b_p75",
        "Cab_mean", "Cab_std", "hab_mean", "ITA",
        "preference_L", "preference_a", "preference_b",
    ]


# ============================================================
# 训练 & 评估
# ============================================================

def evaluate_model(
    model,
    X_train: np.ndarray,
    y_train: np.ndarray,
    X_val: np.ndarray,
    y_val: np.ndarray,
    X_test: np.ndarray,
    y_test: np.ndarray,
    model_name: str,
    normalize: bool = True,
) -> Dict:
    """训练 + 评估。"""
    if normalize:
        scaler = StandardScaler()
        X_train = scaler.fit_transform(X_train)
        X_val = scaler.transform(X_val)
        X_test = scaler.transform(X_test)

    model.fit(X_train, y_train)

    def compute_metrics(X, y, tag):
        pred = model.predict(X).flatten()
        mae = mean_absolute_error(y, pred)
        if len(y) > 1:
            r, p = pearsonr(y, pred)
        else:
            r, p = float("nan"), float("nan")
        return {"mae": mae, "pearson_r": r, "pearson_p": p, "tag": tag}

    train_m = compute_metrics(X_train, y_train, "train")
    val_m = compute_metrics(X_val, y_val, "val")
    test_m = compute_metrics(X_test, y_test, "test")

    return {
        "model": model_name,
        "normalize": normalize,
        "train": train_m,
        "val": val_m,
        "test": test_m,
    }


# ============================================================
# Main
# ============================================================

def main():
    parser = argparse.ArgumentParser(description="Handcrafted feature baseline (SVR / Linear)")
    parser.add_argument("--face-root", type=str, required=True, help="rendered_face root")
    parser.add_argument("--gt-excel", type=str, required=True, help="GT Excel path")
    parser.add_argument("--output-dir", type=str, default="./simple_ml/output", help="Output directory")
    parser.add_argument("--race", type=str, choices=["CA", "AS", "SA", "AF"], required=True)
    parser.add_argument("--cache-dir", type=str, default="./simple_ml/cache", help="Feature cache dir")
    args = parser.parse_args()

    logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
    os.makedirs(args.output_dir, exist_ok=True)

    # 1. 加载数据
    logger.info(f"Loading GT from {args.gt_excel}")
    items = load_gt(args.gt_excel)
    logger.info(f"Total items: {len(items)}")

    # 2. 按人种划分
    train_items, val_items, test_items = split_by_race(items, args.race)
    logger.info(f"Race={args.race}: train={len(train_items)}, val={len(val_items)}, test={len(test_items)}")

    # 3. 提取特征
    os.makedirs(args.cache_dir, exist_ok=True)
    X_train, y_train = build_feature_matrix(
        train_items, args.face_root,
        cache_path=os.path.join(args.cache_dir, f"feats_{args.race}_train.npz"),
    )
    X_val, y_val = build_feature_matrix(
        val_items, args.face_root,
        cache_path=os.path.join(args.cache_dir, f"feats_{args.race}_val.npz"),
    )
    X_test, y_test = build_feature_matrix(
        test_items, args.face_root,
        cache_path=os.path.join(args.cache_dir, f"feats_{args.race}_test.npz"),
    )
    logger.info(f"Feature dims: train={X_train.shape}, val={X_val.shape}, test={X_test.shape}")

    # 4. 训练多个模型
    models = [
        ("LinearRegression", LinearRegression()),
        ("Ridge(alpha=1.0)", Ridge(alpha=1.0)),
        ("Ridge(alpha=10.0)", Ridge(alpha=10.0)),
        ("SVR(RBF)", SVR(kernel="rbf", C=1.0, gamma="scale")),
        ("SVR(RBF,C=10)", SVR(kernel="rbf", C=10.0, gamma="scale")),
        ("SVR(Poly,deg=2)", SVR(kernel="poly", degree=2, C=1.0)),
        ("SVR(Linear)", SVR(kernel="linear", C=1.0)),
    ]

    results = []
    for name, model in models:
        logger.info(f"Training {name}...")
        try:
            r = evaluate_model(model, X_train, y_train, X_val, y_val, X_test, y_test, name)
            results.append(r)
            logger.info(f"  {name}: test MAE={r['test']['mae']:.4f}, Pearson r={r['test']['pearson_r']:.4f}")
        except Exception as e:
            logger.error(f"  {name} FAILED: {e}")

    # 5. 保存结果
    output_path = os.path.join(args.output_dir, f"baseline_{args.race}.json")
    # 转换为可序列化格式
    serializable = []
    for r in results:
        serializable.append({
            k: v if k != "train" and k != "val" and k != "test" else {
                kk: float(vv) if isinstance(vv, (np.floating, float)) else vv
                for kk, vv in v.items()
            }
            for k, v in r.items()
        })

    with open(output_path, "w") as f:
        json.dump(serializable, f, indent=2, ensure_ascii=False)
    logger.info(f"Results saved to {output_path}")

    # 6. 打印汇总
    print("\n" + "=" * 70)
    print(f"  Handcrafted Baseline Results - Race: {args.race}")
    print("=" * 70)
    print(f"  {'Model':<22} {'Test MAE':>10} {'Test Pearson r':>14}")
    print(f"  {'-'*50}")
    for r in results:
        print(f"  {r['model']:<22} {r['test']['mae']:>10.4f} {r['test']['pearson_r']:>14.4f}")
    print("=" * 70)


if __name__ == "__main__":
    main()
