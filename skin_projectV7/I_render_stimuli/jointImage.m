close all; % 关闭所有图窗
clc;       % 清空命令窗口
clear;     % 清除工作区所有变量
%%
%批量拼接
load("D:\oppoSkinExperi\picked40\iphone\cropped\rendered_big_new\jointimage\deltas49.mat"); 
% Get all JPEG files in the current directory
files = dir('D:\oppoSkinExperi\picked40\iphone\cropped\rendered_big_new\*.jpg');
fileNames = {files.name};

% Dictionary to group images by prefix
imgGroups = containers.Map('KeyType', 'char', 'ValueType', 'any');


% Group images
for i = 1:length(fileNames)
    fileName = fileNames{i};
    underscoreIndices = find(fileName == '_');
    if length(underscoreIndices) >= 2
        prefix = fileName(1:underscoreIndices(2)-1);
        if isKey(imgGroups, prefix)
            imgGroups(prefix) = [imgGroups(prefix), {fileName}];
        else
            imgGroups(prefix) = {fileName};
        end
    end
end

% Process each group
keys = imgGroups.keys;
for k = 1:length(keys)
    group = imgGroups(keys{k});
    numImages = length(group);
    concatenatedImage = []; % Initialize empty array for concatenated image
    currentRow = [];
    for j = 1:numImages
        % Read image
        img = imread(strcat(files(1).folder,'\',group{j}));

        % Optionally resize the image
        fixedHeight = 300; % Fixed height in pixels
        scaleFactor = fixedHeight / size(img, 1); % Compute scale factor based on height
        resizedWidth = round(size(img, 2) * scaleFactor);
        img = imresize(img, [fixedHeight resizedWidth]); % Resize image

        % Create text to add to the image
        textStr = sprintf('%0.2f, %0.2f, %0.2f', delta_lab(j, 1), delta_lab(j, 2), delta_lab(j, 3));
        position = [10, 270];  % Text position at bottom of the image
        fontSize = 20;  % Start with an initial fontSize
        % Dynamically adjust fontSize to fit the image dimensions
%         while true
%             testImg = insertText(zeros(size(img, 1), size(img, 2)), position, textStr, 'FontSize', fontSize, 'BoxOpacity', 0);
%             textWidth = sum(any(testImg, 1));  % Get the sum of columns that have any non-zero values
%             textHeight = sum(any(testImg, 2)); % Get the sum of rows that have any non-zero values
%         
%             % Ensure textWidth and textHeight are scalar
%             if isscalar(textHeight) && isscalar(textWidth)
%                 if textHeight <= size(img, 1) / 5 && textWidth <= size(img, 2)
%                     break;
%                 else
%                     fontSize = fontSize - 1;  % Decrease font size if too big
%                 end
%             else
%                 error('textWidth and textHeight should be scalar values');
%             end
%         end
        img = insertText(img, position, textStr, 'FontSize', fontSize, 'BoxOpacity', 0, 'TextColor', 'white');

        % Concatenate images in a row
        currentRow = [currentRow, img];
        % Check if row is full
        if mod(j, 7) == 0 || j == numImages
            if isempty(concatenatedImage)
                concatenatedImage = currentRow;
            else
                concatenatedImage = [concatenatedImage; currentRow];
            end
            currentRow = []; % Reset current row
        end
    end
    
    % Save the big image to file
    outputFile = sprintf('%s_combined.jpg', keys{k});
    outputFile=strcat('D:\oppoSkinExperi\picked40\iphone\cropped\rendered_big_new\jointimage\texted_',outputFile);
    imwrite(concatenatedImage, outputFile);
    fprintf('Saved %s', outputFile);
end
%%
% 定义图片文件夹路径
% folderPath = 'D:\oppoSkinExperi\哈苏jpg\已裁剪\result\results'; % 替换为你的图片文件夹路径
% files = dir(fullfile(folderPath, '*.jpg')); % 假设图片是PNG格式，根据需要调整
% 
% % 假设所有图片的尺寸相同，获取第一张图片的尺寸作为参考
% imgExample = imread(fullfile(folderPath, files(1).name));
% [imgHeight, imgWidth, ~] = size(imgExample);
% 
% % 计算大图的尺寸
% bigImgWidth = imgWidth * 8;
% bigImgHeight = imgHeight * 6;
% 
% % 创建一个空白大图
% bigImg = zeros(bigImgHeight, bigImgWidth, 3, 'uint8');
% 
% % 按顺序将图片拼接到大图上
% for i = 1:length(files)
%     % 计算当前图片在大图中的位置
%     row = floor((i-1) / 8) + 1;
%     col = mod(i-1, 8) + 1;
%     startX = (col-1) * imgWidth + 1;
%     startY = (row-1) * imgHeight + 1;
%     
%     % 读取图片并放置在大图上
%     img = imread(fullfile(folderPath, files(i).name));
%     bigImg(startY:startY+imgHeight-1, startX:startX+imgWidth-1, :) = img;
%     
%     % 在图片上标注文件名
% %     position = [startX, startY]; % 标注的位置
%     %bigImg = insertText(bigImg, position, files(i).name(20:end-4), 'FontSize', 12, 'BoxOpacity', 0, 'TextColor', 'white');
% end
% 
% % 显示大图
% figure(1);
% imshow(bigImg);
% for i = 1:length(files)
%     row = floor((i-1) / 8) + 1;
%     col = mod(i-1, 8) + 1;
%     startX = (col-1) * imgWidth + 1;
%     startY = (row-1) * imgHeight + 8;
%     text(startX, startY, files(i).name(20:end-4), 'Color', 'white', 'FontSize', 8); % 添加文字
% end
% % 可选: 保存大图
% imwrite(bigImg, ['D:\oppoSkinExperi\哈苏jpg\已裁剪\result\results\joint\',files(i).name(1:19),'bigImg.png']);