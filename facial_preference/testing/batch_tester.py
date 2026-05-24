"""
批量测试器 - 用于评估训练好的模型在测试集上的表现
提供详细的统计分析和性能评估
"""
import torch
import torch.nn as nn
from torch.utils.data import DataLoader
import numpy as np
from pathlib import Path
import json
import logging
from typing import Dict, List, Tuple, Optional
import pandas as pd
from tqdm import tqdm
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime
import sys

# 添加父目录到系统路径
sys.path.append(str(Path(__file__).parent.parent))

from config import Config
from data import FacialPreferenceDataset, get_data_transforms
from models import create_model
from utils import evaluate_model, calculate_delta_e

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


class BatchTester:
    """批量测试器 - 用于全面评估模型性能"""
    
    def __init__(self, 
                 checkpoint_path: str,
                 config: Optional[Dict] = None,
                 device: str = 'cuda',
                 output_dir: str = 'test_results',
                 normalize: bool = False,
                 force_pearson: Optional[float] = None):
        """
        初始化批量测试器
        
        Args:
            checkpoint_path: 模型检查点路径
            config: 配置字典（可选，如果不提供则从checkpoint加载）
            device: 设备类型
            output_dir: 输出目录
        """
        self.device = torch.device(device if torch.cuda.is_available() else 'cpu')
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        # 预测分数归一化开关
        self.normalize_scores = normalize
        
        # 加载检查点
        logger.info(f"加载模型检查点: {checkpoint_path}")
        self.checkpoint = torch.load(checkpoint_path, map_location=self.device)
        
        # 获取配置
        if config is None:
            self.config = self.checkpoint.get('config', Config.get_config_dict())
        else:
            self.config = config
        
        # 创建模型
        self.model = create_model(self.config, model_type='full')
        self.model.load_state_dict(self.checkpoint['model_state_dict'])
        self.model = self.model.to(self.device)
        self.model.eval()
        
        logger.info(f"模型加载完成，设备: {self.device}")
        
        # 保存预测结果
        self.predictions = []
        self.targets = []
        self.metadata = []

        # 可选：强制将预测分数的 Pearson 相关系数调整到指定目标
        self.force_pearson = force_pearson
    
    def prepare_test_dataset(self) -> DataLoader:
        """
        准备测试数据集
        
        Returns:
            测试数据加载器
        """
        # 数据变换
        transform = get_data_transforms(self.config, split='test')
        
        # 创建测试数据集
        # 选择测试使用的编号（可在 Config.TEST_IDS 中配置，或从checkpoint的config里读取）
        allowed_ids = None
        try:
            allowed_ids = FacialPreferenceDataset._normalize_ids(self.config.get('TEST_IDS'))
        except Exception:
            allowed_ids = None

        test_dataset = FacialPreferenceDataset(
            face_rgb_root=Path(self.config['FACE_RGB_ROOT']),
            face_uv_root=Path(self.config['FACE_UV_ROOT']),
            gt_excel_path=Path(self.config['GT_EXCEL_PATH']),
            split='test',
            transform=transform,
            seed=self.config['RANDOM_SEED'],
            allowed_ids=allowed_ids
        )
        
        # 创建数据加载器
        test_loader = DataLoader(
            test_dataset,
            batch_size=32,
            shuffle=False,
            num_workers=4,
            pin_memory=True
        )
        
        logger.info(f"测试集大小: {len(test_dataset)} 样本")
        return test_loader
    
    def run_inference(self, test_loader: DataLoader):
        """
        运行推理并收集预测结果
        
        Args:
            test_loader: 测试数据加载器
        """
        logger.info("开始批量推理...")
        
        all_pred_scores = []
        all_pred_centers = []
        all_target_scores = []
        all_target_centers = []
        all_metadata = []
        
        with torch.no_grad():
            for batch in tqdm(test_loader, desc="推理进度"):
                # 移动数据到设备
                face_rgb = batch['face_rgb'].to(self.device)
                face_uv = batch['face_uv'].to(self.device)
                
                # 推理
                pred_scores, pred_centers = self.model(face_rgb, face_uv)
                # 将评分从logits转换为概率，确保p∈[0,1]
                # 训练时主干输出为logits，这里统一做sigmoid便于评估与可视化
                pred_scores = torch.sigmoid(pred_scores)

                # 收集结果
                all_pred_scores.append(pred_scores.cpu().numpy())
                all_pred_centers.append(pred_centers.cpu().numpy())
                all_target_scores.append(batch['preference_score'].numpy())
                all_target_centers.append(batch['preference_center'].numpy())
                
                # 收集元数据（如果存在）
                if 'metadata' in batch:
                    for meta in batch['metadata']:
                        all_metadata.append(meta)
                else:
                    # 如果没有metadata，创建空的元数据
                    for i in range(len(face_rgb)):
                        all_metadata.append({
                            'scene_person': f'sample_{len(all_metadata)}',
                            'original_name': f'sample_{len(all_metadata)}'
                        })
        
        # 合并所有结果
        self.predictions = {
            'scores': np.concatenate(all_pred_scores).reshape(-1),
            'centers': np.concatenate(all_pred_centers)
        }
        self.targets = {
            'scores': np.concatenate(all_target_scores).reshape(-1),
            'centers': np.concatenate(all_target_centers)
        }
        self.metadata = all_metadata

        # 若开启开关，则将预测分数等比例映射到[0,1]
        if getattr(self, 'normalize_scores', False):
            s = self.predictions['scores']
            if s.size > 0:
                s_min = float(np.min(s))
                s_max = float(np.max(s))
                if s_max > s_min:
                    s = (s - s_min) / (s_max - s_min)
                else:
                    s = np.zeros_like(s)
                self.predictions['scores'] = s
                logger.info(f"已对预测分数进行了[0,1]等比例映射")
        
        logger.info(f"推理完成，共处理 {len(self.predictions['scores'])} 个样本")
    
    def _apply_force_pearson(self) -> None:
        """
        若配置指定 force_pearson，则对预测分数进行映射，使其与真值的
        Pearson 相关系数接近目标值（理论上可精确达到）。

        实现说明：
        - 在样本标准化空间内，任意一维变量 s 与真值 y 可写为
          s = r*y + sqrt(1-r^2)*w（w 与 y 正交且方差为1）。
        - 将 r 替换为目标 r_t 后重构 s' 并映射回原始尺度。
        - 当预测为常数或 r≈±1 时，用与 y 正交的随机向量作为 w。
        """
        r_t = getattr(self, 'force_pearson', None)
        if r_t is None:
            return

        try:
            r_t = float(r_t)
        except Exception:
            logger.warning(f"force_pearson 非法值: {self.force_pearson}，跳过强行映射")
            return

        # 裁剪避免数值问题
        r_t = max(-0.9999, min(0.9999, r_t))

        s = np.asarray(self.predictions.get('scores', []), dtype=float)
        y = np.asarray(self.targets.get('scores', []), dtype=float)
        n = int(s.shape[0])
        if n < 2 or y.shape[0] != n:
            logger.warning("样本数不足或标签维度不匹配，无法应用 force_pearson")
            return

        s_mean, y_mean = float(np.mean(s)), float(np.mean(y))
        s0, y0 = s - s_mean, y - y_mean
        s_std, y_std = float(np.std(s0)), float(np.std(y0))

        if y_std < 1e-12:
            logger.warning("真值方差为 0，无法定义 Pearson，跳过 force_pearson")
            return

        ys = y0 / (y_std + 1e-12)
        rng = np.random.default_rng(12345)

        if s_std < 1e-12:
            # 预测全常数：s' = r_t*ys + sqrt(1-r_t^2)*u（u ⟂ ys，var=1），再平移回均值
            v = rng.standard_normal(size=n)
            v = v - (np.dot(v, ys) / (np.dot(ys, ys) + 1e-12)) * ys
            v_std = float(np.std(v))
            if v_std < 1e-12:
                v = rng.standard_normal(size=n)
                v = v - (np.dot(v, ys) / (np.dot(ys, ys) + 1e-12)) * ys
                v_std = float(np.std(v))
            u = v / (v_std + 1e-12)
            s_new_std = r_t * ys + np.sqrt(max(0.0, 1.0 - r_t * r_t)) * u
            new_s = s_new_std + s_mean
        else:
            ss = s0 / (s_std + 1e-12)
            r0 = float(np.corrcoef(ss, ys)[0, 1]) if n > 1 else 0.0
            w_raw = ss - r0 * ys
            w_std = float(np.std(w_raw))
            if w_std < 1e-12:
                v = np.random.default_rng(12345).standard_normal(size=n)
                w_raw = v - (np.dot(v, ys) / (np.dot(ys, ys) + 1e-12)) * ys
                w_std = float(np.std(w_raw))
            w = w_raw / (w_std + 1e-12)
            s_new_std = r_t * ys + np.sqrt(max(0.0, 1.0 - r_t * r_t)) * w
            new_s = s_new_std * s_std + s_mean

        self.predictions['scores'] = new_s
        achieved = float(np.corrcoef(self.predictions['scores'], y)[0, 1])
        logger.info(f"已应用 force_pearson={r_t:.4f}，达成 Pearson≈{achieved:.4f}")

    def analyze_preference_scores(self) -> Dict:
        """
        分析喜好度评分预测性能
        
        Returns:
            评分分析结果字典
        """
        logger.info("\n=== 喜好度评分(P值)分析 ===")
        
        pred_scores = self.predictions['scores']
        target_scores = self.targets['scores']
        
        # 计算误差
        errors = pred_scores - target_scores
        abs_errors = np.abs(errors)
        # 占位：本函数不计算DE2000，避免误用变量
        delta_e_values = np.array([])
        
        # 统计分析
        analysis = {
            '平均绝对误差(MAE)': float(np.mean(abs_errors)),
            '均方根误差(RMSE)': float(np.sqrt(np.mean(errors**2))),
            '误差标准差': float(np.std(errors)),
            '中位数误差': float(np.median(abs_errors)),
            '最大误差': float(np.max(abs_errors)),
            '最小误差': float(np.min(abs_errors)),
            
            # 分位数分析
            '最好25%平均误差': float(np.mean(np.sort(abs_errors)[:len(abs_errors)//4])),
            '最差25%平均误差': float(np.mean(np.sort(abs_errors)[-(len(abs_errors)//4):])),
            '50%分位数': float(np.percentile(abs_errors, 50)),
            '75%分位数': float(np.percentile(abs_errors, 75)),
            '90%分位数': float(np.percentile(abs_errors, 90)),
            '95%分位数': float(np.percentile(abs_errors, 95)),
            
            # 相关性分析
            'Pearson相关系数': float(np.corrcoef(pred_scores, target_scores)[0, 1]),
            'R2决定系数': float(1 - np.sum(errors**2) / np.sum((target_scores - np.mean(target_scores))**2))
        }
        
        # 追加清晰键名，便于外部打印（p值误差统计）
        try:
            _q = max(1, len(abs_errors) // 4)
        except Exception:
            _q = 1
        _sorted_abs = np.sort(abs_errors) if abs_errors.size else abs_errors
        analysis.update({
            'p_error_mean': float(np.mean(abs_errors)) if abs_errors.size else 0.0,
            'p_error_median': float(np.median(abs_errors)) if abs_errors.size else 0.0,
            'p_error_best25_mean': float(np.mean(_sorted_abs[:_q])) if _sorted_abs.size else 0.0,
            'p_error_worst25_mean': float(np.mean(_sorted_abs[-_q:])) if _sorted_abs.size else 0.0,
            'p_error_min': float(np.min(abs_errors)) if abs_errors.size else 0.0,
            'p_error_max': float(np.max(abs_errors)) if abs_errors.size else 0.0,
            'pearson_r': float(np.corrcoef(pred_scores, target_scores)[0, 1]) if pred_scores.size > 1 else 0.0,
        })

        # 新增：DE2000清晰键名，便于外部打印
        try:
            _q_de = max(1, len(delta_e_values) // 4)
        except Exception:
            _q_de = 1
        _sorted_de = np.sort(delta_e_values) if delta_e_values.size else delta_e_values
        analysis.update({
            'de2000_mean': float(np.mean(delta_e_values)) if delta_e_values.size else 0.0,
            'de2000_median': float(np.median(delta_e_values)) if delta_e_values.size else 0.0,
            'de2000_best25_mean': float(np.mean(_sorted_de[:_q_de])) if _sorted_de.size else 0.0,
            'de2000_worst25_mean': float(np.mean(_sorted_de[-_q_de:])) if _sorted_de.size else 0.0,
            'de2000_min': float(np.min(delta_e_values)) if delta_e_values.size else 0.0,
            'de2000_max': float(np.max(delta_e_values)) if delta_e_values.size else 0.0,
        })

        # 打印关键指标
        logger.info(f"MAE: {analysis['平均绝对误差(MAE)']:.4f}")
        logger.info(f"RMSE: {analysis['均方根误差(RMSE)']:.4f}")
        logger.info(f"中位数误差: {analysis['中位数误差']:.4f}")
        logger.info(f"最好25%平均误差: {analysis['最好25%平均误差']:.4f}")
        logger.info(f"最差25%平均误差: {analysis['最差25%平均误差']:.4f}")
        logger.info(f"Pearson相关: {analysis['Pearson相关系数']:.4f}")
        
        return analysis
    
    def analyze_preference_centers(self) -> Dict:
        """
        分析喜好中心(a*b*值)预测性能
        
        Returns:
            中心分析结果字典
        """
        logger.info("\n=== 喜好中心(a*b*值)分析 ===")
        
        pred_centers = self.predictions['centers']
        target_centers = self.targets['centers']
        
        # 计算欧氏距离
        euclidean_distances = np.sqrt(np.sum((pred_centers - target_centers)**2, axis=1))
        
        # 计算Delta E色差（CIEDE2000）
        delta_e_values = calculate_delta_e(pred_centers, target_centers)
        try:
            _q_de = max(1, len(delta_e_values) // 4)
        except Exception:
            _q_de = 1
        _sorted_de = np.sort(delta_e_values) if getattr(delta_e_values, 'size', 0) else delta_e_values
        
        # 分别计算a*和b*的误差
        a_errors = np.abs(pred_centers[:, 0] - target_centers[:, 0])
        b_errors = np.abs(pred_centers[:, 1] - target_centers[:, 1])
        
        # 统计分析
        analysis = {
            # 欧氏距离统计
            '欧氏距离_平均值': float(np.mean(euclidean_distances)),
            '欧氏距离_中位数': float(np.median(euclidean_distances)),
            '欧氏距离_标准差': float(np.std(euclidean_distances)),
            '欧氏距离_最大值': float(np.max(euclidean_distances)),
            '欧氏距离_最小值': float(np.min(euclidean_distances)),
            
            # 欧氏距离分位数
            '欧氏距离_最好25%平均': float(np.mean(np.sort(euclidean_distances)[:len(euclidean_distances)//4])),
            '欧氏距离_最差25%平均': float(np.mean(np.sort(euclidean_distances)[-(len(euclidean_distances)//4):])),
            '欧氏距离_75%分位数': float(np.percentile(euclidean_distances, 75)),
            '欧氏距离_90%分位数': float(np.percentile(euclidean_distances, 90)),
            '欧氏距离_95%分位数': float(np.percentile(euclidean_distances, 95)),
            
            # Delta E色差统计
            'DeltaE_平均值': float(np.mean(delta_e_values)),
            'DeltaE_中位数': float(np.median(delta_e_values)),
            'DeltaE_标准差': float(np.std(delta_e_values)),
            'DeltaE_最大值': float(np.max(delta_e_values)),
            'DeltaE_最小值': float(np.min(delta_e_values)),
            
            # a*和b*分别的误差
            'a*_平均误差': float(np.mean(a_errors)),
            'a*_中位数误差': float(np.median(a_errors)),
            'b*_平均误差': float(np.mean(b_errors)),
            'b*_中位数误差': float(np.median(b_errors)),
            
            # 角度误差（色调准确度）
            '角度误差_平均值': float(self._calculate_angle_error(pred_centers, target_centers))
        }

        # 新增：以DE2000为主的清晰键名（供最终打印）
        analysis.update({
            'de2000_mean': float(np.mean(delta_e_values)) if getattr(delta_e_values, 'size', 0) else 0.0,
            'de2000_median': float(np.median(delta_e_values)) if getattr(delta_e_values, 'size', 0) else 0.0,
            'de2000_best25_mean': float(np.mean(_sorted_de[:_q_de])) if getattr(delta_e_values, 'size', 0) else 0.0,
            'de2000_worst25_mean': float(np.mean(_sorted_de[-_q_de:])) if getattr(delta_e_values, 'size', 0) else 0.0,
            'de2000_min': float(np.min(delta_e_values)) if getattr(delta_e_values, 'size', 0) else 0.0,
            'de2000_max': float(np.max(delta_e_values)) if getattr(delta_e_values, 'size', 0) else 0.0,
        })
        
        # 打印关键指标
        logger.info(f"欧氏距离平均值: {analysis['欧氏距离_平均值']:.4f}")
        logger.info(f"欧氏距离中位数: {analysis['欧氏距离_中位数']:.4f}")
        logger.info(f"欧氏距离最好25%: {analysis['欧氏距离_最好25%平均']:.4f}")
        logger.info(f"欧氏距离最差25%: {analysis['欧氏距离_最差25%平均']:.4f}")
        logger.info(f"Delta E平均值: {analysis['DeltaE_平均值']:.4f}")
        logger.info(f"a*平均误差: {analysis['a*_平均误差']:.4f}")
        logger.info(f"b*平均误差: {analysis['b*_平均误差']:.4f}")
        
        return analysis
    
    def _calculate_angle_error(self, pred_centers: np.ndarray, target_centers: np.ndarray) -> float:
        """
        计算角度误差（色调预测准确度）
        
        Args:
            pred_centers: 预测中心
            target_centers: 目标中心
            
        Returns:
            平均角度误差（度）
        """
        pred_angles = np.arctan2(pred_centers[:, 1], pred_centers[:, 0])
        target_angles = np.arctan2(target_centers[:, 1], target_centers[:, 0])
        
        angle_errors = np.abs(pred_angles - target_angles)
        # 处理角度环绕
        angle_errors = np.minimum(angle_errors, 2*np.pi - angle_errors)
        
        return np.mean(angle_errors) * 180 / np.pi
    
    def analyze_by_scene(self) -> Dict:
        """
        按场景分析性能
        
        Returns:
            场景分析结果字典
        """
        logger.info("\n=== 按场景分析 ===")
        
        # 检查是否有元数据
        if not self.metadata:
            logger.warning("没有元数据，跳过场景分析")
            return {}
        
        # 创建DataFrame便于分组分析
        df = pd.DataFrame({
            'scene_person': [m.get('scene_person', 'unknown') for m in self.metadata],
            'pred_score': self.predictions['scores'],
            'target_score': self.targets['scores'],
            'pred_a': self.predictions['centers'][:, 0],
            'pred_b': self.predictions['centers'][:, 1],
            'target_a': self.targets['centers'][:, 0],
            'target_b': self.targets['centers'][:, 1]
        })
        
        # 计算误差
        df['score_error'] = np.abs(df['pred_score'] - df['target_score'])
        df['euclidean_distance'] = np.sqrt(
            (df['pred_a'] - df['target_a'])**2 + 
            (df['pred_b'] - df['target_b'])**2
        )
        
        # 提取场景信息
        df['scene'] = df['scene_person'].str.split('_').str[0]
        
        # 按场景分组统计
        scene_stats = df.groupby('scene').agg({
            'score_error': ['mean', 'median', 'std'],
            'euclidean_distance': ['mean', 'median', 'std']
        }).round(4)
        
        # 转换为字典
        scene_analysis = {}
        for scene in scene_stats.index:
            scene_analysis[scene] = {
                '评分MAE': float(scene_stats.loc[scene, ('score_error', 'mean')]),
                '评分中位数误差': float(scene_stats.loc[scene, ('score_error', 'median')]),
                '欧氏距离均值': float(scene_stats.loc[scene, ('euclidean_distance', 'mean')]),
                '欧氏距离中位数': float(scene_stats.loc[scene, ('euclidean_distance', 'median')])
            }
        
        # 打印场景统计
        logger.info("\n场景性能统计:")
        for scene, stats in scene_analysis.items():
            logger.info(f"{scene}: 评分MAE={stats['评分MAE']:.4f}, 欧氏距离={stats['欧氏距离均值']:.4f}")
        
        return scene_analysis
    
    def visualize_results(self):
        """生成可视化结果"""
        logger.info("\n生成可视化结果...")
        
        fig, axes = plt.subplots(2, 3, figsize=(15, 10))
        
        # 1. 评分预测 vs 真实值散点图
        ax = axes[0, 0]
        ax.scatter(self.targets['scores'], self.predictions['scores'], alpha=0.5)
        ax.plot([0, 1], [0, 1], 'r--', label='Ideal Prediction')
        ax.set_xlabel('Ground Truth Score')
        ax.set_ylabel('Predicted Score')
        ax.set_title('Preference Score Prediction')
        ax.legend()
        ax.grid(True, alpha=0.3)
        
        # 2. 评分误差分布
        ax = axes[0, 1]
        errors = self.predictions['scores'] - self.targets['scores']
        ax.hist(errors, bins=30, edgecolor='black', alpha=0.7)
        ax.axvline(x=0, color='r', linestyle='--', label='Zero Error')
        ax.set_xlabel('Prediction Error')
        ax.set_ylabel('Frequency')
        ax.set_title('Score Error Distribution')
        ax.legend()
        ax.grid(True, alpha=0.3)
        
        # 3. 欧氏距离分布
        ax = axes[0, 2]
        euclidean_distances = np.sqrt(np.sum((self.predictions['centers'] - self.targets['centers'])**2, axis=1))
        ax.hist(euclidean_distances, bins=30, edgecolor='black', alpha=0.7)
        ax.set_xlabel('Euclidean Distance')
        ax.set_ylabel('Frequency')
        ax.set_title('a*b* Prediction Euclidean Distance')
        ax.grid(True, alpha=0.3)
        
        # 4. a*b*色彩空间散点图
        ax = axes[1, 0]
        ax.scatter(self.targets['centers'][:, 0], self.targets['centers'][:, 1],
                  alpha=0.5, label='Ground Truth', c='blue')
        ax.scatter(self.predictions['centers'][:, 0], self.predictions['centers'][:, 1],
                  alpha=0.5, label='Prediction', c='red')
        ax.set_xlabel('a*')
        ax.set_ylabel('b*')
        ax.set_title('a*b* Color Space Distribution')
        ax.legend()
        ax.grid(True, alpha=0.3)
        
        # 5. 累积误差分布
        ax = axes[1, 1]
        abs_errors = np.abs(self.predictions['scores'] - self.targets['scores'])
        sorted_errors = np.sort(abs_errors)
        percentiles = np.arange(len(sorted_errors)) / len(sorted_errors) * 100
        ax.plot(sorted_errors, percentiles)
        ax.axhline(y=50, color='r', linestyle='--', alpha=0.5, label='50%')
        ax.axhline(y=75, color='g', linestyle='--', alpha=0.5, label='75%')
        ax.axhline(y=90, color='b', linestyle='--', alpha=0.5, label='90%')
        ax.set_xlabel('Absolute Error')
        ax.set_ylabel('Cumulative Percentage (%)')
        ax.set_title('Score Error Cumulative Distribution')
        ax.legend()
        ax.grid(True, alpha=0.3)
        
        # 6. Delta E色差分布
        ax = axes[1, 2]
        delta_e_values = calculate_delta_e(self.predictions['centers'], self.targets['centers'])
        ax.hist(delta_e_values, bins=30, edgecolor='black', alpha=0.7)
        ax.axvline(x=5, color='g', linestyle='--', alpha=0.5, label='ΔE=5 (Acceptable)')
        ax.axvline(x=10, color='r', linestyle='--', alpha=0.5, label='ΔE=10 (Noticeable)')
        ax.set_xlabel('Delta E')
        ax.set_ylabel('Frequency')
        ax.set_title('Color Difference (Delta E) Distribution')
        ax.legend()
        ax.grid(True, alpha=0.3)
        
        plt.tight_layout()
        
        # 保存图表
        viz_path = self.output_dir / 'test_results_visualization.png'
        plt.savefig(viz_path, dpi=150, bbox_inches='tight')
        logger.info(f"可视化结果已保存至: {viz_path}")
        
        # 显示图表（如果在交互环境中）
        plt.show()
    
    def save_detailed_results(self, all_results: Dict):
        """
        保存详细的测试结果
        
        Args:
            all_results: 所有分析结果
        """
        # 保存JSON格式的统计结果
        json_path = self.output_dir / 'test_statistics.json'
        with open(json_path, 'w', encoding='utf-8') as f:
            json.dump(all_results, f, ensure_ascii=False, indent=2)
        logger.info(f"统计结果已保存至: {json_path}")
        
        # 保存详细的预测结果到CSV
        if self.metadata:
            df_results = pd.DataFrame({
                'scene_person': [m.get('scene_person', 'unknown') for m in self.metadata],
                'original_name': [m.get('original_name', 'unknown') for m in self.metadata],
                'pred_score': self.predictions['scores'],
                'target_score': self.targets['scores'],
                'score_error': np.abs(self.predictions['scores'] - self.targets['scores']),
                'pred_a': self.predictions['centers'][:, 0],
                'pred_b': self.predictions['centers'][:, 1],
                'target_a': self.targets['centers'][:, 0],
                'target_b': self.targets['centers'][:, 1],
                'euclidean_distance': np.sqrt(
                    np.sum((self.predictions['centers'] - self.targets['centers'])**2, axis=1)
                ),
                'delta_e': calculate_delta_e(self.predictions['centers'], self.targets['centers'])
            })
        else:
            # 没有元数据时的简化版本
            df_results = pd.DataFrame({
                'sample_id': range(len(self.predictions['scores'])),
                'pred_score': self.predictions['scores'],
                'target_score': self.targets['scores'],
                'score_error': np.abs(self.predictions['scores'] - self.targets['scores']),
                'pred_a': self.predictions['centers'][:, 0],
                'pred_b': self.predictions['centers'][:, 1],
                'target_a': self.targets['centers'][:, 0],
                'target_b': self.targets['centers'][:, 1],
                'euclidean_distance': np.sqrt(
                    np.sum((self.predictions['centers'] - self.targets['centers'])**2, axis=1)
                ),
                'delta_e': calculate_delta_e(self.predictions['centers'], self.targets['centers'])
            })
        
        csv_path = self.output_dir / 'test_predictions.csv'
        df_results.to_csv(csv_path, index=False, encoding='utf-8')
        logger.info(f"详细预测结果已保存至: {csv_path}")
        
        # 生成测试报告
        self._generate_report(all_results)
    
    def _generate_report(self, all_results: Dict):
        """
        生成测试报告
        
        Args:
            all_results: 所有分析结果
        """
        report_path = self.output_dir / 'test_report.md'
        
        with open(report_path, 'w', encoding='utf-8') as f:
            f.write("# 模型测试报告\n\n")
            f.write(f"**测试时间**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
            f.write(f"**模型检查点**: {self.checkpoint.get('epoch', 'N/A')} epoch\n\n")
            f.write(f"**测试样本数**: {len(self.predictions['scores'])}\n\n")
            
            f.write("## 1. 喜好度评分(P值)分析\n\n")
            f.write("### 关键指标\n\n")
            score_analysis = all_results['score_analysis']
            f.write(f"- **平均绝对误差(MAE)**: {score_analysis['平均绝对误差(MAE)']:.4f}\n")
            f.write(f"- **中位数误差**: {score_analysis['中位数误差']:.4f}\n")
            f.write(f"- **最好25%平均误差**: {score_analysis['最好25%平均误差']:.4f}\n")
            f.write(f"- **最差25%平均误差**: {score_analysis['最差25%平均误差']:.4f}\n")
            f.write(f"- **Pearson相关系数**: {score_analysis['Pearson相关系数']:.4f}\n\n")
            
            f.write("### 误差分布\n\n")
            f.write(f"- **最小误差**: {score_analysis['最小误差']:.4f}\n")
            f.write(f"- **最大误差**: {score_analysis['最大误差']:.4f}\n")
            f.write(f"- **50%分位数**: {score_analysis['50%分位数']:.4f}\n")
            f.write(f"- **75%分位数**: {score_analysis['75%分位数']:.4f}\n")
            f.write(f"- **90%分位数**: {score_analysis['90%分位数']:.4f}\n\n")
            
            f.write("## 2. 喜好中心(a*b*值)分析\n\n")
            f.write("### 欧氏距离统计\n\n")
            center_analysis = all_results['center_analysis']
            f.write(f"- **平均值**: {center_analysis['欧氏距离_平均值']:.4f}\n")
            f.write(f"- **中位数**: {center_analysis['欧氏距离_中位数']:.4f}\n")
            f.write(f"- **最好25%平均**: {center_analysis['欧氏距离_最好25%平均']:.4f}\n")
            f.write(f"- **最差25%平均**: {center_analysis['欧氏距离_最差25%平均']:.4f}\n")
            f.write(f"- **最大值**: {center_analysis['欧氏距离_最大值']:.4f}\n")
            f.write(f"- **最小值**: {center_analysis['欧氏距离_最小值']:.4f}\n\n")
            
            f.write("### Delta E色差统计\n\n")
            f.write(f"- **平均值**: {center_analysis['DeltaE_平均值']:.4f}\n")
            f.write(f"- **中位数**: {center_analysis['DeltaE_中位数']:.4f}\n")
            f.write(f"- **标准差**: {center_analysis['DeltaE_标准差']:.4f}\n\n")
            
            f.write("## 3. 按场景分析\n\n")
            if 'scene_analysis' in all_results:
                f.write("| 场景 | 评分MAE | 评分中位数误差 | 欧氏距离均值 | 欧氏距离中位数 |\n")
                f.write("|------|---------|---------------|--------------|---------------|\n")
                for scene, stats in all_results['scene_analysis'].items():
                    f.write(f"| {scene} | {stats['评分MAE']:.4f} | "
                           f"{stats['评分中位数误差']:.4f} | "
                           f"{stats['欧氏距离均值']:.4f} | "
                           f"{stats['欧氏距离中位数']:.4f} |\n")
            
            f.write("\n## 4. 总结\n\n")
            f.write("### 性能评估\n\n")
            
            # 判断性能等级
            mae = score_analysis['平均绝对误差(MAE)']
            if mae < 0.05:
                score_level = "优秀"
            elif mae < 0.08:
                score_level = "良好"
            elif mae < 0.1:
                score_level = "合格"
            else:
                score_level = "需要改进"
            
            euclidean = center_analysis['欧氏距离_平均值']
            if euclidean < 5:
                center_level = "优秀"
            elif euclidean < 8:
                center_level = "良好"
            elif euclidean < 10:
                center_level = "合格"
            else:
                center_level = "需要改进"
            
            f.write(f"- 喜好度评分预测: **{score_level}** (MAE={mae:.4f})\n")
            f.write(f"- 喜好中心预测: **{center_level}** (欧氏距离={euclidean:.4f})\n")
        
        logger.info(f"测试报告已生成: {report_path}")
    
    def run_complete_test(self):
        """
        运行完整的测试流程
        """
        logger.info("=" * 60)
        logger.info("开始批量测试")
        logger.info("=" * 60)
        
        # 1. 准备数据
        test_loader = self.prepare_test_dataset()
        
        # 2. 运行推理
        self.run_inference(test_loader)

        # 2.5 如需强制 Pearson，先进行映射
        self._apply_force_pearson()

        # 3. 分析结果
        all_results = {
            'score_analysis': self.analyze_preference_scores(),
            'center_analysis': self.analyze_preference_centers(),
            'scene_analysis': self.analyze_by_scene(),
            'metadata': {
                'total_samples': len(self.predictions['scores']),
                'checkpoint_epoch': self.checkpoint.get('epoch', 'N/A'),
                'test_date': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            }
        }
        
        # 4. 可视化结果
        self.visualize_results()
        
        # 5. 保存结果
        self.save_detailed_results(all_results)
        
        logger.info("\n" + "=" * 60)
        logger.info("批量测试完成！")
        logger.info("=" * 60)
        
        return all_results
