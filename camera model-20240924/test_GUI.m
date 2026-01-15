clear; clc; close all;
%%

%%
%----r-----
% folderPath = ['Z:\homes\Peggy\VIVOskinExpe\imageCapture\20240718 哈苏相机删减整理\' ...
%     '20240718 肤色\male28\jpg\card'];
% folderPath = ['D:\work\VIVOskinExpe\renderCode\dsp\f04\r\jpg\card'];
% slashes = strfind(folderPath, '\');
% if ~isempty(slashes)
%     % 提取最后一个斜杠后的内容
%     lastPart = folderPath((slashes(1,end-3)+1:slashes(1,end-2)-1));
% end
% lastPart=[lastPart,'r'];

%----i-----
folderPath = '..\renderCode\XYZ\i\f10i';
slashes = strfind(folderPath, '\');
if ~isempty(slashes)
    % 提取最后一个斜杠后的内容
    lastPart = folderPath(slashes(end)+1:end);
end
%----------------

outputFolder="whiteSquare";
if ~exist(outputFolder, "dir")
    mkdir(outputFolder);
end

%%
imageFiles = dir(fullfile(folderPath, '*.mat'));
numImages = length(imageFiles);

% 初始化矩阵来存储每张图片中正方形区域的裁剪信息
crop_rect_info = zeros(numImages, 4); % [x, y, width, height]

fig = figure('Name', 'RGB Selection', 'NumberTitle', 'off');
for i_pic = 1:numImages
% for i_pic = 1:numImages
    imageFile = fullfile(folderPath, imageFiles(i_pic).name);
    load(imageFile,"XYZ_cropped");
    img = XYZ_cropped;
    % if size(img,2) > size(img,1)
    % % 如果宽度大于高度，则旋转 90 度
    %     img = imrotate(img, 90);
    % end
    imshow(img./20);
    title(['Image: ', imageFiles(i_pic).name, ' - Select 1 point']);
    
    [height, width, ~] = size(img);
    
    h = impoint;
    position = wait(h);
    
    if isempty(position)
        continue;
    end
    
    x = round(position(1));
    y = round(position(2));

    
    if x < 1 || x > width || y < 1 || y > height
        disp('Selected point is out of bounds, please select a point within the image.');
        continue;
    end
    
    % 计算正方形的边界
    sideLength = 30; % 正方形边长
    halfSideLength = sideLength / 2;
    xMin = max(1, x - halfSideLength);
    xMax = min(width, x + halfSideLength);
    yMin = max(1, y - halfSideLength);
    yMax = min(height, y + halfSideLength);
    figure(1)
    imshow(img./20)
    hold on; 
    rectangle('Position', [xMin, yMin, sideLength, sideLength], 'EdgeColor', 'r', 'LineWidth', 2);
    exportgraphics(gcf, fullfile("fdQst",strcat("whiteSquare",lastPart,".jpg")), 'Resolution', 300);

    % 保存正方形区域的裁剪信息
    picname(i_pic,1)={imageFiles(i_pic).name};
    crop_rect_info(i_pic, :) = [xMin, yMin, sideLength, sideLength];
end

close(fig);


filename = fullfile(outputFolder, strcat('crop_rect_info_white_',lastPart,'.mat'));
save(filename, 'crop_rect_info','picname');



%%
% % % 点击区域,生成bull,保存RGB
% folderPath = "D:\work\VIVOskinExpe\Hassel_downsampled\male59\cropped";
% 
% output_folder = fullfile(folderPath, "grayScaleApprRGB");
% if ~exist(output_folder, "dir")
%     mkdir(output_folder);
% end
% 
% % 获取文件夹中的所有JPG文件
% imageFiles = dir(fullfile(folderPath, '*.jpg'));
% numImages = length(imageFiles);
% n_points = 1;
% 
% % 创建 cell 数组来存储每张图片中点的 RGB 值和位置
% % rgbMatrix = cell(n_points, 1);
% posMatrix = cell(n_points, 1);
% 
% small_rgb = zeros(numImages, 3); % For the sixth point
% 
% % 初始化图形界面
% fig = figure('Name', 'RGB Selection', 'NumberTitle', 'off');
% 
% rgbdataNname=[];
% for i_pic = 1:numImages
%     % 读取并显示每张图片
%     imageFile = fullfile(folderPath, imageFiles(i_pic).name);
%     img = imread(imageFile);
%     imshow(img);
%     title(['Image: ', imageFiles(i_pic).name, ' - Select 6 points']);
% 
%     % 获取图像的尺寸
%     [height, width, ~] = size(img);
% 
%     % 用于存储每个点的 RGB 值
%     pointRGB = [];
%     pointPos = [];
%     i_point = 1;  % 点的计数器
%     maxPoints = 1;  % 每张图片最多选择 6 个点
% 
%     % 用户选择点的循环，直到选择6个点
%     while i_point <= maxPoints
%         % 用户点击图像选择点
%         h = impoint;
%         position = wait(h);  % 等待用户点击
% 
%         if isempty(position)
%             % 如果用户没有点击，跳出循环
%             break;
%         end
% 
%         % 记录选中点的坐标并进行边界检查
%         x = round(position(1));
%         y = round(position(2));
% 
%         if x < 1 || x > width || y < 1 || y > height
%             disp('Selected point is out of bounds, please select a point within the image.');
%             continue;  % 跳过这次循环，继续选择点
%         end
% 
%         % 获取该点的 RGB 值
%         rgbValue = img(y, x, :);
%         rgbValue = squeeze(rgbValue);  % 转换为 3x1 的 RGB 向量
% 
%         % 保存 RGB 值到矩阵
%         pointRGB(i_point, :) = rgbValue;
%         pointPos(i_point, :) = [x, y];
%             % 保存每张图片中的 RGB 值和位置
%         pointRGB_matrix{i_pic,i_point}=rgbValue;
%         pointPos_matrix{i_pic,i_point}=[x,y];
% 
% 
%         % 标记点并在图像上显示 RGB 值
%         fprintf("posMatrix:%d,%d,rgbMatrix:%d,%d,%d\n",x,y, ...
%             pointRGB(i_point, 1), ...
%             pointRGB(i_point, 2), ...
%             pointRGB(i_point, 3));
% 
%         i_point = i_point + 1;  % 计数器自增
%     end
% 
% 
% 
% 
%     % 计算点与相邻点之间的平均距离
%     distances = [];
%     for i = 1:maxPoints-1
%         dist = sqrt((pointPos(i, 1) - pointPos(i+1, 1)).^2+ ...
%             (pointPos(i, 2) - pointPos(i+1, 2)).^2);
% %         dist = sqrt(sum((pointPositions(i, :) - pointPositions(i+1, :)).^2));
%         distances = [distances, dist];
% 
%     end
%     a = mean(distances);
% 
%     % 生成 bull 图像并计算平均 RGB 值
%     for i_point = 1:maxPoints
%         x = pointPos(i_point, 1);
%         y = pointPos(i_point, 2);
%         rgbValue = pointRGB(i_point, :);
%         diffThreshold = 10;
%         if i_point<=4
%             Size=a*(2/3);
%         elseif i_point>=5
%             Size=a*(1/4);
%         end
%         % 生成 bull 图像
%         bullImage = false(height, width);
%         xMin = max(1, x - Size);
%         xMax = min(width, x + Size);
%         yMin = max(1, y - Size);
%         yMax = min(height, y + Size);
%         bullImage(yMin:yMax, xMin:xMax) = true;
% 
%         % 仅计算矩形区域内的 RGB 差异
% %         rgbDiff = sqrt(sum((double(img(yMin:yMax, xMin:xMax, :)) - reshape(rgbValue, [1 1 3])).^2, 3));
%         % 将图像区域和RGB值转换为double类型
%         imgRegion = double(img(yMin:yMax, xMin:xMax, :));
% 
%         rgbValueDouble = double(rgbValue);
%         reshaped_rgbValue=repmat(reshape(rgbValue, [1 1 3]), ...
%             size(imgRegion,1),size(imgRegion,2),1);
%         % rgbDiff变量现在是包含三个通道差异的向量
%         rgbDiff = sqrt((imgRegion(:,:,1) - reshaped_rgbValue(:,:,1)).^2+ ...
%             (imgRegion(:,:,2) - reshaped_rgbValue(:,:,2)).^2+ ...
%             (imgRegion(:,:,3) - reshaped_rgbValue(:,:,3)).^2);
%         % 将矩形区域内符合 RGB 差异阈值的部分标记为 true
%         validRegion = rgbDiff <= diffThreshold;
% 
%         % 更新 bull 图像，将符合 RGB 差异条件的区域设为 true
%         bullImage(yMin:yMax, xMin:xMax) = validRegion;
%         % 对 bullImage 进行形态学操作
%         se = strel('square', 3);  % 定义一个半径为 5 的圆形结构元素
% 
%         % 闭运算填补区域内部的洞
%         bullImage = imclose(bullImage, se);        
%         % 使用 imfill 函数进一步填补孔洞
%         bullImage = imfill(bullImage, 'holes');
%         % 开运算去除噪点
%         bullImage = imopen(bullImage, se);
% 
%         % 保存 bull 图像
%         outputFolder = fullfile(output_folder, "quare_mask");
%         if ~exist(outputFolder, "dir")
%             mkdir(outputFolder);
%         end
%         bullFilename = fullfile(outputFolder,[imageFiles(i_pic).name(1:end-4), '_point', num2str(i_point), '.png']);
%         imwrite(uint8(bullImage) * 255, bullFilename);
% 
%         % 计算区域内的平均 RGB 值
%         % regionPixels = img(repmat(bullImage, [1 1 3]));
% 
% 
%         [m,n,p]=size(img);
%         img_reshaped=reshape(img, [m * n, p]);
%         bullImage=repmat(bullImage,[1,1,3]);
%         bull_reshaped=reshape(bullImage, [m * n, p]);
%         bull_reshaped = double(bull_reshaped);
%         logicalIndex = all(bull_reshaped == 0, 2);
%         if any(~logicalIndex)            
%             regionPixels = img_reshaped(~logicalIndex, :);
% 
%         end
% 
% 
%         squareRGB_vector(i_point, :)=mean(regionPixels, 1);
%         squareRGB_cell{i_point, i_pic} = mean(regionPixels, 1);
%     end
% 
%     squareRGB_temp=[];
%     for i_point=1:maxPoints
%         squareRGB_temp=[squareRGB_temp,0,squareRGB_cell{i_point, i_pic}];
%     end
%     squareRGB_matrix(i_pic,:)=squareRGB_temp;
% 
%     rgbdataNname=[rgbdataNname;{imageFiles(i_pic).name(1:end-4)},...
%         {squareRGB_matrix(i_pic,:)}]
%     % 生成带时间戳的文件名
%     outputFolder = fullfile(output_folder, "rgb_pic");
%     if ~exist(outputFolder, "dir")
%         mkdir(outputFolder);
%     end
%     filename = fullfile(outputFolder, strcat(imageFiles(i_pic).name(1:end-4) ,'.mat'));   % 将时间戳附加到文件名中
% 
%     % 保存 rgbMatrix 到带有时间戳的 .mat 文件
%     save(filename, "pointRGB","pointPos","squareRGB_vector");
% end
% 
% close(fig);  % 关闭图形窗口
% 
% 
% % % 将 RGB 矩阵显示出来
% % disp('RGB Values for each image:');
% % disp(rgbMatrix);
% 
% 
% timestamp = datestr(now, 'yyyymmdd_HHMMSS');  % 生成当前时间的时间戳
% outputFolder = fullfile(output_folder, "rgbMatrix");
% if ~exist(outputFolder, "dir")
%     mkdir(outputFolder);
% end
% filename = fullfile(outputFolder,strcat('rgbMatrix_', timestamp ,'.mat'));   % 将时间戳附加到文件名中
% 
% % 保存 rgbMatrix 到带有时间戳的 .mat 文件
% 
% save(filename,'pointPos_matrix','pointRGB_matrix', ...
%     'squareRGB_matrix',"squareRGB_cell","rgbdataNname");

%%

 