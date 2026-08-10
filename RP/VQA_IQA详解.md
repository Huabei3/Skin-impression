# Quality Assessment in the Era of Large Models: A Survey -- 调研笔记

---

## 一、AQA（美学质量评估）论文列表

### 1.1 通用照片美学
| 编号 | 论文全称 |
|------|----------|
| 01 | Photo Quality Assessment with DCNN that Understands Image Well (Dong et al., 2015) |
| 02 | Content-based Photo Quality Assessment (Luo et al., 2011) |
| 03 | Visual Aesthetic Quality Assessment with a Regression Model (Kao et al., 2015) |
| 04 | Hierarchical Aesthetic Quality Assessment Using Deep Convolutional Neural Networks (Kao et al., 2016) |
| 05 | Deep Aesthetic Quality Assessment with Semantic Information (Kao et al., 2017) |
| 06 | Photo Aesthetics Ranking Network with Attributes and Content Adaptation (Kong et al., 2016) |
| 07 | Objectivity and Subjectivity in Aesthetic Quality Assessment of Digital Photographs (Kim et al., 2018) |
| 08 | Predicting Aesthetics Score Distribution through Cumulative Jensen-Shannon Divergence (Jin et al., 2018) |
| 09 | Aesthetic Attributes Assessment of Images (Jin et al., 2019) |
| 10 | Deep Learning for Assessing the Aesthetics of Professional Photographs (Chambe et al., 2022) |
| 11 | Rethinking Image Aesthetics Assessment: Models, Datasets and Benchmarks (He et al., 2022) |
| 12 | Pseudo-labeling and Meta Reweighting Learning for Image Aesthetic Quality Assessment (Jin et al., 2022) |
| 13 | Thinking Image Color Aesthetics Assessment: Models, Datasets and Benchmarks (He et al., 2023) |

### 1.2 人脸美学
| 编号 | 论文全称 |
|------|----------|
| 14 | Aesthetic Quality Assessment of Consumer Photos with Faces (Li et al., 2010) |
| 15 | Learning Artistic Lighting Template from Portrait Photographs (Jin et al., 2010) |
| 16 | Low Level Features for Quality Assessment of Facial Images (Lienhard et al., 2015) |

### 1.3 智能手机摄影美学
| 编号 | 论文全称 |
|------|----------|
| 17 | Perceptual Quality Assessment of Smartphone Photography (Fang et al., 2020) |

### 1.4 视频美学
| 编号 | 论文全称 |
|------|----------|
| 18 | Deep Multimodality Learning for UAV Video Aesthetic Quality Assessment (Kuang et al., 2019) |

---

## 二、3DQA（3D质量评估）论文列表

### 2.1 点云质量评估（PCQA）
| 编号 | 论文全称 |
|------|----------|
| 01 | On the Performance of Metrics to Predict Quality in Point Cloud Representations (Alexiou et al., 2017) |
| 02 | Towards Subjective Quality Assessment of Point Cloud Imaging in Augmented Reality (Alexiou et al., 2017) |
| 03 | Point Cloud Quality Assessment Metric Based on Angular Similarity (Alexiou et al., 2018) |
| 04 | Point Cloud Subjective Evaluation Methodology Based on 2D Rendering (Alexiou et al., 2018) |
| 05 | Multi-distance Point Cloud Quality Assessment (Diniz et al., 2020) |
| 06 | Point Cloud Rendering after Coding: Impacts on Subjective and Objective Quality (Javaheri et al., 2020) |
| 07 | Reduced Reference Perceptual Quality Model with Application to Rate Control for Video-based Point Cloud Compression (Liu et al., 2021) |
| 08 | Perceptual Quality Assessment of Colored 3D Point Clouds (Liu et al., 2022) |
| 09 | Point Cloud Quality Assessment: Dataset Construction and Learning-based No-reference Metric (Liu et al., 2023) |
| 10 | Machine Perception Point Cloud Quality Assessment via Vision Tasks (Lu et al., 2020) |
| 11 | A No-reference Quality Assessment Metric for Point Cloud Based on Captured Video Sequences (Fan et al., 2022) |
| 12 | BASICS: Broad Quality Assessment of Static Point Clouds in a Compression Scenario (Ak et al., 2024) |

### 2.2 数字人/网格质量评估
| 编号 | 论文全称 |
|------|----------|
| 13 | A No-reference Quality Assessment Metric for Dynamic 3D Digital Human (Chen et al., 2023) |


---

## 话题二：LMM（大模型）发展概览

### 1. 为什么需要LMM？

传统质量评估是专用小模型：每个任务（IQA/VQA/AQA/3DQA）各自训练。LMM可在质量评估中充当"通才评估器"，同时理解图像和文本，具有零样本推理和泛化能力。

### 2. LLM纯语言基座

- **GPT系列**: GPT-3(2020, 175B) -> ChatGPT/GPT-3.5(2022, RLHF对齐) -> GPT-4(2023, 更强推理)
- **LLaMA系列(Meta)**: LLaMA(2023, 7B-65B) -> LLaMA2(2023, 2T tokens) -> LLaMA3(2024)
- **Vicuna(2023)**: 基于LLaMA，用ShareGPT的70K对话数据指令微调，LLaVA等LMM最常用语言基座
- **Flan-T5(Google)**: Encoder-Decoder架构，BLIP-2/InstructBLIP使用

### 3. 从LLM到LMM：架构实现

**核心公式**: LLM + 视觉编码器 + 适配模块 = LMM

```
视觉输入(I) --[CLIP ViT]--> 视觉特征F_v --[Connector]--+
                                                       v
文本输入(Prompt) ----------------------------------> LLM --> 输出
```

**关键架构演进**:

| 方法 | 视觉编码器 | 适配模块 | 语言基座 | 特点 |
|------|-----------|---------|---------|------|
| OpenFlamingo(2023) | CLIP ViT | 门控交叉注意力 | LLaMA/MPT | 冻结视觉+LLM，最早开源 |
| BLIP-2(2023) | CLIP/EVA ViT | Q-Former | OPT/FlanT5 | 可学习query token桥接两模态 |
| LLaVA(2023) | CLIP ViT-L | 单层Linear | Vicuna | 视觉指令微调，GPT-4生成数据 |
| LLaVA v1.5(2023) | CLIP ViT-L | 2层MLP | Vicuna v1.5 | 更高分辨率，性能显著提升 |
| InstructBLIP(2023) | ViT-G/14 | Q-Former | FlanT5/Vicuna | 指令感知视觉特征提取 |
| MiniGPT-4(2023) | EVA ViT-G | 单层Linear | Vicuna-13B | 轻量级，对齐阶段只用5K图文对 |
| mPLUG-Owl2(2023) | ViT-L | 模态自适应模块 | LLaMA2 | 模态共享+模态特定模块混合 |
| InternLM-VL(2023) | InternViT | 跨模态对齐 | InternLM | 书生系列，中英文多模态 |
| Emu2-Chat(2023) | EVA-02 ViT | - | LLaMA-33B | 统一生成+理解，表4中best SRCC=0.59 |
| CogVLM(2023) | EVA2-CLIP | 视觉专家模块 | Vicuna-7B | LLM每层加可训练视觉专家 |
| Fuyu-8B(2023) | 无独立编码器 | 直接patch projection | Persimmon-8B | 极简设计但评估差(SRCC~0.17) |

### 4. 关键发现

- 语言解码能力是评估能力的基础：相同CLIP编码器+更强LLM -> 显著提升评估
- 模型规模对评估至关重要：Fuyu-8B SRCC仅0.17，Emu2-Chat-33B达0.84
- 开源模型差距缩小：LLaVA v1.5已接近GPT-4V性能


---

## 话题三：5大类多模态Benchmark的输入输出与构建方式

### 第1类：图像理解

#### MMBench(2023)
- **输入**: 单张图像 + 多选题文本(中/英文)
- **输出**: A/B/C/D选项
- **构建**: 2,974题覆盖20个细粒度能力(感知层: 粗/细粒度实例感知+跨实例关系; 认知层: 属性/社交/物理/功能推理)。GPT-4生成问题+人类验证。指标: 准确率

#### MM-Vet(2023)
- **输入**: 单张图像 + 开放式问题(需复杂推理)
- **输出**: 自由文本回答
- **构建**: 6种核心能力(识别/OCR/知识/空间感知/语言生成/数学)，不同难度等级。200个图像-问题对，从VQA/OK-VQA挑选+GPT-4生成。指标: GPT-4辅助评估(0-1分)

#### Q-Bench(2023)
- **输入**: 单张图像 + 质量评估prompt("Describe the quality and aesthetics...")
- **输出**: 
  - 方式1(开放文本): 质量描述
  - 方式2(softmax): 提取good/poor token的logits做softmax -> [0,1]分数
- **构建**: 7个IQA/AQA数据集(KADID-10K/LIVE/KonIQ-10k/AGIQA-3K/AIGCIQA2023/SRIQA-Bench/LIVE-FB)，每张图像有MOS ground truth。统一prompt模板测zero-shot质量感知。指标: SRCC/PLCC。约2,500+图像

#### Aes-Bench(2023)
- **输入**: 单张照片 + 美学评估prompt
- **输出**: 美学评分
- **构建**: 从AVA/TAD66K等美学数据集选取，涵盖通用美学/人脸美学/美食美学。指标: SRCC/PLCC

### 第2类：视频理解

#### MVBench(2023)
- **输入**: 一段视频(截帧后输入) + 多选题
- **输出**: 正确选项
- **构建**: 20个时间理解任务(动作序列/预测/反事实推理/场景转换等)，每任务400个视频+问题对，来自Something-Something/Kinetics/TVQA。指标: 准确率。8,000题

#### Video-MME(2024)
- **输入**: 长视频(最长60分钟，均匀采样关键帧) + 多选题
- **输出**: 正确选项
- **构建**: 30个类别视频(纪录片/电影/教程)，问题涵盖: 时间定位/事件回忆/因果推理。指标: 准确率。2,700题

#### MLVU(2024)
- **输入**: 长视频(最长2小时) + 多选题
- **输出**: 正确选项
- **构建**: 9个任务类别(时间顺序/情节摘要/角色识别/主题推理)，从电影/电视剧提取。指标: 准确率。2,593题

### 第3类：科学/专业推理

#### MathVista(2023)
- **输入**: 图像(几何图/图表/公式/3D模型) + 数学问题文本
- **输出**: 数学答案(数字或选项)
- **构建**: 融合28个现有数学数据集(CLEVR-Math/GeomVerse/IQTest)+GPT-4新题。覆盖7种推理能力(代数/算术/几何/逻辑/数值常识/科学/统计)，5种可视化类型。指标: 准确率。6,141题

#### MMMU(2023)
- **输入**: 大学学科多模态题目(公式+图表+照片+表格+问题文本)
- **输出**: 多选题或开放式回答
- **构建**: 30个大学学科(物理/化学/生/医/艺术/历史等)真实考题。难度本科到专业级(USMLE/LSAT)。领域专家筛选验证。指标: 准确率。11,550题

### 第4类：幻觉检测

#### HallusionBench(2023)
- **输入**: 带视觉陷阱的图像 + 是/否问题
- **输出**: Yes/No
- **构建**: 346对对照图像(原图 vs. 编辑移除关键物体)。问题设计让只看语言先验的模型出错，必须准确理解图像。例如: 原图有猫->"Do you see a cat?"=Yes; 移除猫后的图=No。指标: 准确率/幻觉率。1,129题

#### RAVIE(2023)
- **输入**: 图像 + 描述该图像的句子(可能含虚假信息)
- **输出**: 描述正确/错误
- **构建**: 从COCO选图，生成正确描述+对应虚假描述(替换物体/属性/关系/数量)。测试模型检测"不实描述"能力

### 第5类：3D理解

#### LAMM-Bench(2023)
- **输入**: 3D点云的2D投影/渲染图像 + 3D场景问题
- **输出**: 文本回答(描述/分类/计数等)
- **构建**: 从ShapeNet/3D-FRONT获取点云，渲染为多视角2D图像送入LMM。设计物体识别/空间关系/属性描述问题。指标: 准确率。~1,500题

#### M3DBench(2023)
- **输入**: 3D场景多视角渲染图 + 多模态指令
- **输出**: 文本回答
- **构建**: 从Objaverse等大规模3D数据集构建。设计空间推理/物体关系/3D属性等任务


---

## 话题四：AIGC生成模型发展 详解

### 一、文生图 (T2I, Text-to-Image)

**输入**: 文本描述(prompt)  -->  **输出**: 符合描述的图像(256x256 ~ 1024x1024)

#### 发展时间线

```
2016 AlignDRAW:
  最早T2I，文本编码器与生成式RNN对齐，注意力机制align文本到像素生成，输出32x32

2016-2020 GAN时代:
  StackGAN(2017): 输入文本 -> Stage1:64x64 -> Stage2:256x256
  AttnGAN(2018): 跨模态注意力，细粒度文本-图像对齐
  BigGAN(2019): 大规模GAN，ImageNet高保真图像
  StyleGAN2(2020): 高质量人脸生成
  共同局限: 模式崩溃、多样性不足、可控性有限

2021 CLIP引导生成:
  DALL-E(2021):
    输入: 文本token序列(BPE编码，最多256 tokens)
    输出: 256x256 RGB图像
    原理: VQ-VAE将图像离散化为1024个token，自回归Transformer建模 文本->图像token
  CLIP+VQGAN(2021): CLIP损失指导VQGAN生成，zero-shot T2I无需训练

2022-2023 扩散模型统治:
  Stable Diffusion(2022):
    输入: 文本prompt(CLIP text encoder -> 77x768 dim)
    输出: 512x512/768x768 RGB图像
    原理: Latent Diffusion，在压缩latent space中扩散+去噪
    组件: CLIP Text Encoder + UNet(去噪) + VAE(编解码)
    训练数据: LAION-5B(50亿图文对)

  DALL-E 2(2022):
    输入: 文本描述
    输出: 1024x1024图像
    原理: CLIP文本->图像embedding + 扩散解码器
    特色: 图像编辑(inpainting)、变体生成

  Midjourney(2022-2023):
    输入: 文本prompt + 可选参数(style/ratio/--v5)
    输出: 多种风格艺术感图像
    特点: 闭源、美学优先、社区驱动

  Imagen(Google, 2022):
    输入: 文本prompt
    输出: 1024x1024图像
    原理: 级联扩散，T5-XXL文本编码器(比CLIP更强)，64->256->1024级联超分

  Parti(Google, 2022):
    输入: 长文本(可达1000+tokens)
    输出: 图像
    原理: 自回归seq2seq，VQ-GAN tokenizer+ViT-VQGAN+Encoder-Decoder Transformer

  DALL-E 3(2023):
    输入: 自然语言描述(GPT-4自动优化prompt)
    输出: 高质量图像
    特色: GPT-4进行prompt改写，大幅提升文本遵从度
```

### 二、文生视频 (T2V, Text-to-Video)

**输入**: 文本描述 --> **输出**: 符合描述的视频(多帧序列+时序一致性)

```
2022 CogVideo: 输入中/英文prompt -> 输出480x480视频，CogView2扩展到时间维度
2022 Make-A-Video(Meta): 无需文本-视频配对数据! 用文本-图像+无标注视频时空学习
2023 VideoLDM: Latent Diffusion扩展到视频域，latent space时空扩散
2023 LaVie(腾讯): 输入prompt -> 级联生成+时间插值+超分，base(16帧) -> 上采样(61帧)
2024 Sora(OpenAI):
  输入: 文本prompt + 可选图像/视频条件
  输出: 最长60秒高保真视频
  原理: Diffusion Transformer(DiT) + 时空patch化，3D一致性和世界模型
```


---

## 话题五：AIGC质量评估数据集 详解

| 数据集 | 模型来源 | 规模 | 评价维度 | 输入 | 输出/Ground Truth |
|--------|---------|------|---------|------|-------------------|
| HPS(2023) | SD系列 | 98,800对 | 人类偏好 | 两张AIGC图像pair | 二选一偏好标签 |
| ImageReward(2023) | SD/DALL-E等 | 136,900对 | 对齐+保真+总体 | prompt+图像 | 7分制+排序 |
| AGIQA-3K(2023) | SD/GAN等 | 2,982 | 感知质量+对齐 | 单张AIGC图像 | MOS(1-5)+对齐评分 |
| AIGCIQA2023 | 7个T2I模型 | 2,400 | 技术+美学 | 单张AIGC图像 | MOS(1-5) |
| AIGIQA-20K(2024) | 15个T2I模型 | 20,000 | 感知质量 | 单张AIGC图像 | MOS(1-5) |
| T2VQA-DB(2024) | 9个T2V模型 | 10,000 | 感知质量 | 单个AIGC视频 | MOS(1-5) |
| Pick-a-Pic(2023) | 多种模型 | 500K+ | 人类偏好 | 两张图像pair | 用户选择标签 |

### 各数据集构建方式

**(1) HPS**: 爬取Discord社区SD用户成对比较数据 -> 形成(prompt, image_A, image_B, human_choice)

**(2) ImageReward**: 10,000个prompt -> 多张生成图 -> 3人标注7分制(对齐/保真/总体)+排序 -> 训练Reward Model

**(3) AGIQA-3K**: GAN+扩散模型生成 -> 专业标注感知质量+文本对齐两维度MOS(1-5)

**(4) AIGCIQA2023**: 7个T2I模型各350张 -> 人工标注技术质量+美学质量

**(5) AIGIQA-20K**: 15个T2I模型 -> 20,000张 -> 大规模人工标注感知质量MOS -> 最大AIGC图像质量库

**(6) T2VQA-DB**: 9个T2V模型(modelscope/VideoCrafter/LaVie等) -> 10,000个视频 -> 人工MOS -> 最大AIGC视频质量库


---

## 话题六：Section 4 -- 大模型作为评估器 三方法原理

### 方法一：Prompt驱动评估

**核心**: 自然语言prompt直接让LMM评估质量，无需训练。

#### (A) 单刺激评估(Single-stimulus)

```
Q-Bench Prompt:
"Assume you are an expert in quality assessment. 
Please describe the quality, aesthetics, and other low-level 
appearance of the image <IMAGE> in detail. Then give the final 
quality rating based on your previous description."
```

**softmax分数提取法（核心创新）**：
```
1. 设计回答模板，让模型输出"good"或"poor"
2. 不取文本输出，提取LMM在"good"和"poor"两个token上的原始logits
3. Q = exp(logit_good) / [exp(logit_good) + exp(logit_poor)]

为什么更好？LMM文本输出不稳定，logits隐式编码了内部置信度
```

**Q-Boost改进**: {good+high+fine} vs {average+medium+acceptable} vs {poor+low+bad}，9个token三组，扩大同义词集大幅提升zero-shot性能

**CoT增强(X-iqe)**：
```
Round 1: 图像整体描述
Round 2: 保真度分析
Round 3: 文本-图像对齐分析
Round 4: 美学分析
Round 5: 各维度+总体评分
```

#### (B) 多刺激评估(Multiple-stimulus)

**2AFC-LMMs**:
```
Prompt: "This is the first image: <IMG1>. This is the second image: <IMG2>. 
         Which image has better visual quality?"
Output: "The first/second image."

原理: N张图像两两配对 -> 成对比较矩阵 -> Thurstone's Case V模型
      P(i>j) = Phi(mu_i - mu_j) -> 极大似然估计全局质量分数向量
```

**优缺点**: 零样本/可解释/通用 vs. 依赖prompt设计/输出不稳定/与人工SRCC不如专训模型

---

### 方法二：特征驱动评估

**核心**: 利用LMM/CLIP的中间特征进行质量评估，通常需额外训练。

#### CLIP-based方法

**ZEN-IQA**: 正负prompt对("good image"/"bad image") -> CLIP余弦相似度差 = Q_score，完全零样本

**QA-CLIP**: 构建细粒度质量层级(5级文本描述) -> 冻结图像编码器+微调文本编码器 -> 使图像特征与质量等级文本对齐

**LIQE**: 多任务学习(场景分类+失真识别+质量回归) -> 辅助知识增强 -> 自动优化任务权重 -> 泛化到未见数据集

**VILA**: 从用户评论(非人工评分)学习美学 -> "beautiful composition!"/"too blurry" -> CLIP对齐图像+评论embedding -> 零样本泛化

**QualiCLIP**: 自监督opinion-unaware方法 -> 合成失真图像 + 反义prompt对齐训练 -> 无需人工标注

**BVQI**: CLIP评估视频语义与prompt亲和度 + 时间一致性特征 -> 综合评估视频质量

---

### 方法三：Quality-Infused LMM评估(质量知识注入)

**核心**: 将质量评估知识"注入"LMM，通过微调使LMM成为专业质量评估器。

#### 各方法原理

**Q-Instruct(2023)**:
```
1. 用GPT-4V生成详细的图像质量描述(不仅分数，还有原因分析)
2. 构建大规模质量描述数据集
3. 用这些高质量标注微调LMM(如LLaVA)
4. 微调后: 不仅能打分(3.2/5)，还能解释"为什么"(JPEG伪影/色彩不足等)
```

**Q-Align(2024)**:
```
关键创新：连续MOS -> 离散质量等级文本
  MOS=4.2/5 -> "The quality is good."
  MOS=1.8/5 -> "The quality is poor."
1. 将传统IQA/AQA/AIGC数据重格式化为文本对话
2. 使用LoRA低秩适配微调LMM
3. 证明了将LMM微调为"质量评估器"可行
```

**Co-instruct(2024)**:
```
1. GPT-4V标注大规模图像比较数据
2. Pairwise: "A better than B because..."
3. Listwise: "Ranking: C > A > B, because..."
4. 训练LMM进行开放式质量比较(不仅分高下，还给出理由)
```

**DepictQA(2023)**:
```
层次化任务框架:
  Level 1: 质量等级评估(Rating: excellent/good/fair/poor/bad)
  Level 2: 质量比较(Comparison: A > B)
  Level 3: 详细推理(Answer + Detailed reasoning)
模拟人类从整体感知 -> 比较判断 -> 深入分析的推理过程
```

**DepictQA-Wild(2024)**: 扩展IQA到野外场景 + 保持图像原始分辨率 + 估计置信度

**VisualCritic**: 同时输出定量MOS + 定性解释，模拟类人感知

**AesExpert**: 构建专家级美学基础模型，收集美学评论语料对齐LMM

**Compare2Score**: 创新的软比较方法，将相对比较转化为连续精确质量分数:
```
LMM输出比较偏好概率P(A>B|A,B) 
-> 用Bradley-Terry模型: P(A>B) = exp(s_A) / [exp(s_A) + exp(s_B)]
-> 极大似然估计得到连续质量分数s_A, s_B
```

**LMM-PCQA**: 将LMM扩展到点云质量评估 -> 立方体投影 + 问答对

---

## 三方法对比总结

| 维度 | Prompt驱动 | 特征驱动 | Quality-Infused |
|------|-----------|---------|----------------|
| 训练需求 | 零样本 | 需训练/微调 | 需大量标注微调 |
| 可解释性 | 高(自然语言) | 低(黑箱特征) | 高(语言输出+理由) |
| 与人类相关度 | 中等 | 高 | 最高 |
| 通用性 | 最强 | 中等 | 需要领域数据 |
| 代表性工作 | Q-Bench, 2AFC-LMMs | CLIP-based系列 | Q-Instruct, Q-Align |

