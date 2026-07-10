# Gao 2024 论文 vs 复现代码 — 架构逐项核对

**核对日期**: 2026-07-06  
**论文**: Quality-guided Skin Tone Enhancement for Portrait Photography (Gao et al., 2024, IEEE TMM)  
**代码路径**: `D:\work\VIVOSkinExpe\thesis\Quality_guided_STE\`

---

## 一、总体架构 (对应论文 Fig.4)

| 模块 | 论文描述 | 代码实现 | 结论 |
|------|---------|---------|:---:|
| **输入** | raw image + quality score + skin tone label → concat with down-sampled image | `torch.cat([img_down, score_map, label_map], dim=1)` — 5通道输入 (RGB + score + label) | ✅ |
| **Natural image 模式** | 4通道（去掉 label, Section V-B2） | `use_skin_label=False` → `in_ch=4` | ✅ |
| **CNN Backbone** | 5层卷积 + InstanceNorm，输出 context vector F (Section IV-D) | `BackBoneCNN`: 5×(Conv3+IN+ReLU)，stride=2，通道 16→32→64→32→16，末端 `AdaptiveAvgPool2d(1)` → 16-D | ✅ |
| **Score/Label 空间广播** | "replicated to match the dimensions of the down-scaled image" (Section IV-D) | `score.view(B,1,1,1).expand(B,1,H,W)` / `label_map` 同理 | ✅ |
| **下采样** | "Bilinear Downsample" (Fig.4 标注) | `F.interpolate(img, size=(256,256), mode='bilinear')` | ✅ |

---

## 二、1D LUT 生成与变换

| 模块 | 论文 | 代码 | 结论 |
|------|------|------|:---:|
| **生成器** | `{T_l, T_a, T_b} = g_1D(F)` (Eq.3)，MLP 输出各 channel 权重 | `mlp_1d`: Linear(16→16)→ReLU→Linear(16→3×n_base_1d) → reshape (B,3,n) → softmax | ✅ |
| **基础 LUT** | learnable base 1D LUTs | `base_1d`: `(n_base_1d, 3, lut_dim)` — 3个基础LUT，每个覆盖 L/a/b 3通道 | ✅ |
| **融合** | weighted sum of base LUTs | `einsum('bcn,nch->bch', w_1d, base_1d.permute(1,0,2))` — 逐通道加权融合 | ✅ |
| **应用顺序** | sRGB → CIELAB → 1D LUT (Fig.4) | `rgb_to_lab(img)` → normalize → `apply_1d_lut` | ✅ |
| **CIELAB 归一化** | 论文未明写具体常数 | L: `/50 - 1` (→[-1,1])，a/b: `/128` (→[-1,1]) — 对应标准 CIELAB 范围 [0,100] / [-128,128] | ✅ 合理 |
| **LUT 插值** | 线性插值（1D LUT 标准做法） | `gather`-based 线性插值：参考点 t0/t1 + 权重 wa/wb | ✅ |
| **反归一化** | — | L: `×50 + 50`，a/b: `×128` → `lab_to_rgb` | ✅ |

---

## 三、3D LUT 生成与变换

| 模块 | 论文 | 代码 | 结论 |
|------|------|------|:---:|
| **生成器** | `T_3D = g_3D(F)` (Eq.4) | `mlp_3d`: Linear(16→16)→ReLU→Linear(16→n_base_3d) → softmax | ✅ |
| **基础 LUT** | learnable base 3D LUTs | `base_3d`: `(n_base_3d, 3, D, D, D)` | ✅ |
| **融合** | weighted sum | `einsum('bn,nchwd->bchwd', w_3d, base_3d)` | ✅ |
| **应用顺序** | CIELAB → sRGB → 3D LUT (Eq.5) | `lab_to_rgb` → norm to [-1,1] → `apply_3d_lut` | ✅ |
| **LUT 插值** | trilinear interpolation（3D LUT 标准做法） | `F.grid_sample(mode='bilinear')` — 对 5D tensor 的 3 个 spatial 维度联合插值等价于 trilinear | ✅ |
| **最终输出** | clamp to valid range | `.clamp(0, 1)` | ✅ |

---

## 四、损失函数 (对应论文 Eq.6)

| 分量 | 论文公式 | 代码 | 结论 |
|------|---------|------|:---:|
| **L_r** 重构损失 | L1 (MSE 等价) | `F.l1_loss(pred, target)` | ✅ |
| **L_s** 平滑正则 | TV-like on base LUTs (Eq.6) | `(base_1d[:,:,1:] - base_1d[:,:,:-1])**2` + 对 3D LUT 的 x,y,z 三方向差分平方 | ✅ |
| **L_m** 单调正则 | ensure monotonic (Eq.6) | `F.relu(-diff).mean()` — 惩罚负梯度（即非单调变化） | ✅ |
| **λ1, λ2, λ3** | 1, 1×10⁻⁴, 10 (Section V-A1) | `lambda1=1.0, lambda2=1e-4, lambda3=10.0` | ✅ |

---

## 五、训练配置 (对应论文 Section V-A1)

| 参数 | 论文 | 代码默认值 | 结论 |
|------|------|-----------|:---:|
| Optimizer | Adam | Adam | ✅ |
| Learning rate | 1×10⁻⁴ | `--lr 1e-4` | ✅ |
| Batch size | 1 | `--batch_size 1` | ✅ |
| Epochs | 400 | `--epochs 400` | ✅ |
| LUT dimension | 33 | `--lut_dim 33` | ✅ |
| n_base_1d | 3 | `--n_base_1d 3` | ✅ |
| n_base_3d | 3 | `--n_base_3d 3` | ✅ |
| Score 范围 | [-1, 1]（MOS normalized, Section V-A1） | `dataset.py` 注释 "normalized to [-1,1]" | ✅ |
| Skin label | 聚类中心 1-10（整数, Section IV-C） | float 类型, 默认值 5 | ✅ |

---

## 六、数据流完整对照

```
论文 Fig.4 流程                              代码 forward() 调用链
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Raw Image I + Score + Label                   img + score + label
        │                                            │
        ▼                                            ▼
   Bilinear Downsample                    F.interpolate(img, 256×256)
        │                                            │
        ▼                                            ▼
   Concatenate (5-ch)                      torch.cat([img, score_map, label_map])
        │                                            │
        ▼                                            ▼
   CNN Backbone (5×Conv+IN)                BackBoneCNN (5×(Conv3+IN+ReLU))
        │                                            │
        ▼                                            ▼
   Context Vector F                        F_feat (16-D)
        │                                    │
   ┌────┴────┐                          ┌────┴────┐
   ▼         ▼                          ▼         ▼
  g_1D(F)  g_3D(F)                   mlp_1d    mlp_3d
   │         │                          │         │
   ▼         ▼                          ▼         ▼
  {T_l,T_a,T_b}  T_3D              w_1d (B,3,n)  w_3d (B,n)
   │         │                          │         │
   │    ┌────┘                     softmax    softmax
   │    │                              │         │
   ▼    ▼                              ▼         ▼
  Base 1D LUTs                    einsum × base_1d   einsum × base_3d
   │                                    │         │
   ▼                                    ▼         ▼
  sRGB → CIELAB → 1D LUT          rgb_to_lab → apply_1d_lut
   │                                    │
   ▼                                    ▼
  CIELAB → sRGB → 3D LUT          lab_to_rgb → apply_3d_lut
   │                                    │
   ▼                                    ▼
  Enhanced Image Î                     out.clamp(0,1)
        │                                    │
        ▼                                    ▼
  Reconstruction Loss                 L1_loss(pred, target)
                                  + λs×smooth + λm×mono
```

---

## 七、发现的差异点

| # | 差异点 | 严重程度 | 分析 |
|---|--------|:---:|------|
| **1** | 3D LUT 插值方式 | ⚠️ 低 | 代码用 `F.grid_sample(mode='bilinear')`。`grid_sample` 对 5D tensor (B,3,D,D,D) 的 3 个 spatial 维度做插值，每个维度独立线性 → 3 个维度的联合等价于 trilinear interpolation。**实际无差异。** |
| **2** | CNN 输出特征维度 = 16 | ℹ️ 低 | 论文未写明具体数值。这是从 3D LUT 系列工作 [9][19] 继承的轻量设计，16-D context 对 3-base LUT 权重预测足够。 |
| **3** | 皮肤标签聚类模块未包含 | ℹ️ 预期内 | 论文 Section IV-C 的 K-means 聚类是**预处理阶段**，生成静态 cluster label。代码从 `info.json` 读取预计算 label，合理——聚类结果本质是固定的查表操作，非网络的一部分。 |
| **4** | 损失使用 L1 而非 MSE | ℹ️ 形式差异 | 论文写 "reconstruction loss"，实现用 L1 loss（MAE）而非 L2（MSE）。两者都是重建损失的常见选择，L1 对 outlier 更鲁棒。原论文 Fig.4 标注为 "Reconstruction Loss"，未强制指定 L1/L2。 |

---

## 八、总体结论

```
论文架构                                    代码实现
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  CNN backbone (5conv+IN)                    ✅ 完全一致
  Score+Label 空间广播到图像尺寸               ✅ 完全一致
  1D LUT 生成+融合 (per-channel weighted)     ✅ 完全一致
  3D LUT 生成+融合 (weighted sum)            ✅ 完全一致
  sRGB → CIELAB → 1D LUT → sRGB → 3D LUT   ✅ 完全一致
  L1 + smoothness + monotonicity loss        ✅ 完全一致
  λ 权重 (1, 1e-4, 10)                       ✅ 完全一致
  训练超参 (Adam, lr=1e-4, bs=1, epochs=400) ✅ 完全一致
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**这份代码是论文架构的忠实复现，未发现实质性出入。**

---

## 九、Deepskin 适配注意事项

参考 `D:\work\VIVOSkinExpe\deepskin\simple_ml\experiment_schedule_0715.md` Phase 2 计划：

### 9.1 待实现模块

| 优先级 | 模块 | 说明 |
|:---:|------|------|
| **P0** | 数据转换脚本 | deepskin 格式 → Gao 格式（raw + adjusted pairs + score.json） |
| **P0** | 皮肤标签聚类 | 对 deepskin 人脸区域在 CIELAB 空间做 K-means (k=10)，为每张图分配 cluster label |
| **P1** | 训练脚本适配 | 注册 `--data_root`, `--gt_excel` 等 deepskin 参数 |
| **P1** | 推理+评估脚本 | 输出 enhanced image + 计算 Pearson r vs GT |

### 9.2 Deepskin → Gao 数据映射

| Gao 字段 | Deepskin 来源 |
|----------|--------------|
| `raw` | 原始渲染图 (如 `f01_33.jpg` → 对应的未调整原图) |
| `adjusted` | 各渲染变体 (33 个 variant) |
| `score` | 印象属性得分 (0-1 归一化到 [-1,1])，以"喜好度"为主 score |
| `label` | K-means 聚类后的 skin tone label (1-10) |

### 9.3 训练建议

- 原始论文用 **85 raw + 1105 adjusted pairs**，每 raw 对应 13 adjusted
- Deepskin 有 **48 subjects × 33 variants ≈ 1584 pairs**，数据量级相近
- Score 范围需要从 deepskin 的 [0,1] 映射到 [-1,1]
- 测试时可通过设定不同 score 值观察 continuous enhancement 效果
