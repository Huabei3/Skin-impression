close all; 
clc;       
clear;     
%%
%cardMask
source_folder='Z:\homes\Peggy\oppoSkinExperi\picked40\iphone\cropped\renderedLUTchoose\renderedAdd07\indoor';
input_folder=fullfile(source_folder,'drawable');
dir_picname=dir('Z:\homes\Peggy\oppoSkinExperi\picked40\iphone\*.jpg');

files = dir(fullfile(input_folder,'*.jpg'));  
dir_mask=dir("Z:\homes\Peggy\oppoSkinExperi\picked40\iphone\CardMask\*.jpg");
% save_folder=fullfile(source_folder,'CardProcessed');
save_folder=fullfile(source_folder,'CardProcessed');
if ~exist(save_folder, 'dir')
    mkdir(save_folder);
end

bigdERenNfit=[6,8,9,16,11,15,27,24,21,31,33,34];
for i = 1:numel(files)
    %---------判断图像是否接受处理--------------
    is_big=0;
    for i_big=1:length(bigdERenNfit)
        if contains(files(i).name, dir_picname(bigdERenNfit(i_big)).name(1:end-4))
            is_big=1;
            break
        end
    end
    if is_big==0
        continue
    end
    img_file=strcat(save_folder,'\',files(i).name(1:end-4),'.jpg');
    if exist(img_file, 'file') == 2
        continue
    end
    %-------img转out-----------
    filename = fullfile(files(i).folder, files(i).name);      
    img0=imread(filename);
    img=im2double(img0);
    [m, n, p] = size(img);
    out = reshape(img, [m * n, p]);   
    %-------------生成逻辑索引------------------------
    i_mask=1;
    while (~contains(files(i).name,dir_mask(i_mask).name(1:end-4)))
        i_mask=i_mask+1;
    end

    bull=imread(strcat(dir_mask(i_mask).folder,'\',dir_mask(i_mask).name));
    bull = im2double(bull);    
    % 确保 bull 的尺寸与 img 一致
    if size(bull, 3) == 1
        bull = repmat(bull, [1, 1, 3]);
    end
    if ~isequal(size(bull), size(img))
        if size(bull,1)/size(bull,2)==size(img,1)/size(img,2)
            bull=imresize(bull,[size(img, 1), size(img, 2)]);
        end
    end
    % 获取 bull 中值为 1 的区域的边界
    [row, col] = find(bull(:,:,1) == 1);
    if isempty(row) || isempty(col)
        continue;
    end
    
    % 计算平移量
    min_row = min(row);
    min_col = min(col);
    shift_row = min_row - 1;
    shift_col = min_col - 1;    
    % 平移 bull 使其最上或最左的点靠近图片边缘
    bull_moved = circshift(bull, [-shift_row, -shift_col, 0]);    
    % 确保平移后 bull_moved 中值为 1 的位置不会超出图像边界
    bull_moved = bull_moved(1:m, 1:n, :);    
    % 生成逻辑索引
    bull_reshaped=reshape(bull, [m * n, p])./255;
    bull_reshaped = double(bull_reshaped);
    bull_moved_reshaped=reshape(bull_moved, [m * n, p])./255;
    bull_moved_reshaped = double(bull_moved_reshaped);

    logicalIndex = all(bull_reshaped == 0, 2);
    logicalIndex_moved = all(bull_moved_reshaped == 0, 2);
    


%---------process masked place---------------
    % 将 bull_moved==1 的地方的像素值填充到 bull==1 的地方
    if any(~logicalIndex)            
        out(~logicalIndex, :)=out(~logicalIndex_moved, :);
    end
    outnew = reshape(out, [m, n, p]);
    imshow(outnew);
    imwrite(outnew,strcat(save_folder,'\',files(i).name(1:end-4),'.jpg') );

    currentTime = datetime('now');  
    formattedTime = datestr(currentTime, 'yyyy-mm-dd HH:MM:SS');
    disp([files(i).name(1:end-4),'finished: ',formattedTime]);

end
