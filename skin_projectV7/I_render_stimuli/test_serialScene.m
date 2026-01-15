clc;clear;close all;
%%
% %轮廓
% % 设置文件夹路径
% source_folder = 'Z:\homes\Peggy\VIVOskinExpe\imageCapture\20240718 哈苏相机删减整理\20240719 肤色\male21\jpg\card';
% another_folder = 'Z:\homes\Peggy\VIVOskinExpe\imageCapture\20240718 哈苏相机删减整理\20240719 肤色\female06\jpg\card';
% dest_folder = 'Z:\homes\Peggy\VIVOskinExpe\imageCapture\20240718 哈苏相机删减整理\20240719 肤色\male21\jpg\card\renamed';
% 
% % 获取源文件夹和目标文件夹中的jpg文件列表
% source_files = dir(fullfile(source_folder, '*.jpg'));
% another_files = dir(fullfile(another_folder, '*.jpg'));
% 
% % 创建目标文件夹如果它不存在
% if ~exist(dest_folder, 'dir')
%     mkdir(dest_folder);
% end
% 
% % 读取目标文件夹中的所有图片并提取轮廓
% another_images_contours = cell(length(another_files), 1);
% for j = 1:length(another_files)
%     another_img = imread(fullfile(another_folder, another_files(j).name));
%     another_img_gray = rgb2gray(another_img);
%     another_edges = edge(another_img_gray, 'Canny'); % 使用Canny边缘检测
%     another_contours = bwconncomp(another_edges); % 直接使用边缘检测结果
%     another_images_contours{j} = another_contours;
% end
% 
% % 预分配一个数组来存储文件名和它们的新名称
% new_filenames = cell(length(source_files), 1);
% 
% % 遍历源文件夹中的每个jpg文件
% parfor i = 1:length(source_files)
%     source_img = imread(fullfile(source_folder, source_files(i).name));
%     source_img_gray = rgb2gray(source_img);
%     source_edges = edge(source_img_gray, 'Canny'); % 使用Canny边缘检测
%     source_contours = bwconncomp(source_edges); % 直接使用边缘检测结果
% 
%     [~, name, ext] = fileparts(source_files(i).name); % 提取文件名（不包括扩展名）
% 
%     % 初始化最相似度及其索引
%     min_similarity = inf;
%     idx = 0;
% 
%     % 遍历目标文件夹中的每个轮廓
%     for j = 1:length(another_images_contours)
%         another_contours = another_images_contours{j};
% 
%         % 使用轮廓的个数来比较相似度
%         similarity = abs(numel(source_contours) - numel(another_contours));
% 
%         % 更新最相似的图片索引
%         if similarity < min_similarity
%             min_similarity = similarity;
%             idx = j;
%         end
%     end
% 
%     % 如果找到了最相似的图片
%     if idx > 0
%         [~, another_name, ~] = fileparts(another_files(idx).name); % 提取最相似图片的文件名
%         new_filenames{i} = fullfile(dest_folder, [another_name, ext]); % 存储新文件名
%     else
%         new_filenames{i} = []; % 没有找到相似图片
%     end
% end
% 
% % 处理文件名冲突并复制文件
% name_counter = containers.Map('KeyType', 'char', 'ValueType', 'int32');
% for i = 1:length(new_filenames)
%     if ~isempty(new_filenames{i})
%         [~, name, ext] = fileparts(new_filenames{i});
%         counter = name_counter(name);
%         if isempty(counter)
%             counter = 0;
%         end
%         counter = counter + 1;
%         name_counter(name) = counter;
%         new_file_name = fullfile(dest_folder, [name, num2str(counter), ext]);
%         new_filenames{i} = new_file_name; % 更新新文件名以避免冲突
%         copyfile(fullfile(source_folder, source_files(i).name), new_file_name);
%     else
%         warning('No similar image found for %s', source_files(i).name);
%     end
% end



%%
% % 设置文件夹路径
source_folder = 'Z:\homes\Peggy\VIVOskinExpe\imageCapture\20240718 哈苏相机删减整理\20240719 肤色\male21\jpg\card';
another_folder = 'Z:\homes\Peggy\VIVOskinExpe\imageCapture\20240718 哈苏相机删减整理\20240719 肤色\female06\jpg\card';
dest_folder = 'Z:\homes\Peggy\VIVOskinExpe\imageCapture\20240718 哈苏相机删减整理\20240719 肤色\male21\jpg\card\renamed';

% 获取源文件夹和目标文件夹中的jpg文件列表
source_files = dir(fullfile(source_folder, '*.jpg'));
another_files = dir(fullfile(another_folder, '*.jpg'));

% 创建目标文件夹如果它不存在
if ~exist(dest_folder, 'dir')
    mkdir(dest_folder);
end

% 初始化计数器字典，用于跟踪相同文件名的数量
name_counter = containers.Map('KeyType', 'char', 'ValueType', 'int32');

% 遍历源文件夹中的每个jpg文件
for i = 1:length(source_files)
    source_img = imread(fullfile(source_folder, source_files(i).name));
    [~, name, ~] = fileparts(source_files(i).name); % 提取文件名（不包括扩展名）

    % 初始化最相似度及其索引
    min_similarity = inf;
    idx = 0;

   % 遍历目标文件夹中的每个jpg文件
    for j = 1:length(another_files)
        another_img = imread(fullfile(another_folder, another_files(j).name));

        % 确保两个图像具有相同的尺寸
        if size(source_img) ~= size(another_img)
            error('Image sizes do not match.');
        end

        % 计算每个颜色通道的差异
        if size(source_img, 3) == 3 % RGB image
            channel_diff = double(source_img) - double(another_img);
            channel_diff = squeeze(channel_diff); % 移除单一维度
        else % Gray image
            channel_diff = double(source_img) - double(another_img);
        end

        % 计算每个颜色通道的差异范数的总和
        similarity = sum(sqrt(sum(channel_diff.^2, 1)));

        % 更新最相似的图片索引
        if similarity < min_similarity
            min_similarity = similarity;
            idx = j;
        end
    end

    % 如果找到了最相似的图片
    if idx > 0
        [~, name, ext] = fileparts(another_files(idx).name); % 提取最相似图片的文件名
        new_file_name = fullfile(dest_folder, [name, ext]); % 构造新的文件路径
        while(exist(new_file_name,"file"))
            new_file_name=strcat(new_file_name(1:end-4),"_1",ext);
        end
        % 复制并重命名图片到目标文件夹
        movefile(fullfile(source_folder, source_files(i).name), new_file_name);
        % copyfile(fullfile(source_folder, source_files(i).name), new_file_name);
    else
        warning('No similar image found for %s', source_files(i).name);
    end
end
