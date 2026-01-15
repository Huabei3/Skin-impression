% 检查文件夹是否存在
clc;clear;close all;
%%
folderPath="D:\work\secondYearMaster\CIC\documents\CIC33-Skin color preference under multi-scene demand_9.15";



if ~isfolder(folderPath)
    error('指定的文件夹路径不存在。');
end

% 获取文件夹中所有的PNG文件
filePattern = fullfile(folderPath, '*.png');
theFiles = dir(filePattern);

% 如果没有找到PNG文件，则显示警告并返回
if isempty(theFiles)
    warning('在指定的文件夹中没有找到任何PNG文件。');
    stitchedImage = [];
    return;
end

% 按文件名排序，确保拼接顺序一致
[~, order] = sortrows({theFiles.name}');
theFiles = theFiles(order);

% 初始化拼接后的图像
stitchedImage = [];

% 循环遍历每个文件并拼接
for i = 1:length(theFiles)
    baseFileName = theFiles(i).name;
    fullFileName = fullfile(theFiles(i).folder, baseFileName);

    % 读取图像
    currentImage = imread(fullFileName);
    currentImage=currentImage(:,:,1:3);
    imshow(currentImage);

    % 第一次读取图像时，初始化拼接图像
    if i == 1
        stitchedImage = currentImage;
    else
        % 检查图像高度是否一致，不一致则无法直接拼接
        if size(stitchedImage, 1) ~= size(currentImage, 1)
            error('所有PNG文件的高度必须相同才能进行拼接。');
        end

        % 水平拼接图像
        stitchedImage = [stitchedImage, currentImage];
    end
end
%%
output_folder = fullfile(folderPath, 'concatenated');
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end
output_file = fullfile(output_folder, strcat('bigImg.jpg'));
imwrite(stitchedImage, output_file);