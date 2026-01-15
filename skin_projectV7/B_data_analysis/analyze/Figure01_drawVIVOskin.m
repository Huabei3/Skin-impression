
clear; close all;
%%
save_folder = fullfile("ellip_pic_p\ellipse", "VIVOskin");
if ~exist(save_folder, "dir")
    mkdir(save_folder);
end
model_names = ["f01", "f02", "f03", "f04", ...
               "f05", "f06", "f07", "f08", "f09", "f10", ...
               "m01", "m02", "m03", "m04", "m05", "m06", "m07", ...
               "m08", "m09", "m10"];
nations=["AS","CA","SA","AF"];
num_colors=4;
hue_values = linspace(0, 1, num_colors + 1);
hue_values = hue_values(1:end-1); 
hsv_matrix = [hue_values', 0.8 * ones(num_colors, 1), 0.8 * ones(num_colors, 1)];
colors = hsv2rgb(hsv_matrix);
% 定义人种对应的lastParts索引
nation_indices = cell(5, 1); % 5个人种（包括"all"）
% AS (Asian): f04i, f05i, f06i, m04i, m05i, m06i (索引1-6)
nation_indices{1} = 1:6;
% CA (Caucasian): f01i, f02i, f03i, m01i, m02i, m03i (索引7-12)  
nation_indices{2} = 7:12;
% SA (South Asian): f07i, f08i, m07i, m08i (索引13-16)
nation_indices{3} = 13:16;
% AF (African): f09i, f10i, m09i, m10i (索引17-20)
nation_indices{4} = 17:20;
% all: 所有索引 (索引1-20)
nation_indices{5} = 1:20;
% 读取数据
Data = readtable(fullfile("documents\combined_data1.xlsx"), 'Sheet', "labC", 'ReadVariableNames', false);
% 提取第一列为 'mean' 的行
meanRows = Data(strcmp(Data{:, 1}, 'mean'), :);
% 提取第 2 到第 5 列并转换为矩阵
lab_mean1 = meanRows(:, 2:5);
lab_mean1 = table2array(lab_mean1);
% 逐行读取数据并填充矩阵
lab_mean = zeros(size(lab_mean1)); % 初始化矩阵
for i = 1:size(lab_mean1, 1)
    for j = 1:size(lab_mean1, 2)
        cellValue = lab_mean1(i, j);
        if isnumeric(cellValue)
            lab_mean(i, j) = cellValue;
        else
            lab_mean(i, j) = str2double(cellValue); % 将字符串转换为数值
        end
    end
end
% 提取 L, a, b, C 数据
all_L = lab_mean(:, 1);
all_a = lab_mean(:, 2);
all_b = lab_mean(:, 3);
C = lab_mean(:, 4);
h = atan2d(all_b, all_a);
h_table=[mean(h),max(h),min(h)];
all_LabCh = [all_L, all_a, all_b, C, h];
% 保存数据
save(fullfile(save_folder, "VIVOskin.mat"), "all_LabCh", "model_names");
% 设置坐标轴范围
L_limits = [min(all_L) - 5, max(all_L) + 5];
a_limits = [min(all_a) - 5, max(all_a) + 5];
b_limits = [min(all_b) - 5, max(all_b) + 5];
C_limits = [min(C) - 5, max(C) + 5];
h_limits = [min(h) - 5, max(h) + 5];
ab_limits = [min(min(all_a), min(all_b)) - 5, max(max(all_a), max(all_b)) + 5];
% a-b 图
figure;
hold on;
for i_skin = 1:length(lab_mean)
    if ismember(i_skin,[1,2,3,11,12,13])
        color=colors(2,:);
    elseif ismember(i_skin,[4,5,6,14,15,16])
        color=colors(1,:);
    elseif ismember(i_skin,[7,8,17,18])
        color=colors(3,:);
    else
        color=colors(4,:);
    end
    % 根据 i_skin 的值选择颜色和样式
    if i_skin <= 10
        plot_style="o";
        plot(lab_mean(i_skin, 2), lab_mean(i_skin, 3), plot_style, ...
            'MarkerFaceColor', 'none', 'MarkerEdgeColor', color, 'MarkerSize', 5, 'LineWidth', 1.5);
    else
        plot_style = 'x'; 
        plot(lab_mean(i_skin, 2), lab_mean(i_skin, 3), plot_style, ...
            'MarkerFaceColor', color, 'MarkerEdgeColor', color, 'MarkerSize', 8, 'LineWidth', 1.5);
    end
    % text(lab_mean(i_skin, 2), lab_mean(i_skin, 3), model_names(i_skin), 'Color', 'black', 'FontSize', 5);
end
% 添加45°线
x = linspace(ab_limits(1), ab_limits(2), 1000);
y = x; 
plot(x, y, 'k--', 'LineWidth', 1);

% title('$a^*-b^*$', 'Interpreter', 'latex', 'FontSize', 12*2);
xlabel('$a^*$', 'Interpreter', 'latex', 'FontSize', 12*2);
ylabel('$b^*$', 'Interpreter', 'latex', 'FontSize', 12*2);
axis equal;
xlim(ab_limits);
ylim(ab_limits);
outputFolder = fullfile(save_folder, 'VIVOskin');
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end
exportgraphics(gcf, fullfile(outputFolder, 'all_a_b.jpg'), 'Resolution', 300);
% L-a 图
figure;
hold on;
for i_skin = 1:length(lab_mean)
    if ismember(i_skin,[1,2,3,11,12,13])
        color=colors(2,:);
    elseif ismember(i_skin,[4,5,6,14,15,16])
        color=colors(1,:);
    elseif ismember(i_skin,[7,8,17,18])
        color=colors(3,:);
    else
        color=colors(4,:);
    end
    % 根据 i_skin 的值选择颜色和样式
    if i_skin <= 10
        plot_style="o";
        plot(lab_mean(i_skin, 2), lab_mean(i_skin, 1), plot_style, ...
            'MarkerFaceColor', 'none', 'MarkerEdgeColor', color, 'MarkerSize', 5, 'LineWidth', 1.5);
    else
        plot_style = 'x'; 
        plot(lab_mean(i_skin, 2), lab_mean(i_skin, 1), plot_style, ...
            'MarkerFaceColor', color, 'MarkerEdgeColor', color, 'MarkerSize', 8, 'LineWidth', 1.5);
    end
    % text(lab_mean(i_skin, 2), lab_mean(i_skin, 1), model_names(i_skin), 'Color', 'black', 'FontSize', 5);
end
% title('$L^*-a^*$', 'Interpreter', 'latex', 'FontSize', 12*2);
xlabel('$a^*$', 'Interpreter', 'latex', 'FontSize', 12*2);
ylabel('$L^*$', 'Interpreter', 'latex', 'FontSize', 12*2);
axis equal;
xlim(a_limits);
ylim(L_limits);
exportgraphics(gcf, fullfile(outputFolder, 'all_L_a.jpg'), 'Resolution', 300);
% L-b 图
figure;
hold on;
for i_skin = 1:length(lab_mean)
    if ismember(i_skin,[1,2,3,11,12,13])
        color=colors(2,:);
    elseif ismember(i_skin,[4,5,6,14,15,16])
        color=colors(1,:);
    elseif ismember(i_skin,[7,8,17,18])
        color=colors(3,:);
    else
        color=colors(4,:);
    end
    % 根据 i_skin 的值选择颜色和样式
    if i_skin <= 10
        plot_style="o";
        plot(lab_mean(i_skin, 3), lab_mean(i_skin, 1), plot_style, ...
            'MarkerFaceColor', 'none', 'MarkerEdgeColor', color, 'MarkerSize', 5, 'LineWidth', 1.5);
    else
        plot_style = 'x'; 
        plot(lab_mean(i_skin, 3), lab_mean(i_skin, 1), plot_style, ...
            'MarkerFaceColor', color, 'MarkerEdgeColor', color, 'MarkerSize', 8, 'LineWidth', 1.5);
    end
    % text(lab_mean(i_skin, 3), lab_mean(i_skin, 1), model_names(i_skin), 'Color', 'black', 'FontSize', 5);
end
% title('$L^*-b^*$', 'Interpreter', 'latex', 'FontSize', 12*2);
xlabel('$b^*$', 'Interpreter', 'latex', 'FontSize', 12*2);
ylabel('$L^*$', 'Interpreter', 'latex', 'FontSize', 12*2);
axis equal;
xlim(b_limits);
ylim(L_limits);
exportgraphics(gcf, fullfile(outputFolder, 'all_L_b.jpg'), 'Resolution', 300);
% L-C 图
figure;
hold on;
for i_skin = 1:length(lab_mean)
    if ismember(i_skin,[1,2,3,11,12,13])
        color=colors(2,:);
    elseif ismember(i_skin,[4,5,6,14,15,16])
        color=colors(1,:);
    elseif ismember(i_skin,[7,8,17,18])
        color=colors(3,:);
    else
        color=colors(4,:);
    end
    % 根据 i_skin 的值选择颜色和样式
    if i_skin <= 10
        plot_style="o";
        plot(lab_mean(i_skin, 4), lab_mean(i_skin, 1),plot_style, ...
            'MarkerFaceColor', 'none', 'MarkerEdgeColor', color, 'MarkerSize', 5, 'LineWidth', 1.5);
    else
        plot_style = 'x'; 
        plot(lab_mean(i_skin, 4), lab_mean(i_skin, 1),plot_style, ...
            'MarkerFaceColor', color, 'MarkerEdgeColor', color, 'MarkerSize', 8, 'LineWidth', 1.5);
    end
    % text(lab_mean(i_skin, 4), lab_mean(i_skin, 1), model_names(i_skin), 'Color', 'black', 'FontSize', 5);
end
% title('$L^*-C_{ab}^*$', 'Interpreter', 'latex', 'FontSize', 12*2);
xlabel('$C_{ab}^*$', 'Interpreter', 'latex', 'FontSize', 12*2);
ylabel('$L^*$', 'Interpreter', 'latex', 'FontSize', 12*2);
axis equal;
xlim(C_limits);
ylim(L_limits);
exportgraphics(gcf, fullfile(outputFolder, 'all_L_C.jpg'), 'Resolution', 300);
% L-h 图
figure;
hold on;
for i_skin = 1:length(lab_mean)
    % 根据 i_skin 的值选择颜色和样式
    if ismember(i_skin,[1,2,3,11,12,13])
        color=colors(2,:);
    elseif ismember(i_skin,[4,5,6,14,15,16])
        color=colors(1,:);
    elseif ismember(i_skin,[7,8,17,18])
        color=colors(3,:);
    else
        color=colors(4,:);
    end
    if i_skin <= 10
        plot_style="o";
        plot(h(i_skin), lab_mean(i_skin, 1), plot_style, ...
            'MarkerFaceColor', 'none', 'MarkerEdgeColor', color, 'MarkerSize', 5, 'LineWidth', 1.5);
    else
        plot_style = 'x'; 
        plot(h(i_skin), lab_mean(i_skin, 1), plot_style, ...
            'MarkerFaceColor', color, 'MarkerEdgeColor', color, 'MarkerSize', 8, 'LineWidth', 1.5);
    end
    % text(h(i_skin), lab_mean(i_skin, 1), model_names(i_skin), 'Color', 'black', 'FontSize', 5);
end
% title('$L^*-h_{ab}$', 'Interpreter', 'latex', 'FontSize', 24);
xlabel('$h_{ab}$', 'Interpreter', 'latex', 'FontSize', 12*2);
ylabel('$L^*$', 'Interpreter', 'latex', 'FontSize', 12*2);
axis equal;
xlim(h_limits);
ylim(L_limits);
exportgraphics(gcf, fullfile(outputFolder, 'all_L_h.jpg'), 'Resolution', 300);
concatenate_images1(outputFolder, 5);
