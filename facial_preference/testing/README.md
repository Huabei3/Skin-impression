# 模型测试模块

本模块提供了全面的模型测试和评估功能，用于评估人脸颜色喜好度预测模型的性能。

## 📋 功能特性

### 1. 批量测试
- 在完整测试集上评估模型性能
- 提供详细的统计分析
- 生成可视化报告

### 2. 双维度评估

#### 第一维度：喜好度评分(P值)分析
- **平均绝对误差(MAE)**：评估预测精度
- **中位数误差**：评估预测稳定性
- **最好25%和最差25%平均误差**：评估模型极端表现
- **最大值和最小值**：了解误差范围
- **Pearson相关系数**：评估预测与真实值的相关性
- **R²决定系数**：评估模型解释力

#### 第二维度：喜好中心(a*b*值)分析 - 欧氏距离
- **欧氏距离统计**：
  - 平均值、中位数、标准差
  - 最好25%和最差25%平均值
  - 分位数分析(75%, 90%, 95%)
- **Delta E色差分析**：评估色彩感知差异
- **a*和b*独立误差分析**：了解各通道预测性能
- **角度误差分析**：评估色调预测准确度

### 3. 场景分析
- 按不同场景分组统计
- 识别模型在特定场景下的表现
- 帮助发现模型的优势和弱点

### 4. 模型比较
- 自动比较多个检查点的性能
- 找出最佳模型
- 生成比较报告

## 🚀 快速开始

### 安装依赖

```bash
pip install -r requirements.txt
```

### 运行测试

#### 方式1：交互式界面

```bash
python run_test.py
```

选择测试模式：
1. 快速测试最佳模型
2. 测试指定模型
3. 比较所有模型

#### 方式2：命令行模式

```bash
# 快速测试最佳模型
python run_test.py --mode quick

# 测试指定模型
python run_test.py --mode quick --checkpoint path/to/checkpoint.pth

# 比较所有模型
python run_test.py --mode compare
```

#### 方式3：Python脚本调用

```python
from testing.test_runner import QuickTester, ModelComparator

# 快速测试
tester = QuickTester()
results = tester.run()

# 比较模型
comparator = ModelComparator()
comparison_results = comparator.compare_all()
```

## 📊 输出结果

### 测试结果目录结构

```
test_results/
├── test_statistics.json          # 统计结果
├── test_predictions.csv          # 详细预测数据
├── test_report.md                # Markdown格式报告
├── test_results_visualization.png # 可视化图表
└── comparison/                   # 模型比较结果
    ├── model_comparison.json      # 比较数据
    ├── comparison_report.md       # 比较报告
    ├── best_model/               # 最佳模型测试结果
    ├── checkpoint_epoch_10/      # epoch 10测试结果
    └── ...
```

### 统计指标说明

#### 喜好度评分指标
- **MAE (Mean Absolute Error)**：越小越好，目标 < 0.05
- **RMSE (Root Mean Square Error)**：越小越好
- **Pearson相关系数**：越接近1越好，目标 > 0.85
- **R²决定系数**：越接近1越好

#### 喜好中心指标
- **欧氏距离**：越小越好，目标 < 5.0
- **Delta E**：色差指标，< 5为可接受，< 10为合格
- **角度误差**：色调预测准确度，越小越好

### 可视化图表

生成的可视化包含6个子图：
1. **评分预测散点图**：展示预测值vs真实值
2. **评分误差分布**：展示误差的分布情况
3. **欧氏距离分布**：展示a*b*预测的距离分布
4. **a*b*色彩空间分布**：展示预测和真实值在色彩空间的分布
5. **累积误差分布**：展示误差的累积百分比
6. **Delta E色差分布**：展示色差的分布情况

## 📁 模块结构

```
testing/
├── __init__.py           # 模块初始化
├── batch_tester.py       # 批量测试器核心类
├── test_runner.py        # 测试运行器和模型比较器
├── run_test.py          # 主运行脚本
├── README.md            # 本文档
└── requirements.txt     # 依赖包列表
```

## 🔧 主要类和函数

### BatchTester
核心测试类，负责：
- 加载模型和数据
- 运行推理
- 分析结果
- 生成报告

### QuickTester
快速测试包装器，简化测试流程

### ModelComparator
模型比较器，用于比较多个模型的性能

## 📈 性能评估标准

### 优秀
- 喜好度评分 MAE < 0.05
- 欧氏距离 < 5.0
- Pearson相关 > 0.9

### 良好
- 喜好度评分 MAE < 0.08
- 欧氏距离 < 8.0
- Pearson相关 > 0.85

### 合格
- 喜好度评分 MAE < 0.1
- 欧氏距离 < 10.0
- Pearson相关 > 0.8

## 🔍 高级用法

### 自定义输出目录

```python
from testing.batch_tester import BatchTester

tester = BatchTester(
    checkpoint_path="path/to/model.pth",
    output_dir="custom_output_dir"
)
results = tester.run_complete_test()
```

### 只运行部分分析

```python
# 准备数据
test_loader = tester.prepare_test_dataset()

# 运行推理
tester.run_inference(test_loader)

# 只分析评分
score_analysis = tester.analyze_preference_scores()

# 只分析中心
center_analysis = tester.analyze_preference_centers()
```

### 自定义可视化

```python
# 获取预测结果后自定义可视化
import matplotlib.pyplot as plt

plt.figure(figsize=(10, 6))
plt.scatter(tester.targets['scores'], tester.predictions['scores'])
plt.xlabel('Ground Truth')
plt.ylabel('Predictions')
plt.title('Custom Visualization')
plt.show()
```

## 📝 注意事项

1. **数据路径配置**：确保在 `config.py` 中正确设置了数据路径
2. **GPU内存**：批量测试可能需要较大GPU内存，如遇到内存不足，可减小batch_size
3. **测试集一致性**：使用固定的随机种子(666)确保测试集划分的一致性
4. **结果保存**：所有测试结果会自动保存，避免重复运行

## 🐛 常见问题

### Q: 找不到模型文件
A: 检查模型路径是否正确，默认路径为 `output/checkpoints/best_model.pth`

### Q: CUDA out of memory
A: 减小批次大小或使用CPU运行：
```python
tester = BatchTester(checkpoint_path, device='cpu')
```

### Q: 测试结果不一致
A: 确保使用相同的随机种子和数据预处理方式

## 📧 联系支持

如有问题或建议，请联系开发团队。

## 📄 许可证

本项目仅供研究使用。