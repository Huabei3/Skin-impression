%% plot_pred_vs_target.m
% 从 best_model 目录下 4 个 test_results 文件的 RawData sheet
% 读取 pred vs target 列，绘制 45° 对角线散点图
% axis equal, xticks 与 yticks 间隔相等

clear; clc; close all;

%% ========== 配置 ==========
data_dir = fullfile('..', 'results', 'best_model');
file_tags = {'4_AS', '5_CA', '6_SA','6_AF'};
n_files = length(file_tags);

% plot_titles = {
%     'test\_results\_4\_AS: pred vs target',
%     'test\_results\_5\_CA: pred vs target',
%     'test\_results\_6\_AF: pred vs target',
%     'test\_results\_6\_SA: pred vs target'
% };
plot_titles = {
    'Asian',...
    'Caucasian',...
    'South Asian',...
    'African'
    
};
%% ========== 预处理：给无扩展名的 xlsx 文件加 .xlsx 后缀 ==========
fprintf('=== Preparing xlsx files ===\n');
for i = 1:n_files
    tag = file_tags{i};
    fname = ['test_results_' tag];
    src = fullfile(data_dir, fname);        % 无扩展名原始文件
    dst = fullfile(data_dir, [fname '.xlsx']);  % 加 .xlsx 后缀
    
    if isfile(src)
        if ~isfile(dst)
            copyfile(src, dst);
            fprintf('  Copied: %s -> %s\n', fname, [fname '.xlsx']);
        else
            fprintf('  Already exists: %s\n', [fname '.xlsx']);
        end
    else
        warning('  Source not found: %s', src);
    end
end
fprintf('=== Done preparing ===\n\n');

%% ========== 读取数据 & 绘图 ==========
figure('Position', [100, 100, 1200, 900], 'Name', 'Pred vs Target');

for i = 1:n_files
    tag = file_tags{i};
    fname = ['test_results_' tag '.xlsx'];
    fpath = fullfile(data_dir, fname);
    
    if ~isfile(fpath)
        warning('File not found: %s', fpath);
        continue;
    end
    
    % 读取 RawData sheet
    try
        data = readtable(fpath, 'Sheet', 'RawData');
    catch ME
        warning('Failed to read %s: %s', fname, ME.message);
        continue;
    end
    
    pred   = data.pred;
    target = data.target;
    
    %% ----- 子图 -----
    subplot(2, 2, i);
    hold on;
    
    % 散点
    scatter(target, pred, 18, 'filled', ...
        'MarkerFaceColor', [0.2 0.4 0.7], ...
        'MarkerFaceAlpha', 0.5, ...
        'MarkerEdgeColor', 'none');
    
    % 45° 参考线（固定 [0,1] 范围）
    plot([0, 1], [0, 1], '--', 'Color', [0.8 0.2 0.2], 'LineWidth', 1.5);
    
    xlabel('Target');
    ylabel('Pred');
    title(plot_titles{i}, 'Interpreter', 'none');
    
    % ---- axis equal + 统一 [0,1] 范围 + 相同刻度间隔 ----
    axis equal;
    xlim([0, 1]);
    ylim([0, 1]);
    
    % 刻度：0 : 0.2 : 1
    set(gca, 'XTick', 0:0.2:1, 'YTick', 0:0.2:1);
    grid on;
    box on;
    
    % 标注 R², RMSE, N
    r2 = corr(pred, target)^2;
    rmse = sqrt(mean((pred - target).^2));
    n = length(pred);
    
    text_str = sprintf('N = %d\nR^2 = %.4f\nRMSE = %.4f', n, r2, rmse);
    text(0.55, 0.15, text_str, ...
        'FontSize', 9, 'BackgroundColor', 'w', 'EdgeColor', [0.6 0.6 0.6]);
    
    hold off;
end

%% ========== 保存 ==========
save_dir = fullfile('..', 'results', 'figures');
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

saveas(gcf, fullfile(save_dir, 'pred_vs_target_4panels.png'));
saveas(gcf, fullfile(save_dir, 'pred_vs_target_4panels.fig'));

fprintf('Figure saved to:\n');
fprintf('  %s\n', fullfile(save_dir, 'pred_vs_target_4panels.png'));
fprintf('  %s\n', fullfile(save_dir, 'pred_vs_target_4panels.fig'));
disp('Done.');
