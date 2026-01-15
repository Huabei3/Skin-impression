% M2_adaptive_cube_coverage.m
% 自适应立方体覆盖算法（论文核心方法）

clear; clc; close all;

%% ============== 数据加载（与M1相同） ==============
% % uniform select in lab space
 clear;clc;close all;
load("lab_data.mat","lab_all","lab_pre");
attr_type="pre";
%load lab_r.mat;%全部
if strcmp(attr_type,"all")
    attr_serial="2";
    lab_data=lab_all;             %only preference
elseif strcmp(attr_type,"pre")
    attr_serial="1";
    lab_data=lab_pre;
end

save_folder=fullfile("res",attr_type,"adjusted");
if ~exist(save_folder,"dir")
    mkdir(save_folder);
end


%% ============== 参数设置 ==============
N = 200;  % 目标选择数量
method = 'I';  % 采样方式: 'I' 或 'II'
max_iter = 20;  % 最大迭代次数

%% ============== M2 主算法 ==============
fprintf('\n==================================================\n');
fprintf('M2: Adaptive Cube Coverage Method\n');
fprintf('==================================================\n');

% 初始边长范围
s_lower = 0.5;   % 小边长 -> 多立方体
s_upper = 30.0;  % 大边长 -> 少立方体

best_s = [];
best_centers = [];
best_non_empty = [];
best_holes = [];
best_diff = inf;

for iter = 1:max_iter
    s = (s_lower + s_upper) / 2;
    
    % 生成立方体中心
    all_centers = generate_cube_centers(lab_data, s, method);
    
    % 找非空立方体
    [non_empty_indices, M] = count_non_empty_cubes(lab_data, all_centers, s);
    
    % 找空洞
    non_empty_mask = false(size(all_centers, 1), 1);
    non_empty_mask(non_empty_indices) = true;
    hole_indices = identify_holes(all_centers, non_empty_mask, s);
    H = length(hole_indices);
    
    total = M + H;
    
    fprintf('Iter %2d: s=%.4f, 非空=%d, 空洞=%d, 总计=%d, 目标=%d\n', ...
            iter, s, M, H, total, N);
    
    % 保存最接近的结果
    if abs(total - N) < best_diff
        best_diff = abs(total - N);
        best_s = s;
        best_centers = all_centers;
        best_non_empty = non_empty_indices;
        best_holes = hole_indices;
    end
    
    if total == N
        fprintf('成功找到! 边长=%.4f\n', s);
        break;
    elseif total < N
        s_upper = s;  % 需要更小的边长
    else
        s_lower = s;  % 需要更大的边长
    end
end

% 合并非空立方体和空洞的中心
selected_indices = [best_non_empty; best_holes];
selected_cube_centers = best_centers(selected_indices, :);

% 为每个中心找最近的真实样本
selected_real = zeros(size(selected_cube_centers));
for i = 1:size(selected_cube_centers, 1)
    center = selected_cube_centers(i, :);
    distances = sqrt(sum((lab_data - center).^2, 2));
    [~, nearest_idx] = min(distances);
    selected_real(i, :) = lab_data(nearest_idx, :);
end

%% ============== 评估 ==============
fprintf('\n最终结果:\n');
fprintf('  边长: %.4f\n', best_s);
fprintf('  选中数量: %d\n', size(selected_real, 1));

% 计算体积比
try
    [~, vol_selected] = convhull(selected_real(:,2), selected_real(:,3), selected_real(:,1));
    [~, vol_all] = convhull(lab_data(:,2), lab_data(:,3), lab_data(:,1));
    volume_ratio = vol_selected / vol_all;
    fprintf('  体积比: %.4f\n', volume_ratio);
catch
    fprintf('  体积比: 计算失败\n');
end

% 计算均匀性
uniformity_cv = compute_uniformity(selected_real);
fprintf('  均匀性CV: %.4f\n', uniformity_cv);

%% ============== 可视化 ==============
figure('Position', [100, 100, 1200, 400]);

% 原始数据
subplot(1,3,1);
scatter3(lab_data(:,2), lab_data(:,3), lab_data(:,1), 1, lab_data(:,1), 'filled');
xlabel('a*'); ylabel('b*'); zlabel('L*');
title('Original Data');
colorbar;

% 立方体中心
subplot(1,3,2);
scatter3(selected_cube_centers(:,2), selected_cube_centers(:,3), selected_cube_centers(:,1), ...
         30, selected_cube_centers(:,1), 'filled');
xlabel('a*'); ylabel('b*'); zlabel('L*');
title(sprintf('Cube Centers (N=%d)', size(selected_cube_centers, 1)));
colorbar;

% 选中的真实样本
subplot(1,3,3);
scatter3(selected_real(:,2), selected_real(:,3), selected_real(:,1), ...
         30, selected_real(:,1), 'filled');
xlabel('a*'); ylabel('b*'); zlabel('L*');
title(sprintf('Selected Real Samples (N=%d)', size(selected_real, 1)));
colorbar;

sgtitle('M2: Adaptive Cube Coverage Results');

% 保存结果
save('M2_results.mat', 'selected_cube_centers', 'selected_real', 'best_s');

%% ============== 辅助函数 ==============
function centers = generate_cube_centers(lab_data, side_length, method)
    % 生成立方体中心候选点
    L_min = min(lab_data(:,1)); L_max = max(lab_data(:,1));
    a_min = min(lab_data(:,2)); a_max = max(lab_data(:,2));
    b_min = min(lab_data(:,3)); b_max = max(lab_data(:,3));
    
    if strcmp(method, 'I')
        % 方式I: 从最小值开始
        L_centers = L_min:side_length:L_max;
        a_centers = a_min:side_length:a_max;
        b_centers = b_min:side_length:b_max;
    else
        % 方式II: 中心对齐
        L_mid = (L_min + L_max) / 2;
        a_mid = (a_min + a_max) / 2;
        b_mid = (b_min + b_max) / 2;
        
        n_L = ceil((L_max - L_min) / side_length / 2);
        n_a = ceil((a_max - a_min) / side_length / 2);
        n_b = ceil((b_max - b_min) / side_length / 2);
        
        L_centers = L_mid + (-n_L:n_L) * side_length;
        a_centers = a_mid + (-n_a:n_a) * side_length;
        b_centers = b_mid + (-n_b:n_b) * side_length;
    end
    
    % 生成网格
    [L_grid, a_grid, b_grid] = ndgrid(L_centers, a_centers, b_centers);
    centers = [L_grid(:), a_grid(:), b_grid(:)];
end

function [non_empty_indices, M] = count_non_empty_cubes(lab_data, centers, side_length)
    % 统计非空立方体
    non_empty_indices = [];
    half_s = side_length / 2;
    
    for i = 1:size(centers, 1)
        center = centers(i, :);
        % 检查是否有数据点在立方体内
        in_cube = all(abs(lab_data - center) <= half_s, 2);
        if any(in_cube)
            non_empty_indices(end+1) = i;
        end
    end
    
    M = length(non_empty_indices);
end

function hole_indices = identify_holes(centers, non_empty_mask, side_length)
    % 识别空洞（被非空立方体包围的空立方体）
    hole_indices = [];
    empty_indices = find(~non_empty_mask);
    
    % 6个邻居方向
    directions = [
        side_length, 0, 0;
        -side_length, 0, 0;
        0, side_length, 0;
        0, -side_length, 0;
        0, 0, side_length;
        0, 0, -side_length
    ];
    
    for i = 1:length(empty_indices)
        idx = empty_indices(i);
        center = centers(idx, :);
        
        neighbors_non_empty = 0;
        total_neighbors = 0;
        
        for d = 1:6
            neighbor = center + directions(d, :);
            % 找最近的中心点
            distances = sqrt(sum((centers - neighbor).^2, 2));
            [min_dist, nearest_idx] = min(distances);
            
            if min_dist < side_length * 0.1  % 容差
                total_neighbors = total_neighbors + 1;
                if non_empty_mask(nearest_idx)
                    neighbors_non_empty = neighbors_non_empty + 1;
                end
            end
        end
        
        % 如果大部分邻居是非空的，认为是空洞
        if total_neighbors > 0 && neighbors_non_empty >= total_neighbors * 0.5
            hole_indices(end+1) = idx;
        end
    end
end

function cv = compute_uniformity(points)
    % 计算均匀性（最近邻距离的变异系数）
    n = size(points, 1);
    if n < 2
        cv = 0;
        return;
    end
    
    % 计算距离矩阵
    dist_mat = pdist2(points, points);
    dist_mat(dist_mat == 0) = inf;  % 排除自身
    
    % 最近邻距离
    nn_distances = min(dist_mat, [], 2);
    
    % 变异系数
    cv = std(nn_distances) / mean(nn_distances);
end
