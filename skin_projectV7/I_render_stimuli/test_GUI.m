clear; clc; close all;
%%

folderPath = 'E:\Hassel\dsp\female04\i';
slashes = strfind(folderPath, '\');
if ~isempty(slashes)
    % 提取最后一个斜杠后的内容
    lastPart = folderPath((slashes(1,end-1)+1:slashes(1,end)-1));
end
lastPart=[lastPart,'i'];

imageFiles = dir(fullfile(folderPath, '*.jpg'));
numImages = length(imageFiles);

% 初始化矩阵来存储每张图片中正方形区域的裁剪信息
crop_rect_info = zeros(numImages, 4); % [x, y, width, height]

fig = figure('Name', 'RGB Selection', 'NumberTitle', 'off');

for i_pic = 1:numImages
    imageFile = fullfile(folderPath, imageFiles(i_pic).name);
    img = imread(imageFile);

    imshow(img);
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
    
    % 保存正方形区域的裁剪信息
    picname(i_pic,1)={imageFiles(i_pic).name};
    crop_rect_info(i_pic, :) = [xMin, yMin, sideLength, sideLength];
end

close(fig);

% 保存crop_rect_info到MATLAB文件
% outputFolder = fullfile(output_folder, "crop_rect_info");
% if ~exist(outputFolder, "dir")
%     mkdir(outputFolder);
% end

% outputFolder="whiteSquare";
outputFolder="skinSquare";
if ~exist(outputFolder, "dir")
    mkdir(outputFolder);
end
filename = fullfile(outputFolder, strcat('crop_rect_info_white_',lastPart,'.mat'));
save(filename, 'crop_rect_info','picname');