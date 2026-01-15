%clear;
%load labps.mat


attr_type="all";

%load lab_r.mat;%全部
data_folder=fullfile("res",attr_type);
load(fullfile(data_folder,"lab_selected.mat"),"idselect","labs","lab1");
lab=labs;
lab = lab(end:-1:1, :);  % 行反转
%%
target_points = [
    32.0776, 50.1891;
    30.9276, 46.1223;
    23.0109, 20.7844;
    20.6493, 20.7844
];

%%
%RGBt=Rt(:,2:end)'*diag(spddata(:,2))*SSFtest;  % 计算RGB
%RGBtt=Rtt(:,2:end)'*diag(spddata(:,2))*SSFtest;
% XYZ=lab2xyz(lab,obs,[]);
XYZ=lab2xyz(lab,"d65_64");
RGB=xyz2srgb(XYZ);
RGB = RGB / 255;  % 归一化到 0~1
%%
if strcmp(attr_type,"pre")
    n_col=17;
else
    n_col=12;
end
rows = ceil(length(RGB)/n_col);
cols = n_col;
w = 1; h = 1;  % 每个色块的宽高

figure;
hold on;

for i = 1:size(RGB,1)
    row = ceil(i / cols);        % 当前行
    col = mod(i-1, cols) + 1;    % 当前列
    
    % 绘制矩形
    rectangle('Position', [col-1, rows-row, w, h], 'FaceColor', RGB(i,:), 'EdgeColor', 'k');
end

axis equal;
xlim([0 cols]);
ylim([0 rows]);
axis off;
title('');
hold off;
exportgraphics(gcf,fullfile(data_folder,"color_chart.jpg"),"Resolution",150);

%% 将Lab、XYZ、RGB数据存入Excel
% 创建一个单元格数组来存储数据，第一行为标题
data = cell(size(RGB,1) + 1, 10); % 10列：Lab3列 + XYZ3列 + RGB3列 + 序号1列

% 设置标题行
data(1, :) = {'序号', 'L*', 'a*', 'b*', 'X', 'Y', 'Z', 'R', 'G', 'B'};

% 填充数据
for i = 1:size(RGB,1)
    data(i+1, 1) = {i};                  % 序号
    data(i+1, 2:4) = num2cell(lab(i,:)); % Lab值
    data(i+1, 5:7) = num2cell(XYZ(i,:)); % XYZ值
    data(i+1, 8:10) = num2cell(RGB(i,:));% RGB值（归一化后）
end

% 保存到Excel文件
excel_filename = fullfile(data_folder, strcat(attr_type,"_data.xlsx"));
writecell(data, excel_filename);

% 显示保存信息
fprintf('颜色数据已保存到: %s\n', excel_filename);