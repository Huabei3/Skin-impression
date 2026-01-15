function merge_images(source_folder, add_labels)
    % 定义路径
    merged_folder = fullfile(source_folder,'combined');
    
    % 确保merged文件夹存在
    if ~exist(merged_folder, 'dir')
        mkdir(merged_folder);
    end
    
    % 读取第一张图片
    dir_img=dir(fullfile(source_folder,"*.jpg"));
    img1_path = fullfile(dir_img(1).folder,dir_img(1).name);
    img2_path = fullfile(dir_img(2).folder,dir_img(2).name);
    
    if ~exist(img1_path, 'file') || ~exist(img2_path, 'file')
        error('请在source文件夹中放置1.jpg和2.jpg两张图片');
    end
    
    % 读取图片
    img1 = imread(img1_path);
    img2 = imread(img2_path);
    img2=imresize(img2,[size(img2,1)*3, size(img2,2)*3]);
    
    % 获取图片尺寸
    [h1, w1, c1] = size(img1);
    [h2, w2, c2] = size(img2);
    
    % 确保两张图片的通道数一致
    if c1 ~= c2
        if c1 == 3 && c2 == 1
            % 如果是灰度图转RGB
            img2 = repmat(img2, [1, 1, 3]);
        elseif c1 == 1 && c2 == 3
            % 如果是灰度图转RGB
            img1 = repmat(img1, [1, 1, 3]);
        elseif c1 == 3 && c2 == 4
            % 如果有alpha通道，去除alpha通道
            img2 = img2(:, :, 1:3);
        elseif c1 == 4 && c2 == 3
            % 如果有alpha通道，去除alpha通道
            img1 = img1(:, :, 1:3);
        end
    end
    
    % 获取最终通道数
    if size(img1, 3) == 1
        channels = 1;
    else
        channels = 3;
    end
    
    % 处理第二张图片的宽度
    if w2 > w1
        % 第二张图片比第一张宽，等比例缩小到第一张的宽度
        scale_factor = w1 / w2;
        new_w2 = w1;
        new_h2 = round(h2 * scale_factor);
        
        % 使用imresize调整大小
        img2_resized = imresize(img2, [new_h2, new_w2]);
        final_w2 = new_w2;
        final_h2 = new_h2;
    else
        % 第二张图片不宽于第一张，不需要缩小
        img2_resized = img2;
        final_w2 = w2;
        final_h2 = h2;
    end
    
    % 计算需要填充的左右边距（用于居中）
    if final_w2 < w1
        left_pad = floor((w1 - final_w2) / 2);
        right_pad = w1 - final_w2 - left_pad;
        
        % 创建白色背景
        if channels == 1
            % 灰度图
            white_bg = 255 * ones(final_h2, left_pad, 'like', img2_resized);
            white_bg_right = 255 * ones(final_h2, right_pad, 'like', img2_resized);
        else
            % RGB图
            white_bg = 255 * ones(final_h2, left_pad, channels, 'like', img2_resized);
            white_bg_right = 255 * ones(final_h2, right_pad, channels, 'like', img2_resized);
        end
        
        % 水平拼接：白边 + 图片 + 白边
        img2_padded = [white_bg, img2_resized, white_bg_right];
    else
        % 不需要填充
        img2_padded = img2_resized;
    end
    
    % 确保两张图片宽度一致
    [~, padded_w2, ~] = size(img2_padded);
    if padded_w2 ~= w1
        % 如果还有宽度不一致的情况，调整img2_padded的宽度
        if padded_w2 < w1
            left_pad = floor((w1 - padded_w2) / 2);
            right_pad = w1 - padded_w2 - left_pad;
            
            if channels == 1
                white_bg = 255 * ones(final_h2, left_pad, 'like', img2_padded);
                white_bg_right = 255 * ones(final_h2, right_pad, 'like', img2_padded);
            else
                white_bg = 255 * ones(final_h2, left_pad, channels, 'like', img2_padded);
                white_bg_right = 255 * ones(final_h2, right_pad, channels, 'like', img2_padded);
            end
            
            img2_padded = [white_bg, img2_padded, white_bg_right];
        else
            % 如果填充后宽度超过第一张图，最后再resize一次
            img2_padded = imresize(img2_padded, [final_h2, w1]);
        end
    end
    
    % 如果需要添加标签
    if add_labels
        % 设置文本的颜色和位置
        text_color_number = [0, 0, 0];  % 黑色文本
        
        % 在第一张图片上添加标签 (a)
        [h1, w1, ~] = size(img1);
        font_size_number1 = round(w1 / 50);
        font_size_number = min(font_size_number1, round(h1 / 5));
        font_size_number = min(font_size_number, 200);
        text_position_number = [w1 - font_size_number*2, h1 - font_size_number*1.5];
        
        letter_label1 = '(a)';
        img1_with_text = insertText(img1, text_position_number, letter_label1, ...
            'FontSize', font_size_number, 'TextColor', text_color_number, 'BoxOpacity', 0);
        img1 = img1_with_text;
        
        % 在第二张图片上添加标签 (b)
        [h2_padded, w2_padded, ~] = size(img2_padded);
        font_size_number2 = round(w2_padded / 50);
        font_size_number = min(font_size_number2, round(h2_padded / 5));
        font_size_number = min(font_size_number, 200);
        text_position_number = [w2_padded - font_size_number*2, h2_padded - font_size_number*1.5];
        
        letter_label2 = '(b)';
        img2_padded_with_text = insertText(img2_padded, text_position_number, letter_label2, ...
            'FontSize', font_size_number, 'TextColor', text_color_number, 'BoxOpacity', 0);
        img2_padded = img2_padded_with_text;
    end
    
    % 垂直拼接两张图片
    merged_img = [img1; img2_padded];
    
    % 保存结果
    output_path = fullfile(merged_folder, 'merged_result.jpg');
    imwrite(merged_img, output_path);
    
    % 显示结果
    figure('Name', '合并结果', 'NumberTitle', 'off');
    imshow(merged_img);
    
    fprintf('图片合并完成！\n');
    fprintf('原图1尺寸: %d × %d\n', h1, w1);
    fprintf('原图2尺寸: %d × %d\n', h2, w2);
    fprintf('合并后尺寸: %d × %d\n', size(merged_img, 1), size(merged_img, 2));
    fprintf('结果已保存至: %s\n', output_path);
end

%%
source_folder="D:\work\project_code_backup\OPPOskinExpe\analyzeResult_scaled\AnalyseResults_p\display\rela\efit_p\gender\ellipsoid_sections\concatenated";
% merge_images(source_folder, true);  % true表示添加标签，(a)和(b)
merge_images(source_folder, false); % false表示不添加标签