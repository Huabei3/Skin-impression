"""
deepskin_multi_dataset.py - 多属性 NR 数据集 (用于 pyiqa multi-head 训练)

继承 GeneralNRDataset，额外加载 10 个属性 GT 和对应的 NaN mask。

用法（YAML）:
  datasets:
    train:
      name: deepskin_multi_SA
      type: DeepskinMultiNRDataset
      dataroot_target: /root/autodl-tmp/rendered_2max
      meta_info_file: datasets/deepskin_multi/SA/meta_info.csv
      split_index: split_name
      ...
"""
import torch
import numpy as np
from pyiqa.data.general_nr_dataset import GeneralNRDataset
from pyiqa.utils.registry import DATASET_REGISTRY


@DATASET_REGISTRY.register()
class DeepskinMultiNRDataset(GeneralNRDataset):
    """多属性 NR 数据集，在原有 mos 基础上额外提供 10 个属性的 score 和 mask."""

    _ALL_ATTRS = [
        "01Preference", "02Attractiveness", "03Feminine",
        "04Cooperative", "05Youth", "06Healthy",
        "07Fidelity", "08Harmony", "09Fair", "10Ruddy",
    ]

    def __init__(self, opt):
        super().__init__(opt)
        self._attr_cols = [f"attr_{a}" for a in self._ALL_ATTRS]
        self._mask_cols = [f"mask_{a}" for a in self._ALL_ATTRS]
        self._has_attrs = all(c in self.meta_info.columns for c in self._attr_cols[:1])
        if self._has_attrs:
            self._attr_data = self.meta_info[self._attr_cols].values.astype(np.float32)
            self._mask_data = self.meta_info[self._mask_cols].values.astype(np.float32)

    def __getitem__(self, index):
        data = super().__getitem__(index)
        if self._has_attrs:
            data["attribute_scores"] = torch.from_numpy(self._attr_data[index])
            data["attribute_mask"] = torch.from_numpy(self._mask_data[index])
        return data
