%% RUN_BATCH_FACE_DETECTION
% 批量运行人脸检测脚本 test_face_detection.m
% 处理所有符合条件的图片

clear; close all; clc;

%% 图片列表（从Python脚本生成的唯一图片）
image_paths = {
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\f10i\\f10ih3k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\f10i\\f10ih4k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\f10i\\f10ih5k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\f10i\\f10ih6k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\f10i\\f10ih7k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\f10i\\f10ih8k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\f10i\\f10ihd65_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\f10i\\f10il3k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\f10i\\f10il4k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\f10i\\f10il5k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\f10i\\f10il6k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\f10i\\f10il7k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\f10i\\f10il8k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\f10i\\f10ild65_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\f10i\\f10im3k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\f10i\\f10im4k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\f10i\\f10im5k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\f10i\\f10im6k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\f10i\\f10im7k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\f10i\\f10im8k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\f10i\\f10imd65_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\m09i\\m09ih3k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\m09i\\m09ih4k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\m09i\\m09ih5k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\m09i\\m09ih6k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\m09i\\m09ih7k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\m09i\\m09ih8k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\m09i\\m09ihd65_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\m09i\\m09il3k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\m09i\\m09il4k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\m09i\\m09il5k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\m09i\\m09il6k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\m09i\\m09il7k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\m09i\\m09il8k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\m09i\\m09ild65_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\m09i\\m09im3k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\m09i\\m09im4k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\m09i\\m09im5k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\m09i\\m09im6k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\m09i\\m09im7k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\m09i\\m09im8k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\m09i\\m09imd65_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\m10i\\m10ih3k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\m10i\\m10ih4k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\m10i\\m10ih5k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\m10i\\m10ih6k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\m10i\\m10ih7k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\m10i\\m10ih8k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\m10i\\m10ihd65_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\m10i\\m10il3k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\m10i\\m10il4k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\m10i\\m10il5k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\m10i\\m10il6k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\m10i\\m10il7k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\m10i\\m10il8k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\m10i\\m10ild65_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\m10i\\m10im3k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\m10i\\m10im4k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\m10i\\m10im5k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\m10i\\m10im6k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\m10i\\m10im7k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\m10i\\m10im8k_01.jpg'; ...
    'D:\\work\\secondYearMaster\\thesis\\reference\\appeal\\algorithms\\preference_evaluate\\deepskin\\data\\toMax\\rendered_2max\\m10i\\m10imd65_01.jpg'; ...
};

fprintf('总共需要处理 %d 张图片\\n', length(image_paths));

%% 创建结果目录
result_dir = fullfile(fileparts(mfilename('fullpath')), 'face_detection_results');
if ~exist(result_dir, 'dir')
    mkdir(result_dir);
end

%% 初始化结果记录
results = cell(length(image_paths), 1);
detection_stats.default_detected = 0;
detection_stats.lbp_detected = 0;
detection_stats.cart_detected = 0;

%% 处理每张图片
for idx = 1:length(image_paths)
    img_path = image_paths{idx};
    fprintf('\n[%d/%d] 处理: %s\n', idx, length(image_paths), img_path);
    
    try
        % 保存当前图片路径到临时变量，供test_face_detection使用
        current_img_path = img_path;
        
        % 运行test_face_detection脚本
        run_test_face_detection(img_path, result_dir);
        
        % 记录成功处理
        results{idx} = struct('img_path', img_path, 'status', 'success');
        
        % 这里可以添加更多的结果记录逻辑
        % 注意：test_face_detection.m 会在图片所在目录生成结果图
        % 我们需要将结果图移动到统一的结果目录
        
    catch ME
        fprintf('  错误: %s\n', ME.message);
        results{idx} = struct('img_path', img_path, 'status', 'error', 'message', ME.message);
    end
end

%% 保存汇总结果
summary_file = fullfile(result_dir, 'batch_processing_summary.mat');
save(summary_file, 'results', 'detection_stats');

% 生成报告
report_file = fullfile(result_dir, 'batch_processing_report.txt');
fid = fopen(report_file, 'w');
fprintf(fid, '批量人脸检测结果报告\n');
fprintf(fid, '生成时间: %s\n', datestr(now));
fprintf(fid, '图片总数: %d\n', length(image_paths));

% 统计成功和失败的图片
success_count = sum(cellfun(@(x) strcmp(x.status, 'success'), results));
error_count = sum(cellfun(@(x) strcmp(x.status, 'error'), results));

fprintf(fid, '成功处理: %d\n', success_count);
fprintf(fid, '处理失败: %d\n', error_count);
fprintf(fid, '\n图片列表:\n');

for i = 1:length(results)
    r = results{i};
    if strcmp(r.status, 'success')
        fprintf(fid, '%d. [成功] %s\n', i, r.img_path);
    else
        fprintf(fid, '%d. [失败] %s - %s\n', i, r.img_path, r.message);
    end
end

fclose(fid);

fprintf('\n批量处理完成！\n');
fprintf('结果保存在: %s\n', result_dir);
fprintf('汇总文件: %s\n', summary_file);
fprintf('报告文件: %s\n', report_file);

%% 辅助函数：运行test_face_detection.m并保存结果到指定目录
function run_test_face_detection(img_path, result_dir)
    % 读取图片
    if ~exist(img_path, 'file')
        error('图片不存在: %s', img_path);
    end
    
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
        fprintf('  [Cascade] 检测到 %d 个人脸\n', size(bboxes1,1));
    else
        fprintf('  [Cascade] 未检测到人脸\n');
    end
    
    if ~isempty(bboxes2)
        for i = 1:size(bboxes2,1)
            rectangle('Position', bboxes2(i,:), 'EdgeColor', 'g', 'LineWidth', 2);
        end
        fprintf('  [LBP] 检测到 %d 个人脸\n', size(bboxes2,1));
    else
        fprintf('  [LBP] 未检测到人脸\n');
    end
    
    if ~isempty(bboxes3)
        for i = 1:size(bboxes3,1)
            rectangle('Position', bboxes3(i,:), 'EdgeColor', 'b', 'LineWidth', 2);
        end
        fprintf('  [CART] 检测到 %d 个人脸\n', size(bboxes3,1));
    else
        fprintf('  [CART] 未检测到人脸\n');
    end
    
    % 添加图例
    legend({'Cascade (Default)', 'LBP', 'CART'}, 'Location', 'bestoutside');
    
    % 提取文件名信息
    [path_str, name, ext] = fileparts(img_path);
    
    % 保存结果图到统一结果目录
    out_filename = [name '_detection_test.jpg'];
    out_path = fullfile(result_dir, out_filename);
    imwrite(getframe(fig).cdata, out_path);
    
    close(fig);
    
    fprintf('  结果图已保存: %s\n', out_path);
    
    % 保存检测数据到MAT文件
    result_data_file = fullfile(result_dir, [name '_detection_data.mat']);
    result_data.img_path = img_path;
    result_data.img_size = [w, h];
    result_data.bboxes_default = bboxes1;
    result_data.bboxes_lbp = bboxes2;
    result_data.bboxes_cart = bboxes3;
    result_data.detected_default = ~isempty(bboxes1);
    result_data.detected_lbp = ~isempty(bboxes2);
    result_data.detected_cart = ~isempty(bboxes3);
    result_data.num_faces_default = size(bboxes1, 1);
    result_data.num_faces_lbp = size(bboxes2, 1);
    result_data.num_faces_cart = size(bboxes3, 1);
    
    save(result_data_file, 'result_data');
    fprintf('  检测数据已保存: %s\n', result_data_file);
end