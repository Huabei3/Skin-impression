# Perceptual-based VQA/IQA 领域调研

> 调研时间：2026.8  
> 目标组：University of Bristol, Visual Information Laboratory (VI-Lab) — David Bull / Fan Zhang / Angeliki Katsenou  
> 用户背景：皮肤视觉质量偏好评估（pairwise comparison + psychophysics + deep learning）

---

## 一、领域概述

**IQA（Image Quality Assessment）** 和 **VQA（Video Quality Assessment）** 研究的是：如何自动、准确地预测人眼对图像/视频质量的感知判断。

核心分类：
| 类型 | 说明 | 典型应用 |
|------|------|----------|
| **FR (Full-Reference)** | 有原始高质量参考图 | 压缩/传输质量监控 |
| **RR (Reduced-Reference)** | 仅有参考图的部分特征 | 带宽受限场景 |
| **NR (No-Reference)** | 无参考图，盲评估 | 真实世界/UGC质量评估 |

**Perceptual-based IQA/VQA** 强调"与人眼主观感知对齐"，核心挑战是：客观算法分数与 MOS（Mean Opinion Score）之间的相关性。

---

## 二、发展谱系

### 2.1 经典信号处理时代（2004-2015）

| 方法 | 年份 | 类型 | 核心思想 |
|------|------|------|----------|
| **SSIM** (Wang et al.) | 2004 (IEEE TIP) | FR | 结构相似度：亮度×对比度×结构 |
| **MS-SSIM** | 2004 | FR | 多尺度 SSIM |
| **FSIM** (Zhang et al.) | 2011 (IEEE TIP) | FR | 相位一致性 + 梯度幅值 |
| **BRISQUE** (Mittal et al.) | 2012 (IEEE TIP) | NR | 自然场景统计 (NSS) + SVM |
| **NIQE** (Mittal et al.) | 2012 (IEEE SPL) | NR | 无训练的 NSS 模型，MVG 分布距离 |
| **VMAF** (Netflix) | 2016 | FR | SVM 融合多特征的工业标准 |

关键贡献：SSIM 至今仍是引用量最高的 IQA 论文（>40K），VMAF 是流媒体行业标配。

### 2.2 深度学习时代（2016-2022）

| 方法 | 年份/会议 | 类型 | 贡献 |
|------|-----------|------|------|
| **DeepIQA** (Bosse et al.) | 2016 (ICIP) | FR/NR | 首个端到端 CNN-IQA，patch-wise training |
| **RankIQA** (Liu et al.) | 2017 (ICCV) | NR | 用 synthetic ranking 数据训练 Siamese 网络，突破标注瓶颈 |
| **LPIPS** (Zhang et al.) | 2018 (CVPR) | FR | 用预训练深度特征距离度量感知相似度，成为图像生成标准指标 |
| **DISTS** (Ding et al.) | 2020 (IEEE TPAMI) | FR | 结合深度纹理与结构相似度 |
| **HyperIQA** (Su et al.) | 2020 (CVPR) | NR | 超网络自适应质量预测 |
| **MUSIQ** (Ke et al.) | 2021 (ICCV) | NR | 多尺度 Transformer，支持任意分辨率 |
| **PaQ-2-PiQ** (Ying et al.) | 2020 (CVPR) | NR | 大规模主观数据库 + ResNet 训练 |
| **UNIQUE** (Zhang et al.) | 2021 (IEEE TIP) | NR | 不确定性感知 IQA：同时输出质量分数及其置信度 |

### 2.3 VLM/LLM 时代（2023-2026）

| 方法 | 年份/会议 | 贡献 |
|------|-----------|------|
| **CLIP-IQA** (Wang et al.) | 2023 (AAAI) | 首次用 CLIP 的 semantic understanding 做 IQA：正面/负面 prompt 匹配 |
| **LIQE** (Zhang et al.) | 2023 (CVPR) | CLIP + 多任务学习（质量+场景分类+失真类型） |
| **Q-Align** (Wu et al.) | 2024 (ICML) | 用离散文本Level教 LMM 打分，将 IQA 变成"看图选词"任务 |
| **TOPIQ** (Chen et al.) | 2024 (IEEE TIP) | 当前 NR-IQA SOTA：自顶向下从语义到失真 |
| **Q-Bench / Q-Instruct** | 2024 | LLM 被教"看图说话"评估质量，输出自然语言诊断 |
| **VQA Survey** (Zheng et al.) | 2024 (arXiv:2412.04508) | 52页 VQA 全领域综述 |

核心趋势：**从"设计特征→端到端学习→用语言模型对齐人判断"** 的三级跳。

---

## 三、Perceptual-Based VQA/IQA 核心方法论

### 3.1 主观质量数据库

IQA/VQA 的根基是主观实验数据。关键数据库：

| 数据库 | 规模 | 内容 |
|--------|------|------|
| **LIVE** (UT Austin, Bovik) | 29 ref × 5 dist × ~25K ratings | 经典 FR-IQA 基准 |
| **TID2013** | 25 ref × 24 dist × 3000+ images | 最广泛的失真类型覆盖 |
| **KADID-10k** | 81 ref × 25 dist × 10K+ | 大规模合成失真 |
| **KonIQ-10k** | 10K+ authentic images | 真实世界质量，1.2M ratings |
| **BVI** (Bristol, Bull) | 多系列：BVI-HD/VQA/DVC | Bristol 自建视频质量数据库 |
| **FLIVE/PaQ-2-PiQ** | ~40K images | 最大规模真实世界 IQA |

**与你的关联**：你已有的皮肤 pairwise preference 数据库是一个垂直领域的 specialized perceptual database，这正是领域中的稀缺资源。

### 3.2 Ranking/Preference Learning

这是与你方向最相关的子范式：

```
传统 IQA:  Image → Model → MOS score
Ranking IQA: (Image_A, Image_B) → Model → P(A > B)  # 成对比较
```

| 方法 | 贡献 |
|------|------|
| **RankIQA** (ICCV 2017) | 用合成 distortion 生成 ranking pairs，Siamese + ranking loss |
| **RankDVQA** (Bull, WACV 2024) | 🔑 Bristol 的核心方法：ranking-inspired hybrid training = ranking loss + regression loss |
| **UNIQUE** (IEEE TIP 2021) | 引入 epistemic + aleatoric uncertainty，成对比较的不确定性建模 |
| **P2I-BQA** | 贝叶斯 pairwise IQA |

**你的天然优势**：你做 psychophysics 实验时用的就是 pairwise comparison (2AFC)，数据格式与 ranking loss 天然兼容。

### 3.3 Diagnostic/Interpretable Quality Assessment

| 方法 | 贡献 |
|------|------|
| **Unified-VQA** (Bull, WACV 2025) | 🔑 Diagnostic Mixture-of-Experts：将质量分数分解为多个维度专家的加权输出，每个专家负责一种 degradation |
| **MVAD** (Bull, 2024) | 多视觉 artifact 检测器 |
| **LIQE** | 多任务（质量+失真类型+场景）联合建模 |

思路：质量不是单一数字，而是多维诊断向量。

### 3.4 Frequency-Domain Methods

| 方法 | 贡献 |
|------|------|
| **FGSVQA** (Katsenou & Bull, 2026) | 🔑 频域引导短视频VQA：将图像分解为 artifact branch（高频）和 structure branch（低频），CLIP 编码语义 |

频率域分解在皮肤评估中天然适用：纹理/毛孔/细纹 → 高频 → artifact branch；肤色/光泽/均匀度 → 低频 → structure branch。

---

## 四、全球主要课题组

| 团队 | PI | 机构 | 特色 |
|------|----|----|------|
| **LIVE Lab** | Alan Bovik | UT Austin | IQA 鼻祖，SSIM/BRISQUE/VMAF/VIF |
| **VI-Lab** | **David Bull** | Bristol | 🔑 Ranking VQA, Diagnostic MoE, BVI database |
| **VIP Lab** | Zhou Wang | Waterloo | SSIM 发明者，结构相似度理论 |
| **SJTU** | Guangtao Zhai | 上海交大 | 大规模主观实验，Q-Align 合作者 |
| **NTU** | Weisi Lin | 南洋理工 | FSIM, TOPIQ, 视觉感知建模 |
| **CityU** | Shiqi Wang | 香港城大 | 视频压缩质量，面向任务的 VQA |
| **PolyU** | Lei Zhang | 香港理工 | LPIPS/DISTS 合作者，图像恢复 |
| **MMLab@NTU** | Chen Change Loy | 南洋理工 | CLIP-IQA, 生成图像质量 |
| **S-Lab@NTU** | Haoning Wu | 南洋理工 | Q-Align, TOPIQ, LLM-based IQA |

---

## 五、VQA/IQA 与你的研究方向的交叉点

### 5.1 技术交叉矩阵

| 你的已有工作 | 对应的 VQA/IQA 方法 | 交叉价值 |
|------------|-------------------|---------|
| Pairwise preference DB (2AFC) | RankDVQA ranking loss, UNIQUE uncertainty | 数据格式天然匹配 |
| 多维皮肤评估（纹理/色斑/光泽） | Unified-VQA Diagnostic MoE | 皮肤专用 MoE 设计 |
| 多任务护肤模型 | LIQE 多任务架构 | 质量+诊断联合优化 |
| 高光谱皮肤成像 | FGSVQA 频域分解 | 光谱域→频域的特征对齐 |
| 皮肤风格化 | LPIPS perceptual metric | 生成皮肤图像的质量评估 |

### 5.2 三个可行的 PhD 方向

#### 方向一：Ranking-Inspired Perceptual Skin Quality Assessment

```
你的 pairwise DB → RankDVQA ranking loss → Skin Diagnostic MoE → 多维诊断分数
核心贡献：将 VQA 的 ranking 范式首个应用于垂直领域（皮肤）
```

#### 方向二：Uncertainty-Aware Preference Modeling for Skin IQA

```
你的 pairwise DB + 观察者间歧义 → UNIQUE + BEM(BNN) → 不确定感知偏好分布
核心贡献：建模皮肤审美的主观歧义性（同一张脸不同人偏好不同）
```

#### 方向三：Frequency-Guided Skin Artifact Detection & Diagnosis

```
皮肤光谱/图像 → FGSVQA 频域分解 → Artifact Branch 检测瑕疵 → Structure Branch 评估整体
核心贡献：皮肤专用的 artifact detection + quality scoring 联合框架
```

---

## 六、会议与期刊

### 投稿目标

| 层级 | 会议 | 期刊 |
|------|------|------|
| S级 | CVPR, ICCV, ECCV, NeurIPS, ICML | IEEE TPAMI, IJCV |
| A级 | WACV, AAAI, ACM MM, ICIP | IEEE TIP, TCSVT, TMM |
| B级 | QoMEX, ICASSP | IEEE SPL, JVCIR |

**VQA/IQA 常见投稿组合**：
- 方法创新 → CVPR/ICCV/ECCV
- 应用+数据 → WACV/AAA/ACM MM (Bull组在WACV发了多篇)
- 综述 → IEEE TIP 或 arXiv
- 工业应用 → QoMEX

---

## 七、论文阅读推荐（阅读路径）

### 第一阶段：建立方法论基础（3-5天，先读框架再读细节）

| 顺序 | 论文 | 读什么 | 为什么先读 |
|------|------|--------|------------|
| 1 | LPIPS (Zhang, 2018 CVPR) | Intro + Method | 理解"感知相似度"的基本范式 |
| 2 | RankIQA (Liu, 2017 ICCV) | Intro + Sec 3 (Siamese ranking) | 理解ranking loss在IQA中的用法 |
| 3 | CLIP-IQA (Wang, 2023 AAAI) | 全文 | 理解VLM如何被用于IQA（3-4页很简短） |
| 4 | RankDVQA (Bull, 2024 WACV) | 🔑 精读 | Bristol的ranking VQA方法论，你最需要对齐的论文 |

### 第二阶段：对齐Bristol方法论（2-3天）

| 顺序 | 论文 | 重点 |
|------|------|------|
| 5 | Unified-VQA (Bull, 2025 WACV) | 🔑 精读：Diagnostic MoE架构、多维诊断设计 |
| 6 | FGSVQA (Katsenou & Bull, 2026) | 频率域分解、CLIP编码器用法 |
| 7 | UNIQUE (Zhang, 2021 TIP) | 不确定性建模+成对比较 |

### 第三阶段：追踪前沿（选读）

| 顺序 | 论文 | 重点 |
|------|------|------|
| 8 | Q-Align (Wu, 2024 ICML) | LLM如何被教打分 |
| 9 | TOPIQ (Chen, 2025 TIP) | 当前NR-IQA最强baseline |
| 10 | VQA Comprehensive Survey (Zheng, 2024) | 查漏补缺的工具书 |

---

## 八、关键开源资源

| 资源 | 链接 | 说明 |
|------|------|------|
| Awesome-IQA | github.com/chaofengc/Awesome-Image-Quality-Assessment | IQA 全领域资源索引 |
| pyiqa | github.com/chaofengc/IQA-PyTorch | PyTorch IQA 工具箱 |
| LPIPS | github.com/richzhang/PerceptualSimilarity | 感知相似度官方实现 |
| VMAF | github.com/Netflix/vmaf | Netflix VQA 工业工具 |
| Q-Align | github.com/Q-Future/Q-Align | LLM-IQA 官方代码 |

---

## 九、总结：Bristol 为什么是 VQA/IQA 方向的理想选择

1. **方法论高度匹配**：RankDVQA 的 ranking loss 与你已有的 pairwise preference DB 在数据格式上天然兼容
2. **架构可迁移**：Unified-VQA 的 Diagnostic MoE 可以自然映射到皮肤的多维评估（纹理/色调/瑕疵/光泽）
3. **频域皮肤分析**：FGSVQA 的频域分解直接对应皮肤纹理的物理特性
4. **Bull 的 VQA 身份**：他是该领域核心人物，VQA 是他的主线而非副线
5. **数据库构建经验**：BVI 系列数据库的构建方法可以直接用于标准化你的皮肤质量数据库

---

## 附录：推荐阅读论文 Full Title 列表

### 第一阶段：建立方法论基础

| # | 缩写 | Full Title | 作者 | 会议/期刊 |
|---|------|-----------|------|-----------|
| 01 | LPIPS | **The Unreasonable Effectiveness of Deep Features as a Perceptual Metric** | Richard Zhang, Phillip Isola, Alexei A. Efros, Eli Shechtman, Oliver Wang | CVPR 2018 |
| 02 | RankIQA | **RankIQA: Learning from Rankings for No-reference Image Quality Assessment** | Xialei Liu, Joost van de Weijer, Andrew D. Bagdanov | ICCV 2017 |
| 03 | CLIP-IQA | **Exploring CLIP for Assessing the Look and Feel of Images** | Jianyi Wang, Kelvin C.K. Chan, Chen Change Loy | AAAI 2023 |
| 04 | RankDVQA | **RankDVQA: Deep VQA based on Ranking-inspired Hybrid Training** | Chen Feng, Duolikun Danier, Fan Zhang, David Bull | WACV 2024 |

### 第二阶段：对齐Bristol方法论

| # | 缩写 | Full Title | 作者 | 会议/期刊 |
|---|------|-----------|------|-----------|
| 05 | Unified-VQA | **Towards Unified Video Quality Assessment** | Chen Feng, Fan Zhang, David R. Bull | WACV 2025 |
| 06 | FGSVQA | **FGSVQA: Frequency-Guided Short-form Video Quality Assessment** | X. Wang, A. Katsenou, J. Shen, D. Bull | 2026 |
| 07 | UNIQUE | **Uncertainty-Aware Blind Image Quality Assessment in the Laboratory and Wild** | Weixia Zhang, Kede Ma, Guangtao Zhai | IEEE TIP 2021 |

### 第三阶段：追踪前沿

| # | 缩写 | Full Title | 作者 | 会议/期刊 |
|---|------|-----------|------|-----------|
| 08 | Q-Align | **Q-Align: Teaching LMMs for Visual Scoring via Discrete Text-Defined Levels** | Haoning Wu, Zicheng Zhang, Weixia Zhang, Chaofeng Chen, Chunyi Li, Liang Liao, Annan Wang, Erli Zhang, Wenxiu Sun, Qiong Yan, Xiongkuo Min, Guangtao Zhai | ICML 2024 |
| 09 | TOPIQ | **TOPIQ: A Top-down Approach from Semantics to Distortions for Image Quality Assessment** | Chaofeng Chen, Jiaying Zhu, Sensen Yang, Haoning Wu, Liang Liao, Zicheng Zhang, Annan Wang, Wenxiu Sun, Qiong Yan, Weisi Lin | IEEE TIP 2024 |
| 10 | VQA Survey | **Video Quality Assessment: A Comprehensive Survey** | Qi Zheng, Yibo Fan, Leilei Huang, Tianyu Zhu, Jiaming Liu, Zhijian Hao, Shuo Xing, Chia-Ju Chen et al. | arXiv:2412.04508, 2024 |

---

## 十、参考论文与进一步阅读

### 经典必读
1. Wang et al., "Image Quality Assessment: From Error Visibility to Structural Similarity," IEEE TIP, 2004. (SSIM)
2. Mittal et al., "No-Reference Image Quality Assessment in the Spatial Domain" (BRISQUE), IEEE TIP, 2012.
3. Mittal et al., "Making a 'Completely Blind' Image Quality Analyzer" (NIQE), IEEE SPL, 2012.
4. Zhang et al., "FSIM: A Feature Similarity Index for Image Quality Assessment," IEEE TIP, 2011.

### 深度学习里程碑
5. Bosse et al., "Deep Neural Networks for No-Reference and Full-Reference Image Quality Assessment," IEEE TIP, 2018.
6. Zhang et al., "The Unreasonable Effectiveness of Deep Features as a Perceptual Metric" (LPIPS), CVPR 2018.
7. Ke et al., "MUSIQ: Multi-scale Image Quality Transformer," ICCV 2021.

### Bristol 组核心论文
8. Feng et al., "RankDVQA: Deep VQA based on Ranking-inspired Hybrid Training," WACV 2024.
9. Feng et al., "Towards Unified Video Quality Assessment," WACV 2025.
10. Wang et al., "FGSVQA: Frequency-Guided Short-form Video Quality Assessment," 2026.

### LLM/VLM 时代
11. Wu et al., "Q-Align: Teaching LMMs for Visual Scoring via Discrete Text-Defined Levels," ICML 2024.
12. Wu et al., "Q-Bench: A Benchmark for General-Purpose Foundation Models on Low-level Vision," 2023.
13. Wang et al., "Exploring CLIP for Assessing the Look and Feel of Images," AAAI 2023.

### 综述
14. Zheng et al., "Video Quality Assessment: A Comprehensive Survey," arXiv:2412.04508, 2024.
15. Chen et al., "A Comprehensive Review of Image Quality Assessment," 2023.
