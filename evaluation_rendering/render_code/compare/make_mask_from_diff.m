
%MAKE_MASK_FROM_DIFF Generate binary mask images from differences between
% the 1st and 5th image in each group.
daivid_table_file=fullfile("D:\work\ZJU_entire_skin\David\Naturalness model\Jason's final project\data analysis\res\separate_skin_methods\resTable\quality\David_table.mat");
daivid_table_data=load(daivid_table_file);
fit_table=daivid_table_data.fit_table;

sourceFolder = 'D:\work\ZJU_entire_skin\ZJU_skin_database\A_images\David\rendered_imgs';
maskFolder = fullfile(sourceFolder,'mask');

if ~exist(maskFolder, 'dir')
    mkdir(maskFolder);
end

files = [dir(fullfile(sourceFolder, '*.jpg')); dir(fullfile(sourceFolder, '*.JPG'))];
if isempty(files)
    error('No jpg files found in: %s', sourceFolder);
end

groups = containers.Map('KeyType', 'char', 'ValueType', 'any');
skippedNoIndex = 0;

for i = 1:numel(files)
    [~, name, ~] = fileparts(files(i).name);
    % tokens = regexp(name, '^(skin_\\d+)_\\d+$', 'tokens', 'once');
    name=char(name);
    slash=find(name=='_');

    if length(slash)<2
        skippedNoIndex = skippedNoIndex + 1;
        continue;
    end

    prefix=name(1:slash(2)-1);
    idx = str2double(name(slash(1)+1:slash(2)-1));


    % if isempty(tokens)
    %     skippedNoIndex = skippedNoIndex + 1;
    %     continue;
    % end
    % 
    % prefix = tokens{1};
    % idx = str2double(tokens{2});
    if isnan(idx)
        skippedNoIndex = skippedNoIndex + 1;
        continue;
    end

    if ~isKey(groups, prefix)
        groups(prefix) = containers.Map('KeyType', 'double', 'ValueType', 'char');
    end

    idxMap = groups(prefix);
    idxMap(idx) = fullfile(files(i).folder, files(i).name);
    groups(prefix) = idxMap;
end

groupNames = keys(groups);
processed = 0;

for i = 1:numel(groupNames)
    prefix = groupNames{i};
    idxMap = groups(prefix);

    img_name1=strcat(prefix,"_*1.jpg");
    dir1=dir(fullfile(sourceFolder,img_name1));
    img1 = imread(fullfile(dir1(1).folder,dir1(1).name));

    img_name5=strcat(prefix,"_*5.jpg");
    dir5=dir(fullfile(sourceFolder,img_name5));
    img5 = imread(fullfile(dir5(1).folder,dir5(1).name));

    if ~isequal(size(img1), size(img5))
        fprintf('Skip %s: size mismatch between index 1 and 5.\n', prefix);
        continue;
    end

    % if ndims(img1) == 3
    %     diffMask = any(img1 ~= img5, 3);
    %     % diffMask = any(abs(img1 ~= img5)>0.0001, 3);
    % else
    %     % diffMask = abs(img1 ~= img5)>0.0001;
    %     diffMask = img1 ~= img5;
    % end
    % 1. 转换为灰度图，减少计算量和噪声
    if ndims(img1) == 3
        img1_gray = rgb2gray(img1);
        img5_gray = rgb2gray(img5);
    else
        img1_gray = img1;
        img5_gray = img5;
    end
    
    % 2. 计算绝对差值，使用阈值过滤微小差异（关键！）
    % diff_img = abs(double(img1_gray) - double(img5_gray));
    diff_img1 = abs(double(img1(:,:,1)) - double(img5(:,:,1)));
    diff_img2 = abs(double(img1(:,:,2)) - double(img5(:,:,2)));
    diff_img3 = abs(double(img1(:,:,3)) - double(img5(:,:,3)));
    diff_img=diff_img1|diff_img2|diff_img3;
    % 设置合理的阈值，过滤JPG压缩带来的微小差异
    diffMask = diff_img > 0.0001;  % 阈值可根据实际情况调整（建议5-20）



    % 3. 形态学操作去除噪点和平滑边界
    % 创建结构元素
    % se_disk = strel('disk', 5);  % 圆盘形结构元素，半径2
    % % 先腐蚀去除小噪点
    % diffMask = imdilate(diffMask, se_disk);
    % diffMask = imerode(diffMask, se_disk);
    % 再膨胀恢复边界
    
    % 形态学开闭运算，进一步平滑边界
    % diffMask = imopen(diffMask, strel('disk', 5));
    % diffMask = imclose(diffMask, strel('disk', 5));
    
    % 4. 可选：高斯模糊进一步平滑边界
    % diffMask = imgaussfilt(uint8(diffMask)*255, 0.5) > 128;


    imshow(diffMask);

    mask = uint8(diffMask) * 255;
    % mask = diffMask * 255;
    outPath = fullfile(maskFolder, [prefix '_mask.jpg']);
    imwrite(mask, outPath, 'Quality', 100);
    processed = processed + 1;
end

fprintf('Done. Generated %d mask(s) in %s.\n', processed, maskFolder);
if skippedNoIndex > 0
    fprintf('Skipped %d file(s) without trailing index.\n', skippedNoIndex);
end


