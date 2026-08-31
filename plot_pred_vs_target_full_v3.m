%% plot_pred_vs_target_full_v3.m
% 从 test_results_full_v3_loss_mask_{RACE}.xlsx 创建 pred vs target 图
% data_source:
%   "v3"      → 2×2 子图（4个nation: AS, CA, SA, AF），数据来源 v3
%   "STIM"    → 2×2 子图（4个nation: AS, CA, SA, AF），数据来源 STIM
%   "C_vs_CNN"→ 2×4 子图，上排4个为 STIM 数据来源的4个人种，
%                下排4个为 v3 数据来源的4个人种

close all; clc; clear;

%% ========== 配置 ==========
% data_source: "v3"   → test_results_full_v3_loss_mask_{nation}.xlsx
%              "STIM" → test_results_devide_{nation}.xlsx
%              "C_vs_CNN" → 上下两行对比：上排 STIM，下排 v3
data_source = 'C_vs_CNN';

% 根据 data_source 选择输入文件前缀
switch upper(data_source)
    case 'V3'
        file_prefix = 'test_results_full_v3_loss_mask';
        is_comp = false;   % 非对比模式
    case 'STIM'
        file_prefix = 'test_results_devide';
        is_comp = false;
    case 'C_VS_CNN'
        file_prefix_top    = 'test_results_devide';               % STIM → 上排
        file_prefix_bottom = 'test_results_full_v3_loss_mask';   % v3   → 下排
        is_comp = true;
    otherwise
        error('data_source 必须为 "v3"、"STIM" 或 "C_vs_CNN"');
end

% text_language: "eng" → 英文标注, "ch" → 中文标注
text_language = 'ch';

data_dir = fullfile('D:\work\VIVOskinExpe\skin_model\data\correlation_results', ...
    'fullpara_devide_validation', 'efit_p', 'new', 'devide_validation', 'test_results');

output_dir = fullfile('D:\work\VIVOskinExpe\skin_model\data\correlation_results', ...
    'fullpara_devide_validation', 'efit_p', 'new', 'devide_validation', ...
    sprintf('pred_vs_target_plots_%s', upper(data_source)));
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

% ---- 中文/英文文本映射 ----
nations_en = {'AS', 'CA', 'SA', 'AF'};
if strcmpi(text_language, 'ch')
    plot_titles     = {'亚洲人', '高加索人', '南亚人', '非洲人'};
    xlabel_str      = '真值';
    ylabel_str      = '预测值';
    stat_fmt        = 'r = %.4f\nRMSE = %.4f';
    row_label_stim  = 'STIM数据';
    row_label_v3    = 'v3数据';
else
    plot_titles     = {'Asian', 'Caucasian', 'South Asian', 'African'};
    xlabel_str      = 'Target';
    ylabel_str      = 'Pred';
    stat_fmt        = 'r = %.4f\nRMSE = %.4f';
    row_label_stim  = 'STIM Data';
    row_label_v3    = 'v3 Data';
end

attribute_serials = {
    '01Preference';
    '02Attractiveness';
    '03Feminine';
    '04Cooperative';
    '05Youth';
    '06Healthy';
    '07Fidelity';
    '08Harmony';
    '09Fair';
    '10Ruddy'};
n_attributes = length(attribute_serials);

%% ========== 对每个attribute生成一张图 ==========
for a = 1:n_attributes
    attr = attribute_serials{a};
    fprintf('===== %s =====\n', attr);

    if is_comp
        % ===== C_vs_CNN 模式：2×4 子图 =====
        % 上排4个: STIM 数据 (file_prefix_top)
        % 下排4个: v3   数据 (file_prefix_bottom)
        fig = figure('Name', ['Pred vs Target (STIM vs v3) - ', attr], ...
                     'Position', [50, 100, 2200, 1000], ...
                     'Visible', 'off');

        row_prefixes = {file_prefix_top, file_prefix_bottom};
        row_labels   = {row_label_stim,  row_label_v3};

        for i_row = 1:2
            f_prefix = row_prefixes{i_row};
            r_label  = row_labels{i_row};

            for i_nation = 1:4
                nation = nations_en{i_nation};
                sub_idx = (i_row - 1) * 4 + i_nation;  % 1~8

                % 读取数据
                fpath = fullfile(data_dir, sprintf('%s_%s.xlsx', f_prefix, nation));
                sheet_label = ['RawData_', attr];

                if ~exist(fpath, 'file')
                    fprintf('  [%s] 文件不存在: %s\n', r_label, fpath);
                    subplot(2, 4, sub_idx);
                    title(sprintf('%s - N/A', plot_titles{i_nation}), 'FontSize', 10);
                    axis off;
                    continue;
                end

                try
                    T = readtable(fpath, 'Sheet', sheet_label);
                catch
                    fprintf('  [%s] Sheet "%s" 不存在于 %s\n', r_label, sheet_label, fpath);
                    subplot(2, 4, sub_idx);
                    title(sprintf('%s - N/A', plot_titles{i_nation}), 'FontSize', 10);
                    axis off;
                    continue;
                end

                pred = T.pred;
                target = T.target;

                if isempty(pred) || isempty(target)
                    fprintf('  [%s] %s: 数据为空\n', r_label, nation);
                    subplot(2, 4, sub_idx);
                    title(sprintf('%s - N/A', plot_titles{i_nation}), 'FontSize', 10);
                    axis off;
                    continue;
                end

                % 子图
                subplot(2, 4, sub_idx);
                hold on;

                % 散点图
                scatter(target, pred, 15, [0.2, 0.4, 0.7], ...
                        'filled', 'MarkerFaceAlpha', 0.5);

                % y = x 参考线
                plot([0 1], [0 1], '--', 'Color', [0.8, 0.2, 0.2], 'LineWidth', 1.2);

                xlabel(xlabel_str);
                ylabel(ylabel_str);

                % 标题：人种名
                title(plot_titles{i_nation}, 'FontSize', 10);

                xlim([0 1]);
                ylim([0 1]);
                axis equal;
                pbaspect([1 1 1]);
                grid on;
                box off;
                set(gca, 'GridAlpha', 0.3);

                ticks = 0:0.2:1;
                set(gca, 'XTick', ticks, 'YTick', ticks);

                % 统计量
                r = corr(pred, target, 'rows', 'complete');
                rmse = sqrt(nanmean((pred - target).^2));
                n = length(pred);

                text_str = sprintf(stat_fmt, r, rmse);
                text(0.55, 0.15, text_str, 'FontSize', 8, ...
                     'BackgroundColor', 'white', 'EdgeColor', [0.6, 0.6, 0.6]);

                % 右下角序号 (a)~(h)，放在box外面
                text(1.05, -0.2, ['(', char('a' + sub_idx - 1), ')'], ...
                     'Clipping', 'off', 'FontSize', 10, 'FontWeight', 'bold', ...
                     'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom');

                fprintf('  [%s] %s: N=%d, r=%.4f, RMSE=%.4f\n', ...
                        r_label, nation, n, r, rmse);

                hold off;
            end
        end

        % 在整张图上添加行标注（使用 sgtitle 或 annotation）
        % 左侧添加行标签
        annotation('textbox', [0.01, 0.72, 0.04, 0.06], 'String', row_label_stim, ...
                   'FontSize', 12, 'FontWeight', 'bold', 'EdgeColor', 'none', ...
                   'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
                   'Rotation', 90);
        annotation('textbox', [0.01, 0.22, 0.04, 0.06], 'String', row_label_v3, ...
                   'FontSize', 12, 'FontWeight', 'bold', 'EdgeColor', 'none', ...
                   'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
                   'Rotation', 90);

        % 保存图片
        save_path = fullfile(output_dir, sprintf('pred_vs_target_STIM_vs_v3_%s.png', attr));
        saveas(fig, save_path);
        fprintf('  已保存: %s\n', save_path);

        close(fig);

    else
        % ===== 原始模式：2×2 子图 =====
        fig = figure('Name', ['Pred vs Target - ', attr], ...
                     'Position', [100, 100, 1200, 900], ...
                     'Visible', 'off');
        for i_nation = 1:4
            nation = nations_en{i_nation};

            % 读取数据（根据 data_source 选择文件）
            fpath = fullfile(data_dir, sprintf('%s_%s.xlsx', file_prefix, nation));
            sheet_label = ['RawData_', attr];

            if ~exist(fpath, 'file')
                fprintf('  文件不存在: %s\n', fpath);
                continue;
            end

            try
                T = readtable(fpath, 'Sheet', sheet_label);
            catch
                fprintf('  Sheet "%s" 不存在于 %s\n', sheet_label, fpath);
                continue;
            end

            pred = T.pred;
            target = T.target;

            if isempty(pred) || isempty(target)
                fprintf('  %s: 数据为空\n', nation);
                continue;
            end

            % 子图
            subplot(2, 2, i_nation);
            hold on;

            % 散点图
            scatter(target, pred, 18, [0.2, 0.4, 0.7], ...
                    'filled', 'MarkerFaceAlpha', 0.5);

            % y = x 参考线
            plot([0 1], [0 1], '--', 'Color', [0.8, 0.2, 0.2], 'LineWidth', 1.5);

            xlabel(xlabel_str);
            ylabel(ylabel_str);

            title(plot_titles{i_nation}, 'FontSize', 11);

            xlim([0 1]);
            ylim([0 1]);
            axis equal;
            pbaspect([1 1 1]);   % 强制子图绘图框为正方形，确保原点对齐
            grid on;
            box off;
            set(gca, 'GridAlpha', 0.3);

            % 手动设置 xticks / yticks 相等: 0 : 0.2 : 1
            ticks = 0:0.2:1;
            set(gca, 'XTick', ticks, 'YTick', ticks);

            % 统计量
            r = corr(pred, target, 'rows', 'complete');
            rmse = sqrt(nanmean((pred - target).^2));
            n = length(pred);

            text_str = sprintf(stat_fmt, r, rmse);
            text(0.55, 0.15, text_str, 'FontSize', 9, ...
                 'BackgroundColor', 'white', 'EdgeColor', [0.6, 0.6, 0.6]);

            % 右下角序号 (a)~(d)，放在box外面
            text(1.02, -0.12, ['(', char('a' + i_nation - 1), ')'], ...
                 'Clipping', 'off', 'FontSize', 10, 'FontWeight', 'bold', ...
                 'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom');

            fprintf('  %s: N=%d, r=%.4f, RMSE=%.4f\n', nation, n, r, rmse);

            hold off;
        end

        % 保存图片
        save_path = fullfile(output_dir, sprintf('pred_vs_target_%s.png', attr));
        saveas(fig, save_path);
        fprintf('  已保存: %s\n', save_path);

        close(fig);
    end
end

fprintf('\n========== 完成！共 %d 张图，输出目录: %s ==========\n', n_attributes, output_dir);
