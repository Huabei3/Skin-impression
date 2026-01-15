close all; % 关闭所有图窗
clc;       % 清空命令窗口
clear;     % 清除工作区所有变量
%%
%----------r---------
% folder ='F:\Hassel\dsp\female41\r\jpg\noCard';
% files = dir(fullfile(folder, '*.jpg'));  % 读取文件夹中的所有.jpg文件
% 
% slashes = strfind(folder, '\');
% model = folder((slashes(1,end-3)+1:slashes(1,end-2)-1));
% iOr = folder((slashes(1,end-2)+1:slashes(1,end-1)-1));
% lastPart=strcat(model,iOr);

%----i------------
folder ='D:\work\VIVOskinExpe\renderCode\dsp\male39\i';
files = dir(fullfile(folder, '*.jpg'));  % 读取文件夹中的所有.jpg文件

slashes = strfind(folder, '\');
model = folder((slashes(1,end-1)+1:slashes(1,end)-1));
iOr = folder((slashes(1,end)+1:end));
lastPart=strcat(model,iOr);
%-------------------
save_folder=fullfile('D:\work\VIVOskinExpe\renderCode\mask_findCen',lastPart,'auto');
if exist(save_folder,'dir')==0
    mkdir(save_folder);
end


for i = 1:numel(files)  %改为1：numel(files),可以实现对文件夹中图片进行批量操作
    close all
    % white65=[95.04,100,108.89];
    white65=[94.813,100.000,107.262];
    white=white65;
    w=white65;
    ellipse=[62.6,18.8,19.50,0.021918043,0.114852178,0.047455333,-0.057891224,2.083585086];
    startcenter=ellipse;
    filename = fullfile(folder, files(i).name);  % 获取文件名,包含路径
    img0=imread(filename);

 % 显示图像并让用户选择一个点
    figure, imshow(img0);
    fprintf('Please select a point in the image.\n');
    [x, y] = ginput(1); % 等待用户在图像上选择一个点
    close; % 关闭图像窗口

    % 使用用户选择的点为中心，20像素为边长的正方形
    r = 10; % 半边长
    x1 = max(1, x - r);
    y1 = max(1, y - r);
    x2 = min(size(img0, 2), x + r);
    y2 = min(size(img0, 1), y + r);    
    % 提取正方形区域并计算平均RGB值
    squareRegion = img0(y1:y2, x1:x2, :);
    avgRGB(1,1)=mean(mean(squareRegion(:,:,1))); 
    avgRGB(1,2)=mean(mean(squareRegion(:,:,2))); 
    avgRGB(1,3)=mean(mean(squareRegion(:,:,3))); 
    % avgRGB = mean(mean(squareRegion, 1), 1);    
    % 将RGB转换为XYZ
    avgRGB=avgRGB./255;
    [avgxyz] = srgb2xyz(avgRGB);    
    % 将XYZ转换为Lab
    avglab = xyz2lab(avgxyz,'d65_64');    
    % 更新startcenter的前三个值
    startcenter(1:3) = avglab(1:3);

    img=im2double(img0);
    % [predict_white,rgbnew,ccT,duv,bull,bullx,ratio,lab,xyz,center0,center1]=AWBrendering1(img,i,spq,w,dlab,'srgb');%渲染函数
    [lab,xyz,center,bull,count,round]=mask(img,startcenter,white,w,'srgb');
    imshow(bull);
    imwrite(bull,fullfile(save_folder,files(i).name) );

    output_folder=fullfile(save_folder,'autoAve');
    if exist(output_folder,'dir')==0
        mkdir(output_folder);
    end
    save(fullfile(output_folder,strcat("aveSkinColor",files(i).name(1:end-4),".mat")),'center');
end




%%
% % 文件夹路径
% folderPath =save_folder;  % 这里替换为你的文件夹路径
% 
% % 获取文件夹下的所有图像文件
% imageFiles = dir(fullfile(folderPath, '*.jpg'));  % 你可以根据需要修改文件类型，如*.png
% 
% % 定义结构元素，腐蚀操作所用的
% se = strel('disk', 10);  % 3 是结构元素的半径，可以根据需要调整
% 
% % 遍历文件夹中的每个图像文件
% for i = 1:length(imageFiles)
%     % 读取图像
%     img = imread(fullfile(folderPath, imageFiles(i).name));
% 
%     % 检查是否是RGB图像
%     if size(img, 3) == 3
%         % 分离RGB通道
%         R = img(:,:,1);
%         G = img(:,:,2);
%         B = img(:,:,3);
% 
%         % 对每个通道进行腐蚀操作
%         R_eroded = imerode(R, se);
%         G_eroded = imerode(G, se);
%         B_eroded = imerode(B, se);
% 
%         % 合并腐蚀后的三个通道
%         img_eroded = cat(3, R_eroded, G_eroded, B_eroded);
% 
%         % 保存腐蚀后的图像
%         eroded_folder=fullfile(folderPath, "eroded");
%         if exist(eroded_folder,'dir')==0
%             mkdir(eroded_folder);
%         end
%         imwrite(img_eroded, fullfile(eroded_folder,imageFiles(i).name));
%     else
%         disp(['Skipping non-RGB image: ' imageFiles(i).name]);
%     end
% end
