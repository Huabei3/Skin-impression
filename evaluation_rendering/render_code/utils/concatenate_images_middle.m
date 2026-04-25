function concatenate_images_middle(save_folder,n_col)
    % 读取输入目录中的所有JPG和PNG图片文件
    image_files=dir(fullfile(save_folder,"*.jpg"));
    image_files=[image_files;dir(fullfile(save_folder,"*.png"))];
    if isempty(image_files)
        error('No JPG/PNG images found in the specified directory.');
    end
    lastParts=["实验室","室内","夜景","室外","黄昏"];
    
    % 读取第一张图片并获取其基准高度
    first_image = imread(fullfile(save_folder, image_files(1).name));
    [first_rows, first_cols, channels] = size(first_image);
    
    % 将所有图片的高度调整为与第一张图片相同，保持宽高比
    num_images = length(image_files);
    resized_images = cell(1, num_images);
    img_heights = zeros(1, num_images); % 存储每张图片调整后的高度（实际都是first_rows，备用）
    img_widths = zeros(1, num_images);  % 存储每张图片调整后的宽度
    for i = 1:num_images
        img = imread(fullfile(save_folder, image_files(i).name));
        [rows, cols, ~] = size(img);
        scale_factor = first_rows / rows; % 计算高度缩放比例
        new_cols = round(cols * scale_factor); % 等比例缩放宽度
        resized_images{i} = imresize(img, [first_rows, new_cols]);
        img_heights(i) = first_rows;       % 记录高度
        img_widths(i) = new_cols;          % 记录宽度
    end
    
    % 设置文本的颜色和位置
    text_color_number = [0, 0, 0]; 
    
    % 在每张图片上添加文本并保存带文本的图片
    [rows, cols, ~] = size(resized_images{1});
    font_size_number1 = round(cols / 10);
        
    for i = 1:num_images
        img = resized_images{i};
        [rows, cols, ~] = size(img);
        
        % 动态计算字体大小，大约为图片宽度的1/20
        font_size_number = min(font_size_number1, round(rows / 15));
        
        % 动态计算文本位置，确保文本在图片内部且居于左上角
        text_position_number = [cols - font_size_number*2.5, font_size_number*4];
        
        % 在图片上插入编号
        font_size_number=min(font_size_number,200);
        letter_label=lastParts(i);
        img_with_text = insertText(img, text_position_number, letter_label, ...
            'FontSize', font_size_number, 'TextColor', text_color_number, 'BoxOpacity', 0);
        resized_images{i} = img_with_text;
    end
    
    % ========== 核心修改：重新计算拼接尺寸和位置（支持垂直居中） ==========
    % 1. 分组：按n_col列分组，确定每行包含的图片
    n = n_col; % 每行放置的图片数量
    num_rows = ceil(num_images / n); % 总行数
    row_img_indices = cell(num_rows, 1); % 存储每行的图片索引
    row_max_height = zeros(num_rows, 1); % 每行的最大高度（当前都是first_rows）
    row_total_width = zeros(num_rows, 1); % 每行的总宽度
    
    % 初始化每行的图片索引和尺寸
    for r = 1:num_rows
        start_idx = (r-1)*n + 1;
        end_idx = min(r*n, num_images);
        row_img_indices{r} = start_idx:end_idx;
        row_max_height(r) = first_rows; % 所有图片高度已统一为first_rows
        row_total_width(r) = sum(img_widths(row_img_indices{r}));
    end
    
    % 2. 计算拼接画布的总尺寸
    total_height = sum(row_max_height); % 总行高 = 各行最大高度之和
    max_row_width = max(row_total_width); % 最大行宽（画布宽度）
    
    % 3. 创建空白拼接图像（白色背景）
    concatenated_image = 255 * ones(total_height, max_row_width, channels, 'uint8');
    
    % 4. 逐行拼接图片，实现垂直居中
    current_start_row = 1; % 当前行的起始行位置
    for r = 1:num_rows
        img_indices = row_img_indices{r}; % 当前行的图片索引
        current_row_height = row_max_height(r); % 当前行的最大高度
        current_start_col = 1; % 当前行的起始列位置
        
        % 遍历当前行的每张图片
        for idx = img_indices
            img = resized_images{idx};
            [img_h, img_w, ~] = size(img);
            
            % 计算垂直居中的偏移量（当前所有图片高度相同，偏移量为0，保留逻辑适配不同高度场景）
            vertical_offset = floor((current_row_height - img_h) / 2);
            actual_img_start_row = current_start_row + vertical_offset;
            actual_img_end_row = actual_img_start_row + img_h - 1;
            
            % 计算水平位置
            actual_img_start_col = current_start_col;
            actual_img_end_col = actual_img_start_col + img_w - 1;
            
            % 将图片写入画布（垂直居中）
            concatenated_image(actual_img_start_row:actual_img_end_row, ...
                actual_img_start_col:actual_img_end_col, :) = img;
            
            % 更新当前行的列位置
            current_start_col = current_start_col + img_w;
        end
        
        % 更新下一行的起始行位置
        current_start_row = current_start_row + current_row_height;
    end
    
    % 保存拼接后的图像
    output_folder = fullfile(save_folder, 'concatenated');
    if ~exist(output_folder, 'dir')
        mkdir(output_folder);
    end
    output_file = fullfile(output_folder, strcat('bigImg.jpg'));
    imwrite(concatenated_image, output_file);
    
    fprintf('Concatenated image saved to %s\n', output_file);
end

%% 调用示例（保持和你原调用方式一致）
% concatenate_images_middle("D:\work\VIVOskinExpe\skin_model\evaluation_rendering\render_code\compare\res\pic\on_Peggy_OPPO\concatenated\picked",1)