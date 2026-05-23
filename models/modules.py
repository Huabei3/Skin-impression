import torch
import torch.nn as nn
import torch.nn.functional as F
import numpy as np
from skimage import color
import cv2


# ==================== ① 肤色区域注意力 ====================
class SkinRegionAttention(nn.Module):
    """肤色区域注意力模块"""
    def __init__(self, method='hsv_threshold'):
        super(SkinRegionAttention, self).__init__()
        self.method = method

        # 可学习的注意力权重
        self.attention_conv = nn.Sequential(
            nn.Conv2d(1, 16, kernel_size=3, padding=1),
            nn.ReLU(inplace=True),
            nn.Conv2d(16, 1, kernel_size=1),
            nn.Sigmoid()
        )

    def get_skin_mask(self, x):
        """提取肤色掩膜"""
        # x: [B, 3, H, W] in range [0, 1]
        B, C, H, W = x.shape
        masks = []

        for i in range(B):
            img = x[i].permute(1, 2, 0).cpu().numpy()  # [H, W, 3]
            img_uint8 = (img * 255).astype(np.uint8)

            if self.method == 'hsv_threshold':
                # HSV阈值分割
                hsv = cv2.cvtColor(img_uint8, cv2.COLOR_RGB2HSV)
                lower = np.array([0, 20, 70], dtype=np.uint8)
                upper = np.array([20, 255, 255], dtype=np.uint8)
                mask = cv2.inRange(hsv, lower, upper)
                mask = mask.astype(np.float32) / 255.0
            else:
                # 简单的RGB阈值
                mask = np.ones((H, W), dtype=np.float32)

            masks.append(torch.from_numpy(mask))

        masks = torch.stack(masks).unsqueeze(1).to(x.device)  # [B, 1, H, W]
        return masks

    def forward(self, x):
        """
        x: [B, C, H, W]
        """
        # 获取肤色掩膜
        skin_mask = self.get_skin_mask(x)

        # 可学习的注意力增强
        attention_map = self.attention_conv(skin_mask)

        # 应用注意力
        return x * attention_map, skin_mask


# ==================== ② 色彩空间分支 ====================
class ColorSpaceBranch(nn.Module):
    """单个色彩空间的特征提取分支"""
    def __init__(self, backbone, color_space='rgb'):
        super(ColorSpaceBranch, self).__init__()
        self.color_space = color_space
        self.backbone = backbone

    def rgb_to_lab(self, x):
        """RGB转L*a*b*"""
        # x: [B, 3, H, W] in range [0, 1]
        B, C, H, W = x.shape
        lab_images = []

        for i in range(B):
            rgb = x[i].permute(1, 2, 0).cpu().numpy()  # [H, W, 3]
            lab = color.rgb2lab(rgb)  # L: [0, 100], a: [-128, 127], b: [-128, 127]

            # 归一化到[0, 1]
            lab[:, :, 0] = lab[:, :, 0] / 100.0  # L
            lab[:, :, 1] = (lab[:, :, 1] + 128) / 255.0  # a
            lab[:, :, 2] = (lab[:, :, 2] + 128) / 255.0  # b

            lab_images.append(torch.from_numpy(lab).float())

        lab_tensor = torch.stack(lab_images).permute(0, 3, 1, 2).to(x.device)
        return lab_tensor

    def forward(self, x):
        """
        x: [B, 3, H, W] RGB图像
        """
        if self.color_space == 'lab':
            x = self.rgb_to_lab(x)
        elif self.color_space == 'hsv':
            # 可以添加HSV转换
            pass

        return self.backbone(x)


# ==================== ③ 肤色统计特征 ====================
class SkinStatisticsModule(nn.Module):
    """提取肤色统计特征"""
    def __init__(self, feature_dim=64):
        super(SkinStatisticsModule, self).__init__()

        # ���统计特征映射到高维空间
        self.fc = nn.Sequential(
            nn.Linear(3, feature_dim),  # 3: RGB平均值
            nn.ReLU(inplace=True),
            nn.Linear(feature_dim, feature_dim)
        )

    def forward(self, x, skin_mask):
        """
        x: [B, 3, H, W]
        skin_mask: [B, 1, H, W]
        """
        B = x.size(0)

        # 计算肤色区域的平均颜色
        masked_x = x * skin_mask  # [B, 3, H, W]
        sum_pixels = skin_mask.sum(dim=[2, 3], keepdim=True)  # [B, 1, 1, 1]
        sum_pixels = sum_pixels + 1e-6  # 避免除零

        mean_color = masked_x.sum(dim=[2, 3]) / sum_pixels.squeeze(-1).squeeze(-1)  # [B, 3]

        # 映射到特征空间
        stats_features = self.fc(mean_color)  # [B, feature_dim]

        return stats_features, mean_color


# ==================== ⑤ 多任务头 ====================
class MultiTaskHead(nn.Module):
    """多任务学习头"""
    def __init__(self, in_features=1024, tasks_config=None):
        super(MultiTaskHead, self).__init__()
        self.tasks_config = tasks_config or {}

        # 共享特征层
        self.shared_fc = nn.Sequential(
            nn.Linear(in_features, 512),
            nn.ReLU(inplace=True),
            nn.Dropout(0.5)
        )

        # 任务1: 喜好度评分
        if self.tasks_config.get('preference_score', {}).get('enabled', True):
            self.score_head = nn.Sequential(
                nn.Linear(512, 128),
                nn.ReLU(inplace=True),
                nn.Dropout(0.3),
                nn.Linear(128, 1)
            )

        # 任务2: 喜好中心L*a*b*
        if self.tasks_config.get('preference_center', {}).get('enabled', False):
            self.center_head = nn.Sequential(
                nn.Linear(512, 128),
                nn.ReLU(inplace=True),
                nn.Dropout(0.3),
                nn.Linear(128, 3)  # L*, a*, b*
            )

    def forward(self, x):
        """
        x: [B, in_features]
        返回: dict of outputs
        """
        shared = self.shared_fc(x)

        outputs = {}

        if hasattr(self, 'score_head'):
            outputs['preference_score'] = self.score_head(shared)

        if hasattr(self, 'center_head'):
            outputs['preference_center'] = self.center_head(shared)

        return outputs


# ==================== ⑥ 肤色渲染模块 ====================
class SkinRenderingModule(nn.Module):
    """根据喜好中心渲染肤色"""
    def __init__(self):
        super(SkinRenderingModule, self).__init__()

    def render(self, image, skin_mask, target_lab):
        """
        image: [B, 3, H, W] RGB图像
        skin_mask: [B, 1, H, W] 肤色掩膜
        target_lab: [B, 3] 目标L*a*b*值
        """
        B, C, H, W = image.shape
        rendered_images = []

        for i in range(B):
            rgb = image[i].permute(1, 2, 0).cpu().numpy()
            mask = skin_mask[i, 0].cpu().numpy()
            target = target_lab[i].cpu().numpy()

            # RGB转L*a*b*
            lab = color.rgb2lab(rgb)

            # 在肤色区域替换为目标L*a*b*
            lab[mask > 0.5] = target

            # L*a*b*转回RGB
            rendered_rgb = color.lab2rgb(lab)
            rendered_images.append(torch.from_numpy(rendered_rgb).float())

        rendered = torch.stack(rendered_images).permute(0, 3, 1, 2).to(image.device)
        return rendered
