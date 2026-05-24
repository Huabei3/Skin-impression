"""
推理脚本 - 用于模型推理和预测
"""
import torch
import torch.nn as nn
from torch.utils.data import DataLoader
import numpy as np
from pathlib import Path
from PIL import Image
import torchvision.transforms as transforms
from typing import Dict, Tuple, Optional, List
import json
import logging

from config import Config
from models import create_model
from data import get_data_transforms

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class FacialPreferencePredictor:
    """人脸颜色喜好度预测器"""
    
    def __init__(self, 
                 checkpoint_path: str,
                 device: str = 'cuda',
                 model_type: str = 'full'):
        """
        初始化预测器
        
        Args:
            checkpoint_path: 模型检查点路径
            device: 设备类型
            model_type: 模型类型 ('full' or 'simplified')
        """
        self.device = torch.device(device if torch.cuda.is_available() else 'cpu')
        
        # 加载配置
        checkpoint = torch.load(checkpoint_path, map_location=self.device)
        self.config = checkpoint.get('config', Config.get_config_dict())
        
        # 创建模型
        self.model = create_model(self.config, model_type=model_type)
        self.model.load_state_dict(checkpoint['model_state_dict'])
        self.model = self.model.to(self.device)
        self.model.eval()
        
        # 数据变换
        self.transform = get_data_transforms(self.config, split='test')
        
        logger.info(f"Loaded model from {checkpoint_path}")
        logger.info(f"Model on device: {self.device}")
    
    def preprocess_face_rgb(self, image_path: str) -> torch.Tensor:
        """
        预处理人脸RGB图像
        
        Args:
            image_path: 图像路径
            
        Returns:
            预处理后的张量
        """
        image = Image.open(image_path).convert('RGB')
        image = self.transform(image)
        return image
    
    def preprocess_face_uv(self, uv_path: str) -> torch.Tensor:
        """
        预处理人脸UV数据
        
        Args:
            uv_path: UV数据路径
            
        Returns:
            预处理后的张量
        """
        uv_data = np.load(uv_path)
        uv_tensor = torch.from_numpy(uv_data).float()
        
        # 确保形状正确
        if len(uv_tensor.shape) == 2:
            uv_tensor = uv_tensor.unsqueeze(0)
        elif len(uv_tensor.shape) == 3 and uv_tensor.shape[-1] == 2:
            uv_tensor = uv_tensor.permute(2, 0, 1)

        # 归一化到[0,1]并裁剪（与训练一致）
        with torch.no_grad():
            uv_min = uv_tensor.amin(dim=(-2, -1), keepdim=True)
            uv_max = uv_tensor.amax(dim=(-2, -1), keepdim=True)
            if (uv_min < -1e-3).any() or (uv_max > 1 + 1e-3).any():
                denom = (uv_max - uv_min).clamp_min(1e-6)
                uv_tensor = (uv_tensor - uv_min) / denom
            uv_tensor = uv_tensor.clamp(0.0, 1.0)

        return uv_tensor
    
    def predict_single(self, 
                      face_rgb_path: str,
                      face_uv_path: str,
                      global_rgb_path: Optional[str] = None) -> Dict[str, float]:
        """
        对单个样本进行预测
        
        Args:
            face_rgb_path: 人脸RGB图像路径
            face_uv_path: 人脸UV数据路径
            global_rgb_path: 全局图像路径（可选）
            
        Returns:
            预测结果字典
        """
        # 预处理输入
        face_rgb = self.preprocess_face_rgb(face_rgb_path).unsqueeze(0).to(self.device)
        face_uv = self.preprocess_face_uv(face_uv_path).unsqueeze(0).to(self.device)
        
        global_rgb = None
        if global_rgb_path:
            global_rgb = self.preprocess_face_rgb(global_rgb_path).unsqueeze(0).to(self.device)
        
        # 预测
        with torch.no_grad():
            if hasattr(self.model, 'global_stream') and global_rgb is not None:
                pred_score, pred_center = self.model(face_rgb, face_uv, global_rgb)
            else:
                pred_score, pred_center = self.model(face_rgb, face_uv)

        # 转换结果（评分做Sigmoid转为概率）
        score_prob = torch.sigmoid(pred_score)
        result = {
            'preference_score': float(score_prob.cpu().item()),
            'preference_center_a': float(pred_center[0, 0].cpu().item()),
            'preference_center_b': float(pred_center[0, 1].cpu().item())
        }
        
        return result
    
    def predict_batch(self,
                     face_rgb_paths: List[str],
                     face_uv_paths: List[str],
                     batch_size: int = 32) -> List[Dict[str, float]]:
        """
        批量预测
        
        Args:
            face_rgb_paths: 人脸RGB图像路径列表
            face_uv_paths: 人脸UV数据路径列表
            batch_size: 批次大小
            
        Returns:
            预测结果列表
        """
        assert len(face_rgb_paths) == len(face_uv_paths), "输入列表长度不匹配"
        
        results = []
        num_samples = len(face_rgb_paths)
        
        for i in range(0, num_samples, batch_size):
            batch_rgb_paths = face_rgb_paths[i:i+batch_size]
            batch_uv_paths = face_uv_paths[i:i+batch_size]
            
            # 准备批次数据
            batch_rgb = []
            batch_uv = []
            
            for rgb_path, uv_path in zip(batch_rgb_paths, batch_uv_paths):
                batch_rgb.append(self.preprocess_face_rgb(rgb_path))
                batch_uv.append(self.preprocess_face_uv(uv_path))
            
            batch_rgb = torch.stack(batch_rgb).to(self.device)
            batch_uv = torch.stack(batch_uv).to(self.device)
            
            # 批量预测
            with torch.no_grad():
                pred_scores, pred_centers = self.model(batch_rgb, batch_uv)
                pred_scores = torch.sigmoid(pred_scores)
            
            # 收集结果
            for j in range(len(batch_rgb_paths)):
                result = {
                    'file': batch_rgb_paths[j],
                    'preference_score': float(pred_scores[j].cpu().item()),
                    'preference_center_a': float(pred_centers[j, 0].cpu().item()),
                    'preference_center_b': float(pred_centers[j, 1].cpu().item())
                }
                results.append(result)
        
        return results
    
    def analyze_features(self,
                        face_rgb_path: str,
                        face_uv_path: str,
                        global_rgb_path: Optional[str] = None) -> Dict[str, np.ndarray]:
        """
        分析中间特征（用于可视化和调试）
        
        Args:
            face_rgb_path: 人脸RGB图像路径
            face_uv_path: 人脸UV数据路径
            global_rgb_path: 全局图像路径
            
        Returns:
            特征字典
        """
        # 预处理输入
        face_rgb = self.preprocess_face_rgb(face_rgb_path).unsqueeze(0).to(self.device)
        face_uv = self.preprocess_face_uv(face_uv_path).unsqueeze(0).to(self.device)
        
        global_rgb = None
        if global_rgb_path:
            global_rgb = self.preprocess_face_rgb(global_rgb_path).unsqueeze(0).to(self.device)
        
        # 获取中间特征
        with torch.no_grad():
            if hasattr(self.model, 'get_intermediate_features'):
                features = self.model.get_intermediate_features(face_rgb, face_uv, global_rgb)
                
                # 转换为numpy
                features_np = {}
                for name, feat in features.items():
                    features_np[name] = feat.cpu().numpy()
                
                return features_np
            else:
                logger.warning("Model does not support feature extraction")
                return {}


def test_model_on_dataset(checkpoint_path: str,
                          test_data_path: str,
                          output_path: str):
    """
    在测试数据集上评估模型
    
    Args:
        checkpoint_path: 模型检查点路径
        test_data_path: 测试数据路径
        output_path: 输出结果路径
    """
    # 创建预测器
    predictor = FacialPreferencePredictor(checkpoint_path)
    
    # 加载测试数据（这里需要根据实际数据组织修改）
    from data import FacialPreferenceDataset
    test_dataset = FacialPreferenceDataset(
        face_rgb_root=Config.FACE_RGB_ROOT,
        face_uv_root=Config.FACE_UV_ROOT,
        gt_excel_path=Config.GT_EXCEL_PATH,
        split='test',
        transform=predictor.transform,
        seed=Config.RANDOM_SEED,
        allowed_ids=FacialPreferenceDataset._normalize_ids(getattr(Config, 'TEST_IDS', None)),
        global_rgb_root=getattr(Config, 'GLOBAL_RGB_ROOT', Config.FACE_RGB_ROOT)
    )
    
    test_loader = DataLoader(
        test_dataset,
        batch_size=32,
        shuffle=False,
        num_workers=4
    )
    
    # 预测
    all_predictions = []
    all_targets = []
    
    logger.info("Running predictions on test set...")
    
    with torch.no_grad():
        for batch in test_loader:
            face_rgb = batch['face_rgb'].to(predictor.device)
            face_uv = batch['face_uv'].to(predictor.device)
            
            # 预测
            pred_scores, pred_centers = predictor.model(face_rgb, face_uv)
            pred_scores = torch.sigmoid(pred_scores)
            
            # 收集结果
            for i in range(len(face_rgb)):
                prediction = {
                    'scene_person': batch['metadata'][i]['scene_person'],
                    'original_name': batch['metadata'][i]['original_name'],
                    'pred_score': float(pred_scores[i].cpu().item()),
                    'pred_center_a': float(pred_centers[i, 0].cpu().item()),
                    'pred_center_b': float(pred_centers[i, 1].cpu().item()),
                    'target_score': float(batch['preference_score'][i].item()),
                    'target_center_a': float(batch['preference_center'][i, 0].item()),
                    'target_center_b': float(batch['preference_center'][i, 1].item())
                }
                all_predictions.append(prediction)
    
    # 计算评估指标
    from utils.metrics import evaluate_model
    
    pred_scores = np.array([p['pred_score'] for p in all_predictions])
    target_scores = np.array([p['target_score'] for p in all_predictions])
    pred_centers = np.array([[p['pred_center_a'], p['pred_center_b']] for p in all_predictions])
    target_centers = np.array([[p['target_center_a'], p['target_center_b']] for p in all_predictions])
    
    metrics = evaluate_model(pred_scores, target_scores, pred_centers, target_centers)
    
    # 保存结果
    output_data = {
        'metrics': metrics,
        'predictions': all_predictions
    }
    
    with open(output_path, 'w') as f:
        json.dump(output_data, f, indent=4)
    
    logger.info(f"Results saved to {output_path}")
    logger.info("Evaluation Metrics:")
    for key, value in metrics.items():
        logger.info(f"  {key}: {value:.4f}")


def demo_single_prediction():
    """演示单个样本预测"""
    
    # 示例路径（需要根据实际修改）
    checkpoint_path = "F:/Dataset/face_preference/output/checkpoints/best_model.pth"
    face_rgb_path = "F:/Dataset/face_preference/face_rgb/person1_scene1/image1_face.jpg"
    face_uv_path = "F:/Dataset/face_preference/face_uv/person1_scene1/image1_face_uv.npy"
    
    # 创建预测器
    predictor = FacialPreferencePredictor(checkpoint_path)
    
    # 预测
    result = predictor.predict_single(face_rgb_path, face_uv_path)
    
    print("Prediction Result:")
    print(f"  Preference Score: {result['preference_score']:.4f}")
    print(f"  Preference Center (a*, b*): ({result['preference_center_a']:.2f}, {result['preference_center_b']:.2f})")


def main():
    """主函数"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Facial Preference Prediction Inference')
    parser.add_argument('--checkpoint', type=str, required=True,
                       help='Path to model checkpoint')
    parser.add_argument('--mode', type=str, default='single',
                       choices=['single', 'batch', 'test', 'demo'],
                       help='Inference mode')
    parser.add_argument('--face_rgb', type=str,
                       help='Path to face RGB image')
    parser.add_argument('--face_uv', type=str,
                       help='Path to face UV data')
    parser.add_argument('--output', type=str, default='predictions.json',
                       help='Output file path')
    
    args = parser.parse_args()
    
    if args.mode == 'single':
        if not args.face_rgb or not args.face_uv:
            parser.error("Single mode requires --face_rgb and --face_uv")
        
        predictor = FacialPreferencePredictor(args.checkpoint)
        result = predictor.predict_single(args.face_rgb, args.face_uv)
        
        print("Prediction Result:")
        print(f"  Preference Score: {result['preference_score']:.4f}")
        print(f"  Preference Center (a*, b*): ({result['preference_center_a']:.2f}, {result['preference_center_b']:.2f})")
        
        # 保存结果
        with open(args.output, 'w') as f:
            json.dump(result, f, indent=4)
    
    elif args.mode == 'test':
        test_model_on_dataset(args.checkpoint, "", args.output)
    
    elif args.mode == 'demo':
        demo_single_prediction()
    
    else:
        parser.error(f"Mode {args.mode} not implemented yet")


if __name__ == '__main__':
    main()
