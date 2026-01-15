clear;
%%
% 定义源文件夹和目标文件夹路径
sourceFolder = 'Z:\homes\Peggy\oppoSkinExperi\HasselCropped\rendered\renderedLUT07\discarded07_1';
targetFolder = 'Z:\homes\Peggy\oppoSkinExperi\HasselCropped\rendered\renderedLUT07\inlab_night';

% 获取所有 JPG 文件
jpgFiles = dir(fullfile(sourceFolder, '*.jpg'));

% 定义目标日期
targetDate = datetime(2024, 7, 5);

% 遍历每个文件
for i = 1:length(jpgFiles)
    % 获取文件完整路径
    filePath = fullfile(jpgFiles(i).folder, jpgFiles(i).name);
    
    % 获取文件的生成日期
    fileInfo = dir(filePath);
    fileDate = datetime(fileInfo.datenum, 'ConvertFrom', 'datenum');
    
    % 检查文件日期是否为目标日期
    if fileDate == targetDate
        % 目标文件路径
        targetFilePath = fullfile(targetFolder, jpgFiles(i).name);
        
        % 移动文件
        movefile(filePath, targetFilePath);
    end
end

disp('文件移动完成');

%%

% sp07=load("Z:\homes\Peggy\oppoSkinExperi\HasselCropped\setPoints07\" + ...
%     "setPoints0.7被试女5已带妆7000km.mat");
% sp07_1=load("Z:\homes\Peggy\oppoSkinExperi\HasselCropped\setPoints07_1\" + ...
%     "setPoints0.7_1被试女5已带妆7000km.mat");
% sp=load("Z:\homes\Peggy\oppoSkinExperi\HasselCropped\setPoints\" + ...
%     "setPoints被试女5已带妆7000km.mat");
% % A=sp07new.centers-sp07.centers;
% 
% D_lab07=sp07.centers-sp07.center0.*ones(49,1);
% D_lab07_1=sp07_1.centers-sp07_1.center0.*ones(49,1);
% D_lab=sp.centers-sp.center0.*ones(49,1);
% A=D_lab07-D_lab07_1;



% % sp07new=load("Z:\homes\Peggy\oppoSkinExperi\HasselCropped\setPoints07new\" + ...
% %     "setPoints0.7被试女5已带妆7000km.mat");
% sp07=load("Z:\homes\Peggy\oppoSkinExperi\picked40\iphone\cropped\setPoints07\" + ...
%     "setPoints0.7cropped_indoor01.mat");
% sp=load("Z:\homes\Peggy\oppoSkinExperi\picked40\iphone\cropped\discarded\setPoints\" + ...
%     "setPointscropped_indoor01.mat");
% % A=sp07new.centers-sp07.centers;
% 
% D_lab07=sp07.centers-sp07.center0.*ones(49,1);
% D_lab=sp.centers-sp.center0.*ones(49,1);
% A=D_lab07-0.7*D_lab;
