#!/usr/bin/env python3
"""
批量处理多个 toMax 场景的数据准备脚本
支持处理 f01i, f02i, f03i, m01i, m02i 等多个场景

使用方法:
    python prepare_tomax_batch.py --scenes f01i f02i f03i m01i m02i
    或
    python prepare_tomax_batch.py --priority  # 只处理优先级场景
"""

import os
import re
import sys
import json
import argparse
import urllib.request
from pathlib import Path
from typing import Dict, List, Optional, Tuple
import logging

import numpy as np
import pandas as pd
import cv2
from PIL import Image

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# ========================== 配置 ==========================

# 源数据根目录
SRC_ROOT_BASE = Path("/root/autodl-tmp/toMax_deepskin/rendered_2max")

# 输出根目录
DST_ROOT = Path("/root/autodl-tmp/toMax_deepskin")

# 使用 Haar Cascade 进行人脸检测（OpenCV 内置，无需下载）
USE_HAAR_CASCADE = True

CENTER_CROP_MARGIN = 0.15

# ========================== 工具函数 ==========================

def build_face_detector():
    """初始化 Haar Cascade 人脸检测器（OpenCV 内置）"""
    # 使用 OpenCV 内置的 Haar Cascade
    cascade_path = cv2.data.haarcascades + 'haarcascade_frontalface_default.xml'
    face_cascade = cv2.CascadeClassifier(cascade_path)
    if face_cascade.empty():
        logger.error("Failed to load Haar Cascade")
        sys.exit(1)
    return face_cascade


def detect_face(face_cascade, image_path: Path) -> Tuple[int, int, int, int]:
    """
    使用 Haar Cascade 检测人脸 bbox，失败则使用中心裁剪
    返回 (x1, y1, x2, y2)
    """
    img = cv2.imread(str(image_path))
    if img is None:
        raise ValueError(f"Cannot read image: {image_path}")
    h, w = img.shape[:2]

    # 转换为灰度图
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    # 检测人脸
    faces = face_cascade.detectMultiScale(
        gray,
        scaleFactor=1.1,
        minNeighbors=5,
        minSize=(30, 30)
    )

    if len(faces) > 0:
        # 选择最大的人脸
        areas = [w * h for (x, y, w, h) in faces]
        max_idx = np.argmax(areas)
        x, y, fw, fh = faces[max_idx]

        # 添加一些边距
        margin = 0.2
        x1 = max(0, int(x - fw * margin))
        y1 = max(0, int(y - fh * margin))
        x2 = min(w, int(x + fw * (1 + margin)))
        y2 = min(h, int(y + fh * (1 + margin)))

        return (x1, y1, x2, y2)

    # Fallback: center crop
    margin = CENTER_CROP_MARGIN
    x1 = int(w * margin)
    y1 = int(h * margin)
    x2 = int(w * (1.0 - margin))
    y2 = int(h * (1.0 - margin))
    logger.warning(f"No face detected, using center crop: {image_path.name}")
    return (x1, y1, x2, y2)


def rgb_to_luv(rgb_img: np.ndarray) -> np.ndarray:
    """
    RGB -> Luv 转换
    输入: (H, W, 3) uint8 RGB
    输出: (H, W, 3) float32 Luv
    """
    rgb_float = rgb_img.astype(np.float32) / 255.0

    # RGB -> XYZ
    # 使用 sRGB 标准矩阵
    M = np.array([
        [0.4124564, 0.3575761, 0.1804375],
        [0.2126729, 0.7151522, 0.0721750],
        [0.0193339, 0.1191920, 0.9503041]
    ])

    # Gamma correction
    mask = rgb_float > 0.04045
    rgb_linear = np.where(mask,
                          ((rgb_float + 0.055) / 1.055) ** 2.4,
                          rgb_float / 12.92)

    # 转换到 XYZ
    xyz = np.dot(rgb_linear.reshape(-1, 3), M.T).reshape(rgb_img.shape)

    # XYZ -> Luv
    # D65 白点
    Xn, Yn, Zn = 0.95047, 1.0, 1.08883

    # 计算 u', v'
    denom = xyz[:,:,0] + 15*xyz[:,:,1] + 3*xyz[:,:,2]
    denom = np.where(denom == 0, 1e-10, denom)
    u_prime = 4 * xyz[:,:,0] / denom
    v_prime = 9 * xyz[:,:,1] / denom

    un_prime = 4 * Xn / (Xn + 15*Yn + 3*Zn)
    vn_prime = 9 * Yn / (Xn + 15*Yn + 3*Zn)

    # L*
    y_ratio = xyz[:,:,1] / Yn
    L = np.where(y_ratio > 0.008856,
                 116 * (y_ratio ** (1/3)) - 16,
                 903.3 * y_ratio)

    # u*, v*
    u = 13 * L * (u_prime - un_prime)
    v = 13 * L * (v_prime - vn_prime)

    luv = np.stack([L, u, v], axis=2).astype(np.float32)
    return luv


def save_npy(data: np.ndarray, path: Path):
    """保存为 .npy 格式"""
    np.save(path, data)


def process_scene(scene_person: str, face_cascade, all_excel_data: List[Dict]):
    """
    处理单个场景

    Args:
        scene_person: 场景标识，如 'f01i'
        face_cascade: 人脸检测器
        all_excel_data: 用于收集所有场景的 Excel 数据
    """
    logger.info("=" * 60)
    logger.info(f"Processing scene: {scene_person}")
    logger.info("=" * 60)

    # 源目录（rendered_2max 中的全局图像）
    src_dir = SRC_ROOT_BASE / scene_person
    if not src_dir.exists():
        logger.warning(f"Source directory not found: {src_dir}")
        return

    # 输出目录
    out_face = DST_ROOT / "rendered_face" / scene_person
    out_uv = DST_ROOT / "rendered_face_uv" / scene_person
    out_global = DST_ROOT / "rendered_2max" / scene_person
    out_gt = DST_ROOT / "gt"

    for d in [out_face, out_uv, out_global, out_gt]:
        d.mkdir(parents=True, exist_ok=True)

    # 扫描图片文件
    jpg_files = sorted(src_dir.glob(f"{scene_person}*.jpg"))
    if not jpg_files:
        logger.warning(f"No images found in {src_dir}")
        return

    logger.info(f"Found {len(jpg_files)} images")

    # 分组处理
    group_map = {}
    pattern = re.compile(rf'^{scene_person}([a-z0-9]+)_(\d{{2}})\.jpg$', re.IGNORECASE)

    for jpg_file in jpg_files:
        match = pattern.match(jpg_file.name)
        if not match:
            continue
        grp = match.group(1).lower()
        idx = int(match.group(2))

        if grp not in group_map:
            group_map[grp] = []
        group_map[grp].append({
            'name': jpg_file.name,
            'idx': idx,
            'path': jpg_file
        })

    logger.info(f"Found {len(group_map)} groups: {', '.join(sorted(group_map.keys()))}")

    # 处理每个 group
    processed_count = 0
    for grp in sorted(group_map.keys()):
        items = sorted(group_map[grp], key=lambda x: x['idx'])
        logger.info(f"Processing group {grp} with {len(items)} images")

        for item in items:
            original_name = item['name'].replace('.jpg', '')
            src_img_path = item['path']

            # 输出路径
            face_out_path = out_face / f"{original_name}_face.jpg"
            uv_out_path = out_uv / f"{original_name}_face_uv.npy"
            global_out_path = out_global / f"{original_name}.jpg"

            # 检查是否已处理
            if face_out_path.exists() and uv_out_path.exists() and global_out_path.exists():
                logger.debug(f"Already processed: {original_name}")
                processed_count += 1
                continue

            try:
                # 1. 检测人脸并裁剪
                x1, y1, x2, y2 = detect_face(face_cascade, src_img_path)
                img = cv2.imread(str(src_img_path))
                face_img = img[y1:y2, x1:x2]

                # 2. 保存人脸图像
                cv2.imwrite(str(face_out_path), face_img)

                # 3. 转换为 Luv 并保存 UV 通道
                face_rgb = cv2.cvtColor(face_img, cv2.COLOR_BGR2RGB)
                luv = rgb_to_luv(face_rgb)
                uv_data = luv[:, :, 1:3]  # 只取 U, V 通道
                save_npy(uv_data, uv_out_path)

                # 4. 复制全局图像
                if not global_out_path.exists():
                    import shutil
                    shutil.copy2(src_img_path, global_out_path)

                processed_count += 1

                if processed_count % 50 == 0:
                    logger.info(f"Processed {processed_count} images...")

            except Exception as e:
                logger.error(f"Error processing {original_name}: {e}")
                continue

    logger.info(f"Scene {scene_person} completed: {processed_count} images processed")


def generate_dummy_gt(scenes: List[str], dst_root: Path):
    """
    生成虚拟的 GT Excel 文件
    因为没有原始的 .mat 标注文件，我们创建占位符

    Excel 格式（每个 sheet 对应一个场景）：
    列0: original_name
    列1: preference_score
    列2: L*
    列3: a*
    列4: b*
    """
    logger.info("Generating dummy GT Excel file...")

    xlsx_path = dst_root / "gt" / "toMax_gt.xlsx"

    # 按场景分 sheet
    with pd.ExcelWriter(xlsx_path, engine='openpyxl') as writer:
        for scene in scenes:
            scene_dir = dst_root / "rendered_2max" / scene
            if not scene_dir.exists():
                continue

            scene_data = []
            jpg_files = sorted(scene_dir.glob(f"{scene}*.jpg"))
            for jpg_file in jpg_files:
                original_name = jpg_file.stem
                scene_data.append({
                    'original_name': original_name,
                    'preference_score': 0.5,  # 占位符
                    'L*': 50.0,  # 占位符
                    'a*': 0.0,   # 占位符
                    'b*': 0.0    # 占位符
                })

            if scene_data:
                # 注意：不包含 scene_person 列，按照数据加载代码期望的格式
                scene_df = pd.DataFrame(scene_data)
                scene_df.to_excel(writer, sheet_name=scene, index=False)

    logger.info(f"GT Excel saved to: {xlsx_path}")
    logger.warning("Note: GT values are placeholders (0.5, 50, 0, 0)")


def main():
    parser = argparse.ArgumentParser(description='Batch process toMax scenes')
    parser.add_argument('--scenes', nargs='+', help='Scene IDs to process (e.g., f01i f02i)')
    parser.add_argument('--priority', action='store_true', help='Process priority scenes only')
    parser.add_argument('--skip-gt', action='store_true', help='Skip GT generation')

    args = parser.parse_args()

    # 确定要处理的场景
    if args.priority:
        scenes = ['f01i', 'f02i', 'f03i', 'm01i', 'm02i']
    elif args.scenes:
        scenes = args.scenes
    else:
        # 默认处理所有可用场景
        scenes = [d.name for d in SRC_ROOT_BASE.iterdir() if d.is_dir()]

    logger.info(f"Will process {len(scenes)} scenes: {', '.join(scenes)}")

    # 初始化人脸检测器
    logger.info("Initializing Haar Cascade face detector...")
    face_cascade = build_face_detector()

    # 处理每个场景
    all_excel_data = []
    for scene in scenes:
        try:
            process_scene(scene, face_cascade, all_excel_data)
        except Exception as e:
            logger.error(f"Failed to process {scene}: {e}")
            continue

    # 生成 GT 文件
    if not args.skip_gt:
        generate_dummy_gt(scenes, DST_ROOT)

    logger.info("=" * 60)
    logger.info("All scenes processed!")
    logger.info(f"Output directory: {DST_ROOT}")
    logger.info("=" * 60)


if __name__ == "__main__":
    main()
