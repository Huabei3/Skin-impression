"""
评估指标模块 - 计算各种评估指标
"""
import numpy as np
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
from scipy.stats import pearsonr, spearmanr
from typing import Dict, Tuple
import torch

# 可选使用 colour-science 提供的 dE2000（若系统已安装）
try:
    from colour.difference import delta_E as _colour_delta_E
    _HAS_COLOUR = True
except Exception:
    _HAS_COLOUR = False


def calculate_delta_e2000(lab1: np.ndarray, lab2: np.ndarray) -> np.ndarray:
    """
    计算CIEDE2000色差（dE00）。由于仅有 a* 与 b*，此处统一假设 L*=50。
    输入: lab1, lab2 形状为 (N, 2) 的 [a*, b*]
    返回: (N,) 的 dE00 数组
    """
    if lab1.shape[1] == 2:
        L1 = np.full((lab1.shape[0], 1), 50.0, dtype=np.float64)
        L2 = np.full((lab2.shape[0], 1), 50.0, dtype=np.float64)
        Lab1 = np.concatenate([L1, lab1.astype(np.float64)], axis=1)
        Lab2 = np.concatenate([L2, lab2.astype(np.float64)], axis=1)
    else:
        Lab1 = lab1.astype(np.float64)
        Lab2 = lab2.astype(np.float64)
    # 若安装了 colour-science，优先使用其实现
    if _HAS_COLOUR:
        try:
            return _colour_delta_E(Lab1, Lab2, method='CIE 2000')
        except Exception:
            pass
    return _ciede2000_np(Lab1, Lab2)


def _ciede2000_np(Lab1: np.ndarray, Lab2: np.ndarray,
                  kL: float = 1.0, kC: float = 1.0, kH: float = 1.0) -> np.ndarray:
    # 基于 Sharma et al. (2005) 的 CIEDE2000 实现（向量化）
    L1, a1, b1 = Lab1[:, 0], Lab1[:, 1], Lab1[:, 2]
    L2, a2, b2 = Lab2[:, 0], Lab2[:, 1], Lab2[:, 2]

    C1 = np.sqrt(a1 * a1 + b1 * b1)
    C2 = np.sqrt(a2 * a2 + b2 * b2)
    C_avg = (C1 + C2) / 2.0
    C_avg7 = np.power(C_avg, 7)
    G = 0.5 * (1 - np.sqrt(C_avg7 / (C_avg7 + np.power(25.0, 7))))

    a1p = (1 + G) * a1
    a2p = (1 + G) * a2
    C1p = np.sqrt(a1p * a1p + b1 * b1)
    C2p = np.sqrt(a2p * a2p + b2 * b2)

    h1p = np.degrees(np.arctan2(b1, a1p))
    h2p = np.degrees(np.arctan2(b2, a2p))
    h1p = np.where(h1p < 0, h1p + 360, h1p)
    h2p = np.where(h2p < 0, h2p + 360, h2p)

    dLp = L2 - L1
    dCp = C2p - C1p

    dhp = h2p - h1p
    dhp = np.where((C1p * C2p) == 0, 0.0, dhp)
    dhp = np.where(dhp > 180, dhp - 360, dhp)
    dhp = np.where(dhp < -180, dhp + 360, dhp)
    dHp = 2.0 * np.sqrt(C1p * C2p) * np.sin(np.radians(dhp) / 2.0)

    Lp_ = (L1 + L2) / 2.0
    Cp_ = (C1p + C2p) / 2.0

    hsum = h1p + h2p
    hdiff = np.abs(h1p - h2p)
    hp_ = np.where((C1p * C2p) == 0, hsum,
                   np.where(hdiff > 180, (hsum + 360) / 2.0, hsum / 2.0))
    hp_ = np.where(hp_ >= 360, hp_ - 360, hp_)

    T = (
        1
        - 0.17 * np.cos(np.radians(hp_ - 30))
        + 0.24 * np.cos(np.radians(2 * hp_))
        + 0.32 * np.cos(np.radians(3 * hp_ + 6))
        - 0.20 * np.cos(np.radians(4 * hp_ - 63))
    )

    dTheta = 30.0 * np.exp(-((hp_ - 275.0) / 25.0) ** 2)
    Rc = 2.0 * np.sqrt(np.power(Cp_, 7) / (np.power(Cp_, 7) + np.power(25.0, 7)))
    Sl = 1.0 + (0.015 * (Lp_ - 50.0) ** 2) / np.sqrt(20.0 + (Lp_ - 50.0) ** 2)
    Sc = 1.0 + 0.045 * Cp_
    Sh = 1.0 + 0.015 * Cp_ * T
    Rt = -np.sin(np.radians(2.0 * dTheta)) * Rc

    dE = np.sqrt(
        (dLp / (kL * Sl)) ** 2
        + (dCp / (kC * Sc)) ** 2
        + (dHp / (kH * Sh)) ** 2
        + Rt * (dCp / (kC * Sc)) * (dHp / (kH * Sh))
    )
    return dE


def evaluate_model(
    pred_scores: np.ndarray,
    target_scores: np.ndarray,
    pred_centers: np.ndarray,
    target_centers: np.ndarray,
) -> Dict[str, float]:
    """
    评估模型性能

    Args:
        pred_scores: 预测的喜好度评分 (N, 1)
        target_scores: 目标喜好度评分 (N, 1)
        pred_centers: 预测的喜好中心 (N, 2) [a*, b*]
        target_centers: 目标喜好中心 (N, 2) [a*, b*]

    Returns:
        评估指标字典
    """
    pred_scores = pred_scores.reshape(-1)
    target_scores = target_scores.reshape(-1)

    # 评分指标
    mae_score = mean_absolute_error(target_scores, pred_scores)
    rmse_score = np.sqrt(mean_squared_error(target_scores, pred_scores))
    r2 = r2_score(target_scores, pred_scores)

    # 相关系数
    pearson_corr, pearson_p = pearsonr(target_scores, pred_scores)
    spearman_corr, spearman_p = spearmanr(target_scores, pred_scores)

    # 喜好中心指标（dE2000）
    delta_e_values = calculate_delta_e2000(pred_centers, target_centers)
    delta_e_mean = float(np.mean(delta_e_values))
    delta_e_std = float(np.std(delta_e_values))
    delta_e_median = float(np.median(delta_e_values))
    delta_e_90 = float(np.percentile(delta_e_values, 90))

    # 欧氏距离（保留做参考）
    euclidean_distances = np.sqrt(np.sum((pred_centers - target_centers) ** 2, axis=1))
    euclidean_mean = float(np.mean(euclidean_distances))

    # 角度误差（色调）
    pred_angles = np.arctan2(pred_centers[:, 1], pred_centers[:, 0])
    target_angles = np.arctan2(target_centers[:, 1], target_centers[:, 0])
    angle_errors = np.abs(pred_angles - target_angles)
    angle_errors = np.minimum(angle_errors, 2 * np.pi - angle_errors)
    angle_error_mean = float(np.mean(angle_errors) * 180 / np.pi)

    metrics = {
        'mae_score': float(mae_score),
        'rmse_score': float(rmse_score),
        'r2': float(r2),
        'pearson': float(pearson_corr),
        'pearson_p': float(pearson_p),
        'spearman': float(spearman_corr),
        'spearman_p': float(spearman_p),
        'delta_e_mean': delta_e_mean,
        'delta_e_std': delta_e_std,
        'delta_e_median': delta_e_median,
        'delta_e_90': delta_e_90,
        'euclidean_mean': euclidean_mean,
        'angle_error_mean': angle_error_mean,
    }
    return metrics


def compute_batch_metrics(
    pred_scores: torch.Tensor,
    target_scores: torch.Tensor,
    pred_centers: torch.Tensor,
    target_centers: torch.Tensor,
) -> Dict[str, float]:
    """
    计算批次指标（用于训练过程中的监控）
    """
    with torch.no_grad():
        mae_score = torch.mean(torch.abs(pred_scores - target_scores)).item()
        # dE2000（转 numpy 计算）
        pred_np = pred_centers.detach().cpu().numpy()
        target_np = target_centers.detach().cpu().numpy()
        delta_e_values = calculate_delta_e2000(pred_np, target_np)
        delta_e_mean = float(np.mean(delta_e_values))
        return {
            'mae_score': mae_score,
            'delta_e_mean': delta_e_mean,
        }


class MetricTracker:
    """指标跟踪器 - 用于跟踪训练过程中的指标"""

    def __init__(self, metrics_names: list):
        self.metrics_names = metrics_names
        self.reset()

    def reset(self):
        self.metrics = {name: [] for name in self.metrics_names}
        self.counts = {name: 0 for name in self.metrics_names}

    def update(self, metrics_dict: Dict[str, float], n: int = 1):
        for name, value in metrics_dict.items():
            if name in self.metrics:
                self.metrics[name].append(value * n)
                self.counts[name] += n

    def average(self) -> Dict[str, float]:
        avg_metrics = {}
        for name in self.metrics_names:
            if self.counts[name] > 0:
                avg_metrics[name] = sum(self.metrics[name]) / self.counts[name]
            else:
                avg_metrics[name] = 0.0
        return avg_metrics

    def get_best(self, metric_name: str, mode: str = 'min') -> float:
        if metric_name not in self.metrics or len(self.metrics[metric_name]) == 0:
            return float('inf') if mode == 'min' else float('-inf')
        values = self.metrics[metric_name]
        if mode == 'min':
            return min(values)
        else:
            return max(values)


class EarlyStopping:
    """早停机制"""

    def __init__(self, patience: int = 15, min_delta: float = 0.0001, mode: str = 'min'):
        self.patience = patience
        self.min_delta = min_delta
        self.mode = mode
        self.counter = 0
        self.best_value = float('inf') if mode == 'min' else float('-inf')
        self.early_stop = False

    def __call__(self, value: float) -> bool:
        if self.mode == 'min':
            if value < self.best_value - self.min_delta:
                self.best_value = value
                self.counter = 0
            else:
                self.counter += 1
        else:
            if value > self.best_value + self.min_delta:
                self.best_value = value
                self.counter = 0
            else:
                self.counter += 1
        if self.counter >= self.patience:
            self.early_stop = True
        return self.early_stop

    def reset(self):
        self.counter = 0
        self.best_value = float('inf') if self.mode == 'min' else float('-inf')
        self.early_stop = False


# --- Robust evaluator with NaN/Inf filtering ---
def evaluate_model_safe(
    pred_scores: np.ndarray,
    target_scores: np.ndarray,
    pred_centers: np.ndarray,
    target_centers: np.ndarray,
) -> Dict[str, float]:
    """
    评估模型表现，自动过滤输入中的 NaN/Inf，避免 sklearn 报错。

    参数:
      - pred_scores: 预测分数 (N, 1) 或 (N,)
      - target_scores: 真实分数 (N, 1) 或 (N,)
      - pred_centers: 预测中心 (N, 2) [a*, b*]
      - target_centers: 真实中心 (N, 2) [a*, b*]
    返回: 各项指标字典
    """
    import logging
    from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
    from scipy.stats import pearsonr, spearmanr

    logger = logging.getLogger(__name__)

    ps = np.asarray(pred_scores).reshape(-1)
    ts = np.asarray(target_scores).reshape(-1)
    pc = np.asarray(pred_centers)
    tc = np.asarray(target_centers)

    if pc.ndim == 1:
        pc = pc.reshape(-1, 2)
    if tc.ndim == 1:
        tc = tc.reshape(-1, 2)

    n = min(len(ps), len(pc))
    ps, ts, pc, tc = ps[:n], ts[:n], pc[:n], tc[:n]

    m_scores = np.isfinite(ps) & np.isfinite(ts)
    m_centers = np.all(np.isfinite(pc), axis=1) & np.all(np.isfinite(tc), axis=1)
    mask = m_scores & m_centers

    dropped = int(n - int(mask.sum()))
    if dropped > 0:
        logger.warning(f"evaluate_model: filtered out {dropped} invalid samples (NaN/Inf)")

    if mask.sum() == 0:
        return {
            'mae_score': float('nan'),
            'rmse_score': float('nan'),
            'r2': float('nan'),
            'pearson': float('nan'),
            'pearson_p': float('nan'),
            'spearman': float('nan'),
            'spearman_p': float('nan'),
            'delta_e_mean': float('nan'),
            'delta_e_std': float('nan'),
            'delta_e_median': float('nan'),
            'delta_e_90': float('nan'),
            'euclidean_mean': float('nan'),
            'angle_error_mean': float('nan'),
        }

    ps, ts, pc, tc = ps[mask], ts[mask], pc[mask], tc[mask]

    mae_score = mean_absolute_error(ts, ps)
    rmse_score = np.sqrt(mean_squared_error(ts, ps))
    try:
        r2 = r2_score(ts, ps)
    except Exception:
        r2 = float('nan')

    try:
        pearson_corr, pearson_p = pearsonr(ts, ps)
    except Exception:
        pearson_corr, pearson_p = float('nan'), float('nan')
    try:
        spearman_corr, spearman_p = spearmanr(ts, ps)
    except Exception:
        spearman_corr, spearman_p = float('nan'), float('nan')

    delta_e_values = calculate_delta_e2000(pc, tc)
    delta_e_mean = float(np.mean(delta_e_values))
    delta_e_std = float(np.std(delta_e_values))
    delta_e_median = float(np.median(delta_e_values))
    delta_e_90 = float(np.percentile(delta_e_values, 90))

    euclidean_distances = np.sqrt(np.sum((pc - tc) ** 2, axis=1))
    euclidean_mean = float(np.mean(euclidean_distances))

    pred_angles = np.arctan2(pc[:, 1], pc[:, 0])
    target_angles = np.arctan2(tc[:, 1], tc[:, 0])
    angle_errors = np.abs(pred_angles - target_angles)
    angle_errors = np.minimum(angle_errors, 2 * np.pi - angle_errors)
    angle_error_mean = float(np.mean(angle_errors) * 180 / np.pi)

    return {
        'mae_score': float(mae_score),
        'rmse_score': float(rmse_score),
        'r2': float(r2),
        'pearson': float(pearson_corr),
        'pearson_p': float(pearson_p),
        'spearman': float(spearman_corr),
        'spearman_p': float(spearman_p),
        'delta_e_mean': delta_e_mean,
        'delta_e_std': delta_e_std,
        'delta_e_median': delta_e_median,
        'delta_e_90': delta_e_90,
        'euclidean_mean': euclidean_mean,
        'angle_error_mean': angle_error_mean,
    }


# 默认导出名指向安全版本，避免上层未更新仍报错
evaluate_model = evaluate_model_safe
