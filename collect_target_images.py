import os
import sys
from pathlib import Path
import re
from PIL import Image
import json

def parse_filename(filename):
    """
    解析文件名，提取前缀和各个部分
    
    文件名格式: f10ih3k_01_face.jpg
    第一个 _ 前的部分: f10ih3k (personiOrscene)
    person: f10 (前3位: 性别+编号, 如 f01, m02)
    iOr: i 或 r (第4位)
    scene: h3k (剩余部分)
    """
    stem = filename.stem  # f10ih3k_01_face
    parts = stem.split('_')
    if not parts:
        return None
    
    prefix = parts[0]  # f10ih3k
    if len(prefix) < 4:
        return None
    
    # 提取各个部分
    # 假设格式: [f/m][两位数字][i/r][场景代码]
    match = re.match(r'^([fm])(\d{2})([ir])(.+)$', prefix)
    if not match:
        return None
    
    gender = match.group(1)  # f 或 m
    number = match.group(2)  # 01, 02, ...
    i_or = match.group(3)    # i 或 r
    scene = match.group(4)   # h3k, l4k, 等
    
    return {
        'prefix': prefix,
        'gender': gender,
        'number': number,
        'i_or': i_or,
        'scene': scene,
        'person': f"{gender}{number}",  # f10
        'personiOr': f"{gender}{number}{i_or}",  # f10i
        'personiOrscene': prefix,  # f10ih3k
        'filename': filename.name
    }

def find_large_face_images():
    """
    在 rendered_face 文件夹下找到所有尺寸大于800像素的图片
    """
    base_path = Path(r"D:\work\secondYearMaster\thesis\reference\appeal\algorithms\preference_evaluate\deepskin\data\toMax\rendered_face")
    
    i_folders = [f for f in base_path.iterdir() if f.is_dir() and f.name.endswith('i')]
    print(f"找到 {len(i_folders)} 个以 i 结尾的文件夹")
    
    large_images = []
    
    for folder in i_folders:
        folder_name = folder.name
        print(f"检查文件夹: {folder_name}")
        
        count = 0
        for img_file in folder.glob("*.jpg"):
            try:
                with Image.open(img_file) as img:
                    width, height = img.size
                    if width > 800 or height > 800:
                        parsed = parse_filename(img_file)
                        if parsed:
                            parsed.update({
                                'width': width,
                                'height': height,
                                'face_path': str(img_file),
                                'folder': folder_name
                            })
                            large_images.append(parsed)
                            count += 1
            except Exception as e:
                print(f"  处理 {img_file.name} 时出错: {e}")
                continue
        
        if count > 0:
            print(f"  找到 {count} 张尺寸大于800像素的图片")
    
    print(f"\n总共找到 {len(large_images)} 张尺寸大于800像素的图片")
    return large_images

def find_corresponding_global_images(large_images):
    """
    为每张人脸图片找到对应的全局图片
    
    全局图片路径格式:
    D:\work\secondYearMaster\thesis\reference\appeal\algorithms\preference_evaluate\deepskin\data\toMax\rendered_2max\{personiOr}\{personiOrscene}_01.jpg
    例如: ...\rendered_2max\f10i\f10ih3k_01.jpg
    """
    global_base = Path(r"D:\work\secondYearMaster\thesis\reference\appeal\algorithms\preference_evaluate\deepskin\data\toMax\rendered_2max")
    
    for item in large_images:
        personiOr = item['personiOr']  # f10i
        personiOrscene = item['personiOrscene']  # f10ih3k
        
        # 构建全局图片路径
        global_folder = global_base / personiOr
        global_filename = f"{personiOrscene}_01.jpg"
        global_path = global_folder / global_filename
        
        item['global_path'] = str(global_path) if global_path.exists() else None
        item['global_exists'] = global_path.exists()
    
    # 统计存在的全局图片
    existing = sum(1 for item in large_images if item.get('global_exists', False))
    print(f"\n找到 {existing} 张对应的全局图片（共 {len(large_images)} 张）")
    
    return large_images

def create_image_list(images_with_global):
    """
    创建图片列表，只包含全局图片存在的项
    """
    valid_images = [item for item in images_with_global if item.get('global_exists', False)]
    
    print(f"\n有效的图片对（人脸+全局）：{len(valid_images)} 对")
    
    # 按 personiOr 分组统计
    groups = {}
    for item in valid_images:
        personiOr = item['personiOr']
        if personiOr not in groups:
            groups[personiOr] = []
        groups[personiOr].append(item)
    
    print("\n按 personiOr 分组统计:")
    for personiOr, items in sorted(groups.items()):
        print(f"  {personiOr}: {len(items)} 张图片")
    
    # 保存到不同的格式
    output_dir = Path(__file__).parent
    
    # 1. JSON 格式（完整信息）
    json_file = output_dir / "image_pairs.json"
    with open(json_file, 'w', encoding='utf-8') as f:
        json.dump(valid_images, f, indent=2, ensure_ascii=False)
    
    # 2. 纯文本列表（每行一个全局图片路径）
    txt_file = output_dir / "global_images.txt"
    with open(txt_file, 'w', encoding='utf-8') as f:
        for item in valid_images:
            f.write(item['global_path'] + '\n')
    
    # 3. CSV 格式
    csv_file = output_dir / "image_pairs.csv"
    with open(csv_file, 'w', encoding='utf-8') as f:
        f.write("personiOrscene,person,personiOr,scene,face_path,global_path,width,height\n")
        for item in valid_images:
            f.write(f"{item['prefix']},{item['person']},{item['personiOr']},{item['scene']},\"{item['face_path']}\",\"{item['global_path']}\",{item['width']},{item['height']}\n")
    
    print(f"\n结果已保存到:")
    print(f"  JSON: {json_file}")
    print(f"  文本列表: {txt_file}")
    print(f"  CSV: {csv_file}")
    
    return valid_images

def main():
    print("=" * 60)
    print("收集需要处理的人脸检测图片")
    print("=" * 60)
    
    # 步骤1：找到大尺寸的人脸图片
    print("\n步骤1: 扫描 rendered_face 文件夹...")
    large_images = find_large_face_images()
    
    if not large_images:
        print("没有找到符合条件的图片")
        return
    
    # 步骤2：找到对应的全局图片
    print("\n步骤2: 查找对应的全局图片...")
    images_with_global = find_corresponding_global_images(large_images)
    
    # 步骤3：创建图片列表
    print("\n步骤3: 创建图片列表...")
    valid_images = create_image_list(images_with_global)
    
    # 步骤4：创建MATLAB脚本
    print("\n步骤4: 创建MATLAB处理脚本...")
    create_matlab_script(valid_images)

def create_matlab_script(valid_images):
    """
    创建MATLAB脚本，用于批量处理图片
    """
    script_content = '''%% BATCH_FACE_DETECTION
% 批量处理人脸检测
% 自动处理所有符合条件的图片

clear; close all; clc;

%% 图片列表
image_paths = {
'''

    # 添加所有图片路径
    for item in valid_images:
        # 转换Windows路径为MATLAB格式
        matlab_path = item['global_path'].replace('\\', '\\\\')
        script_content += f"    '{matlab_path}'; ...\n"

    script_content += '''};

fprintf('总共需要处理 %d 张图片\\n', length(image_paths));

%% 创建结果目录
result_dir = fullfile(fileparts(mfilename('fullpath')), 'face_detection_results');
if ~exist(result_dir, 'dir')
    mkdir(result_dir);
end

%% 处理每张图片
results = cell(length(image_paths), 1);
detection_stats = struct();

for idx = 1:length(image_paths)
    img_path = image_paths{idx};
    fprintf('[%d/%d] 处理: %s\\n', idx, length(image_paths), img_path);
    
    try
        % 读取图片
        img = imread(img_path);
        [h, w, ~] = size(img);
        
        % 初始化检测器
        faceMinSize = [80 80];
        
        % 1) 默认检测器
        faceDetector = vision.CascadeObjectDetector();
        faceDetector.MinSize = faceMinSize;
        bboxes1 = faceDetector(img);
        
        % 2) LBP检测器
        faceDetectorLBP = vision.CascadeObjectDetector('FrontalFaceLBP');
        faceDetectorLBP.MinSize = faceMinSize;
        bboxes2 = faceDetectorLBP(img);
        
        % 3) CART检测器
        faceDetectorCART = vision.CascadeObjectDetector('FrontalFaceCART');
        faceDetectorCART.MinSize = faceMinSize;
        bboxes3 = faceDetectorCART(img);
        
        % 创建可视化结果
        fig = figure('Visible', 'off');
        imshow(img); hold on;
        
        % 绘制检测框
        if ~isempty(bboxes1)
            for i = 1:size(bboxes1,1)
                rectangle('Position', bboxes1(i,:), 'EdgeColor', 'r', 'LineWidth', 2);
            end
        end
        
        if ~isempty(bboxes2)
            for i = 1:size(bboxes2,1)
                rectangle('Position', bboxes2(i,:), 'EdgeColor', 'g', 'LineWidth', 2);
            end
        end
        
        if ~isempty(bboxes3)
            for i = 1:size(bboxes3,1)
                rectangle('Position', bboxes3(i,:), 'EdgeColor', 'b', 'LineWidth', 2);
            end
        end
        
        % 添加图例
        legend({'Cascade (Default)', 'LBP', 'CART'}, 'Location', 'bestoutside');
        
        % 提取文件名信息
        [path_str, name, ~] = fileparts(img_path);
        
        % 保存结果图
        out_filename = [name '_detection_test.jpg'];
        out_path = fullfile(result_dir, out_filename);
        imwrite(getframe(fig).cdata, out_path);
        
        close(fig);
        
        % 保存检测结果
        result = struct();
        result.img_path = img_path;
        result.img_size = [w, h];
        result.bboxes_default = bboxes1;
        result.bboxes_lbp = bboxes2;
        result.bboxes_cart = bboxes3;
        result.output_path = out_path;
        
        % 计算检测统计
        result.detected_default = ~isempty(bboxes1);
        result.detected_lbp = ~isempty(bboxes2);
        result.detected_cart = ~isempty(bboxes3);
        result.num_faces_default = size(bboxes1, 1);
        result.num_faces_lbp = size(bboxes2, 1);
        result.num_faces_cart = size(bboxes3, 1);
        
        results{idx} = result;
        
        % 更新全局统计
        if result.detected_default
            detection_stats.default_detected = detection_stats.default_detected + 1;
        end
        if result.detected_lbp
            detection_stats.lbp_detected = detection_stats.lbp_detected + 1;
        end
        if result.detected_cart
            detection_stats.cart_detected = detection_stats.cart_detected + 1;
        end
        
        fprintf('  完成: 默认=%d, LBP=%d, CART=%d\\n', ...
                result.num_faces_default, result.num_faces_lbp, result.num_faces_cart);
        
    catch ME
        fprintf('  错误: %s\\n', ME.message);
        results{idx} = struct('img_path', img_path, 'error', ME.message);
    end
end

%% 保存汇总结果
summary_file = fullfile(result_dir, 'detection_summary.mat');
save(summary_file, 'results', 'detection_stats');

% 生成报告
report_file = fullfile(result_dir, 'detection_report.txt');
fid = fopen(report_file, 'w');
fprintf(fid, '人脸检测结果报告\\n');
fprintf(fid, '生成时间: %s\\n', datestr(now));
fprintf(fid, '图片总数: %d\\n', length(image_paths));
fprintf(fid, '\\n检测统计:\\n');
fprintf(fid, '默认检测器检测到人脸的图片数: %d\\n', detection_stats.default_detected);
fprintf(fid, 'LBP检测器检测到人脸的图片数: %d\\n', detection_stats.lbp_detected);
fprintf(fid, 'CART检测器检测到人脸的图片数: %d\\n', detection_stats.cart_detected);
fclose(fid);

fprintf('\\n处理完成！\\n');
fprintf('结果保存在: %s\\n', result_dir);
fprintf('汇总文件: %s\\n', summary_file);
fprintf('报告文件: %s\\n', report_file);
'''

    # 初始化检测统计
    script_content = script_content.replace(
        '% 更新全局统计',
        '''% 初始化检测统计（添加在循环之前）
detection_stats.default_detected = 0;
detection_stats.lbp_detected = 0;
detection_stats.cart_detected = 0;

%% 处理每张图片
results = cell(length(image_paths), 1);

for idx = 1:length(image_paths)
    img_path = image_paths{idx};
    fprintf('[%d/%d] 处理: %s\\n', idx, length(image_paths), img_path);
    
    try
        % 读取图片
        img = imread(img_path);
        [h, w, ~] = size(img);
        
        % 初始化检测器
        faceMinSize = [80 80];
        
        % 1) 默认检测器
        faceDetector = vision.CascadeObjectDetector();
        faceDetector.MinSize = faceMinSize;
        bboxes1 = faceDetector(img);
        
        % 2) LBP检测器
        faceDetectorLBP = vision.CascadeObjectDetector('FrontalFaceLBP');
        faceDetectorLBP.MinSize = faceMinSize;
        bboxes2 = faceDetectorLBP(img);
        
        % 3) CART检测器
        faceDetectorCART = vision.CascadeObjectDetector('FrontalFaceCART');
        faceDetectorCART.MinSize = faceMinSize;
        bboxes3 = faceDetectorCART(img);
        
        % 创建可视化结果
        fig = figure('Visible', 'off');
        imshow(img); hold on;
        
        % 绘制检测框
        if ~isempty(bboxes1)
            for i = 1:size(bboxes1,1)
                rectangle('Position', bboxes1(i,:), 'EdgeColor', 'r', 'LineWidth', 2);
            end
        end
        
        if ~isempty(bboxes2)
            for i = 1:size(bboxes2,1)
                rectangle('Position', bboxes2(i,:), 'EdgeColor', 'g', 'LineWidth', 2);
            end
        end
        
        if ~isempty(bboxes3)
            for i = 1:size(bboxes3,1)
                rectangle('Position', bboxes3(i,:), 'EdgeColor', 'b', 'LineWidth', 2);
            end
        end
        
        % 添加图例
        legend({'Cascade (Default)', 'LBP', 'CART'}, 'Location', 'bestoutside');
        
        % 提取文件名信息
        [path_str, name, ~] = fileparts(img_path);
        
        % 保存结果图
        out_filename = [name '_detection_test.jpg'];
        out_path = fullfile(result_dir, out_filename);
        imwrite(getframe(fig).cdata, out_path);
        
        close(fig);
        
        % 保存检测结果
        result = struct();
        result.img_path = img_path;
        result.img_size = [w, h];
        result.bboxes_default = bboxes1;
        result.bboxes_lbp = bboxes2;
        result.bboxes_cart = bboxes3;
        result.output_path = out_path;
        
        % 计算检测统计
        result.detected_default = ~isempty(bboxes1);
        result.detected_lbp = ~isempty(bboxes2);
        result.detected_cart = ~isempty(bboxes3);
        result.num_faces_default = size(bboxes1, 1);
        result.num_faces_lbp = size(bboxes2, 1);
        result.num_faces_cart = size(bboxes3, 1);
        
        results{idx} = result;
        
        % 更新全局统计'''
    )

    script_file = Path(__file__).parent / "batch_face_detection.m"
    with open(script_file, 'w', encoding='utf-8') as f:
        f.write(script_content)
    
    print(f"  MATLAB脚本: {script_file}")
    
    # 创建简单的MATLAB调用脚本
    simple_script = '''%% RUN_FACE_DETECTION
% 运行人脸检测脚本
clear; close all; clc;

% 添加当前目录到路径
addpath(fileparts(mfilename('fullpath')));

% 运行批量处理
batch_face_detection;

fprintf('\\n处理完成！\\n');
'''
    
    simple_file = Path(__file__).parent / "run_face_detection.m"
    with open(simple_file, 'w', encoding='utf-8') as f:
        f.write(simple_script)
    
    print(f"  运行脚本: {simple_file}")

if __name__ == "__main__":
    main()