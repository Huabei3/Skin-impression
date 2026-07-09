"""
Statistical Stream module.

Encodes non-pixel scene/portrait metadata into a feature vector,
concatenated with face + global features before fusion.

Usage:
  --ablation-stat-stream  (启用统计流)
  不加则完全回退到原始 STIM-CNN 逻辑
"""

from __future__ import annotations

import torch
import torch.nn as nn


# ============================================================
# Metadata 编码规则
# ============================================================

# 场景类型 → one-hot index
_SCENE_TYPE_MAP = {
    # lab scenes: ih3k, ih4k, ..., imd65, il3k, ..., mh3k, ... → 0
    "i": 0,  # lab/studio
}

# 实景场景 → category
_REAL_SCENE_CATEGORY = {
    # indoor
    "rs01": 1, "rs02": 1, "rs05": 1, "rs06": 1,
    # outdoor
    "rs03": 2, "rs07": 2, "rs08": 2, "rs10": 2, "rs12": 2,
    # backlight
    "rs04": 3, "rs09": 3, "rs11": 3,
    # night
    "rs13": 4, "rs14": 4,
}

# lab scene CCT 查询
_LAB_CCT = {
    "h3k": 3000, "h4k": 4000, "h5k": 5000, "h6k": 6000,
    "h7k": 7000, "h8k": 8000, "hd65": 6500,
    "m3k": 3000, "m4k": 4000, "m5k": 5000, "m6k": 6000,
    "m7k": 7000, "m8k": 8000, "md65": 6500,
    "l3k": 3000, "l4k": 4000, "l5k": 5000, "l6k": 6000,
    "l7k": 7000, "l8k": 8000, "ld65": 6500,
}

# lab scene 照度查询
_LAB_ILLUM = {
    "h": 1000, "m": 500, "l": 100,
}

# 模型ID → 人种 (one-hot index: 0=CA, 1=AS, 2=SA, 3=AF)
_MODEL_ETHNICITY = {
    "01": 0, "02": 0, "03": 0,   # CA
    "04": 1, "05": 1, "06": 1,   # AS
    "07": 2, "08": 2,            # SA
    "09": 3, "10": 3,            # AF
}

# CCT 归一化范围
_CCT_MIN, _CCT_MAX = 3000.0, 8000.0
# 照度归一化范围 (lux)
_ILLUM_MIN, _ILLUM_MAX = 100.0, 1000.0


def extract_metadata(original_name: str) -> torch.Tensor:
    """
    从 original_name 提取统计特征向量 (11-D)。

    original_name 格式示例:
      "f07ih3k_01" → model=f07, female, ethnicity=SA, lab scene, CCT=3000K, illuminance=1000lx
      "m05rrs03_15" → model=m05, male, ethnicity=AS, outdoor scene, CCT≈5500K, illuminance≈500lx
      "f01imd65_22" → model=f01, female, ethnicity=CA, lab scene, CCT=6500K, illuminance=500lx

    Returns: (11,) tensor
      [0:4]   scene_type one-hot [lab, indoor, outdoor, night]
      [4]     CCT normalized [0, 1]
      [5]     illuminance normalized [0, 1]
      [6:10]  ethnicity one-hot [CA, AS, SA, AF]
      [10]    gender (0=female, 1=male)
    """
    s = str(original_name)
    # 去掉末尾 _数字 后缀
    parts = s.rsplit("_", 1)
    prefix = parts[0] if len(parts) >= 2 else s

    if len(prefix) < 5:
        raise ValueError(f"Cannot parse original_name: {original_name!r}")

    model_id = prefix[1:3]   # e.g. "07" from "f07"
    gender = 0 if prefix[0] == "f" else 1   # f=female, m=male
    ior = prefix[3]           # "i" or "r"
    scene_code = prefix[4:]   # e.g. "h3k" or "rs01"

    # --- scene type one-hot ---
    scene_onehot = [0.0, 0.0, 0.0, 0.0]  # [lab, indoor, outdoor, night]
    cct = 5500.0      # default for real scenes
    illuminance = 500.0  # default for real scenes

    if ior == "i":
        # lab scene
        scene_onehot[0] = 1.0
        cct = float(_LAB_CCT.get(scene_code, 6500))
        # illuminance from first char of scene_code (h/m/l)
        ill_key = scene_code[0] if len(scene_code) > 0 else "m"
        illuminance = float(_LAB_ILLUM.get(ill_key, 500))
    else:
        # real scene
        cat = _REAL_SCENE_CATEGORY.get(scene_code, 0)
        if cat == 1:
            scene_onehot[1] = 1.0  # indoor
        elif cat == 2:
            scene_onehot[2] = 1.0  # outdoor
        elif cat == 3:
            scene_onehot[2] = 1.0  # outdoor (backlight is subset of outdoor)
        elif cat == 4:
            scene_onehot[3] = 1.0  # night
        # CCT / illuminance: use defaults for real scenes (≈outdoor avg)

    # --- ethnicity one-hot ---
    eth_idx = _MODEL_ETHNICITY.get(model_id, 0)
    eth_onehot = [0.0, 0.0, 0.0, 0.0]
    eth_onehot[eth_idx] = 1.0

    # --- normalize continuous ---
    cct_norm = (cct - _CCT_MIN) / (_CCT_MAX - _CCT_MIN)
    illum_norm = (illuminance - _ILLUM_MIN) / (_ILLUM_MAX - _ILLUM_MIN)

    vec = scene_onehot + [cct_norm, illum_norm] + eth_onehot + [float(gender)]
    return torch.tensor(vec, dtype=torch.float32)


# ============================================================
# Statistical Stream Module
# ============================================================

class StatisticalStream(nn.Module):
    """
    将场景/人像元数据编码为特征向量。

    输入: (B, 11) metadata tensor
    输出: (B, output_dim) feature tensor
    """

    def __init__(self, input_dim: int = 11, hidden_dim: int = 64,
                 output_dim: int = 128, dropout: float = 0.2) -> None:
        super().__init__()
        self.net = nn.Sequential(
            nn.Linear(int(input_dim), int(hidden_dim)),
            nn.BatchNorm1d(int(hidden_dim)),
            nn.ReLU(inplace=True),
            nn.Dropout(float(dropout)),
            nn.Linear(int(hidden_dim), int(output_dim)),
            nn.BatchNorm1d(int(output_dim)),
            nn.ReLU(inplace=True),
        )
        self.output_dim = int(output_dim)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        return self.net(x)
