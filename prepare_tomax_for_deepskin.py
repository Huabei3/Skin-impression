"""
将 toMax 数据集 (如 f01i) 预处理为 deepskin 网络可直接读取的格式。

输出结构:
    DATA_ROOT/
        rendered_face/
            f01i/
                {original_name}_face.jpg
        rendered_face_uv/
            f01i/
                {original_name}_face_uv.npy
        rendered_2max/
            f01i/
                {original_name}.jpg
        gt/
            toMax_gt.xlsx   (sheet_name = "f01i")

依赖安装:
    pip install numpy pandas scipy opencv-python Pillow openpyxl

使用说明:
    1) 先运行脚本，观察终端打印的 mat 文件结构诊断信息。
    2) 核对 par_all 行与 group (h3k/h4k/...) 的对应关系；如有需要，修改 PAR_ALL_ROW_MAP。
    3) 再次运行生成最终数据。
"""

import os
import re
import sys
import json
import urllib.request
from pathlib import Path
from typing import Dict, List, Optional, Tuple

import numpy as np
import pandas as pd
import cv2
from PIL import Image
from scipy.io import loadmat

# ========================== 用户可配置区域 ==========================

# 源数据路径
SRC_F01I = Path(r"D:\work\secondYearMaster\thesis\reference\appeal\datasets\toMax\f01i")
DRAWABLE_DIR = SRC_F01I / "drawable"

# 读取哪一类标注: "non_model" 或 "model_group"
ANNOTATION_SUBDIR = "non_model"          # <-- 如需 model_group 请改这里
ATTRIBUTE_DIR = "01Preference"           # <-- 如需其他属性请改这里

MAT_DIR = SRC_F01I / ANNOTATION_SUBDIR / ATTRIBUTE_DIR / "labNscore"
ELLIP_DIR = SRC_F01I / ANNOTATION_SUBDIR / ATTRIBUTE_DIR / "ellipPara"

# 输出根目录（建议放在 deepskin 内部，方便改 config.py）
DST_ROOT = Path(r"D:\work\secondYearMaster\thesis\reference\appeal\algorithms\preference_evaluate\deepskin\data\toMax")

# 当前场景/人物标识，也作为 Excel 的 sheet_name
SCENE_PERSON = "f01i"

# 图片分组正则: f01i<h3k>_01.jpg -> group=h3k, idx=01
GROUP_RE = re.compile(r'^f01i([a-z0-9]+)_(\d{2})\.jpg$', re.IGNORECASE)

# 是否使用统一 center (average_bf + par_all) 作为所有图的 L,a,b
# False: 逐样本使用 lab_group[i] 作为 L,a,b（默认，符合"Lab与图片对应"）
# True : 所有图共享 center L=avg_bf, a,b=par_all[row,3:5]
USE_UNIFIED_CENTER = False

# 如果 fitRes.mat 中 par_all 的行与 group 无法自动对应，请在此手动指定
# 例: {"h3k": 0, "h4k": 1, ...}   (Python 0-based 索引)
PAR_ALL_ROW_MAP: Optional[Dict[str, int]] = None

# OpenCV DNN 人脸检测模型下载地址
OPENCV_PROTO_URL = (
    "https://raw.githubusercontent.com/opencv/opencv/master/samples/dnn/face_detector/deploy.prototxt"
)
OPENCV_MODEL_URL = (
    "https://github.com/opencv/opencv_3rdparty/raw/dnn_samples_face_detector_20170830/"
    "res10_300x300_ssd_iter_140000.caffemodel"
)

# 人脸检测置信度阈值
FACE_CONF_THRESH = 0.7

# fallback 中心裁剪比例（检测不到人脸时）
CENTER_CROP_MARGIN = 0.15

# ========================== 工具函数 ==========================

def download_opencv_face_detector() -> Tuple[str, str]:
    """自动下载 OpenCV DNN 人脸检测器所需的 prototxt 和 caffemodel。"""
    model_dir = Path(__file__).parent / "opencv_models"
    model_dir.mkdir(parents=True, exist_ok=True)
    prototxt = model_dir / "deploy.prototxt"
    caffemodel = model_dir / "res10_300x300_ssd_iter_140000.caffemodel"

    if not prototxt.exists():
        print(f"[Download] {prototxt.name} ...")
        try:
            urllib.request.urlretrieve(OPENCV_PROTO_URL, prototxt)
        except Exception as e:
            print(f"下载失败，请手动放置到: {prototxt}\n错误: {e}")
            sys.exit(1)
    if not caffemodel.exists():
        print(f"[Download] {caffemodel.name} ...")
        try:
            urllib.request.urlretrieve(OPENCV_MODEL_URL, caffemodel)
        except Exception as e:
            print(f"下载失败，请手动放置到: {caffemodel}\n错误: {e}")
            sys.exit(1)
    return str(prototxt), str(caffemodel)


def build_face_detector():
    """初始化 OpenCV DNN 人脸检测器。"""
    prototxt, caffemodel = download_opencv_face_detector()
    net = cv2.dnn.readNetFromCaffe(prototxt, caffemodel)
    return net


def detect_face(net, image_path: Path) -> Tuple[int, int, int, int]:
    """
    使用 OpenCV DNN 检测人脸 bbox。
    若检测失败，回退到中心裁剪。
    返回 (x1, y1, x2, y2)。
    """
    img = cv2.imread(str(image_path))
    if img is None:
        raise ValueError(f"无法读取图片: {image_path}")
    h, w = img.shape[:2]

    blob = cv2.dnn.blobFromImage(img, 1.0, (300, 300), [104.0, 177.0, 123.0], False, False)
    net.setInput(blob)
    detections = net.forward()

    best_conf = 0.0
    best_box = None
    for i in range(detections.shape[2]):
        confidence = float(detections[0, 0, i, 2])
        if confidence > FACE_CONF_THRESH and confidence > best_conf:
            x1 = int(detections[0, 0, i, 3] * w)
            y1 = int(detections[0, 0, i, 4] * h)
            x2 = int(detections[0, 0, i, 5] * w)
            y2 = int(detections[0, 0, i, 6] * h)
            x1, y1 = max(0, x1), max(0, y1)
            x2, y2 = min(w, x2), min(h, y2)
            if x2 > x1 and y2 > y1:
                best_conf = confidence
                best_box = (x1, y1, x2, y2)

    if best_box is not None:
        return best_box

    # ---- fallback: center crop ----
    margin = CENTER_CROP_MARGIN
    x1 = int(w * margin)
    y1 = int(h * margin)
    x2 = int(w * (1.0 - margin))
    y2 = int(h * (1.0 - margin))
    print(f"  [WARN] 未检测到人脸，使用中心裁剪: {image_path.name}")
    return x1, y1, x2, y2


def generate_face_uv(face_rgb: np.ndarray) -> np.ndarray:
    """
    从人脸 RGB (uint8, HxWx3) 生成 UV 数据。

n    这里采用 CIE L*u*v* 颜色空间的 u*,v* 两个通道作为 UV 近似。
    输出形状: (2, H, W), float32。
    数值范围不做强制归一化（deepskin 的 dataset 会自行 min-max 到 [0,1]）。
    """
    # OpenCV COLOR_RGB2Luv: 输入 uint8 -> 输出 uint8 (范围非线性压缩)
    # 先保证是 uint8
    if face_rgb.dtype != np.uint8:
        face_rgb = np.clip(face_rgb, 0, 255).astype(np.uint8)
    luv = cv2.cvtColor(face_rgb, cv2.COLOR_RGB2Luv)
    # 拆分通道
    l_ch, u_ch, v_ch = cv2.split(luv)
    # 转为 float32
    uv = np.stack([u_ch.astype(np.float32), v_ch.astype(np.float32)], axis=0)
    return uv


def inspect_mat(mat_path: Path, label: str):
    """诊断打印 mat 文件变量。"""
    print(f"\n=== 诊断: {label} ===")
    print(f"  路径: {mat_path}")
    if not mat_path.exists():
        print("  [ERROR] 文件不存在")
        return None
    m = loadmat(mat_path)
    vars_ = [k for k in m.keys() if not k.startswith('__')]
    print(f"  变量: {vars_}")
    for k in sorted(vars_):
        v = m[k]
        print(f"    {k}: shape={v.shape}, dtype={v.dtype}")
        if v.size <= 20:
            print(f"         value={v}")
        else:
            print(f"         first/last few={v.flat[:5]} ... {v.flat[-5:]}")
    return m


# ========================== 主流程 ==========================

def main():
    print("=" * 60)
    print("toMax -> deepskin 数据准备脚本")
    print("=" * 60)

    # ---- 1. 扫描图片并按 group 分组 ----
    if not DRAWABLE_DIR.exists():
        print(f"[ERROR] 图片目录不存在: {DRAWABLE_DIR}")
        sys.exit(1)

    group_to_images: Dict[str, List[Path]] = {}
    for img_path in sorted(DRAWABLE_DIR.glob("*.jpg")):
        m = GROUP_RE.match(img_path.name)
        if not m:
            continue
        group_name = m.group(1).lower()
        group_to_images.setdefault(group_name, []).append(img_path)

    if not group_to_images:
        print("[ERROR] drawable 下没有匹配的分组图片。请检查 GROUP_RE 正则。")
        sys.exit(1)

    print(f"\n发现 {len(group_to_images)} 个 image group:")
    for g, imgs in sorted(group_to_images.items()):
        print(f"  {g}: {len(imgs)} 张")

    # ---- 2. 诊断读取 mat 文件 ----
    print("\n--- 开始读取 .mat 文件（诊断模式）---")
    ellip_mat_path = ELLIP_DIR / "fitRes.mat"
    ellip_mat = inspect_mat(ellip_mat_path, "ellipPara/fitRes.mat")

    # 读取一个示例 labNscore mat
    first_group = sorted(group_to_images.keys())[0]
    example_mat_name = f"labNscore_groupf01i{first_group}.mat"
    example_mat_path = MAT_DIR / example_mat_name
    example_mat = inspect_mat(example_mat_path, f"labNscore/{example_mat_name}")

    print("\n[提示] 请检查上方诊断输出，确认变量名和形状是否符合预期。")
    print("      如果 fitRes.mat 中的 par_all 行与 group 对应关系不明确，")
    print("      请修改脚本顶部的 PAR_ALL_ROW_MAP 后重新运行。")
    input("\n确认无误后按 Enter 继续生成数据...")

    # ---- 3. 解析 fitRes.mat (par_all) ----
    if ellip_mat is None:
        print("[ERROR] 无法读取 fitRes.mat")
        sys.exit(1)
    par_all = ellip_mat['par_all']   # shape 假设为 (N_groups, M_params)
    if par_all.ndim == 1:
        par_all = par_all.reshape(1, -1)
    n_par_rows = par_all.shape[0]
    print(f"\nfitRes.mat / par_all 形状: {par_all.shape}")

    # 建立 group -> par_all 行号的映射
    sorted_groups = sorted(group_to_images.keys())
    if PAR_ALL_ROW_MAP is not None:
        group_to_par_row = {g: PAR_ALL_ROW_MAP[g] for g in sorted_groups if g in PAR_ALL_ROW_MAP}
    elif n_par_rows == 1:
        group_to_par_row = {g: 0 for g in sorted_groups}
        print("par_all 仅 1 行，所有 group 共享同一 center a,b。")
    elif n_par_rows == len(sorted_groups):
        group_to_par_row = {g: i for i, g in enumerate(sorted_groups)}
        print("par_all 行数与 group 数量一致，按字母序自动分配行号。")
    else:
        print(f"[WARN] par_all 行数({n_par_rows}) != group 数量({len(sorted_groups)})，")
        print("       默认按字母序循环分配。强烈建议手动设置 PAR_ALL_ROW_MAP。")
        group_to_par_row = {g: i % n_par_rows for i, g in enumerate(sorted_groups)}

    # ---- 4. 初始化人脸检测器 ----
    print("\n[初始化] OpenCV DNN 人脸检测器...")
    face_net = build_face_detector()

    # ---- 5. 准备输出目录 ----
    out_face = DST_ROOT / "rendered_face" / SCENE_PERSON
    out_uv = DST_ROOT / "rendered_face_uv" / SCENE_PERSON
    out_global = DST_ROOT / "rendered_2max" / SCENE_PERSON
    out_gt = DST_ROOT / "gt"
    for d in (out_face, out_uv, out_global, out_gt):
        d.mkdir(parents=True, exist_ok=True)

    all_records = []
    group_centers = {}

    # ---- 6. 逐 group 处理 ----
    for group_name in sorted_groups:
        img_paths = sorted(group_to_images[group_name])
        mat_name = f"labNscore_groupf01i{group_name}.mat"
        mat_path = MAT_DIR / mat_name

        if not mat_path.exists():
            print(f"\n[SKIP] mat 文件不存在: {mat_path}")
            continue

        mat = loadmat(mat_path)
        # 安全读取变量
        p_group = mat.get('p_group')
        lab_group = mat.get('lab_group')
        average_bf = mat.get('average_bf')

        if p_group is None or lab_group is None:
            print(f"\n[SKIP] {mat_name} 缺少 p_group 或 lab_group")
            continue

        p_group = np.asarray(p_group).flatten()
        lab_group = np.asarray(lab_group)
        if lab_group.ndim == 1 and lab_group.size % 3 == 0:
            lab_group = lab_group.reshape(-1, 3)

        n_mat = p_group.shape[0]
        n_img = len(img_paths)
        if n_mat != n_img:
            print(f"\n[WARN] {group_name}: mat 样本数({n_mat}) != 图片数({n_img})，以较小值为准。")

        n_use = min(n_mat, n_img)

        # center L,a,b
        if average_bf is not None:
            center_L = float(np.asarray(average_bf).flatten()[0])
        else:
            center_L = float(np.mean(lab_group[:, 0])) if lab_group.size else 50.0

        par_row = group_to_par_row.get(group_name, 0)
        center_a = float(par_all[par_row, 3])
        center_b = float(par_all[par_row, 4])
        group_centers[group_name] = {"L": center_L, "a": center_a, "b": center_b}

        print(f"\n[处理 group] {group_name}: {n_use} 张 | center L={center_L:.3f}, a={center_a:.3f}, b={center_b:.3f}")

        for i in range(n_use):
            img_path = img_paths[i]
            original_name = img_path.stem   # e.g. f01ih3k_01

            # -- 检测人脸并裁剪 --
            x1, y1, x2, y2 = detect_face(face_net, img_path)
            img_pil = Image.open(img_path).convert('RGB')
            face_pil = img_pil.crop((x1, y1, x2, y2))

            # -- 保存 global_rgb (原图) --
            global_path = out_global / f"{original_name}.jpg"
            img_pil.save(global_path)

            # -- 保存 face_rgb --
            face_path = out_face / f"{original_name}_face.jpg"
            face_pil.save(face_path)

            # -- 生成并保存 UV --
            face_np = np.array(face_pil)  # RGB uint8
            uv_np = generate_face_uv(face_np)
            uv_path = out_uv / f"{original_name}_face_uv.npy"
            np.save(uv_path, uv_np.astype(np.float32))

            # -- 构建 GT 记录 --
            if USE_UNIFIED_CENTER:
                rec_L, rec_a, rec_b = center_L, center_a, center_b
            else:
                rec_L = float(lab_group[i, 0])
                rec_a = float(lab_group[i, 1])
                rec_b = float(lab_group[i, 2])

            all_records.append({
                'original_name': original_name,
                'preference_score': float(p_group[i]),
                'L*': rec_L,
                'a*': rec_a,
                'b*': rec_b,
            })

    # ---- 7. 保存 Excel ----
    df = pd.DataFrame(all_records)
    xlsx_path = out_gt / "toMax_gt.xlsx"
    with pd.ExcelWriter(xlsx_path, engine='openpyxl') as writer:
        df.to_excel(writer, sheet_name=SCENE_PERSON, index=False)

    # ---- 8. 保存 group center 摘要 ----
    json_path = out_gt / "group_centers.json"
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(group_centers, f, ensure_ascii=False, indent=2)

    # ---- 9. 打印摘要 ----
    print("\n" + "=" * 60)
    print("处理完成!")
    print(f"  总样本数: {len(df)}")
    print(f"  Excel  : {xlsx_path}")
    print(f"  Sheet  : {SCENE_PERSON}")
    print(f"  face   : {out_face}")
    print(f"  uv     : {out_uv}")
    print(f"  global : {out_global}")
    print(f"  centers: {json_path}")
    print("=" * 60)
    print("\n下一步:")
    print("  1) 修改 facial_preference/config.py 中的路径指向上述输出目录:")
    print(f"       FACE_RGB_ROOT  = r'{DST_ROOT / 'rendered_face'}'")
    print(f"       FACE_UV_ROOT   = r'{DST_ROOT / 'rendered_face_uv'}'")
    print(f"       GLOBAL_RGB_ROOT= r'{DST_ROOT / 'rendered_2max'}'")
    print(f"       GT_EXCEL_PATH  = r'{xlsx_path}'")
    print("  2) 如需处理 f02i / m01r 等，请复制本脚本并修改 SRC_F01I 和 SCENE_PERSON。")


if __name__ == "__main__":
    main()
