clear;
close all;
%% %按照01 02 03 04分组
% % 定义目标文件夹路径
% sourceFolder = 'D:\work\VIVOskinExpe\renderCode\rendered\33_i_wei\non_model\90\summer\toVIVO1'; % 替换为你的文件夹路径
% 
% % 获取文件夹中所有的 .jpg 文件
% filePattern = fullfile(sourceFolder, '*.jpg');
% files = dir(filePattern);
% 
% % 遍历每个文件
% for k = 1:length(files)
%     fileName = files(k).name; % 获取文件名
%     filePath = files(k).folder; % 获取文件路径
%     fullPath = fullfile(filePath, fileName); % 获取完整路径
% 
% 
%     slash=find(fileName=='[');
%     serial = fileName(slash-2:slash-1);
% 
%     % 创建目标文件夹路径
%     newFolderPath = fullfile(sourceFolder, serial);
% 
%     % 检查目标文件夹是否存在，如果不存在则创建
%     if ~exist(newFolderPath, 'dir')
%         mkdir(newFolderPath);
%     end
% 
%     % 移动文件到目标文件夹
%     copyfile(fullPath, newFolderPath);
% end
% 
% disp('文件移动完成！');
%%
% 设置输入目录和输出目录

save_folder = "rendered\33_i_wei\non_model\90\summer\toVIVO1\04";
input_folder = fullfile(save_folder); % 替换为实际的输入目录路径
output_folder = fullfile(save_folder, 'big1'); % 替换为实际的输出目录路径

if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end
n = 10; % 每行放置的图片数量

% 读取输入目录中的所有JPG图片文件
image_files = dir(fullfile(input_folder, '*.jpg'));

if isempty(image_files)
    error('No JPG images found in the specified directory.');
end

% 提取文件名前缀并分组
prefix_groups = containers.Map();
for i = 1:length(image_files)
    [~, name, ~] = fileparts(image_files(i).name);
    % prefix=image_files(i).name(1:5);
    underscore_pos = find(name == '_', 1);
    if isempty(underscore_pos)
        prefix = name;
    else
        prefix = name(1:underscore_pos-1);
    end

    if ~isKey(prefix_groups, prefix)
        prefix_groups(prefix) = {};
    end
    prefix_groups(prefix) = [prefix_groups(prefix), image_files(i)];
end

% 对每个前缀分组进行拼接
for prefix = keys(prefix_groups)
    prefix = prefix{1}; % 获取前缀字符串
    group_files = prefix_groups(prefix);

    % 读取第一张图片并获取其大小
    first_image = imread(fullfile(input_folder, group_files{1}.name));
    [first_rows, first_cols, channels] = size(first_image);
    if first_rows>=1000
        first_rows=first_rows./10;
    elseif first_rows>=500
        first_rows=first_rows./5;
    end

    % 将所有图片的高度调整为与第一张图片相同，保持宽高比
    num_images = length(group_files);
    resized_images = cell(1, num_images);
    for i = 1:num_images
        img = imread(fullfile(input_folder, group_files{i}.name));
        slashe0 = find(group_files{i}.name=='_');
        slashe1 = find(group_files{i}.name=='[');
        slashe2 = find(group_files{i}.name==',');
        slashe3 = find(group_files{i}.name==']');    
        dlabs(i,1) = str2double(group_files{i}.name(slashe1+1:slashe2(1)-1));
        dlabs(i,2) = str2double(group_files{i}.name(slashe2(1)+1:slashe2(2)-1));
        dlabs(i,3) = str2double(group_files{i}.name(slashe2(2)+1:slashe3-1));
        labels{i}=group_files{i}.name(slashe0+1:slashe1-1);
        labels{i}=gen_attribute_new(labels{i});

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
        font_size_number = round(cols / 15);
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
            % 在图片上插入其他文本
        % img_with_text = insertText(img_with_text, text_position_labels, ...
        % strcat(sprintf("%.2f",dlabs(i,1)),',',sprintf("%.2f",dlabs(i,2)),',',sprintf("%.2f",dlabs(i,3))), ...
        % 'FontSize', font_size_labels, 'TextColor', text_color_number, 'BoxOpacity', 0);
        img_with_text = insertText(img_with_text, text_position_labels, ...
        labels{i}, ...
        'FontSize', font_size_labels, 'TextColor', text_color_number, 'BoxOpacity', 0);
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

    % 在拼接图像的右下角添加 prefix 文本
    [total_rows, total_cols, ~] = size(concatenated_image);
    font_size_prefix = round(total_cols / 50); % 字体大小为拼接图像宽度的 1/20
    text_position_prefix = [total_cols - font_size_prefix*5, total_rows - font_size_prefix*7];
    concatenated_image = insertText(concatenated_image, text_position_prefix, prefix, ...
        'FontSize', font_size_prefix, 'TextColor', text_color_number, 'BoxOpacity', 0);

    % 保存拼接后的图像
    imshow(concatenated_image);
    sort_order = ["3K"; "4K"; "5K"; "6K";"D65"; "7K"; "8K"];
    [~,light]=ismember(prefix(6:end),sort_order);
    dest_folder=fullfile(output_folder,prefix(1:5));
    if ~exist(dest_folder,"dir")
        mkdir(dest_folder);
    end
    output_file = fullfile(dest_folder ,strcat(prefix(1:4), ...
        sprintf("%02d",light),prefix(5:end), '.jpg'));
    if strcmp(prefix(end-2:end),"D65")
        concatenate_images1(dest_folder,1);
    end
    imwrite(concatenated_image, output_file);


    fprintf('Concatenated image for prefix %s saved to %s\n', prefix, output_file);
end
%%
% 定义源文件夹路径
% source_folder = fullfile(save_folder,"big1");
% 
% % 定义排序顺序
% sort_order = ["3K", "4K", "5K", "6K", "D65", "7K", "8K"];
% 
% % 确保源文件夹存在
% if ~isfolder(source_folder)
%     error('指定的文件夹不存在：%s', source_folder);
% end
% 
% % 获取所有JPG图片
% image_files = dir(fullfile(source_folder, '*.jpg'));
% 
% if isempty(image_files)
%     error('No JPG images found in the specified directory.');
% end
% 
% % 按文件名前5个字符分组
% grouped_images = containers.Map('KeyType', 'char', 'ValueType', 'any');
% 
% for i = 1:length(image_files)
%     file_name = image_files(i).name;
%     group_key = file_name(1:5); % 文件名前5个字符作为分组键
%     if ~isKey(grouped_images, group_key)
%         grouped_images(group_key) = {file_name};
%     else
%         grouped_images(group_key) = [grouped_images(group_key), file_name];
%     end
% end
% 
% % 创建输出文件夹
% output_folder = fullfile(source_folder, 'concatenated');
% if ~exist(output_folder, 'dir')
%     mkdir(output_folder);
% end
% 
% % 遍历每个分组并拼接图片
% keys = keys(grouped_images);
% for k = 1:length(keys)
%     group_key = keys{k};
%     file_names = grouped_images(group_key);
% 
%     % 按文件名后2个字符排序
%     [~, sort_idx] = sort(arrayfun(@(x) find(ismember(sort_order, x(end-1:end))), file_names));
%     file_names = file_names(sort_idx);
% 
%     % 读取第一张图片并获取其大小
%     first_image = imread(fullfile(source_folder, file_names{1}));
%     [first_rows, first_cols, channels] = size(first_image);
% 
%     % 将所有图片的高度调整为与第一张图片相同，保持宽高比
%     num_images = length(file_names);
%     resized_images = cell(1, num_images);
%     for i = 1:num_images
%         img = imread(fullfile(source_folder, file_names{i}));
%         [rows, cols, ~] = size(img);
%         scale_factor = first_rows / rows; % 计算高度缩放比例
%         new_cols = round(cols * scale_factor); % 等比例缩放宽度
%         resized_images{i} = imresize(img, [first_rows, new_cols]);
%     end
% 
%     % 设置文本的颜色和位置
%     text_color_number = [255, 0, 0]; % 红色 (R, G, B) - 用于图像编号
% 
%     % 在每张图片上添加文本并保存带文本的图片
%     for i = 1:num_images
%         img = resized_images{i};
%         [rows, cols, ~] = size(img);
% 
%         % 动态计算字体大小，大约为图片宽度的1/20
%         font_size_number = round(cols / 20);
% 
%         % 确保字体大小不超过图片尺寸
%         font_size_number = min(font_size_number, round(rows / 5));
% 
%         % 动态计算文本位置，确保文本在图片内部且居于右下角
%         text_position_number = [cols - font_size_number*2, rows - font_size_number*1.5];
% 
%         % 在图片上插入编号
%         font_size_number = min(font_size_number, 200);
%         img_with_text = insertText(img, text_position_number, num2str(i), ...
%             'FontSize', font_size_number, 'TextColor', text_color_number, 'BoxOpacity', 0);
% 
%         resized_images{i} = img_with_text;
%     end
% 
%     % 计算拼接图像的总高度和宽度
%     n = 3; % 每行放置的图片数量
%     total_height = 0;
%     row_widths = zeros(1, num_images);
%     max_row_width = 0;
%     current_row = 1;
%     for i = 1:num_images
%         [rows, cols, ~] = size(resized_images{i});
%         row_widths(current_row) = row_widths(current_row) + cols;
%         if row_widths(current_row) > max_row_width
%             max_row_width = row_widths(current_row);
%         end
%         if mod(i, n) == 0 || i == num_images
%             total_height = total_height + rows;
%             current_row = current_row + 1;
%         end
%     end
% 
%     % 创建一个空白的拼接图像（白色背景）
%     concatenated_image = 255 * ones(total_height, max_row_width, channels, 'uint8'); % 白色背景
% 
%     % 将图片放入拼接图像中
%     start_row = 1;
%     current_row = 1;
%     current_col = 1;
%     for i = 1:num_images
%         [rows, cols, ~] = size(resized_images{i});
% 
%         if current_col + cols - 1 > max_row_width
%             start_row = start_row + first_rows; % 新行开始
%             current_col = 1; % 重置列位置
%         end
% 
%         start_col = current_col;
%         concatenated_image(start_row:start_row+rows-1, start_col:start_col+cols-1, :) = resized_images{i};
%         current_col = current_col + cols; % 更新列位置
% 
%         % 检查是否需要换行
%         if mod(i, n) == 0
%             start_row = start_row + rows; % 下一行
%             current_col = 1; % 从新行开始
%         end
%     end
% 
%     % 保存拼接后的图像
%     output_file = fullfile(output_folder, strcat(group_key, '_bigImg.jpg'));
%     imwrite(concatenated_image, output_file);
% 
%     fprintf('Concatenated image saved to %s\n', output_file);
% end