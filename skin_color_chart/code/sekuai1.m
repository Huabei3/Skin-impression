%clear;
%load labps.mat
clc;clear;close all;

attr_type="pre";

%load lab_r.mat;%全部
data_folder=fullfile("res",attr_type,"adjusted/");
load(fullfile(data_folder,"lab_selected.mat"),"idselect","labs","lab1");
lab=labs;
lab = lab(end:-1:1, :);  % 行反转



%%
% target_points = [
%     32.0776, 50.1891;
%     30.9276, 46.1223;
%     23.0109, 20.7844;
%     20.6493, 20.7844
% ];
target_points = [];
% 初始化逻辑索引（所有行先标记为“保留”）
keep_rows = true(size(lab, 1), 1);

% 遍历目标点，标记需删除的行
for i = 1:size(target_points, 1)
    X = target_points(i, 1);
    Y = target_points(i, 2);
    keep_rows = keep_rows & ~((abs(lab(:, 1) - Y) < 1e-3) & (abs(lab(:, 3) - X) < 1e-3));
end

% 保留不满足删除条件的行
lab = lab(keep_rows, :);
%%
if strcmp(attr_type,"all")
    lab(end-1,:)=[22.69174444	4.280355409	6.906400343];
    lab(end,:)=[22.69174444	4.641793188	9.226150897];
end
%%

figure(1);hold on;

plot(lab(:,3),lab(:,1), 'k*','MarkerSize', 3)  
grid on
axis equal
xlim([0,50])
ylim([15,90])
% plot(target_points(:,1),target_points(:,2), 'r*','MarkerSize', 3)  
%%
%RGBt=Rt(:,2:end)'*diag(spddata(:,2))*SSFtest;  % 计算RGB
%RGBtt=Rtt(:,2:end)'*diag(spddata(:,2))*SSFtest;
% XYZ=lab2xyz(lab,obs,[]);
XYZ=lab2xyz(lab,"d65_64");
RGB=xyz2srgb(XYZ);
RGB = RGB / 255;  % 归一化到 0~1
%%
% cols = 13;
% cols = 17;%pre
if strcmp(attr_type,"all")
    cols = 12;%all
elseif strcmp(attr_type,"pre")
    cols = 17;
end
rows = ceil(length(RGB)/cols);


w = 1; h = 1;  % 每个色块的宽高

figure;
hold on;

for i = 1:size(RGB,1)
    row = ceil(i / cols);        % 当前行
    col = mod(i-1, cols) + 1;    % 当前列
    
    % 绘制矩形
    rectangle('Position', [col-1, rows-row, w, h], 'FaceColor', RGB(i,:), 'EdgeColor', 'k');keep_rows
end

axis equal;
xlim([0 cols]);
ylim([0 rows]);
axis off;
title('');
hold off;
exportgraphics(gcf,fullfile(data_folder,"color_chart.jpg"),"Resolution",3000);

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

save(fullfile(data_folder,"lab_changed_dark2.mat"),"lab");