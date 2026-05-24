# predict_p 网络结构说明（`train.py` 入口）

本文档解释 `predict_p/train.py` 训练入口所使用的 **predict_p**（只预测偏好度分数 `p`）网络结构。网络定义主要在：

- `predict_p/models/network.py`
- `predict_p/models/face_stream.py`
- `predict_p/models/global_stream.py`
- `predict_p/models/fusion.py`
- `predict_p/models/heads.py`
- `predict_p/models/backbones.py`

---

## 1. 训练入口做了什么（`train.py`）

`predict_p/train.py` 是训练/测试的入口，核心流程：

1. 读取 `Config.get_config_dict()`（`predict_p/config.py`）。
2. 根据 CLI 参数覆盖配置：
   - `--model-variant {v1,v2,v3}`：选择网络变体（见下文）。
   - `--rgb-backbone {simple_cnn,resnet50,efficientnet_b0}`：人脸 RGB 分支骨干。
   - `--global-backbone {simple_cnn,mobilenet_v3_small,mobilenet_v3_large,efficientnet_b0}`：全局分支骨干。
   - `--no-pretrained`：关闭 torchvision 预训练权重（对 `simple_cnn` 无影响）。
3. `_apply_model_variant_overrides()`：当 `MODEL_NAME` 仍为 `predict_p` 且 variant 非 `v1` 时，将输出目录切换到 `predict_p_{variant}`（例如 `predict_p_v3`）。
4. 设置随机种子后创建 `Trainer` 并调用 `train()`、`test()`（`predict_p/trainer.py`）。

---

## 2. 总体网络结构（Two-Stream + Gate Fusion + Score Head）

网络是“两路输入流 + 融合 + 输出头”，只输出一个标量 **logit**：

- 输出：`score_logits`，形状 `(B, 1)`（`B` 为 batch size）
- 训练/评估时通常用 `torch.sigmoid(score_logits)` 得到 `(0,1)` 的分数概率（`predict_p/trainer.py`、`predict_p/loss.py`）

数据流（简化）：

```text
face_rgb --------------> FaceStream ----------> face_features
global_rgb(or face_rgb) -> GlobalStream ------> global_features

(face_features, global_features) -> TwoStreamFusion(gated) -> fused
fused -> ScoreHead(MLP) -> score_logits (B,1)
```

---

## 3. 模块级细节

### 3.1 `PredictPNetwork`（`models/network.py`）

构造函数做三件事：

1. 选择人脸流 `face_stream`（由 `MODEL_VARIANT` 和 `use_attention` 决定）
2. 构建全局流 `global_stream`
3. 构建融合模块 `TwoStreamFusion` + 预测头 `ScoreHead`

前向签名：

```python
forward(face_rgb, face_uv, global_rgb=None) -> score_logits
```

关键约束：

- 当 `MODEL_VARIANT == "v3"`：`face_uv` **不需要**（也不会被使用）
- 当 `MODEL_VARIANT in {"v1","v2"}`：`face_uv` **必须提供**，否则直接抛错

---

### 3.2 Face Stream（`models/face_stream.py`）

Face Stream 的目标是把**局部人脸信息**编码成一个向量 `face_features`，并通过 `self.output_dim` 告诉后续融合模块维度。

输入：

- `face_rgb`: `(B, 3, H, W)`（通常 `H=W=224`，由数据管线 resize）
- `face_uv`: `(B, C, H, W)`，其中 `C>=2`（至少包含 U/V 两个通道；数据集会整理成 `(C,H,W)`）

#### 3.2.1 `RGBBranch`

`RGBBranch(backbone, pretrained, feature_dim)` 输出 `(B, feature_dim)`。

支持骨干：

- `resnet50`：去掉 `fc`，用 `children()[:-1]` 得到全局池化后的特征，再用 `Linear + BN + ReLU + Dropout` 投影到 `feature_dim`
- `efficientnet_b0`：将 `classifier` 替换为 `Identity`，再投影到 `feature_dim`
- `simple_cnn`：使用 `SimpleCNNBackbone(in_channels=3, out_dim=feature_dim)`（见 `models/backbones.py`），并把 `feature_projector` 设为 `Identity`

#### 3.2.2 `compute_uv_histogram`：UV → 2D 直方图特征图

UV 分支并不直接对原始 UV 图做卷积，而是先把 UV 坐标量化成 2D bins 形成直方图：

- 输入：`face_uv` `(B, C, H, W)`，取第 0/1 通道作为 U/V
- 归一化：根据 `u_range`/`v_range` 将 U/V 映射到 `[0,1]`，再量化到 `num_bins_u × num_bins_v`
- 输出：`hist` 形状 `(B, out_channels, num_bins_u, num_bins_v)`
  - 当 `out_channels is None`：默认 `out_channels = C`，并将 `(B,1,Hu,Hv)` 扩展为 `(B,C,Hu,Hv)`
  - 在 `v2` 变体中显式 `out_channels=1`，避免通道复制

> 直方图的构建使用了 `torch.bincount`，并在 batch 维度上用 Python 循环逐样本计算（实现上更直观，但对大 batch 的吞吐会有影响）。

#### 3.2.3 `UVBranch`：直方图特征图 → 向量

`UVBranch(input_channels, conv_layers, feature_dim)`：

- 若 `conv_layers=[32, 64, 128, 128]`（默认来自 config）：
  - 前两层 stride=2，下采样直方图空间分辨率；后续 stride=1
  - 每层使用 `DWSeparableBlock`（深度可分离卷积：depthwise 3×3 + pointwise 1×1 + BN + ReLU，满足条件时带残差）
- `AdaptiveAvgPool2d(1)` 全局池化
- `Linear(conv_layers[-1] -> feature_dim) + BN + ReLU + Dropout`

输出：`uv_feats` `(B, feature_dim)`。

#### 3.2.4 Face Stream 三个版本（`MODEL_VARIANT`）

| 变体 | 类 | 输入 | 结构差异 | 输出维度 |
|---|---|---|---|---|
| `v1` | `AttentiveFaceStream`（默认）或 `FaceStream` | `face_rgb` + `face_uv` | `AttentiveFaceStream` 多一个“RGB/UV 权重注意力”（样本级 2 类 softmax） | 固定 256 |
| `v2` | `FaceStreamV2` | `face_rgb` + `face_uv` | 无注意力；直方图强制 `out_channels=1`，UV 分支输入通道也为 1 | 固定 256 |
| `v3` | `FaceStreamV3` | 仅 `face_rgb` | 移除 UV 分支（RGB-only） | `rgb_only_output_dim`（默认 256） |

其中 `v1` 的注意力融合逻辑（简化）：

```text
rgb_feats, uv_feats -> concat -> attention -> (w_rgb, w_uv)
fused_input = concat(rgb_feats * w_rgb, uv_feats * w_uv)
fused_input -> MLP -> face_features (B,256)
```

---

### 3.3 Global Stream（`models/global_stream.py`）

Global Stream 把**全局图像**编码为 `(B, global_feature_dim)`：

- 输入：`global_rgb` `(B,3,H,W)`；若调用方没传 `global_rgb`，`PredictPNetwork.forward()` 会用 `face_rgb` 代替
- 支持骨干：
  - `simple_cnn`：`SimpleCNNBackbone(in_channels=3, out_dim=feature_dim)`，不再额外投影
  - `mobilenet_v3_small/large`、`efficientnet_b0`：去掉 `classifier`，再用 `Linear + BN + ReLU + Dropout` 投影到 `feature_dim`

输出维度由 `config["MODEL"]["global_stream"]["feature_dim"]` 控制（默认 256）。

---

### 3.4 Two-Stream 融合（`models/fusion.py`）

`TwoStreamFusion(face_dim, global_dim, fusion_dim, dropout)`：

1. 分别线性投影到同一维度：
   - `f = Linear(face_dim -> fusion_dim)`
   - `g = Linear(global_dim -> fusion_dim)`
2. 使用 gate 网络生成两路权重（样本级，softmax 归一化）：
   - `w = Softmax(Linear(ReLU(Linear([f;g]))))`，输出 `(B,2)`
3. 加权求和得到融合特征：
   - `fused = w0 * f + w1 * g`
4. 输出层：
   - `Linear(fusion_dim -> fusion_dim) + BN + ReLU + Dropout`

输出：`fused` `(B, fusion_dim)`（默认 256）。

---

### 3.5 Score Head（`models/heads.py`）

`ScoreHead(input_dim, hidden_dims, output_dim=1)` 是一个 MLP：

- 逐层：`Linear -> BN -> ReLU -> Dropout(0.3)`
- 最后：`Linear -> (B,1)`

注意输出是 **logit**（未过 sigmoid）。

---

## 4. 默认配置下的维度示例（`config.py` 默认值）

`predict_p/config.py` 默认关键维度：

- face stream:
  - `rgb_feature_dim = 256`
  - `uv_feature_dim = 128`（仅 `v1/v2` 使用）
  - face stream 输出维度 `output_dim = 256`
- global stream:
  - `feature_dim = 256`
- fusion:
  - `fusion_dim = 256`
- head:
  - `hidden_dims = [128, 64]`
  - `output_dim = 1`

因此（无论 `v1/v2/v3`），最终 `PredictPNetwork` 输出都是 `(B,1)`。

---

## 5. 权重初始化与“pretrained”注意点

`PredictPNetwork.__init__()` 最后会调用 `_initialize_weights()`，它会遍历 `self.modules()` 并对以下层做重新初始化：

- `nn.Conv2d`：Kaiming normal
- `nn.BatchNorm1d/2d`：weight=1, bias=0
- `nn.Linear`：`Normal(mean=0, std=0.01)`

这意味着：**即使在 `RGBBranch/GlobalStream` 中创建 torchvision backbone 时传了 `pretrained=True`，其卷积/线性层权重也会在这里被重新初始化覆盖**（预训练权重不再保留）。

如果你的目标是“真正使用 torchvision 的预训练权重”，需要调整初始化策略（例如跳过对 backbone 的初始化，或仅初始化新增的 projector/head/fusion 层）。

---

## 6. 常见问题/调试要点

- `ValueError: face_uv is required ...`：你在 `v1/v2` 下把 `face_uv` 传成了 `None`（或数据 loader 没提供）。
- 直方图 bins：UV 直方图大小为 `uv_hist_bins × uv_hist_bins`（默认 64×64）；若想加速可减小 bins 或减少 batch size。
- 输出数值范围：训练时 loss 会对 `sigmoid(logits)` 做回归项（`SmoothL1`），并对 logits 做 `BCEWithLogits`；所以 logits 不必在 `[0,1]`。

---

## 7. 运行示例（切换变体/骨干）

```bash
python -m predict_p.train --model-variant v3 --rgb-backbone simple_cnn --global-backbone simple_cnn
python -m predict_p.train --model-variant v1 --rgb-backbone resnet50 --global-backbone mobilenet_v3_small --no-pretrained
```
