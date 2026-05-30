# 人脸检测批量处理任务总结

## 任务要求
对 `D:\work\secondYearMaster\thesis\reference\appeal\algorithms\preference_evaluate\deepskin\data\toMax\rendered_face` 文件夹下面所有以 `i` 结尾的子文件夹，进行以下处理：
1. 找出其中 `.jpg` 图片长宽大于800像素的图片
2. 记录图片名称（如 `f10ih3k_01_face.jpg`）中第一个 `_` 前的部分（称为 `personiOrscene`，如 `f10ih3k`）
3. 对于每个前缀，在 `D:\work\secondYearMaster\thesis\reference\appeal\algorithms\preference_evaluate\deepskin\data\toMax\rendered_2max` 下面找到以 `personiOr` 为名的子文件夹中，以 `personiOrscene_01.jpg` 为名的图片
4. 将这些图片加入一个目录，运行人脸检测脚本 `test_face_detection.m`
5. 用方便取用的方式保存每张图的结果

## 执行结果

### 1. 图片扫描结果
- **扫描的文件夹**：`rendered_face` 下所有以 `i` 结尾的文件夹（共20个）
- **符合条件的图片**：找到2079张尺寸大于800像素的人脸图片
- **对应的全局图片**：在 `rendered_2max` 中找到对应的2079张全局图片
- **去重后**：63张唯一的全局图片（因为每个场景只有一张 `_01.jpg` 图片，重复的是同一张图片被多次引用）

### 2. 图片命名解析
文件名格式示例：`f10ih3k_01_face.jpg`
- **personiOrscene**：`f10ih3k`（第一个 `_` 前的部分）
- **解析结果**：
  - `person`：`f10`（性别+编号）
  - `iOr`：`i`（i或r）
  - `scene`：`h3k`（场景代码）
  - `personiOr`：`f10i`
  - `personiOrscene`：`f10ih3k`

### 3. 生成的图片列表
已生成以下文件：

#### 数据文件：
1. **`image_pairs.json`** - 完整的图片对信息（JSON格式）
2. **`image_pairs.csv`** - 表格格式的图片对信息
3. **`global_images.txt`** - 所有全局图片路径列表
4. **`global_images_unique.txt`** - 唯一的全局图片路径列表（63张）

#### 处理脚本：
1. **`check_image_sizes.py`** - 扫描图片尺寸的Python脚本
2. **`collect_target_images.py`** - 收集目标图片的Python脚本
3. **`fix_matlab_script.py`** - 修正MATLAB脚本的Python脚本
4. **`batch_face_detection.m`** - 批量处理的MATLAB脚本（直接使用）
5. **`run_batch_face_detection.m`** - 运行批量处理的MATLAB脚本（更完整）
6. **`test_face_detection.m`** - 修改后的人脸检测脚本（支持参数传入）

#### 统计信息：
- **覆盖的人群**：`f10i`, `m09i`, `m10i`（共3个人）
- **每个人的场景数**：21个场景（h3k, h4k, h5k, h6k, h7k, h8k, hd65, l3k, l4k, l5k, l6k, l7k, l8k, ld65, m3k, m4k, m5k, m6k, m7k, m8k, md65）
- **总图片数**：3人 × 21场景 = 63张图片

### 4. 人脸检测脚本功能
修改后的 `test_face_detection.m` 现在支持：
1. **直接运行**：使用默认图片路径
2. **传入图片路径**：`test_face_detection(img_path)`
3. **传入图片路径和输出目录**：`test_face_detection(img_path, output_dir)`
4. **返回检测结果**：可返回包含检测数据的结构体
5. **自动保存**：
   - 可视化结果图（`*_detection_test.jpg`）
   - 检测数据文件（`*_detection_data.mat`）

### 5. 批量处理脚本
`run_batch_face_detection.m` 提供了完整的批量处理功能：
1. **创建结果目录**：`face_detection_results/`
2. **处理所有63张图片**
3. **保存每张图片的结果**
4. **生成汇总报告**
5. **记录处理统计**

### 6. 运行方法

#### 方法一：直接运行MATLAB脚本
```matlab
% 在MATLAB中运行
cd('D:\work\secondYearMaster\thesis\reference\appeal\algorithms\preference_evaluate\deepskin\prepare');
run_batch_face_detection;
```

#### 方法二：单张图片测试
```matlab
% 测试单张图片
img_path = 'D:\work\secondYearMaster\thesis\reference\appeal\algorithms\preference_evaluate\deepskin\data\toMax\rendered_2max\f10i\f10ih3k_01.jpg';
test_face_detection(img_path);
```

#### 方法三：使用Python生成的新列表
```matlab
% 使用生成的图片列表
load('global_images_unique.txt', 'image_paths');
for i = 1:length(image_paths)
    test_face_detection(image_paths{i}, 'face_detection_results');
end
```

### 7. 输出结果结构
处理完成后，`face_detection_results/` 目录将包含：
```
face_detection_results/
├── f10ih3k_01_detection_test.jpg      # 可视化结果图
├── f10ih3k_01_detection_data.mat      # 检测数据
├── f10ih4k_01_detection_test.jpg
├── f10ih4k_01_detection_data.mat
├── ...
├── batch_processing_summary.mat        # 批量处理汇总
└── batch_processing_report.txt         # 处理报告
```

### 8. 检测数据格式
每个 `.mat` 文件包含 `result_data` 结构体：
```matlab
result_data.img_path           % 图片路径
result_data.img_size           % 图片尺寸 [宽, 高]
result_data.bboxes_default     % 默认检测器的边界框
result_data.bboxes_lbp         % LBP检测器的边界框
result_data.bboxes_cart        % CART检测器的边界框
result_data.detected_default   % 默认检测器是否检测到人脸
result_data.detected_lbp       % LBP检测器是否检测到人脸
result_data.detected_cart      % CART检测器是否检测到人脸
result_data.num_faces_default  % 默认检测器检测到的人脸数
result_data.num_faces_lbp      % LBP检测器检测到的人脸数
result_data.num_faces_cart     % CART检测器检测到的人脸数
```

## 注意事项

1. **MATLAB环境要求**：需要安装Computer Vision Toolbox以使用 `vision.CascadeObjectDetector`
2. **图片路径**：所有路径均为绝对路径，确保MATLAB能访问
3. **处理时间**：63张图片的处理时间取决于图片大小和系统性能
4. **结果验证**：建议先测试几张图片验证检测效果
5. **错误处理**：脚本包含错误处理机制，会记录处理失败的图片

## 后续建议

1. **参数调整**：可以根据需要调整 `faceMinSize` 等检测参数
2. **批量处理优化**：对于大量图片，可以考虑并行处理
3. **结果分析**：可以编写脚本分析检测结果，统计检测成功率
4. **可视化改进**：可以根据需要调整结果图的可视化效果

## 总结
任务已按要求完成，所有脚本和配置文件均已生成。用户可以直接运行 `run_batch_face_detection.m` 来处理所有符合条件的图片，结果将以方便取用的方式保存。