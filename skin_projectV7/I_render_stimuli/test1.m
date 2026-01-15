clc;clear;close all;
%%

%%
% 读入41x41x3图像
img = imread('Z:\homes\Peggy\oppoSkinExperi\picked40\iphone\cropped\findRdQst\Blued\Blued_1.jpg'); % 替换为你的图像路径
% img = imread('Z:\homes\Peggy\oppoSkinExperi\picked40\iphone\cropped\findRdQst\sRGB\sRGB_1.jpg'); % 替换为你的图像路径

% 检查图像尺寸是否为41x41x3
if size(img, 1) ~= 41 || size(img, 2) ~= 41 || size(img, 3) ~= 3
    error('图像尺寸必须为41x41x3');
end

% 将图像的RGB通道分别存储在单独的矩阵中
r_channel = img(:, :, 1);
g_channel = img(:, :, 2);
b_channel = img(:, :, 3);

% 创建一个cell数组存储三个通道
rgb_cells = cell(1, 3);
rgb_cells{1} = r_channel;
rgb_cells{2} = g_channel;
rgb_cells{3} = b_channel;

% 保存到.mat文件
save('rgb_channels.mat', 'rgb_cells');

%%
% % %crop坐标周围的区域
% % %读取mask
% imagePath = ['Z:\homes\Peggy\oppoSkinExperi\picked40\iphone\cropped\mask\' ...
%     'mask_cropped_indoor09_1.JPG'];
% % % 读取Ori
% % imagePath = ['Z:\homes\Peggy\oppoSkinExperi\picked40\iphone\cropped\rendered_new\' ...
% %     'cropped_indoor09_2[53.516,16.452,31.6112].JPG'];
% % % 读取sRGB
% % imagePath = ['Z:\homes\Peggy\oppoSkinExperi\picked40\iphone\cropped\rendered_new\' ...
% %     'cropped_indoor09_2[53.516,16.452,31.6112].JPG'];
% % 读取Blued
% % imagePath = ['Z:\homes\Peggy\oppoSkinExperi\picked40\iphone\cropped\rendered_LUTipv40_3_2\' ...
% %     'cropped_indoor09_02[53.516,16.452,31.6112].jpg']; % 替换为你的图片路径
% img = imread(imagePath);
% 
% % 点击位置和裁剪参数
% positions = [83, 144; 958, 316];
% cropSize = 20; % 上下20行，共41x41的裁剪区域
% 
% % 创建保存裁剪区域的文件夹
% outputFolder = 'Z:\homes\Peggy\oppoSkinExperi\picked40\iphone\cropped\findRdQst\mask';
% if ~exist(outputFolder, 'dir')
%     mkdir(outputFolder);
% end
% 
% % 循环处理每个点击位置
% for i = 1:size(positions, 1)
%     % 获取当前位置的坐标
%     x = positions(i, 1);
%     y = positions(i, 2);
%     
%     % 计算裁剪区域
%     xStart = max(x - cropSize, 1);
%     xEnd = min(x + cropSize, size(img, 2));
%     yStart = max(y - cropSize, 1);
%     yEnd = min(y + cropSize, size(img, 1));
%     
%     % 裁剪图片
%     croppedImg = img(yStart:yEnd, xStart:xEnd, :);
%     
%     % 保存裁剪后的图片
%     outputFileName = fullfile(outputFolder, sprintf('mask_%d.jpg', i));
%     imwrite(croppedImg, outputFileName);
% end
% 
% disp('所有裁剪区域已保存。');

%%
%点击获取RGB和坐标
% 读取指定图像
% image = imread("Z:\homes\Peggy\oppoSkinExperi\picked40\iphone\cropped\rendered_LUTipv40_3_2\" + ...
%     "cropped_indoor09_01[53.516,18.142,26.9112].jpg");
% 
% % 创建图像显示窗口
% hFig = figure;
% hIm = imshow(image, 'InitialMagnification', 'fit');
% title('点击图像以记录像素值，按回车键结束');
% axis on; % 显示坐标轴
% 
% % 开启放大、缩小和移动功能
% zoom on;
% pan on;
% 
% % 初始化存储点击位置和像素值的数组
% click_positions = [];
% pixel_values = [];
% 
% % 标志交互是否结束
% interaction_ended = false;
% 
% % 设置按键回调函数
% set(hFig, 'KeyPressFcn', @(src, event) key_press_callback(event, hIm));
% 
% % 开始交互
% while ~interaction_ended
%     [x, y, button] = ginput(1);
%     
%     if isempty(button) % 如果按回车键，button为空
%         interaction_ended = true;
%         break;
%     end
%     
%     % 确保点击位置在图像范围内
%     x = round(x);
%     y = round(y);
%     if x > 0 && x <= size(image, 2) && y > 0 && y <= size(image, 1)
%         % 记录点击位置和对应的像素值
%         click_positions = [click_positions; x, y];
%         pixel_values = [pixel_values; squeeze(image(y, x, :))'];
%         
%         % 在命令行窗口显示点击位置
%         disp(['点击位置: (', num2str(x), ', ', num2str(y), ')']);
%         disp(['像素值: R=', num2str(pixel_values(end, 1)), ...
%               ', G=', num2str(pixel_values(end, 2)), ...
%               ', B=', num2str(pixel_values(end, 3))]);
%         
%         % 在图像上标注点击位置
%         hold on;
%         plot(x, y, 'r+', 'MarkerSize', 10, 'LineWidth', 2);
%         hold off;
%     end
% end
% 
% % 将点击位置和像素值写入Excel文件
% output_filename = fullfile('Z:\homes\Peggy\oppoSkinExperi\picked40\iphone\cropped\rendered_LUTipv40_3_1\', 'click_positions_and_pixel_values.xlsx');
% data_table = array2table([click_positions, pixel_values], ...
%     'VariableNames', {'X', 'Y', 'R', 'G', 'B'});
% writetable(data_table, output_filename);
% 
% disp(['点击位置和像素值已保存到 ' output_filename]);
% 
% % 按键回调函数
% function key_press_callback(event, hIm)
%     persistent hZoom hPan
%     if isempty(hZoom)
%         hZoom = zoom(hIm.Parent);
%     end
%     if isempty(hPan)
%         hPan = pan(hIm.Parent);
%     end
% 
%     switch event.Key
%         case 'return'
%             assignin('base', 'interaction_ended', true); % 设置交互结束标志
%         case 'z'
%             if ismember('control', event.Modifier)
%                 undo_last_point();
%             end
%         case 'f'
%             if ismember('control', event.Modifier)
%                 hZoom.Direction = 'in';
%                 hZoom.Enable = 'on';
%                 hZoom.Motion = 'both';
%                 zoom(hIm.Parent, 2); % 放大
%             end
%         case 'hyphen'
%             if ismember('control', event.Modifier)
%                 hZoom.Direction = 'out';
%                 hZoom.Enable = 'on';
%                 hZoom.Motion = 'both';
%                 zoom(hIm.Parent, 0.5); % 缩小
%             end
%     end
% end
% 
% % 撤销最后一个点的函数
% function undo_last_point()
%     click_positions = evalin('base', 'click_positions');
%     pixel_values = evalin('base', 'pixel_values');
%     
%     if ~isempty(click_positions)
%         % 移除最后一个点
%         click_positions(end, :) = [];
%         pixel_values(end, :) = [];
%         
%         % 更新工作区变量
%         assignin('base', 'click_positions', click_positions);
%         assignin('base', 'pixel_values', pixel_values);
%         
%         % 重新绘制图像和标注点
%         hIm = findobj(gca, 'Type', 'image');
%         imshow(hIm.CData, 'InitialMagnification', 'fit');
%         hold on;
%         for i = 1:size(click_positions, 1)
%             plot(click_positions(i, 1), click_positions(i, 2), 'r.', 'MarkerSize',3, 'LineWidth', 2);
%         end
%         hold off;
%         
%         disp('撤销上一个点');
%     end
% end

%%
%
% % 读取图像
% image = imread("Z:\homes\Peggy\oppoSkinExperi\picked40\iphone\cropped\rendered_LUTipv40_3_1\" + ...
%     "cropped_indoor01_1[51.9,10.6105,10.2775].jpg");
% dir_mask = dir("Z:\homes\Peggy\oppoSkinExperi\picked40\iphone\cropped\mask\*.jpg");
% i = 19;
% bull = imread(strcat(dir_mask(i).folder, '\', dir_mask(i).name));
% bull=bull(:,:,1);
% threshold = 20;
% [rows, cols, ~] = size(image);
% 
% % 确定 bull == 1 的像素位置
% [bull_rows, bull_cols] = find(bull == 0);
% 
% % 初始化差别过大的点的坐标
% diff_points = [];
% 
% % 遍历 bull == 1 的所有像素
% for j = 1:length(bull_rows)
%     r = bull_rows(j);
%     c = bull_cols(j);
% 
%     % 获取当前像素的颜色
%     current_color = double(image(r, c, :));
% 
%     % 获取周围8个像素的颜色
%     neighbors = [];
%     for dr = -1:1
%         for dc = -1:1
%             if dr == 0 && dc == 0
%                 continue;
%             end
%             rr = r + dr;
%             cc = c + dc;
%             if rr > 0 && rr <= rows && cc > 0 && cc <= cols
%                 neighbors = [neighbors; double(image(rr, cc, :))];
%             end
%         end
%     end
% 
%     % 计算当前像素与周围像素的颜色差异
%     if ~isempty(neighbors)
%         mean_neighbors = mean(neighbors, 1);
%         color_diff = abs(current_color - mean_neighbors);
% 
%         % 如果任一通道的颜色差异超过阈值，则记录坐标
%         if any(color_diff > threshold)
%             diff_points = [diff_points; r, c];
%         end
%     end
% end
% 
% % 显示图像
% imshow(image);
% hold on;
% 
% % 在图像上标注颜色差异过大的点
% for j = 1:size(diff_points, 1)
%     r = diff_points(j, 1);
%     c = diff_points(j, 2);
%     plot(c, r, 'r.', 'MarkerSize', 10); % 使用红色点标记
% end
% 
% hold off;
%%
% indices1 = (bull(:,:,1) == 1);
% indices2 = (bull(:,:,2) == 1);
% indices3 = (bull(:,:,3) == 1);
% are_equal_1_2 = isequal(indices2, indices1);
%%
%
% % 清理环境
% clear all;
% close all;
% 
% % 读取图像
% img = imread(['Z:\homes\Peggy\oppoSkinExperi\picked40\iphone\cropped\rendered_LUTipv40_3\', ...
%     'cropped_indoor01_44[59.92,7.0305,17.6075].jpg']); % 替换为你的图像文件名
% if size(img, 3) == 3
%     img = rgb2gray(img); % 如果是彩色图像，转换为灰度图像
% end
% 
% % 显示原始图像
% figure;
% imshow(img);
% title('原始图像');
% 
% % 使用较大的中值滤波器去除较大的噪声
% filtered_img1 = medfilt2(img, [5, 5]);
% figure;
% imshow(filtered_img1);
% % imwrite(filtered_img1,['Z:\homes\Peggy\oppoSkinExperi\picked40\iphone\cropped\rendered_LUTipv40_3\', ...
% %     'cropped_indoor01_44[59.92,7.0305,17.6075]_2.jpg']);
% % 使用双边滤波进一步平滑图像
% filtered_img2 = imbilatfilt(filtered_img1, 15, 30);
% % imwrite(filtered_img2,['Z:\homes\Peggy\oppoSkinExperi\picked40\iphone\cropped\rendered_LUTipv40_3\', ...
% %     'cropped_indoor01_44[59.92,7.0305,17.6075]_3.jpg']);
% % 显示去噪后的图像
% figure;
% imshow(filtered_img2);
% title('去除较大噪声后的图像');

%%
%中值滤波
% clear;
% % 读取彩色图像
% img_color = imread(['Z:\homes\Peggy\oppoSkinExperi\picked40\iphone\cropped\rendered_LUTipv40_3\' ...
%     'cropped_indoor01_44[59.92,7.0305,17.6075].jpg']); % 替换为你的彩色图像文件名
% 
% % 分别对 R, G, B 通道应用中值滤波
% r_channel = medfilt2(img_color(:, :, 1), [3, 3]);
% g_channel = medfilt2(img_color(:, :, 2), [3, 3]);
% b_channel = medfilt2(img_color(:, :, 3), [3, 3]);
% 
% % 合并处理后的通道
% filtered_img_color = cat(3, r_channel, g_channel, b_channel);
% imwrite(filtered_img_color,['Z:\homes\Peggy\oppoSkinExperi\picked40\iphone\cropped\rendered_LUTipv40_3\', ...
%     'cropped_indoor01_44[59.92,7.0305,17.6075]_1.jpg']);
% % 显示原始彩色图像
% figure;
% imshow(img_color);
% title('原始彩色图像');
% 
% % 显示去噪后的彩色图像
% figure;
% imshow(filtered_img_color);
% title('去除胡椒噪声后的彩色图像');
%%
% %一位数字变两位
% % Specify the directory containing the JPEG files
% folderPath = 'D:\oppoSkinExperi\picked40\iphone\cropped\rendered_big_new'; % Change this to your directory path
% files = dir(fullfile(folderPath, '*.jpg'));
% 
% % Process each file
% for i = 1:length(files)
%     fileName = files(i).name;
%     % Find indices of all underscores
%     underscoreIndices = find(fileName == '_');
% %     braceIndices = find(fileName == '[');
%     if length(underscoreIndices) >= 2
%         % Extract the number after the second underscore
%         nextUnderscoreIndex = find(fileName(underscoreIndices(2)+1:end) == '[', 1);
%         if isempty(nextUnderscoreIndex)
%             partNumber = fileName(underscoreIndices(2)+1:end);
%         else
%             partNumber = fileName(underscoreIndices(2)+1:underscoreIndices(2)+nextUnderscoreIndex-1);
%         end
%         
%         % Check if partNumber has only one digit
%         if length(partNumber) == 1
%             % Generate new filename by inserting '0' before the number
%             newFileName = [fileName(1:underscoreIndices(2)), '0', fileName(underscoreIndices(2)+1:end)];
%             % Rename the file
%             movefile(fullfile(folderPath, fileName), fullfile(folderPath, newFileName));
%             fprintf('Renamed %s to %s', fileName, newFileName);
%         end
%     end
% end

%%
% load("D:\oppoSkinExperi\picked40\iphone\cropped\rendered_big_new\jointimage\deltas49.mat");  
% string_deltas=[];
% for i_deltas=1:length(delta_lab)
%     string_deltas=[string_deltas;[num2str(delta_lab(i_deltas,1)),',',...
%         num2str(delta_lab(i_deltas,2)),',',num2str(delta_lab(i_deltas,3))]];
% end

%%
%批量改文件名
% % Get all JPEG files in the current directory
% files = dir('D:\oppoSkinExperi\picked40\iphone\cropped\rendered_big_new\*.jpg');
% fileNames = {files.name};
% 
% % Process each file
% for i = 1:length(fileNames)
%     fileName = fileNames{i};
%     % Check if the filename starts with 'cropped_'
%     if startsWith(fileName, 'cropped_')
%         % New filename without 'cropped_'
%         newFileName = strrep(fileName, 'cropped_', '');
%         % Rename the file
%         file_Name=[files(1).folder,'\',fileName];
%         newFile_Name=[files(1).folder,'\',newFileName];
%         movefile(file_Name, newFile_Name);
%         fprintf('Renamed %s to %s', fileName, newFileName);
%     end
% end
%%
% folderPath='D:\oppoSkinExperi\picked40\iphone\cropped\setPoints\';
% % Get a list of all files in the folder
% fileList = dir(strcat(folderPath,'*.jpg'));  % This captures all files
% 
% % Loop through each file and rename
% for i = 1:length(fileList)
%     % Get the current file name
%     oldName = fileList(i).name;
%     
% 
%     
%     % Append '.mat' to the new name
%     newName = [oldName(1:end-4), '.mat'];
% %     newName = [oldName(1:end-8), '.mat'];
%     % Construct the full paths for old and new names
%     oldFullPath = fullfile(folderPath, oldName);
%     newFullPath = fullfile(folderPath, newName);
%     
%     % Rename the file
%     movefile(oldFullPath, newFullPath);
%     
%     % Display the change
%     disp(['Renamed ', oldName, ' to ', newName]);
% end
%%
%保存train_index
% A=load("D:\oppoSkinExperi\picked40\iphone\cropped\setPoints\setPointscropped_indoor01.JPG.mat");
% index=zeros(13,1);
% [~, index(1,1)] = max(A.centers(:,1));
% 
% [~, index(2,1)] = min(A.centers(:,1));
% 
% 
% sumOfSquares = A.centers(:,2).^2+ A.centers(:,3).^2;
% 
% % Find the indices of the five largest values
% [~, index(3:7,1)] = maxk(sumOfSquares, 5);
% 
% % Find the indices of the five smallest values
% [~, index(8:12,1)] = mink(sumOfSquares, 5);
% 
% index(13,1)=49;
% save("train_index.mat",'index');


% A=imread("D:\oppoSkinExperi\picked40\iphone\train\new\mask\mask_rendering_Lab=[60,12,12].jpg");
% A1=A(:,:,1);