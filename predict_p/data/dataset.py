"""
数据集类 - 处理人脸RGB图像、UV数据和Excel GT
"""
import os
import re
import hashlib
import numpy as np
import pandas as pd
import torch
from torch.utils.data import Dataset, DataLoader
from PIL import Image
import torchvision.transforms as transforms
import torchvision.transforms.functional as F
from pathlib import Path
from typing import Dict, Tuple, List, Optional
import logging
from sklearn.model_selection import train_test_split
import openpyxl

logger = logging.getLogger(__name__)


class FacialPreferenceDataset(Dataset):
    """人脸颜色喜好度数据集"""
    
    def __init__(self, 
                 face_rgb_root: Path,
                 face_uv_root: Path,
                 gt_excel_path: Path,
                 split: str = 'train',
                 transform: Optional[transforms.Compose] = None,
                 seed: int = 42,
                 train_ratio: float = 0.7,
                 val_ratio: float = 0.15,
                 test_ratio: float = 0.15,
                 allowed_ids: Optional[List] = None,
                 global_rgb_root: Optional[Path] = None,
                 split_strategy: str = "stable_by_id_hash",
                 load_uv: bool = True,
                 uv_is_hist: bool = False,
                 uv_log_ratio: bool = False,
                 allowed_scenes: Optional[List] = None,
                 valid_prefixes: Optional[List[str]] = None,
                 test_prefixes: Optional[List[str]] = None,
                 split_export_path: Optional[str] = None):
        """
        初始化数据集
        
        Args:
            face_rgb_root: 人脸RGB图像根目录
            face_uv_root: 人脸UV数据根目录
            gt_excel_path: GT Excel文件路径
            split: 数据集划分 ('train', 'val', 'test')
            transform: 图像变换
            seed: 随机种子
            train_ratio: 训练集比例
            val_ratio: 验证集比例
            test_ratio: 测试集比例
            valid_prefixes: manual_prefix策略下进入valid的original_name前缀列表
            test_prefixes: manual_prefix策略下进入test的original_name前缀列表
            split_export_path: 划分结果导出xlsx路径（None不导出）
        """
        self.face_rgb_root = Path(face_rgb_root)
        self.face_uv_root = Path(face_uv_root)
        self.gt_excel_path = Path(gt_excel_path)
        self.split = split
        self.transform = transform
        self.seed = seed
        self.split_strategy = split_strategy
        self.load_uv = bool(load_uv)
        self.uv_is_hist = bool(uv_is_hist)
        self.uv_log_ratio = bool(uv_log_ratio)
        self.valid_prefixes = self._normalize_prefixes(valid_prefixes)
        self.test_prefixes = self._normalize_prefixes(test_prefixes)
        self.split_export_path = split_export_path
        # 全局图根目录：默认回退到 face_rgb_root，便于兼容旧配置
        self.global_rgb_root = Path(global_rgb_root) if global_rgb_root is not None else self.face_rgb_root
        # 允许使用的编号（两位字符串，如 "01"），None 表示全部
        self.allowed_ids = self._normalize_ids(allowed_ids)
        self.allowed_scenes = self._normalize_scenes(allowed_scenes)
        self.allowed_scenes_set = set(self.allowed_scenes) if self.allowed_scenes is not None else None
        
        # 设置数据集划分比例
        self.train_ratio = train_ratio
        self.val_ratio = val_ratio
        self.test_ratio = test_ratio
        
        # 加载数据
        self.data_items = self._load_data()

        # Phase 0: 预计算 Statistical Stream 特征（scene_type, CCT, illuminance, ethnicity, gender）
        from predict_p.models.stat_stream import extract_metadata as _extract_stat
        for item in self.data_items:
            oname = item.get("original_name", "")
            item["stat_features"] = _extract_stat(oname) if oname else torch.zeros(11)

        # 如有需要，按编号过滤（基于子文件夹名/Sheet名，例如 f01i/m01r）
        if self.allowed_ids is not None:
            self._filter_by_ids()

        # 保存一份全量数据副本（供 manual_prefix 导出 xlsx 使用）
        self._all_data_items_for_export = list(self.data_items)

        # 数据集划分
        self._split_dataset_by_items()
        
        logger.info(f"Loaded {len(self.data_items)} samples for {split} split")
    
    def _load_data(self) -> List[Dict]:
        """
        加载所有数据
        
        Returns:
            数据项列表，每项包含文件路径和标签
        """
        data_items = []
        
        # 加载Excel文件
        excel_file = pd.ExcelFile(self.gt_excel_path)
        
        # 遍历每个sheet（每个sheet代表一个人在一个场景下的数据）
        for sheet_name in excel_file.sheet_names:
            if self.allowed_scenes_set is not None:
                if str(sheet_name).lower() not in self.allowed_scenes_set:
                    continue
            df = pd.read_excel(excel_file, sheet_name=sheet_name)
            
            # 获取场景和人物信息（从sheet名称解析）
            scene_person = sheet_name  # 例如: "person1_scene1"
            
            # 遍历每一行数据
            for idx, row in df.iterrows():
                # 获取原始文件名（第一列）
                original_name = row.iloc[0]
                
                # 获取喜好度评分（第二列）
                preference_score = float(row.iloc[1])

                # 获取喜好中心LAB（第3-5列）
                # 备注：模型目前只预测 a*/b*，但测试阶段的色差计算需要使用 GT 的 L*
                try:
                    l_star = float(row.iloc[2])
                except Exception:
                    l_star = np.nan
                a_star = float(row.iloc[3])
                b_star = float(row.iloc[4])

                # 过滤无效标注（NaN/Inf）
                if not np.isfinite(preference_score) or not np.isfinite(a_star) or not np.isfinite(b_star):
                    logger.warning(f"Skip row with invalid labels in sheet '{sheet_name}', index {idx}:")
                    logger.warning(f"  score={preference_score}, a*={a_star}, b*={b_star}")
                    continue
                if not np.isfinite(l_star):
                    # 若 GT 缺失 L*，回退到常用参考值，避免整个样本被丢弃
                    l_star = 50.0
                
                # 构建文件路径
                # 人脸RGB文件：原名_face.jpg
                face_rgb_filename = f"{original_name}_face.jpg"
                face_rgb_path = self.face_rgb_root / scene_person / face_rgb_filename
                
                # 全局RGB文件：原名.jpg（与人脸同一 original_name，但不带 _face 后缀）
                global_rgb_filename = f"{original_name}.jpg"
                global_rgb_path = self.global_rgb_root / scene_person / global_rgb_filename
                
                # UV文件：原名_face_uv.npy
                face_uv_filename = f"{original_name}_face_uv.npy"
                face_uv_path = self.face_uv_root / scene_person / face_uv_filename
                
                # 检查文件是否存在（全局图若缺失，则回退到人脸RGB路径）
                if not face_rgb_path.exists():
                    logger.warning(f"RGB file not found: {face_rgb_path}")
                    continue
                if self.load_uv and not face_uv_path.exists():
                    logger.warning(f"UV file not found: {face_uv_path}")
                    continue
                if not global_rgb_path.exists():
                    logger.warning(f"Global RGB file not found: {global_rgb_path}, fallback to face_rgb_path")
                    global_rgb_path = face_rgb_path
                
                # 添加数据项
                data_item = {
                    'face_rgb_path': str(face_rgb_path),
                    'face_uv_path': str(face_uv_path),
                    'global_rgb_path': str(global_rgb_path),
                    'preference_score': preference_score,
                    'preference_L': float(l_star),
                    'preference_center': (a_star, b_star),
                    'scene_person': scene_person,
                    'original_name': original_name
                }
                data_items.append(data_item)
        
        logger.info(f"Total loaded samples: {len(data_items)}")
        return data_items

    @staticmethod
    def _normalize_ids(allowed_ids: Optional[List]) -> Optional[List[str]]:
        """将编号标准化为两位字符串列表；None 或 'all' 返回 None。

        支持输入：
        - None / 'all'：返回 None（表示使用全部）
        - ["01", "02"] 或 [1, 2]：返回 ["01", "02"]
        """
        if allowed_ids is None:
            return None
        if isinstance(allowed_ids, str):
            if allowed_ids.lower() == 'all':
                return None
            # 逗号分隔字符串也支持，例如 "01,02,03"
            parts = [p.strip() for p in allowed_ids.split(',') if p.strip()]
            return [f"{int(p):02d}" for p in parts if p.isdigit() or p.isnumeric()]
        norm: List[str] = []
        for x in allowed_ids:
            try:
                norm.append(f"{int(x):02d}")
            except Exception:
                # 忽略非数字项
                continue
        return norm if norm else None

    @staticmethod
    def _normalize_scenes(allowed_scenes: Optional[List]) -> Optional[List[str]]:
        """
        Normalize scene/sheet selection.

        Supported:
          - None / "all": return None
          - "inLab,outdoor": return ["inlab", "outdoor"]
          - ["inLab", "outdoor"]: return ["inlab", "outdoor"]
        """
        if allowed_scenes is None:
            return None
        if isinstance(allowed_scenes, str):
            s = allowed_scenes.strip()
            if not s or s.lower() == "all":
                return None
            parts = [p.strip() for p in s.split(",") if p.strip()]
            return sorted({p.lower() for p in parts}) if parts else None
        parts = []
        for x in allowed_scenes:
            sx = str(x).strip()
            if sx:
                parts.append(sx.lower())
        return sorted(set(parts)) if parts else None

    @staticmethod
    def _load_npy_fix(path: str) -> np.ndarray:
        """鲁棒加载 .npy 文件，兼容文件头被错误 UTF-8 编码（开头多 0xc2 字节）的情况。

        正常 .npy 文件头: \\x93NUMPY
        损坏 .npy 文件头: \\xc2\\x93NUMPY  (0x93 被错误编码为 UTF-8 双字节)
        """
        with open(path, 'rb') as f:
            header = f.read(6)
            if header == b'\x93NUMPY':
                # 正常文件：seek 回开头，交给 numpy
                f.seek(0)
                return np.load(f, allow_pickle=True)
            elif header == b'\xc2\x93NUMP':
                # 损坏文件：跳过第一个字节，从第二个字节开始读
                f.seek(1)
                return np.load(f, allow_pickle=True)
            else:
                # 未知格式，回退到标准加载
                f.seek(0)
                return np.load(f, allow_pickle=True)

    @staticmethod
    def _normalize_prefixes(prefixes: Optional[List[str]]) -> Optional[set]:
        """标准化前缀列表：None/空列表 → None，否则返回 set"""
        if prefixes is None:
            return None
        if isinstance(prefixes, (list, tuple, set)):
            cleaned = {str(p).strip() for p in prefixes if p and str(p).strip()}
            return cleaned if cleaned else None
        return None

    @staticmethod
    def _extract_prefix_from_original_name(original_name: str) -> str:
        """从 original_name 提取场景前缀（去掉末尾 _数字 后缀）。
        
        例如: "f08rrs02_01" → "f08rrs02"
              "f05ih3k_15" → "f05ih3k"
              "no_underscore" → "no_underscore" (不变)
        """
        s = str(original_name)
        parts = s.rsplit("_", 1)
        if len(parts) == 2 and parts[1].isdigit():
            return parts[0]
        return s

    @staticmethod
    def _extract_id_from_name(name: str) -> Optional[str]:
        """从子文件夹/Sheet 名（如 f01i/m01r）中提取两位编号。

        规则：匹配 ^[fm](\d{2})[ir]$，匹配成功返回两位数字，否则返回 None。
        """
        m = re.match(r'^[fm](\d{2})[ir]$', name)
        if m:
            return m.group(1)
        return None

    def _filter_by_ids(self) -> None:
        """按编号过滤数据项。"""
        before = len(self.data_items)
        filtered: List[Dict] = []
        for item in self.data_items:
            sid = self._extract_id_from_name(item['scene_person'])
            if sid is None:
                # 不符合命名规则的 sheet/文件夹，直接跳过（严格遵循用户的命名约定）
                continue
            if sid in self.allowed_ids:
                filtered.append(item)
        self.data_items = filtered
        logger.info(f"Filtered by IDs {self.allowed_ids}: {before} -> {len(self.data_items)} samples")
    
    def _split_dataset(self):
        """
        根据seed进行3-fold数据集划分
        """
        # 获取所有场景-人物组合
        scene_persons = list(set([item['scene_person'] for item in self.data_items]))
        
        # 设置随机种子以确保可重复性
        np.random.seed(self.seed)
        np.random.shuffle(scene_persons)
        
        # 计算划分点
        n_total = len(scene_persons)
        # 先确定训练集场景数
        n_train = max(1, int(round(n_total * self.train_ratio))) if n_total > 0 else 0
        n_train = min(n_train, n_total)
        # 对剩余场景，按 val:test 比例切分，避免 test 为 0
        rem = max(0, n_total - n_train)
        if rem == 0:
            n_val = 0
            n_test = 0
        else:
            vt = max(1e-6, float(self.val_ratio) + float(self.test_ratio))
            n_val = int(round(rem * (float(self.val_ratio) / vt)))
            if rem >= 2:
                n_val = max(1, min(rem - 1, n_val))
            else:
                n_val = 0
            n_test = rem - n_val

        # 划分场景-人物组合
        train_scenes = scene_persons[:n_train]
        vt_scenes = scene_persons[n_train:]
        val_scenes = vt_scenes[:n_val]
        test_scenes = vt_scenes[n_val:]
        
        # 根据split筛选数据
        if self.split == 'train':
            self.data_items = [item for item in self.data_items 
                              if item['scene_person'] in train_scenes]
        elif self.split == 'val':
            self.data_items = [item for item in self.data_items 
                              if item['scene_person'] in val_scenes]
        elif self.split == 'test':
            self.data_items = [item for item in self.data_items 
                              if item['scene_person'] in test_scenes]
        else:
            raise ValueError(f"Invalid split: {self.split}")
    
    def _split_dataset_by_items_legacy_shuffle(self) -> None:
        """旧版样本级划分：对当前 data_items 直接洗牌后切 train/val/test。

        注意：该策略对“先过滤 allowed_ids 再切分”的场景不稳定，
        不同编号组合会改变每个编号内部的 train/val/test 归属。
        仅用于兼容历史训练的 checkpoint（不想重训但想复现当时的划分）。
        """
        n_total = len(self.data_items)
        if n_total == 0:
            return
        indices = np.arange(n_total)
        np.random.seed(self.seed)
        np.random.shuffle(indices)

        n_val = int(round(n_total * float(self.val_ratio)))
        n_test = int(round(n_total * float(self.test_ratio)))
        n_train = n_total - n_val - n_test

        # 确保在样本允许的前提下，val/test 非空
        if n_total >= 2:
            if self.val_ratio > 0 and n_val == 0:
                if n_train > 1:
                    n_train -= 1
                    n_val += 1
                elif n_test > 0:
                    n_test -= 1
                    n_val += 1
            if self.test_ratio > 0 and n_test == 0:
                if n_train > 1:
                    n_train -= 1
                    n_test += 1
                elif n_val > 1:
                    n_val -= 1
                    n_test += 1

        train_idx = indices[:n_train]
        val_idx = indices[n_train:n_train + n_val]
        test_idx = indices[n_train + n_val:]

        if self.split == 'train':
            self.data_items = [self.data_items[i] for i in train_idx]
        elif self.split == 'val':
            self.data_items = [self.data_items[i] for i in val_idx]
        elif self.split == 'test':
            self.data_items = [self.data_items[i] for i in test_idx]
        else:
            raise ValueError(f"Invalid split: {self.split}")

    def _split_dataset_by_items_stable_by_id_hash(self) -> None:
        """样本级划分（稳定且可复现），按编号分组后切分 train/val/test。

        设计目标：
        - 固定 seed 后，同一个样本永远分到同一个 split；
        - 当 allowed_ids 改变（选择 01/02/任意组合）时，每个编号内部的划分保持不变；
        - 允许 TRAIN_IDS 与 TEST_IDS 交叠时，也能保证 train/val/test 互斥，避免“训练见过测试样本”。
        """
        n_total = len(self.data_items)
        if n_total == 0:
            return

        def _stable_int(text: str) -> int:
            # 使用稳定哈希，避免 Python 内置 hash 的随机化导致跨进程/跨运行不一致
            h = hashlib.md5(text.encode("utf-8")).digest()
            return int.from_bytes(h[:8], byteorder="big", signed=False)

        def _split_counts(n: int) -> tuple[int, int, int]:
            n_val = int(round(n * float(self.val_ratio)))
            n_test = int(round(n * float(self.test_ratio)))
            n_train = n - n_val - n_test

            # 确保在样本允许的前提下，val/test 非空
            if n >= 2:
                if self.val_ratio > 0 and n_val == 0:
                    if n_train > 1:
                        n_train -= 1
                        n_val += 1
                    elif n_test > 0:
                        n_test -= 1
                        n_val += 1
                if self.test_ratio > 0 and n_test == 0:
                    if n_train > 1:
                        n_train -= 1
                        n_test += 1
                    elif n_val > 1:
                        n_val -= 1
                        n_test += 1

            # 兜底：避免出现负数（极端比例设置/浮点误差）
            if n_train < 0:
                n_train = 0
            if n_val < 0:
                n_val = 0
            if n_test < 0:
                n_test = 0
            # 再兜底：保证总和为 n（必要时从 n_train 调整）
            s = n_train + n_val + n_test
            if s != n:
                n_train = max(0, n_train + (n - s))
            return n_train, n_val, n_test

        # 1) 按编号分组（编号从 scene_person 中提取，如 f01i/m01r -> "01"）
        groups: Dict[str, List[int]] = {}
        for idx, item in enumerate(self.data_items):
            sid = self._extract_id_from_name(item.get("scene_person", ""))
            group_key = sid if sid is not None else str(item.get("scene_person", "unknown"))
            groups.setdefault(group_key, []).append(idx)

        # 2) 每组内使用“样本稳定哈希”排序，再按比例切分
        train_idx: List[int] = []
        val_idx: List[int] = []
        test_idx: List[int] = []

        for group_key in sorted(groups.keys()):
            g_indices = groups[group_key]
            g_indices_sorted = sorted(
                g_indices,
                key=lambda i: _stable_int(
                    f"{int(self.seed)}|{self.data_items[i].get('scene_person','')}|{self.data_items[i].get('original_name','')}"
                ),
            )

            n_train, n_val, n_test = _split_counts(len(g_indices_sorted))
            train_idx.extend(g_indices_sorted[:n_train])
            val_idx.extend(g_indices_sorted[n_train:n_train + n_val])
            test_idx.extend(g_indices_sorted[n_train + n_val:n_train + n_val + n_test])

        # 3) 选择 split 对应的子集
        if self.split == 'train':
            chosen = train_idx
        elif self.split == 'val':
            chosen = val_idx
        elif self.split == 'test':
            chosen = test_idx
        else:
            raise ValueError(f"Invalid split: {self.split}")

        self.data_items = [self.data_items[i] for i in chosen]

    @staticmethod
    def _extract_group_prefix_from_original_name(original_name: str) -> Optional[str]:
        """
        提取“同源样本组”前缀，用于避免将强相关样本拆到不同 split 造成泄漏。

        典型场景（OPPO 实验数据）:
          original_name = "cropped_inLab01_01" ... "cropped_inLab01_49"
        这些样本通常共享同一底图，仅皮肤色不同，应当作为一个 group 一起切分。

        规则（尽量保守）:
          - 若存在 '_' 且最后一段为纯数字（如 "01" / "49"），则返回去掉最后一段后的前缀；
          - 否则返回 None。
        """
        if not original_name:
            return None
        parts = str(original_name).split("_")
        if len(parts) < 2:
            return None
        last = parts[-1]
        if not last.isdigit():
            return None
        prefix = "_".join(parts[:-1]).strip()
        return prefix or None

    def _split_dataset_by_items_stable_by_original_prefix(self) -> None:
        """
        样本组级别的稳定切分（避免强相关样本跨 split）。

        与 stable_by_id_hash 的差异:
          - stable_by_id_hash 是“组内按样本切分”，适用于每个样本相对独立的情况；
          - 本策略是“组作为整体切分”，适用于同一个 original_name 前缀代表同一底图/同一人
            的多种变体（如 OPPO 的 49 张皮肤色版本），否则会导致 test 过于乐观。
        """
        n_total = len(self.data_items)
        if n_total == 0:
            return

        def _stable_int(text: str) -> int:
            h = hashlib.md5(text.encode("utf-8")).digest()
            return int.from_bytes(h[:8], byteorder="big", signed=False)

        def _split_counts(n: int) -> tuple[int, int, int]:
            n_val = int(round(n * float(self.val_ratio)))
            n_test = int(round(n * float(self.test_ratio)))
            n_train = n - n_val - n_test

            if n >= 2:
                if self.val_ratio > 0 and n_val == 0:
                    if n_train > 1:
                        n_train -= 1
                        n_val += 1
                    elif n_test > 0:
                        n_test -= 1
                        n_val += 1
                if self.test_ratio > 0 and n_test == 0:
                    if n_train > 1:
                        n_train -= 1
                        n_test += 1
                    elif n_val > 1:
                        n_val -= 1
                        n_test += 1

            if n_train < 0:
                n_train = 0
            if n_val < 0:
                n_val = 0
            if n_test < 0:
                n_test = 0
            s = n_train + n_val + n_test
            if s != n:
                n_train = max(0, n_train + (n - s))
            return n_train, n_val, n_test

        # 1) 构建样本组
        groups: Dict[str, List[int]] = {}
        for idx, item in enumerate(self.data_items):
            scene_person = str(item.get("scene_person", ""))
            original_name = str(item.get("original_name", ""))
            group_prefix = self._extract_group_prefix_from_original_name(original_name)
            if group_prefix is not None:
                group_key = f"{scene_person}|{group_prefix}"
            else:
                # 回退：优先按两位编号（旧规则），否则按 sheet/folder 名
                sid = self._extract_id_from_name(scene_person)
                group_key = sid if sid is not None else scene_person
            groups.setdefault(group_key, []).append(idx)

        group_keys_sorted = sorted(
            groups.keys(),
            key=lambda k: _stable_int(f"{int(self.seed)}|{k}"),
        )

        n_train_g, n_val_g, n_test_g = _split_counts(len(group_keys_sorted))
        train_groups = set(group_keys_sorted[:n_train_g])
        val_groups = set(group_keys_sorted[n_train_g:n_train_g + n_val_g])
        test_groups = set(group_keys_sorted[n_train_g + n_val_g:n_train_g + n_val_g + n_test_g])

        train_idx: List[int] = []
        val_idx: List[int] = []
        test_idx: List[int] = []
        for gk in group_keys_sorted:
            if gk in train_groups:
                train_idx.extend(groups[gk])
            elif gk in val_groups:
                val_idx.extend(groups[gk])
            else:
                test_idx.extend(groups[gk])

        if self.split == "train":
            chosen = train_idx
        elif self.split == "val":
            chosen = val_idx
        elif self.split == "test":
            chosen = test_idx
        else:
            raise ValueError(f"Invalid split: {self.split}")

        self.data_items = [self.data_items[i] for i in chosen]

    def _split_dataset_by_items(self) -> None:
        """按 split_strategy 选择切分实现。"""
        strategy_raw = (getattr(self, "split_strategy", None) or "stable_by_id_hash").strip().lower()
        if strategy_raw in {"stable", "stable_by_id", "stable_by_id_hash", "by_id", "hash"}:
            return self._split_dataset_by_items_stable_by_id_hash()
        if strategy_raw in {"stable_by_original_prefix", "stable_by_prefix", "stable_by_group", "group"}:
            return self._split_dataset_by_items_stable_by_original_prefix()
        if strategy_raw in {"legacy", "legacy_shuffle", "shuffle"}:
            return self._split_dataset_by_items_legacy_shuffle()
        if strategy_raw in {"manual_prefix", "manual"}:
            return self._split_dataset_by_items_manual_prefix()
        raise ValueError(f"Unknown split_strategy: {self.split_strategy}")

    def _split_dataset_by_items_manual_prefix(self) -> None:
        """手动前缀划分策略。
        
        根据 VALID_PREFIXES / TEST_PREFIXES 配置，将匹配前缀的样本分配到 valid/test，
        其余全进 train。前缀从 original_name 提取（去掉末尾 _数字）。
        
        导出 xlsx 到 SPLIT_EXPORT_PATH（如果配置了）。
        """
        valid_prefixes: Optional[set] = getattr(self, "valid_prefixes", None)
        test_prefixes: Optional[set] = getattr(self, "test_prefixes", None)
        export_path: Optional[str] = getattr(self, "split_export_path", None)
        
        # 如果没配手动前缀，回退到 stable_by_id_hash
        if not valid_prefixes and not test_prefixes:
            logger.info("manual_prefix: no VALID_PREFIXES/TEST_PREFIXES configured, falling back to stable_by_id_hash")
            return self._split_dataset_by_items_stable_by_id_hash()
        
        n_total = len(self.data_items)
        if n_total == 0:
            return
        
        # 1) 为每个样本提取前缀并分配
        train_idx: List[int] = []
        val_idx: List[int] = []
        test_idx: List[int] = []
        
        for idx, item in enumerate(self.data_items):
            original_name = str(item.get("original_name", ""))
            prefix = self._extract_prefix_from_original_name(original_name)
            
            # test 优先（如果一个前缀同时出现在 valid 和 test 中，进 test）
            if test_prefixes and prefix in test_prefixes:
                test_idx.append(idx)
            elif valid_prefixes and prefix in valid_prefixes:
                val_idx.append(idx)
            else:
                train_idx.append(idx)
        
        # 2) 根据当前 split 选择子集
        if self.split == "train":
            chosen = train_idx
        elif self.split == "val":
            chosen = val_idx
        elif self.split == "test":
            chosen = test_idx
        else:
            raise ValueError(f"Invalid split: {self.split}")
        
        # 3) 导出划分结果 xlsx（在切分 self.data_items 之前，用 _all_data_items_for_export）
        if export_path and self.split == "train":
            full_items = getattr(self, "_all_data_items_for_export", None)
            if full_items is not None:
                self._export_split_result(
                    export_path=export_path,
                    train_idx=train_idx,
                    val_idx=val_idx,
                    test_idx=test_idx,
                    full_items=full_items,
                )
        
        self.data_items = [self.data_items[i] for i in chosen]
    
    def _export_split_result(self, export_path: str, train_idx: List[int],
                              val_idx: List[int], test_idx: List[int],
                              full_items: List[Dict]) -> None:
        """导出数据集划分结果到 xlsx 文件。
        
        输出列: Set | Model | iOr | Scene | original_name | scene_person
        """
        
        import openpyxl as xl
        from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
        
        wb = xl.Workbook()
        ws = wb.active
        ws.title = "Split Result"
        
        # 表头
        headers = ["Set", "Model", "iOr", "Scene", "original_name", "scene_person"]
        header_font = Font(bold=True, color="FFFFFF", size=11)
        header_fill = PatternFill(start_color="4472C4", end_color="4472C4", fill_type="solid")
        header_align = Alignment(horizontal="center", vertical="center")
        thin_border = Border(
            left=Side(style="thin"), right=Side(style="thin"),
            top=Side(style="thin"), bottom=Side(style="thin"),
        )
        
        for col_idx, h in enumerate(headers, 1):
            cell = ws.cell(row=1, column=col_idx, value=h)
            cell.font = header_font
            cell.fill = header_fill
            cell.alignment = header_align
            cell.border = thin_border
        
        # 颜色标记
        train_fill = PatternFill(start_color="C6EFCE", end_color="C6EFCE", fill_type="solid")  # 绿
        val_fill = PatternFill(start_color="BDD7EE", end_color="BDD7EE", fill_type="solid")    # 蓝
        test_fill = PatternFill(start_color="F4B4C2", end_color="F4B4C2", fill_type="solid")   # 红
        
        set_indices = {"train": train_idx, "val": val_idx, "test": test_idx}
        set_fills = {"train": train_fill, "val": val_fill, "test": test_fill}
        
        row = 2
        for set_name, indices in set_indices.items():
            fill = set_fills[set_name]
            for idx in indices:
                item = full_items[idx]
                sp = str(item.get("scene_person", ""))
                oname = str(item.get("original_name", ""))
                
                # 解析 model, iOr, scene
                # model: 从 scene_person 提取前3字符如 f01, m05
                model = sp[:3] if len(sp) >= 3 else sp
                
                # iOr: scene_person 的第4字符
                ior = sp[3] if len(sp) >= 4 else ""
                
                # scene: 从 original_name 前缀中去掉 model+ior 前缀
                # original_name 如 f01ih3k_01 → 前缀 f01ih3k
                prefix = self._extract_prefix_from_original_name(oname)
                # 去掉 model+ior 部分（如 f01i），剩余即 scene
                model_ior = model + ior
                if prefix.startswith(model_ior):
                    scene = prefix[len(model_ior):]
                else:
                    scene = prefix
                
                row_data = [set_name, model, ior, scene, oname, sp]
                for col_idx, val in enumerate(row_data, 1):
                    cell = ws.cell(row=row, column=col_idx, value=val)
                    cell.fill = fill
                    cell.border = thin_border
                    cell.alignment = Alignment(vertical="center")
                row += 1
        
        # 设置列宽
        col_widths = [10, 10, 8, 14, 30, 14]
        for col_idx, w in enumerate(col_widths, 1):
            ws.column_dimensions[xl.utils.get_column_letter(col_idx)].width = w
        
        # 冻结首行
        ws.freeze_panes = "A2"
        
        # 添加统计 sheet
        ws2 = wb.create_sheet("Statistics")
        ws2.cell(row=1, column=1, value="Set").font = header_font
        ws2.cell(row=1, column=2, value="Count").font = header_font
        for r, (set_name, indices) in enumerate(set_indices.items(), 2):
            ws2.cell(row=r, column=1, value=set_name)
            ws2.cell(row=r, column=2, value=len(indices))
        ws2.cell(row=5, column=1, value="Total").font = Font(bold=True)
        ws2.cell(row=5, column=2, value=sum(len(v) for v in set_indices.values()))
        ws2.column_dimensions["A"].width = 12
        ws2.column_dimensions["B"].width = 10
        
        # 确保目录存在
        Path(export_path).parent.mkdir(parents=True, exist_ok=True)
        wb.save(export_path)
        logger.info(f"Split result exported to: {export_path}")
        logger.info(f"  train={len(train_idx)}, val={len(val_idx)}, test={len(test_idx)}")

    def __len__(self) -> int:
        """返回数据集大小"""
        return len(self.data_items)
    
    def __getitem__(self, idx: int) -> Dict[str, torch.Tensor]:
        """
        获取一个数据样本
        
        Args:
            idx: 索引
            
        Returns:
            包含以下键的字典：
            - face_rgb: 人脸RGB图像张量
            - face_uv: 人脸UV数据张量
            - global_rgb: 全局流输入图像张量（当前与 face_rgb 相同）
            - preference_score: 喜好度评分
            - preference_center: 喜好中心(a*, b*)
            - metadata: 元数据
        """
        data_item = self.data_items[idx]
        
        # 加载人脸RGB图像与全局RGB图像（路径可能不同，但一一对应）
        face_rgb_img = Image.open(data_item['face_rgb_path']).convert('RGB')
        global_rgb_img = Image.open(data_item.get('global_rgb_path', data_item['face_rgb_path'])).convert('RGB')
        
        # 训练集：对 face_rgb 和 global_rgb 做完全一致的数据增强
        if self.split == 'train':
            face_input_size = (224, 224)
            if isinstance(self.transform, transforms.Compose):
                # 尝试从 config 派生的 transform 中推断输入尺寸
                for t in self.transform.transforms:
                    if isinstance(t, transforms.Resize):
                        face_input_size = t.size if isinstance(t.size, tuple) else (t.size, t.size)
                        break
            # Resize
            face_rgb = F.resize(face_rgb_img, face_input_size)
            global_rgb = F.resize(global_rgb_img, face_input_size)
            # 随机水平翻转（共同）
            if torch.rand(1).item() < 0.5:
                face_rgb = F.hflip(face_rgb)
                global_rgb = F.hflip(global_rgb)
            # 随机旋转（共同）
            rotation_degree = 10
            if isinstance(self.transform, transforms.Compose):
                for t in self.transform.transforms:
                    if isinstance(t, transforms.RandomRotation):
                        rotation_degree = t.degrees if isinstance(t.degrees, (int, float)) else max(t.degrees)
                        break
            angle = float(torch.empty(1).uniform_(-rotation_degree, rotation_degree).item())
            face_rgb = F.rotate(face_rgb, angle)
            global_rgb = F.rotate(global_rgb, angle)
            # 颜色抖动（可选）：仅当 transform 中包含 ColorJitter 时才启用
            cj = None
            if isinstance(self.transform, transforms.Compose):
                for t in self.transform.transforms:
                    if isinstance(t, transforms.ColorJitter):
                        cj = t
                        break
            if cj is not None:
                if cj.brightness is not None:
                    brightness_range = cj.brightness
                    b_min, b_max = (
                        brightness_range
                        if isinstance(brightness_range, (list, tuple))
                        else (1 - brightness_range, 1 + brightness_range)
                    )
                    b_factor = float(torch.empty(1).uniform_(b_min, b_max).item())
                    face_rgb = F.adjust_brightness(face_rgb, b_factor)
                    global_rgb = F.adjust_brightness(global_rgb, b_factor)
                if cj.contrast is not None:
                    contrast_range = cj.contrast
                    c_min, c_max = (
                        contrast_range
                        if isinstance(contrast_range, (list, tuple))
                        else (1 - contrast_range, 1 + contrast_range)
                    )
                    c_factor = float(torch.empty(1).uniform_(c_min, c_max).item())
                    face_rgb = F.adjust_contrast(face_rgb, c_factor)
                    global_rgb = F.adjust_contrast(global_rgb, c_factor)
            # ToTensor + Normalize
            face_rgb = F.to_tensor(face_rgb)
            global_rgb = F.to_tensor(global_rgb)
            mean = [0.485, 0.456, 0.406]
            std = [0.229, 0.224, 0.225]
            face_rgb = F.normalize(face_rgb, mean, std)
            global_rgb = F.normalize(global_rgb, mean, std)
        else:
            # 验证/测试集：无随机增强，直接应用相同的 transform
            if self.transform:
                face_rgb = self.transform(face_rgb_img)
                global_rgb = self.transform(global_rgb_img)
            else:
                face_rgb = transforms.ToTensor()(face_rgb_img)
                global_rgb = transforms.ToTensor()(global_rgb_img)
        
        face_uv = None
        if self.load_uv:
            # 加载UV数据
            face_uv = self._load_npy_fix(data_item['face_uv_path'])
            face_uv = torch.from_numpy(face_uv).float()

            # 确保UV数据是正确的形状 (C, H, W)
            if len(face_uv.shape) == 2:
                face_uv = face_uv.unsqueeze(0)  # 添加通道维度
            elif len(face_uv.shape) == 3 and face_uv.shape[-1] == 2:
                face_uv = face_uv.permute(2, 0, 1)  # (H, W, C) -> (C, H, W)

            if self.uv_is_hist:
                # 预计算的 UV histogram（例如 2 x bins x bins），无需 resize/归一化。
                with torch.no_grad():
                    face_uv = torch.nan_to_num(face_uv, nan=0.0, posinf=0.0, neginf=0.0)
            else:
                # 调整UV数据大小以匹配RGB图像
                if face_uv.shape[-2:] != face_rgb.shape[-2:]:
                    # 使用插值调整UV数据大小
                    face_uv = torch.nn.functional.interpolate(
                        face_uv.unsqueeze(0),
                        size=face_rgb.shape[-2:],
                        mode='bilinear',
                        align_corners=False
                    ).squeeze(0)

                if self.uv_log_ratio:
                    # 为 log(R/G)/log(B/G) 的后续处理保留原始比例信息，不做每样本 min-max。
                    with torch.no_grad():
                        face_uv = torch.nan_to_num(face_uv, nan=1.0, posinf=1.0, neginf=1.0)
                        face_uv = face_uv.clamp_min(1e-6)
                else:
                    # 归一化UV数据到[0,1]（若检测到越界则做min-max归一化；并修正 NaN/Inf）
                    with torch.no_grad():
                        # 替换 NaN/Inf 为合理值，避免传播
                        face_uv = torch.nan_to_num(face_uv, nan=0.5, posinf=1.0, neginf=0.0)
                        uv_min = face_uv.amin(dim=(-2, -1), keepdim=True)
                        uv_max = face_uv.amax(dim=(-2, -1), keepdim=True)
                        if (uv_min < -1e-3).any() or (uv_max > 1 + 1e-3).any():
                            denom = (uv_max - uv_min).clamp_min(1e-6)
                            face_uv = (face_uv - uv_min) / denom
                        face_uv = face_uv.clamp(0.0, 1.0)
        
        # 准备标签
        preference_score = torch.tensor([data_item['preference_score']], dtype=torch.float32)
        preference_L = torch.tensor([data_item.get('preference_L', 50.0)], dtype=torch.float32)
        preference_center = torch.tensor(data_item['preference_center'], dtype=torch.float32)
        
        # 不返回metadata，因为它包含字符串，会导致batch化问题
        out = {
            'face_rgb': face_rgb,
            'global_rgb': global_rgb,
            'preference_score': preference_score,
            'preference_L': preference_L,
            'preference_center': preference_center
        }
        # Phase 0: Statistical Stream — 预计算的统计特征 (11-D tensor, no string)
        if 'stat_features' in data_item:
            out['stat_features'] = data_item['stat_features']
        if face_uv is not None:
            out['face_uv'] = face_uv
        return out


def get_data_transforms(config: Dict, split: str = 'train') -> transforms.Compose:
    """
    获取数据变换
    
    Args:
        config: 配置字典
        split: 数据集划分
        
    Returns:
        变换组合
    """
    # 从配置中获取必要的参数
    face_input_size = tuple(config.get('FACE_INPUT_SIZE', (224, 224)))
    augmentation = config.get('AUGMENTATION', {})
    
    if split == 'train':
        # 训练集增强
        transform_list = [
            transforms.Resize(face_input_size),
            transforms.RandomHorizontalFlip(p=0.5),
            transforms.RandomRotation(degrees=augmentation.get('rotation_degree', 10)),
            transforms.ColorJitter(
                brightness=augmentation.get('brightness_range', (0.8, 1.2)),
                contrast=augmentation.get('contrast_range', (0.8, 1.2))
            ),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406],
                               std=[0.229, 0.224, 0.225])
        ]
        if not bool(augmentation.get("enable_color_jitter", True)):
            transform_list = [t for t in transform_list if not isinstance(t, transforms.ColorJitter)]
    else:
        # 验证/测试集：仅基本预处理
        transform_list = [
            transforms.Resize(face_input_size),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406],
                               std=[0.229, 0.224, 0.225])
        ]
    
    return transforms.Compose(transform_list)


def create_data_loaders(config: Dict) -> Tuple[DataLoader, DataLoader, DataLoader]:
    """
    创建数据加载器
    
    Args:
        config: 配置字典
        
    Returns:
        训练、验证、测试数据加载器
    """
    # 从配置字典中获取必要的值
    face_rgb_root = Path(config['FACE_RGB_ROOT'])
    face_uv_root = Path(config['FACE_UV_ROOT'])
    gt_excel_path = Path(config['GT_EXCEL_PATH'])
    # 全局RGB根目录优先使用 GLOBAL_RGB_ROOT，若未提供则退回 FACE_RGB_ROOT
    global_rgb_root = Path(config.get('GLOBAL_RGB_ROOT', config['FACE_RGB_ROOT']))
    random_seed = config['RANDOM_SEED']
    train_ratio = config['TRAIN_RATIO']
    val_ratio = config['VAL_RATIO']
    test_ratio = config['TEST_RATIO']
    batch_size = config['TRAINING']['batch_size']
    split_strategy = config.get("SPLIT_STRATEGY", "stable_by_id_hash")
    allowed_scenes = config.get("SCENES", None)
    
    # manual_prefix 策略专用配置
    valid_prefixes = config.get("VALID_PREFIXES", None)
    test_prefixes = config.get("TEST_PREFIXES", None)
    split_export_path = config.get("SPLIT_EXPORT_PATH", None)

    # v3 is RGB-only, skip loading UV to reduce CPU/I/O overhead.
    model_variant = str(config.get("MODEL_VARIANT", "v1")).lower().strip()
    load_uv = model_variant != "v3"
    uv_is_hist = bool(config.get("FACE_UV_IS_HIST", False))
    uv_log_ratio = bool(((config.get("MODEL", {}) or {}).get("face_stream", {}) or {}).get("uv_log_ratio", False))

    dl_cfg = config.get("DATALOADER", {}) or {}
    num_workers = int(dl_cfg.get("num_workers", 0))
    pin_memory = bool(dl_cfg.get("pin_memory", True))
    persistent_workers = bool(dl_cfg.get("persistent_workers", False)) if num_workers > 0 else False
    prefetch_factor = int(dl_cfg.get("prefetch_factor", 2)) if num_workers > 0 else None

    # 读取编号选择（可为 'all'/None 或 列表）
    train_ids = config.get('TRAIN_IDS', None)
    test_ids = config.get('TEST_IDS', None)
    # 若未显式提供 TEST_IDS，则默认与 TRAIN_IDS 一致，确保三者使用同一编号过滤
    norm_train_ids = FacialPreferenceDataset._normalize_ids(train_ids)
    norm_test_ids = FacialPreferenceDataset._normalize_ids(test_ids)
    if norm_test_ids is None and norm_train_ids is not None:
        norm_test_ids = norm_train_ids
    
    # 获取数据变换
    train_transform = get_data_transforms(config, 'train')
    val_transform = get_data_transforms(config, 'val')
    test_transform = get_data_transforms(config, 'test')
    
    # 创建数据集
    # manual_prefix 策略下：如果配置了 TRAIN_IDS（如按人种过滤），保留用于编号范围限制；
    # 前缀已精确控制 train/val/test 分配，编号过滤只用于限定数据范围
    _train_ids = norm_train_ids
    _test_ids = norm_test_ids
    
    train_dataset = FacialPreferenceDataset(
        face_rgb_root=face_rgb_root,
        face_uv_root=face_uv_root,
        gt_excel_path=gt_excel_path,
        split='train',
        transform=train_transform,
        seed=random_seed,
        train_ratio=train_ratio,
        val_ratio=val_ratio,
        test_ratio=test_ratio,
        allowed_ids=_train_ids,
        global_rgb_root=global_rgb_root,
        split_strategy=split_strategy,
        load_uv=load_uv,
        uv_is_hist=uv_is_hist,
        uv_log_ratio=uv_log_ratio,
        allowed_scenes=allowed_scenes,
        valid_prefixes=valid_prefixes,
        test_prefixes=test_prefixes,
        split_export_path=split_export_path,  # 只在 train 时导出
    )
    
    val_dataset = FacialPreferenceDataset(
        face_rgb_root=face_rgb_root,
        face_uv_root=face_uv_root,
        gt_excel_path=gt_excel_path,
        split='val',
        transform=val_transform,
        seed=random_seed,
        train_ratio=train_ratio,
        val_ratio=val_ratio,
        test_ratio=test_ratio,
        allowed_ids=_train_ids,
        global_rgb_root=global_rgb_root,
        split_strategy=split_strategy,
        load_uv=load_uv,
        uv_is_hist=uv_is_hist,
        uv_log_ratio=uv_log_ratio,
        allowed_scenes=allowed_scenes,
        valid_prefixes=valid_prefixes,
        test_prefixes=test_prefixes,
        split_export_path=None,  # 不重复导出
    )
    
    test_dataset = FacialPreferenceDataset(
        face_rgb_root=face_rgb_root,
        face_uv_root=face_uv_root,
        gt_excel_path=gt_excel_path,
        split='test',
        transform=test_transform,
        seed=random_seed,
        train_ratio=train_ratio,
        val_ratio=val_ratio,
        test_ratio=test_ratio,
        allowed_ids=_test_ids,
        global_rgb_root=global_rgb_root,
        split_strategy=split_strategy,
        load_uv=load_uv,
        uv_is_hist=uv_is_hist,
        uv_log_ratio=uv_log_ratio,
        allowed_scenes=allowed_scenes,
        valid_prefixes=valid_prefixes,
        test_prefixes=test_prefixes,
        split_export_path=None,  # 不重复导出
    )
    
    # 创建数据加载器
    train_loader = DataLoader(
        train_dataset,
        batch_size=batch_size,
        shuffle=True,
        num_workers=num_workers,
        pin_memory=pin_memory,
        persistent_workers=persistent_workers,
        prefetch_factor=prefetch_factor,
        drop_last=True  # 丢弃最后一个不完整的batch
    )
    
    val_loader = DataLoader(
        val_dataset,
        batch_size=batch_size,
        shuffle=False,
        num_workers=num_workers,
        pin_memory=pin_memory,
        persistent_workers=persistent_workers,
        prefetch_factor=prefetch_factor,
    )
    
    test_loader = DataLoader(
        test_dataset,
        batch_size=batch_size,
        shuffle=False,
        num_workers=num_workers,
        pin_memory=pin_memory,
        persistent_workers=persistent_workers,
        prefetch_factor=prefetch_factor,
    )
    
    return train_loader, val_loader, test_loader
