%clear;
%load labps.mat
obs = 'd65_31';
lab=labs;
%RGBt=Rt(:,2:end)'*diag(spddata(:,2))*SSFtest;  % 计算RGB
%RGBtt=Rtt(:,2:end)'*diag(spddata(:,2))*SSFtest;
XYZ=lab2xyz(lab,obs,[]);
RGB=xyz2srgb(XYZ);
RGB = RGB / 255;  % 归一化到 0~1

rows = 7;
cols = 10;
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