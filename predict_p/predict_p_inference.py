#!/usr/bin/env python
"""
predict_p 推理脚本 - 用于对白种人数据进行批量推理
用法: python inference_predict_p.py --checkpoint <checkpoint_path> [--output <output_dir>]
"""
import torch
import numpy as np
from pathlib import Path
from PIL import Image
import json
import logging
from typing import Dict, List, Optional, Tuple
from tqdm import tqdm
import torchvision.transforms as transforms

# ==================== 配置 ====================
class InferenceConfig:
    """推理配置"""

    # 数据路径
    FACE_RGB_ROOT = Path("/root/autodl-tmp/toMax/rendered_face")
    FACE_UV_ROOT = Path("/root/autodl-tmp/toMax/rendered_face_uv")
    GLOBAL_RGB_ROOT = Path("/root/autodl-tmp/toMax/rendered_2max")
    GT_EXCEL_PATH = Path("/root/autodl-tmp/toMax/gt/toMax_gt.xlsx")

    # 白种人subject配置
    CAUCASIAN_SUBJECTS = {
        'f01': ['f01i', 'f01r'],
        'f02': ['f02i', 'f02r'],
        'f03': ['f03i', 'f03r'],
        'm01': ['m01i', 'm01r'],
        'm02': ['m02i', 'm02r'],
        'm03': ['m03i', 'm03r'],
    }

    # 图像预处理
    IMAGE_SIZE = (224, 224)
    TRANSFORM = transforms.Compose([
        transforms.Resize(256),
        transforms.CenterCrop(IMAGE_SIZE),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
    ])

    # 设备
    DEVICE = 'cuda' if torch.cuda.is_available() else 'cpu'

    # 输出目录
    OUTPUT_ROOT = Path("/root/autodl-tmp/deepskin/predict_p/inference_results")


def get_scene_dirs_for_subject(subject: str, config: InferenceConfig) -> List[str]:
    """获取某个subject的所有可用scene目录"""
    subject_lower = subject.lower()
    scenes = []

    for scene_prefix in ['f01', 'f02', 'f03', 'f04', 'f05', 'f06', 'f07', 'f08', 'f09', 'f10',
                          'm01', 'm02', 'm03', 'm04', 'm05', 'm06', 'm07', 'm08', 'm09', 'm10']:
        if scene_prefix.startswith(subject_lower) or scene_prefix.lower().startswith(subject_lower):
            for suffix in ['i', 'r']:
                scene = f"{scene_prefix}{suffix}"
                scene_path = config.FACE_RGB_ROOT / scene
                if scene_path.exists():
                    scenes.append(scene)
    return scenes


def find_face_images(scene_dir: Path, subject_prefix: str) -> List[Path]:
    """查找某个scene目录下的所有人脸图像"""
    if not scene_dir.exists():
        return []

    images = []
    for img_path in scene_dir.glob(f"{subject_prefix}*_face.jpg"):
        images.append(img_path)

    # 按序号排序
    def get_num(p):
        name = p.stem  # e.g., "f01ih3k_01_face"
        parts = name.split('_')
        if len(parts) >= 2:
            try:
                return int(parts[1])
            except:
                pass
        return 0

    return sorted(images, key=get_num)


def find_uv_file(uv_root: Path, face_image_path: Path) -> Optional[Path]:
    """根据人脸图像路径找到对应的UV文件"""
    face_name = face_image_path.stem  # e.g., "f01ih3k_01_face"
    uv_name = f"{face_name}_uv.npy"
    uv_path = uv_root / face_image_path.parent.name / uv_name

    if uv_path.exists():
        return uv_path
    return None


class PredictPInferencer:
    """predict_p 模型推理器"""

    def __init__(self, checkpoint_path: str, device: str = 'cuda'):
        self.device = torch.device(device if torch.cuda.is_available() else 'cpu')

        # 加载checkpoint
        checkpoint = torch.load(checkpoint_path, map_location=self.device)
        self.config = checkpoint.get('config', {})

        # 获取模型variant
        self.model_variant = self.config.get('MODEL_VARIANT', 'v3')

        # 获取模型配置
        model_cfg = self.config.get('MODEL', {})

        # 动态导入创建模型
        import sys
        sys.path.insert(0, str(Path(__file__).parent))

        from models.network import PredictPNetwork, create_model

        # 创建模型
        self.model = create_model(self.config, model_type='full', model_variant=self.model_variant)
        self.model.load_state_dict(checkpoint['model_state_dict'])
        self.model = self.model.to(self.device)
        self.model.eval()

        logging.info(f"Loaded model from {checkpoint_path}")
        logging.info(f"Model variant: {self.model_variant}")
        logging.info(f"Device: {self.device}")

    def preprocess_image(self, image_path: Path) -> torch.Tensor:
        """预处理图像"""
        image = Image.open(image_path).convert('RGB')
        return InferenceConfig.TRANSFORM(image)

    def preprocess_uv(self, uv_path: Path) -> torch.Tensor:
        """预处理UV数据"""
        uv_data = np.load(uv_path)
        uv_tensor = torch.from_numpy(uv_data).float()

        # 确保形状正确 (H, W, 2) -> (2, H, W)
        if len(uv_tensor.shape) == 2:
            uv_tensor = uv_tensor.unsqueeze(0)
        elif len(uv_tensor.shape) == 3 and uv_tensor.shape[-1] == 2:
            uv_tensor = uv_tensor.permute(2, 0, 1)

        # 归一化到[0,1]
        uv_min = uv_tensor.amin(dim=(-2, -1), keepdim=True)
        uv_max = uv_tensor.amax(dim=(-2, -1), keepdim=True)
        denom = (uv_max - uv_min).clamp_min(1e-6)
        uv_tensor = (uv_tensor - uv_min) / denom
        uv_tensor = uv_tensor.clamp(0.0, 1.0)

        return uv_tensor

    def predict_single(self, face_rgb: torch.Tensor, face_uv: Optional[torch.Tensor] = None) -> float:
        """单次预测"""
        face_rgb = face_rgb.unsqueeze(0).to(self.device)
        if face_uv is not None:
            face_uv = face_uv.unsqueeze(0).to(self.device)

        with torch.no_grad():
            score_logits = self.model(face_rgb, face_uv)
            score_prob = torch.sigmoid(score_logits)

        return float(score_prob.cpu().item())

    def predict_batch(self, face_rgb_list: List[torch.Tensor],
                     face_uv_list: List[Optional[torch.Tensor]]) -> List[float]:
        """批量预测"""
        batch_rgb = torch.stack(face_rgb_list).to(self.device)

        batch_uv = None
        if any(uv is not None for uv in face_uv_list):
            batch_uv = torch.stack([uv if uv is not None else torch.zeros(2, 224, 224) for uv in face_uv_list]).to(self.device)

        with torch.no_grad():
            score_logits = self.model(batch_rgb, batch_uv)
            score_probs = torch.sigmoid(score_logits)

        return [float(p.cpu().item()) for p in score_probs]


def run_inference_for_subject(
    inferencer: PredictPInferencer,
    subject: str,
    scenes: List[str],
    config: InferenceConfig
) -> List[Dict]:
    """对某个subject的所有数据运行推理"""
    results = []

    for scene in scenes:
        scene_rgb_path = config.FACE_RGB_ROOT / scene
        scene_uv_path = config.FACE_UV_ROOT / scene

        if not scene_rgb_path.exists():
            logging.warning(f"Scene directory not found: {scene_rgb_path}")
            continue

        # 获取subject前缀用于匹配文件
        subject_prefix = subject[:2].lower()  # e.g., "f0" for "f01"
        if subject.startswith('f'):
            subject_prefix = f"{subject[0]}0"  # "f0" for "f01", "f1" for "f10"
        elif subject.startswith('m'):
            subject_prefix = f"{subject[0]}0"  # "m0" for "m01", "m1" for "m10"

        # 找到所有人脸图像
        face_images = find_face_images(scene_rgb_path, subject_prefix)

        logging.info(f"  {scene}: found {len(face_images)} images")

        for img_path in tqdm(face_images, desc=f"  {scene}"):
            # 查找UV文件
            uv_path = find_uv_file(scene_uv_path, img_path)

            # 预处理
            face_rgb = inferencer.preprocess_image(img_path)
            face_uv = inferencer.preprocess_uv(uv_path) if uv_path and inferencer.model_variant != 'v3' else None

            # 推理
            score = inferencer.predict_single(face_rgb, face_uv)

            results.append({
                'subject': subject,
                'scene': scene,
                'image_name': img_path.name,
                'image_path': str(img_path),
                'uv_path': str(uv_path) if uv_path else None,
                'pred_score': score,
                'model_variant': inferencer.model_variant,
            })

    return results


def main():
    import argparse

    parser = argparse.ArgumentParser(description='predict_p 批量推理脚本')
    parser.add_argument('--checkpoint', type=str, required=True,
                       help='模型checkpoint路径')
    parser.add_argument('--subjects', type=str, default='f01,f02,f03,m01,m02,m03',
                       help='要推理的subject列表，逗号分隔')
    parser.add_argument('--output', type=str, default=None,
                       help='输出目录路径')
    parser.add_argument('--device', type=str, default='cuda',
                       help='设备 (cuda/cpu)')

    args = parser.parse_args()

    # 配置
    config = InferenceConfig()

    # 创建输出目录
    if args.output:
        output_dir = Path(args.output)
    else:
        checkpoint_name = Path(args.checkpoint).stem  # e.g., "best_model_predict_p_v3"
        output_dir = config.OUTPUT_ROOT / checkpoint_name
    output_dir.mkdir(parents=True, exist_ok=True)

    # 设置日志
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler(output_dir / 'inference.log'),
            logging.StreamHandler()
        ]
    )

    # 创建推理器
    inferencer = PredictPInferencer(args.checkpoint, device=args.device)

    # 解析subjects
    subjects = [s.strip() for s in args.subjects.split(',')]

    # 对每个subject运行推理
    all_results = []

    for subject in subjects:
        logging.info(f"Processing subject: {subject}")

        # 获取该subject的所有scene
        scenes = config.CAUCASIAN_SUBJECTS.get(subject, [])
        if not scenes:
            # 动态查找scene
            scenes = get_scene_dirs_for_subject(subject, config)

        logging.info(f"  Scenes: {scenes}")

        results = run_inference_for_subject(inferencer, subject, scenes, config)
        all_results.extend(results)

        logging.info(f"  Completed: {len(results)} predictions")

    # 保存结果
    output_file = output_dir / 'predictions.json'
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(all_results, f, indent=2, ensure_ascii=False)

    logging.info(f"Results saved to {output_file}")
    logging.info(f"Total predictions: {len(all_results)}")

    # 打印统计信息
    scores = [r['pred_score'] for r in all_results]
    logging.info(f"Score statistics: min={min(scores):.4f}, max={max(scores):.4f}, mean={np.mean(scores):.4f}")


if __name__ == '__main__':
    main()
