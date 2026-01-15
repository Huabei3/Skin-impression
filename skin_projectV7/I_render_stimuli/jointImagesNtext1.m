clear; close all;

% 设置输入目录和输出目录
save_folder="D:\work\VIVOskinExpe\analyze\AnalyseResults\summer\f01i\non_model\01Preference\pre_draw";
% save_folder=['Z:\homes\Peggy\oppoSkinExperi\ExperimentResult\analyseFile\' ...
%     'all_delete\D65\sunsetAdd\ellipsoid_sections_NoL49\a_b'];
% save_folder = 'Z:\homes\Peggy\oppoSkinExperi\ExperimentResult\analyseFile\PlotCenSection1_2\sunset';
input_folder = fullfile(save_folder); % 替换为实际的输入目录路径
output_folder = fullfile(save_folder, 'big1'); % 替换为实际的输出目录路径
% output_folder = fullfile(save_folder, 'long_downsampled'); % 替换为实际的输出目录路径
disp("begin")
% num_points = readmatrix('Z:\homes\Peggy\oppoSkinExperi\points48.xlsx'); 
% num_center = num_points(53,:); 
% num_points(50:53,:)=[];
% dlabs=num_points-repmat(num_center,49,1);

if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

n = 7; % 每行放置的图片数量

% 读取输入目录中的所有JPG图片文件
image_files = dir(fullfile(input_folder, '*.jpg'));
% image_files = dir(fullfile(input_folder, 'sunset03*.jpg'));

if isempty(image_files)
    error('No JPG images found in the specified directory.');
end

% 读取第一张图片并获取其大小
first_image = imread(fullfile(input_folder, image_files(1).name));
[first_rows, first_cols, channels] = size(first_image);
%若图片过大，进行压缩
if first_rows>1400
    first_rows=first_rows./10;
end
% 将所有图片的高度调整为与第一张图片相同，保持宽高比
num_images = length(image_files);
resized_images = cell(1, num_images);
for i = 1:num_images
    img = imread(fullfile(input_folder, image_files(i).name));

    slashe1 = find(image_files(i).name=='[');
    slashe2 = find(image_files(i).name==',');
    slashe3 = find(image_files(i).name==']');    
    % dlabs(i,1) = str2double(image_files(i).name(slashe1+1:slashe2(1)-1));
    % dlabs(i,2) = str2double(image_files(i).name(slashe2(1)+1:slashe2(2)-1));
    % dlabs(i,3) = str2double(image_files(i).name(slashe2(2)+1:slashe3-1));

    [rows, cols, ~] = size(img);
    scale_factor = first_rows / rows; % 计算高度缩放比例
    new_cols = round(cols * scale_factor); % 等比例缩放宽度
    resized_images{i} = imresize(img, [first_rows, new_cols]);
end

% 设置文本的颜色和位置
text_color_number = [255, 0, 0]; % 橙色 (R, G, B) - 用于图像编号


% 在每张图片上添加文本并保存带文本的图片
for i = 1:num_images
    img = resized_images{i};
    [rows, cols, ~] = size(img);

    % 动态计算字体大小，大约为图片宽度的1/20
    font_size_number = round(cols / 10);
    font_size_labels = round(cols / 15);

    % 确保字体大小不超过图片尺寸
    font_size_number = min(font_size_number, round(rows / 5));
    font_size_labels = min(font_size_labels, round(rows / 5));

    % 动态计算文本位置，确保文本在图片内部且居于右下角
    text_position_number = [cols - font_size_number*2, rows - font_size_number*1.5];
    text_position_labels = [cols - font_size_labels*15, rows - font_size_labels*1.5];

    % 在图片上插入编号
    img_with_text = insertText(img, text_position_number, num2str(i), ...
        'FontSize', font_size_number, 'TextColor', text_color_number, 'BoxOpacity', 0);

    % % 在图片上插入其他文本
    % img_with_text = insertText(img_with_text, text_position_labels, ...
    %     strcat(sprintf("%.2f",dlabs(i,1)),',',sprintf("%.2f",dlabs(i,2)),',',sprintf("%.2f",dlabs(i,3))), ...
    %     'FontSize', font_size_labels, 'TextColor', text_color_number, 'BoxOpacity', 0);

    resized_images{i} = img_with_text;
end

% 计算拼接图像的总高度和宽度
total_height = 0;
row_widths = zeros(1, num_images);
max_row_width = 0;
current_row = 1;
for i = 1:num_images
    [rows, cols, ~] = size(resized_images{i});
    row_widths(current_row) = row_widths(current_row) + cols;
    if row_widths(current_row) > max_row_width
        max_row_width = row_widths(current_row);
    end
    if mod(i, n) == 0 || i == num_images
        total_height = total_height + rows;
        current_row = current_row + 1;
    end
end

% 创建一个空白的拼接图像
concatenated_image = zeros(total_height, max_row_width, channels, 'uint8');

% 将图片放入拼接图像中
start_row = 1;
current_row = 1;
current_col = 1;
for i = 1:num_images
    [rows, cols, ~] = size(resized_images{i});
    
    if current_col + cols - 1 > max_row_width
        start_row = start_row + first_rows; % 新行开始
        current_col = 1; % 重置列位置
    end
    
    start_col = current_col;
    concatenated_image(start_row:start_row+rows-1, start_col:start_col+cols-1, :) = resized_images{i};
    current_col = current_col + cols; % 更新列位置

    % 检查是否需要换行
    if mod(i, n) == 0
        start_row = start_row + rows; % 下一行
        current_col = 1; % 从新行开始
    end
end

% 保存拼接后的图像
imshow(concatenated_image);
output_file = fullfile(output_folder, strcat(image_files(1).name,'_bigImg.jpg'));
imwrite(concatenated_image, output_file);

fprintf('Concatenated image saved to %s\n', output_file);
