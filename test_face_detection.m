function test_face_detection(varargin)
%% TEST_FACE_DETECTION
% 测试 MATLAB 人脸检测效果，在图片上框出检测区域
% 用法1：直接运行，使用默认图片路径
% 用法2：test_face_detection(img_path) - 传入图片路径
% 用法3：test_face_detection(img_path, output_dir) - 传入图片路径和输出目录

% 检查输入参数
if nargin < 1
    % 如果没有输入参数，使用默认图片
    % imgPath = fullfile('D:','work','secondYearMaster','thesis','reference',...
    %     'appeal','algorithms','preference_evaluate','deepskin','data','toMax',...
    %     'rendered_face','f10i','f10il4k_01_face.jpg');
    imgPath = fullfile(['D:\work\secondYearMaster\thesis\reference\' ...
        'appeal\algorithms\preference_evaluate\deepskin\data\toMax\' ...
        'rendered_2max\f01r\f01rrs01_01.jpg']);
    % 也支持检测原始大图
    % imgPath = fullfile('D:','work','secondYearMaster','thesis','reference',...
    %     'appeal','datasets','toMax','f01i','drawable','f01ih3k_01.jpg');
else
    imgPath = varargin{1};
end

if nargin < 2
    % 如果没有指定输出目录，使用图片所在目录
    [output_dir, ~, ~] = fileparts(imgPath);
else
    output_dir = varargin{2};
end

if ~exist(imgPath, 'file')
    error('图片不存在: %s', imgPath);
end

img = imread(imgPath);
figure('Name','Face Detection Test','NumberTitle','off');
imshow(img); hold on;
title('Original Image');

%% 1) vision.CascadeObjectDetector (默认)
faceMinSize = [80 80];
faceDetector = vision.CascadeObjectDetector();
faceDetector.MinSize = faceMinSize;
bboxes1 = faceDetector(img);

if ~isempty(bboxes1)
    for i = 1:size(bboxes1,1)
        rectangle('Position', bboxes1(i,:), 'EdgeColor', 'r', 'LineWidth', 2);
    end
    fprintf('[Cascade] 检测到 %d 个人脸\n', size(bboxes1,1));
else
    fprintf('[Cascade] 未检测到人脸\n');
end

%% 2) vision.CascadeObjectDetector (FrontalFaceLBP)
faceDetectorLBP = vision.CascadeObjectDetector('FrontalFaceLBP');
faceDetectorLBP.MinSize = faceMinSize;
bboxes2 = faceDetectorLBP(img);

if ~isempty(bboxes2)
    for i = 1:size(bboxes2,1)
        rectangle('Position', bboxes2(i,:), 'EdgeColor', 'g', 'LineWidth', 2);
    end
    fprintf('[LBP] 检测到 %d 个人脸\n', size(bboxes2,1));
else
    fprintf('[LBP] 未检测到人脸\n');
end

%% 3) vision.CascadeObjectDetector (FrontalFaceCART)
faceDetectorCART = vision.CascadeObjectDetector('FrontalFaceCART');
faceDetectorCART.MinSize = faceMinSize;
bboxes3 = faceDetectorCART(img);

if ~isempty(bboxes3)
    for i = 1:size(bboxes3,1)
        rectangle('Position', bboxes3(i,:), 'EdgeColor', 'b', 'LineWidth', 2);
    end
    fprintf('[CART] 检测到 %d 个人脸\n', size(bboxes3,1));
else
    fprintf('[CART] 未检测到人脸\n');
end

legend({'Cascade (Default)', 'LBP', 'CART'}, 'Location', 'bestoutside');

%% 4) 打印各 bbox 尺寸与图片比例
[h, w, ~] = size(img);
fprintf('\n图片尺寸: %d x %d\n', w, h);
if ~isempty(bboxes1)
    fprintf('Default bbox:  x=%d y=%d w=%d h=%d  (面积占比 %.1f%%)\n', ...
        bboxes1(1,1), bboxes1(1,2), bboxes1(1,3), bboxes1(1,4), ...
        100 * bboxes1(1,3) * bboxes1(1,4) / (w*h));
end
if ~isempty(bboxes2)
    fprintf('LBP    bbox:  x=%d y=%d w=%d h=%d  (面积占比 %.1f%%)\n', ...
        bboxes2(1,1), bboxes2(1,2), bboxes2(1,3), bboxes2(1,4), ...
        100 * bboxes2(1,3) * bboxes2(1,4) / (w*h));
end
if ~isempty(bboxes3)
    fprintf('CART   bbox:  x=%d y=%d w=%d h=%d  (面积占比 %.1f%%)\n', ...
        bboxes3(1,1), bboxes3(1,2), bboxes3(1,3), bboxes3(1,4), ...
        100 * bboxes3(1,3) * bboxes3(1,4) / (w*h));
end

%% 5) 保存结果图
[~, name, ~] = fileparts(imgPath);
outPath = fullfile(output_dir, [name '_detection_test.jpg']);
imwrite(getframe(gcf).cdata, outPath);
fprintf('\n结果图已保存: %s\n', outPath);

% 保存检测数据到MAT文件
result_data.img_path = imgPath;
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

data_file = fullfile(output_dir, [name '_detection_data.mat']);
save(data_file, 'result_data');
fprintf('检测数据已保存: %s\n', data_file);

% 返回检测结果
if nargout > 0
    varargout{1} = result_data;
end

end
