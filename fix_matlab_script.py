import os
import json
from pathlib import Path

def fix_matlab_script():
    # 读取图片对数据
    json_file = Path(__file__).parent / "image_pairs.json"
    with open(json_file, 'r', encoding='utf-8') as f:
        image_pairs = json.load(f)
    
    print(f"读取到 {len(image_pairs)} 张图片")
    
    # 去重：只保留唯一的全局图片路径
    unique_paths = []
    seen_paths = set()
    
    for item in image_pairs:
        path = item.get('global_path')
        if path and path not in seen_paths:
            seen_paths.add(path)
            unique_paths.append(path)
    
    print(f"去重后剩下 {len(unique_paths)} 张唯一图片")
    
    # 生成MATLAB脚本内容
    script_content = '''%% BATCH_FACE_DETECTION
% 批量处理人脸检测
% 自动处理所有符合条件的图片

clear; close all; clc;

%% 图片列表
image_paths = {
'''
    
    # 添加所有唯一图片路径
    for path in unique_paths:
        # 转换Windows路径为MATLAB格式
        matlab_path = path.replace('\\', '\\\\')
        script_content += f"    '{matlab_path}'; ...\n"
    
    script_content += '''};

fprintf('总共需要处理 %d 张图片\\n', length(image_paths));

%% 初始化检测统计
detection_stats.default_detected = 0;
detection_stats.lbp_detected = 0;
detection_stats.cart_detected = 0;

%% 创建结果目录
result_dir = fullfile(fileparts(mfilename('fullpath')), 'face_detection_results');
if ~exist(result_dir, 'dir')
    mkdir(result_dir);
end

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
    
    # 保存修正后的MATLAB脚本
    script_file = Path(__file__).parent / "batch_face_detection.m"
    with open(script_file, 'w', encoding='utf-8') as f:
        f.write(script_content)
    
    print(f"修正后的MATLAB脚本已保存到: {script_file}")
    
    # 更新文本文件
    txt_file = Path(__file__).parent / "global_images_unique.txt"
    with open(txt_file, 'w', encoding='utf-8') as f:
        for path in unique_paths:
            f.write(path + '\n')
    
    print(f"唯一图片列表已保存到: {txt_file}")
    
    # 统计信息
    print(f"\n统计信息:")
    print(f"  原始图片数量: {len(image_pairs)}")
    print(f"  唯一图片数量: {len(unique_paths)}")
    print(f"  重复图片数量: {len(image_pairs) - len(unique_paths)}")
    
    # 检查一些示例路径
    if unique_paths:
        print(f"\n示例图片路径（前5个）:")
        for i, path in enumerate(unique_paths[:5]):
            print(f"  {i+1}. {path}")

if __name__ == "__main__":
    fix_matlab_script()