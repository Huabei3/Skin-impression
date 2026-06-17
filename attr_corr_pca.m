%% attr_corr_pca.m
% 对10个 attribute 的 preference_score 进行:
%   ① 两两相关性计算 + 热力图
%   ② PCA 分析
%
% 数据来源: D:\work\VIVOSkinExpe\toMax\gt\toMax_gt_*.xlsx
%   按 (sheetname, original_name) 对齐, 剔除任意维度为 NaN 的行
%
% 开关:
%   separate_nation:  'merge'    → 全量 PCA (所有人种合并)
%                     'separate' → 分人种 PCA (AS/CA/SA/AF)
%   separate_iOr:     false → i/r 合并分析
%                     true  → i/r 分开分析 (实验室 vs 实景)
%
% Kenzie, 2026-06-01 / 更新 2026-06-16

clear; clc; close all;

% 确保当前脚本目录在 MATLAB path 中 (以便调用 reformat_pca_loadings 等工具函数)
script_fullpath = mfilename('fullpath');
[script_dir, ~, ~] = fileparts(script_fullpath);
if ~isempty(script_dir)
    addpath(script_dir);
end

%% ======================== 配置 ========================
gt_dir = 'D:\work\VIVOSkinExpe\toMax\gt';

% ===== ★ 开关1: separate_nation =====
%   'merge'    → 全量合并分析
%   'separate' → 按人种分别分析
separate_nation = 'separate';   % <--- 在这里切换

% ===== ★ 开关2: separate_iOr =====
%   false → i/r 合并
%   true  → i(实验室) / r(实景) 分别分析
separate_iOr = false;        % <--- 在这里切换

% ===== ★ 开关3: load_prev_matrix =====
%   true  → 从缓存加载 map (跳过读取 10 个 xlsx, 省 ~90% 时间)
%   false → 重新读取所有 xlsx 并刷新缓存
load_prev_matrix = true;     % <--- 第二次及以后运行建议 true

% ===== ★ 开关4: text_language =====
%   'eng' → 英文标注 (all-scenes / in-lab / real-scene)
%   'ch'  → 中文标注 (全部场景 / 实验室内 / 实景)
text_language = 'ch';        % <--- 在这里切换

% ===== ★ 开关5: skip_analysis =====
%   true  → 跳过 PCA/相关性计算, 直接整理已有图片
%   false → 完整运行分析 + 整理图片 (默认)
skip_analysis = false;       % <--- 在这里切换

% 10 个 attribute: {文件名, 显示标签}
attr_files = {
    'toMax_gt_01Preference.xlsx',      'Preference';
    'toMax_gt_02Attractiveness.xlsx',  'Attractiveness';
    'toMax_gt_03Feminine.xlsx',        'Feminine';
    'toMax_gt_04Cooperative.xlsx',     'Cooperative';
    'toMax_gt_05Youth.xlsx',           'Youth';
    'toMax_gt_06Healthy.xlsx',         'Healthy';
    'toMax_gt_07Fidelity.xlsx',        'Fidelity';
    'toMax_gt_08Harmony.xlsx',         'Harmony';
    'toMax_gt_09Fair.xlsx',            'Fair';
    'toMax_gt_10Ruddy.xlsx',           'Ruddy';
};

n_attr = size(attr_files, 1);
attr_labels = attr_files(:, 2);

% ===== 人种定义 =====
% Sheet 命名: {f/m}{%02d}{i/r}
%   CA (高加索): {f/m}01-03
%   AS (亚洲):   {f/m}04-06
%   SA (南亚):   {f/m}07-08
%   AF (非洲):   {f/m}09-10
race_defs = {
    'AS', {'f04','f05','f06','m04','m05','m06'}, '01_AS';
    'CA', {'f01','f02','f03','m01','m02','m03'}, '02_CA';
    'SA', {'f07','f08','m07','m08'},             '03_SA';
    'AF', {'f09','f10','m09','m10'},             '04_AF';
};

if strcmp(separate_nation, 'separate')
    race_list = race_defs;
    n_races_base = size(race_list, 1);
else
    race_list = {'ALL', {{}}, '00_merged'};
    n_races_base = 1;
end

% ===== i/r 环境列表 =====
if separate_iOr
    env_list = {'i', 'r'};          % i=实验室, r=实景
    env_labels = {'lab', 'real'};   % 用于标题/文件名
else
    env_list = {'all'};
    env_labels = {'all'};
end

% ===== iOr 输出层级目录名 =====
iOr_dirname = sprintf('sepaiOr_%d', separate_iOr);

fprintf('=== 配置 ===\n');
fprintf('  separate_nation  = %s\n', separate_nation);
fprintf('  separate_iOr     = %d  → 输出: attr_analysis/%s/\n', separate_iOr, iOr_dirname);
fprintf('  load_prev_matrix = %d\n', load_prev_matrix);
fprintf('  skip_analysis    = %d\n', skip_analysis);
fprintf('  环境列表: %s\n', strjoin(env_list, ', '));

% ===== 如果 skip_analysis, 跳过计算，直接整理图片 =====
if skip_analysis
    fprintf('\n=== skip_analysis=true: 跳过分析, 仅整理图片 ===\n');
else

% 数据缓存路径 (跳过 xlsx 读取时使用)
cache_dir = fullfile('D:\work\VIVOSkinExpe\deepskin\prepare', 'attr_analysis');
cache_file = fullfile(cache_dir, '_data_cache.mat');

%% ======================== 第一步: 获取原始数据 (读取 xlsx 或加载缓存) ========================
if load_prev_matrix && exist(cache_file, 'file')
    fprintf('\n=== 从缓存加载数据 (跳过 xlsx 读取) ===\n');
    load(cache_file, 'all_maps', 'all_keys', 'n_attr');
    % 验证缓存完整性
    if ~exist('all_maps', 'var') || ~exist('all_keys', 'var')
        warning('缓存文件损坏, 回退到 xlsx 读取');
        load_prev_matrix = false;
    else
        fprintf('已加载 %d 个 attribute 的 Map, %d 个唯一 key\n', n_attr, length(all_keys));
    end
end

if ~load_prev_matrix || ~exist('all_maps', 'var')
    fprintf('\n=== 读取 10 个 attribute 文件 ===\n');
    
    % all_maps{a} = containers.Map(key, preference_score)
    all_maps = cell(n_attr, 1);
    all_keys = {};
    
    for a = 1:n_attr
        fpath = fullfile(gt_dir, attr_files{a, 1});
        fprintf('[%d/%d] %s ... ', a, n_attr, attr_files{a, 1});
        
        sheet_names = sheetnames(fpath);
        m = containers.Map('KeyType', 'char', 'ValueType', 'double');
        
        n_total = 0;
        n_nan = 0;
        
        for s = 1:length(sheet_names)
            sn = sheet_names{s};
            data = readtable(fpath, 'Sheet', sn, 'VariableNamingRule', 'preserve');
            
            orig_names = data.original_name;
            scores = data.preference_score;
            
            for r = 1:height(data)
                key = [char(sn), '|', char(orig_names{r})];
                if isnumeric(scores(r)) && ~isnan(scores(r))
                    m(key) = scores(r);
                else
                    n_nan = n_nan + 1;
                end
                n_total = n_total + 1;
                all_keys{end+1} = key;  %#ok<AGROW>
            end
        end
        
        all_maps{a} = m;
        fprintf('有效=%d, NaN=%d, 总计=%d\n', m.Count, n_nan, n_total);
    end
    
    all_keys = unique(all_keys);
    fprintf('\n所有唯一 key 数: %d\n', length(all_keys));
    
    % 保存缓存 (下次运行时 load_prev_matrix=true 可直接加载)
    if ~exist(cache_dir, 'dir')
        mkdir(cache_dir);
    end
    save(cache_file, 'all_maps', 'all_keys', 'n_attr', '-v7.3');
    fprintf('数据缓存已保存到: %s\n', cache_file);
end

%% ======================== 第二步: 环境 × 人种 双重循环分析 ========================
n_envs = length(env_list);

for env_idx = 1:n_envs
    env = env_list{env_idx};
    env_label = env_labels{env_idx};
    
    fprintf('\n');
    fprintf('############################################################\n');
    if strcmp(env, 'all')
        fprintf('###  环境: 全部 (i+r 合并)\n');
    else
        fprintf('###  环境: %s (%s)\n', env, env_label);
    end
    fprintf('############################################################\n');
    
    %% --- 按 i/r 过滤 key ---
    if strcmp(env, 'all')
        env_filtered_idx = true(length(all_keys), 1);
    else
        env_filtered_idx = false(length(all_keys), 1);
        for k = 1:length(all_keys)
            parts = strsplit(all_keys{k}, '|');
            sn = parts{1};
            % 检查 sheetname 最后一个字符是否匹配 env ('i' 或 'r')
            if ~isempty(sn) && sn(end) == env
                env_filtered_idx(k) = true;
            end
        end
    end
    
    env_keys = all_keys(env_filtered_idx);
    fprintf('该环境有效 key 数: %d\n', length(env_keys));
    
    if isempty(env_keys)
        warning('  环境 %s 无数据, 跳过', env);
        continue;
    end
    
    %% --- 构建当前环境的 race_subdir 后缀 ---
    if separate_iOr
        env_suffix = ['_', env];  % 如 _i, _r
    else
        env_suffix = '';
    end
    
    % 用于跨人种比较的结构 (存储 coeff + 属性标签)
    if n_races_base > 1
        race_data = cell(n_races_base, 1);   % struct with .coeff, .labels
        race_names = race_list(:, 1);
    end
    
    %% --- 人种循环 ---
    for race_idx = 1:n_races_base
        race_name = race_list{race_idx, 1};
        
        if n_races_base > 1
            race_prefixes = race_list{race_idx, 2};
            race_subdir_base = race_list{race_idx, 3};
        else
            race_prefixes = {};
            race_subdir_base = '00_merged';
        end
        
        race_subdir = [race_subdir_base, env_suffix];  % 如 01_AS_i
        
        % 确定输出目录
        output_dir = fullfile('D:\work\VIVOSkinExpe\deepskin\prepare', ...
            'attr_analysis', iOr_dirname, race_subdir);
        if ~exist(output_dir, 'dir')
            mkdir(output_dir);
        end
        
        fprintf('\n');
        fprintf('--- 分析 [%s | env=%s]  (%s) ---\n', race_name, env, race_subdir);
        
        %% --- 过滤 key: 当前环境的 key 基础上, 按人种筛选 ---
        if isempty(race_prefixes)
            final_key_idx = true(length(env_keys), 1);
        else
            final_key_idx = false(length(env_keys), 1);
            for k = 1:length(env_keys)
                parts = strsplit(env_keys{k}, '|');
                sn = parts{1};
                for p = 1:length(race_prefixes)
                    if startsWith(sn, race_prefixes{p})
                        final_key_idx(k) = true;
                        break;
                    end
                end
            end
        end
        
        filtered_keys = env_keys(final_key_idx);
        n_keys_filtered = length(filtered_keys);
        fprintf('该组有效 key 数: %d\n', n_keys_filtered);
        
        if n_keys_filtered == 0
            warning('  无数据, 跳过 %s | env=%s', race_name, env);
            if n_races_base > 1
                race_coeffs{race_idx} = [];
            end
            continue;
        end
        
        %% --- 构建 N×10 矩阵 ---
        fprintf('=== 构建 N×%d 矩阵 ===\n', n_attr);
        
        data_matrix = NaN(n_keys_filtered, n_attr);
        
        for a = 1:n_attr
            m = all_maps{a};
            for k = 1:n_keys_filtered
                if isKey(m, filtered_keys{k})
                    data_matrix(k, a) = m(filtered_keys{k});
                end
            end
        end
        
        % 统计每列有效值
        column_stats = zeros(n_attr, 2);
        for a = 1:n_attr
            column_stats(a, 1) = sum(~isnan(data_matrix(:, a)));
            column_stats(a, 2) = sum(isnan(data_matrix(:, a)));
        end
        
        % 检测全 NaN 列并自动排除
        all_nan_cols = find(column_stats(:, 1) == 0);
        if ~isempty(all_nan_cols)
            fprintf('\n*** 警告: 以下 attribute 在所有行均为 NaN, 自动排除: ***\n');
            for c = 1:length(all_nan_cols)
                fprintf('  → %s (列 %d)\n', attr_labels{all_nan_cols(c)}, all_nan_cols(c));
            end
            valid_attr_idx = setdiff(1:n_attr, all_nan_cols);
            n_attr_used = length(valid_attr_idx);
        else
            valid_attr_idx = 1:n_attr;
            n_attr_used = n_attr;
        end
        
        for i = 1:length(valid_attr_idx)
            a = valid_attr_idx(i);
            fprintf('  %s: 有效=%d, NaN=%d / %d\n', ...
                attr_labels{a}, column_stats(a, 1), column_stats(a, 2), n_keys_filtered);
        end
        
        % 剔除任意(有效)维度为 NaN 的行
        valid_rows = all(~isnan(data_matrix(:, valid_attr_idx)), 2);
        data_clean = data_matrix(valid_rows, valid_attr_idx);
        attr_labels_used = attr_labels(valid_attr_idx);
        n_clean = size(data_clean, 1);
        n_removed = n_keys_filtered - n_clean;
        
        fprintf('\n剔除含 NaN 的行: %d 行\n', n_removed);
        fprintf('最终矩阵大小: %d × %d\n', n_clean, n_attr_used);
        
        if n_clean < n_attr_used
            warning('  样本量(%d) < 变量数(%d), PCA 结果可能不稳定', n_clean, n_attr_used);
        end
        
        % 保存矩阵
        save(fullfile(output_dir, 'attr_data_matrix.mat'), ...
            'data_clean', 'data_matrix', 'attr_labels_used', ...
            'filtered_keys', 'valid_rows', 'valid_attr_idx', 'all_nan_cols');
        
        %% --- 调用分析子程序 ---
        title_suffix = sprintf('%s_%s', race_name, env);
        [R, P, coeff, score, explained] = run_attr_analysis( ...
            data_clean, attr_labels_used, n_attr_used, output_dir, title_suffix, text_language);
        
        % 保存跨人种比较所需数据 (含属性标签, 用于交集比对)
        if n_races_base > 1 && n_attr_used >= 2
            race_data{race_idx} = struct('coeff', coeff, 'labels', {attr_labels_used});
        end
    end  % race loop
    
    % 保存当前环境的 race_data 用于后续跨环境比较
    if n_races_base > 1
        if ~exist('all_env_race_data', 'var')
            all_env_race_data = {};
            all_env_labels = {};
        end
        all_env_race_data{end+1} = race_data;
        all_env_labels{end+1} = env;
    end
    
    %% --- 当前环境的跨人种载荷一致性 ---
    if n_races_base > 1
        fprintf('\n');
        fprintf('===  跨人种载荷一致性 [env=%s] ===\n', env);
        
        comparison_dir = fullfile('D:\work\VIVOSkinExpe\deepskin\prepare', ...
            'attr_analysis', iOr_dirname, ['comparison', env_suffix]);
        if ~exist(comparison_dir, 'dir')
            mkdir(comparison_dir);
        end
        
        valid_races = find(~cellfun(@isempty, race_data));
        n_valid = length(valid_races);
        
        % 语言/标题预设
        if strcmp(text_language, 'ch')
            race_labels_full = {'亚洲人', '高加索人', '南亚人', '非洲人'};
            if strcmp(env, 'all')
                env_title = '全部场景';
            elseif strcmp(env, 'i')
                env_title = '实验室内';
            elseif strcmp(env, 'r')
                env_title = '实景';
            else
                env_title = env;
            end
        else
            race_labels_full = {'Asian', 'Caucasian', 'South Asian', 'African'};
            if strcmp(env, 'all')
                env_title = 'all-scenes';
            elseif strcmp(env, 'i')
                env_title = 'in-lab';
            elseif strcmp(env, 'r')
                env_title = 'real-scene';
            else
                env_title = env;
            end
        end
        
        % ---- 对 PC1~PC3 分别计算跨人种载荷相似度 ----
        all_pc_sim = cell(3, 1);  % 存储3个矩阵用于后续拼接
        
        for pc_idx = 1:3
            pc_label = sprintf('PC%d', pc_idx);
            fprintf('\n--- %s 载荷向量之间的一致性 (基于属性标签交集) ---\n', pc_label);
            fprintf('  值越接近 1 → attribute 结构越相似\n\n');
            
            pc_similarity = NaN(n_races_base, n_races_base);
            fprintf('%-8s', '');
            for i = 1:n_races_base
                fprintf('%-10s', race_names{i});
            end
            fprintf('\n');
            
            for i = 1:n_races_base
                fprintf('%-8s', race_names{i});
                for j = 1:n_races_base
                    if i == j
                        pc_similarity(i, j) = 1.0;
                        fprintf('%-10s', '---');
                    else
                        di = race_data{i};
                        dj = race_data{j};
                        if ~isempty(di) && ~isempty(dj)
                            [common_labels, idx_i, idx_j] = intersect(di.labels, dj.labels, 'stable');
                            n_common = length(common_labels);
                            if pc_idx == 1
                                n_common_matrix(i, j) = n_common;
                            end
                            if n_common >= 3
                                r_val = corr(di.coeff(idx_i, pc_idx), dj.coeff(idx_j, pc_idx));
                                if ~isnan(r_val)
                                    pc_similarity(i, j) = r_val;
                                    fprintf('%-10.3f', r_val);
                                else
                                    fprintf('%-10s', 'NaN');
                                end
                            else
                                fprintf('%-10s', 'N/A');
                            end
                        else
                            fprintf('%-10s', 'N/A');
                        end
                    end
                end
                fprintf('\n');
            end
            
            % 只在 PC1 时打印共同属性数
            if pc_idx == 1
                fprintf('\n--- 两两人种间共同属性数 ---\n');
                fprintf('%-8s', '');
                for i = 1:n_races_base
                    fprintf('%-10s', race_names{i});
                end
                fprintf('\n');
                for i = 1:n_races_base
                    fprintf('%-8s', race_names{i});
                    for j = 1:n_races_base
                        if i == j
                            fprintf('%-10s', '---');
                        else
                            fprintf('%-10d', n_common_matrix(i, j));
                        end
                    end
                    fprintf('\n');
                end
            end
            
            % 保存 xlsx
            sim_table = array2table(pc_similarity, ...
                'VariableNames', matlab.lang.makeValidName(race_names), ...
                'RowNames', race_names);
            xlsx_name = sprintf('%s_loading_similarity.xlsx', lower(pc_label));
            writetable(sim_table, fullfile(comparison_dir, xlsx_name), ...
                'WriteRowNames', true);
            
            % 热力图 (单张)
            if n_valid >= 2
                fig_comp = figure('Position', [200, 200, 650, 550], ...
                    'Name', sprintf('Cross-Race %s Similarity [%s]', pc_label, env), 'Visible', 'off');
                imagesc(pc_similarity);
                colormap(jet);
                caxis([-1, 1]);
                axis square;
                
                set(gca, 'XTick', 1:n_races_base, 'XTickLabel', race_labels_full, ...
                         'YTick', 1:n_races_base, 'YTickLabel', race_labels_full);
                title(pc_label, 'FontSize', 13, 'FontWeight', 'bold');
                
                for i = 1:n_races_base
                    for j = 1:n_races_base
                        if ~isnan(pc_similarity(i, j)) && i ~= j
                            text(j, i, sprintf('%.3f', pc_similarity(i, j)), ...
                                'HorizontalAlignment', 'center', 'FontSize', 10, 'Color', 'k');
                        end
                    end
                end
                
                % 存储矩阵供拼接使用
                all_pc_sim{pc_idx} = pc_similarity;
                
                png_name = sprintf('%s_loading_similarity.png', lower(pc_label));
                fig_name = sprintf('%s_loading_similarity.fig', lower(pc_label));
                saveas(fig_comp, fullfile(comparison_dir, png_name));
                saveas(fig_comp, fullfile(comparison_dir, fig_name));
                close(fig_comp);
                fprintf('\n%s 对比图已保存到: %s\n', pc_label, comparison_dir);
            end
        end
        
        % ---- 拼接 PC1+PC2+PC3 为一张 1×3 组合图 (共用右侧colorbar) ----
        if n_valid >= 2 && ~isempty(all_pc_sim{1})
            fig_combined = figure('Position', [50, 200, 2100, 550], ...
                'Name', sprintf('PC1-3 Loading Similarity Combined [%s]', env), 'Visible', 'off');
            
            ax3 = [];
            for pc_idx = 1:3
                ax = subplot(1, 3, pc_idx);
                imagesc(all_pc_sim{pc_idx});
                colormap(jet);
                caxis([-1, 1]);
                axis square;
                
                set(gca, 'XTick', 1:n_races_base, 'XTickLabel', race_labels_full, ...
                         'YTick', 1:n_races_base, 'YTickLabel', race_labels_full);
                title(sprintf('PC%d', pc_idx), 'FontSize', 13, 'FontWeight', 'bold');
                
                % 标注数值
                mat = all_pc_sim{pc_idx};
                for i = 1:n_races_base
                    for j = 1:n_races_base
                        if ~isnan(mat(i, j)) && i ~= j
                            text(j, i, sprintf('%.3f', mat(i, j)), ...
                                'HorizontalAlignment', 'center', 'FontSize', 9, 'Color', 'k');
                        end
                    end
                end
                
                if pc_idx == 3
                    ax3 = ax;
                end
            end
            
            % 在第三个子图右侧放置共享 colorbar
            pos3 = get(ax3, 'Position');
            % 高度缩短至0.8倍, 中心固定
            cb_h = pos3(4) * 0.8;
            cb_y = pos3(2) + (pos3(4) - cb_h) / 2;
            colorbar('Position', [pos3(1) + pos3(3) + 0.03, cb_y, 0.02, cb_h]);
            
            combined_png = fullfile(comparison_dir, 'pc_loading_similarity_combined.png');
            combined_fig = fullfile(comparison_dir, 'pc_loading_similarity_combined.fig');
            saveas(fig_combined, combined_png);
            saveas(fig_combined, combined_fig);
            close(fig_combined);
            fprintf('组合对比图已保存到: %s\n', comparison_dir);
        end
    end  % cross-race comparison
    
end  % env loop

%% ======================== 跨环境 (i vs r) PC1 载荷一致性 ========================
if exist('all_env_race_data', 'var') && length(all_env_race_data) == 2
    fprintf('\n');
    fprintf('############################################################\n');
    fprintf('###  跨环境 PC1 载荷一致性 (i vs r)\n');
    fprintf('############################################################\n');
    
    comp_env_dir = fullfile('D:\work\VIVOSkinExpe\deepskin\prepare', ...
        'attr_analysis', iOr_dirname, 'comparison_i_vs_r');
    if ~exist(comp_env_dir, 'dir')
        mkdir(comp_env_dir);
    end
    
    env1_data = all_env_race_data{1};
    env2_data = all_env_race_data{2};
    env1_name = all_env_labels{1};
    env2_name = all_env_labels{2};
    
    fprintf('\n--- 各人种 PC1 载荷在 %s vs %s 之间的一致性 ---\n', env1_name, env2_name);
    fprintf('%-8s  %10s  %10s  %10s\n', 'Race', 'r', 'CommonN', 'P-value');
    fprintf('%-8s  %10s  %10s  %10s\n', '----', '----------', '--------', '-------');
    
    cross_env_r = zeros(n_races_base, 1);
    
    for r = 1:n_races_base
        di = env1_data{r};
        dj = env2_data{r};
        if ~isempty(di) && ~isempty(dj)
            [common_labels, idx_i, idx_j] = intersect(di.labels, dj.labels, 'stable');
            n_common = length(common_labels);
            if n_common >= 3
                [r_val, p_val] = corrcoef(di.coeff(idx_i, 1), dj.coeff(idx_j, 1));
                r_val = r_val(1, 2);
                p_val = p_val(1, 2);
                cross_env_r(r) = r_val;
                fprintf('%-8s  %10.3f  %10d  %10.4f\n', race_names{r}, r_val, n_common, p_val);
            else
                fprintf('%-8s  %10s  %10d  (不足3个共同属性)\n', race_names{r}, 'N/A', n_common);
                cross_env_r(r) = NaN;
            end
        else
            fprintf('%-8s  %10s\n', race_names{r}, '无数据');
            cross_env_r(r) = NaN;
        end
    end
    
    % 保存
    ce_table = table(race_names, cross_env_r, ...
        'VariableNames', {'Race', 'PC1_Correlation_i_vs_r'});
    writetable(ce_table, fullfile(comp_env_dir, 'env_similarity.xlsx'));
    
    % 柱状图
    fig_ce = figure('Position', [200, 200, 500, 400], ...
        'Name', 'Cross-Env PC1 Similarity', 'Visible', 'off');
    bar(cross_env_r, 'FaceColor', [0.4 0.6 0.9]);
    set(gca, 'XTick', 1:n_races_base, 'XTickLabel', race_names);
    if strcmp(text_language, 'ch')
        ylabel('PC1载荷相关性 (实验室 vs 实景)', 'FontSize', 11);
        title('跨场景PC1载荷一致性', 'FontSize', 13, 'FontWeight', 'bold');
    else
        ylabel('PC1 Loading Correlation (i vs r)', 'FontSize', 11);
        title('Cross-Environment PC1 Loading Consistency', 'FontSize', 13, 'FontWeight', 'bold');
    end
    ylim([-1, 1]);
    grid on;
    % 标注数值
    for r = 1:n_races_base
        if ~isnan(cross_env_r(r))
            text(r, cross_env_r(r) + 0.05 * sign(cross_env_r(r)), ...
                sprintf('%.3f', cross_env_r(r)), ...
                'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold');
        end
    end
    saveas(fig_ce, fullfile(comp_env_dir, 'env_similarity.png'));
    saveas(fig_ce, fullfile(comp_env_dir, 'env_similarity.fig'));
    close(fig_ce);
    fprintf('\n跨环境比较已保存到: %s\n', comp_env_dir);
end

fprintf('\n======== 全部完成 ========\n');
fprintf('输出根目录: %s\n', fullfile('D:\work\VIVOSkinExpe\deepskin\prepare', 'attr_analysis', iOr_dirname));
fprintf('各子目录:\n');

if separate_iOr
    if n_races_base > 1
        for r = 1:n_races_base
            for e = 1:n_envs
                fprintf('  %s_%s\n', race_list{r, 3}, env_list{e});
            end
        end
        for e = 1:n_envs
            fprintf('  comparison_%s\n', env_list{e});
        end
    else
        for e = 1:n_envs
            fprintf('  00_merged_%s\n', env_list{e});
        end
    end
else
    for r = 1:n_races_base
        fprintf('  %s\n', race_list{r, 3});
    end
    if n_races_base > 1
        fprintf('  comparison\n');
    end
end

end  % if ~skip_analysis (跳过分析时直接跳到这里)

%% ======================== 后处理: 整理图片到分类文件夹 + 生成2x2拼接 ========================
fprintf('\n=== 后处理: 整理图片 ===\n');
base_analysis_dir = fullfile('D:\work\VIVOSkinExpe\deepskin\prepare', 'attr_analysis');

% 扫描 sepaiOr_0 和 sepaiOr_1, 有数据就整理 (不管当前开关设置)
for iov = 0:1
    iov_dirname = sprintf('sepaiOr_%d', iov);
    if exist(fullfile(base_analysis_dir, iov_dirname), 'dir')
        organize_pca_figures(base_analysis_dir, iov_dirname, race_defs, text_language);
    end
end


%% ============================================================
%%  子函数: 对给定数据运行相关性 + PCA
%% ============================================================
function [R, P, coeff, score, explained] = run_attr_analysis(data_clean, attr_labels, n_attr, output_dir, title_suffix, text_language)

    % ===== 语言标签定义 =====
    if strcmp(text_language, 'ch')
        L = struct(...
            'pc',        '主成分', ...
            'score',     '得分图', ...
            'loading',   '载荷矩阵', ...
            'corr',      '相关系数', ...
            'scree',     '碎石图', ...
            'variance',  '解释方差', ...
            'cumulative','累计方差');
        % 属性名映射
        attr_map = containers.Map(...
            {'Preference','Attractiveness','Feminine','Cooperative','Youth','Healthy','Fidelity','Harmony','Fair','Ruddy'}, ...
            {'喜好的','有吸引力的','女性化的','友善的','年轻的','健康的','真实还原的','与环境适配的','白皙的','红润的'});
    else
        L = struct(...
            'pc',        'PC', ...
            'score',     'Score', ...
            'loading',   'Loading Matrix', ...
            'corr',      'Correlation', ...
            'scree',     'Scree Plot', ...
            'variance',  'Variance Explained', ...
            'cumulative','Cumulative Variance');
        attr_map = containers.Map();
    end
    
    % 翻译属性标签 (如果是中文模式)
    if strcmp(text_language, 'ch')
        attr_labels_disp = cell(size(attr_labels));
        for ia = 1:length(attr_labels)
            if isKey(attr_map, attr_labels{ia})
                attr_labels_disp{ia} = attr_map(attr_labels{ia});
            else
                attr_labels_disp{ia} = attr_labels{ia};
            end
        end
    else
        attr_labels_disp = attr_labels;
    end

    fprintf('\n=== ① 相关性计算 (%s) ===\n', title_suffix);
    
    [R, P] = corrcoef(data_clean);
    
    fprintf('\n--- Pearson 相关系数矩阵 ---\n');
    fprintf('                ');
    for a = 1:n_attr
        fprintf('%-14s', attr_labels_disp{a});
    end
    fprintf('\n');
    for i = 1:n_attr
        fprintf('%-15s ', attr_labels_disp{i});
        for j = 1:n_attr
            fprintf('%-14.4f', R(i, j));
        end
        fprintf('\n');
    end
    
    % --- 热力图 ---
    fig_corr = figure('Position', [100, 100, 900, 750], ...
        'Name', sprintf('Corr Heatmap [%s]', title_suffix), 'Visible', 'off');
    
    imagesc(R);
    colormap(jet);
    caxis([-1, 1]);
    colorbar;
    axis square;
    
    set(gca, 'XTick', 1:n_attr, 'XTickLabel', attr_labels_disp, ...
             'YTick', 1:n_attr, 'YTickLabel', attr_labels_disp);
    set(gca, 'XTickLabelRotation', 45);
    if strcmp(text_language, 'ch')
        title(sprintf('皮尔逊相关系数 [%s]', title_suffix), ...
            'FontSize', 14, 'FontWeight', 'bold');
    else
        title(sprintf('Pearson Correlation [%s]', title_suffix), ...
            'FontSize', 14, 'FontWeight', 'bold');
    end
    
    for i = 1:n_attr
        for j = 1:n_attr
            if i ~= j
                text(j, i, sprintf('%.2f', R(i, j)), ...
                    'HorizontalAlignment', 'center', 'FontSize', 9, 'Color', 'k');
            else
                text(j, i, sprintf('%.2f', R(i, j)), ...
                    'HorizontalAlignment', 'center', 'FontSize', 9, ...
                    'Color', 'k', 'FontWeight', 'bold');
            end
        end
    end
    
    saveas(fig_corr, fullfile(output_dir, 'correlation_heatmap.png'));
    saveas(fig_corr, fullfile(output_dir, 'correlation_heatmap.fig'));
    close(fig_corr);
    fprintf('  热力图已保存\n');
    
    %% === ② PCA 分析 ===
    fprintf('\n=== ② PCA 分析 (%s) ===\n', title_suffix);
    
    data_z = zscore(data_clean);
    [coeff, score, latent, ~, explained, mu] = pca(data_z);
    
    fprintf('\n--- 各主成分解释方差比例 ---\n');
    for pc = 1:min(5, n_attr)
        fprintf('  PC%d: %.2f%% (累计: %.2f%%)\n', pc, explained(pc), sum(explained(1:pc)));
    end
    
    fprintf('\n--- 载荷矩阵 (属性 × PC) ---\n');
    fprintf('                ');
    for pc = 1:min(5, n_attr)
        fprintf('%-14s', sprintf('%s%d', L.pc, pc));
    end
    fprintf('\n');
    for i = 1:n_attr
        fprintf('%-15s ', attr_labels_disp{i});
        for pc = 1:min(5, n_attr)
            fprintf('%-14.4f', coeff(i, pc));
        end
        fprintf('\n');
    end
    
    %% --- PCA Loading Heatmap (独立图, 右子图) ---
    n_colors = 256;
    r_cmap = [(0:n_colors/2-1)'/(n_colors/2-1); ones(n_colors/2, 1)];
    g_cmap = [(0:n_colors/2-1)'/(n_colors/2-1); (n_colors/2-1:-1:0)'/(n_colors/2-1)];
    b_cmap = [ones(n_colors/2, 1); (n_colors/2-1:-1:0)'/(n_colors/2-1)];
    redblue_custom = [r_cmap, g_cmap, b_cmap];
    
    fig_load = figure('Position', [100, 100, 700, 600], ...
        'Name', sprintf('PCA Loading [%s]', title_suffix), 'Visible', 'off');
    
    n_pc_show = min(5, n_attr);
    imagesc(coeff(:, 1:n_pc_show));
    colormap(gca, redblue_custom);
    caxis([-1, 1]);
    colorbar;
    axis square;
    
    xtick_lbls = cell(1, n_pc_show);
    for pc = 1:n_pc_show
        xtick_lbls{pc} = sprintf('%s%d (%.1f%%)', L.pc, pc, explained(pc));
    end
    
    set(gca, 'XTick', 1:n_pc_show, ...
             'XTickLabel', xtick_lbls, ...
             'XTickLabelRotation', 30, ...
             'YTick', 1:n_attr, 'YTickLabel', attr_labels_disp);
    title(sprintf('%s [%s]', L.loading, title_suffix), 'FontSize', 13, 'FontWeight', 'bold');
    
    for i = 1:n_attr
        for pc = 1:n_pc_show
            text(pc, i, sprintf('%.2f', coeff(i, pc)), ...
                'HorizontalAlignment', 'center', 'FontSize', 9, 'Color', 'k');
        end
    end
    
    saveas(fig_load, fullfile(output_dir, 'pca_loadings_heatmap.png'));
    saveas(fig_load, fullfile(output_dir, 'pca_loadings_heatmap.fig'));
    close(fig_load);
    fprintf('  Loading heatmap 已保存\n');
    
    %% --- PC1-PC2 Score Plot (独立图, 原左子图) ---
    fig_pc12 = figure('Position', [100, 100, 650, 550], ...
        'Name', sprintf('PC1-PC2 Score [%s]', title_suffix), 'Visible', 'off');
    
    scatter(score(:, 1), score(:, 2), 15, 'filled', ...
        'MarkerFaceAlpha', 0.3, 'MarkerEdgeAlpha', 0.3);
    xlabel(sprintf('%s1 (%.1f%%)', L.pc, explained(1)), 'FontSize', 12);
    ylabel(sprintf('%s2 (%.1f%%)', L.pc, explained(2)), 'FontSize', 12);
    title(sprintf('%s: %s1 vs %s2 [%s]', L.score, L.pc, L.pc, title_suffix), 'FontSize', 13, 'FontWeight', 'bold');
    grid on;
    axis equal;
    hold on;
    
    xline(0, '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 0.5);
    yline(0, '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 0.5);
    
    scale_factor = max(max(abs(score(:, 1:2)))) * 0.8;
    for i = 1:n_attr
        quiver(0, 0, coeff(i, 1) * scale_factor, coeff(i, 2) * scale_factor, ...
            'LineWidth', 1.5, 'Color', 'r', 'MaxHeadSize', 0.5);
        text(coeff(i, 1) * scale_factor * 1.1, coeff(i, 2) * scale_factor * 1.1, ...
            attr_labels_disp{i}, 'FontSize', 9, 'Color', 'r', 'FontWeight', 'bold');
    end
    
    saveas(fig_pc12, fullfile(output_dir, 'pca_score_pc12.png'));
    saveas(fig_pc12, fullfile(output_dir, 'pca_score_pc12.fig'));
    close(fig_pc12);
    fprintf('  PCA 图 (PC1-PC2 score) 已保存\n');
    
    %% --- PC2-PC3 Score Plot (当 PC1 为一般因子时更有信息量) ---
    if n_attr >= 3
        fig_pc23 = figure('Position', [100, 100, 600, 550], ...
            'Name', sprintf('PC2-PC3 Score [%s]', title_suffix), 'Visible', 'off');
        
        scatter(score(:, 2), score(:, 3), 20, 'filled', ...
            'MarkerFaceAlpha', 0.3, 'MarkerEdgeAlpha', 0.3);
        xlabel(sprintf('%s2 (%.1f%%)', L.pc, explained(2)), 'FontSize', 12);
        ylabel(sprintf('%s3 (%.1f%%)', L.pc, explained(3)), 'FontSize', 12);
        title(sprintf('%s: %s2 vs %s3 [%s]', L.score, L.pc, L.pc, title_suffix), 'FontSize', 13, 'FontWeight', 'bold');
        grid on;
        axis equal;
        hold on;
        
        xline(0, '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 0.5);
        yline(0, '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 0.5);
        
        % 载荷向量 (PC2-PC3 平面)
        scale_factor = max(max(abs(score(:, 2:3)))) * 0.8;
        for i = 1:n_attr
            quiver(0, 0, coeff(i, 2) * scale_factor, coeff(i, 3) * scale_factor, ...
                'LineWidth', 1.5, 'Color', 'r', 'MaxHeadSize', 0.5);
            text(coeff(i, 2) * scale_factor * 1.1, coeff(i, 3) * scale_factor * 1.1, ...
                attr_labels_disp{i}, 'FontSize', 10, 'Color', 'r', 'FontWeight', 'bold');
        end
        
        saveas(fig_pc23, fullfile(output_dir, 'pca_score_pc23.png'));
        saveas(fig_pc23, fullfile(output_dir, 'pca_score_pc23.fig'));
        close(fig_pc23);
        fprintf('  PCA 图 (PC2-PC3) 已保存\n');
    end
    
    %% --- Scree plot ---
    fig_scree = figure('Position', [150, 150, 600, 450], ...
        'Name', sprintf('Scree Plot [%s]', title_suffix), 'Visible', 'off');
    yyaxis left;
    bar(1:n_attr, explained, 'FaceColor', [0.4 0.6 0.9], 'EdgeColor', 'k');
    ylabel(sprintf('%s (%%)', L.variance), 'FontSize', 12);
    yyaxis right;
    plot(1:n_attr, cumsum(explained), 'ro-', 'LineWidth', 2, 'MarkerFaceColor', 'r');
    ylabel(sprintf('%s (%%)', L.cumulative), 'FontSize', 12);
    xlabel(L.pc, 'FontSize', 12);
    title(sprintf('%s [%s]', L.scree, title_suffix), 'FontSize', 13, 'FontWeight', 'bold');
    xlim([0.5, n_attr + 0.5]);
    grid on;
    
    for pc = 1:n_attr
        text(pc, cumsum(explained(pc)) + 1, sprintf('%.1f%%', cumsum(explained(pc))), ...
            'HorizontalAlignment', 'center', 'FontSize', 8, 'Color', 'r');
    end
    
    saveas(fig_scree, fullfile(output_dir, 'pca_scree_plot.png'));
    saveas(fig_scree, fullfile(output_dir, 'pca_scree_plot.fig'));
    close(fig_scree);
    fprintf('  Scree plot 已保存\n');
    
    %% === 保存数值到 Excel ===
    fprintf('\n=== 保存数值结果 (%s) ===\n', title_suffix);
    
    corr_table = array2table(R, ...
        'VariableNames', matlab.lang.makeValidName(attr_labels), ...
        'RowNames', attr_labels);
    writetable(corr_table, fullfile(output_dir, 'correlation_matrix.xlsx'), ...
        'WriteRowNames', true);
    
    explained_table = table((1:n_attr)', explained, cumsum(explained), ...
        'VariableNames', {'PC', 'VarianceExplained_percent', 'Cumulative_percent'});
    writetable(explained_table, fullfile(output_dir, 'pca_explained.xlsx'));
    
    loading_table = array2table(coeff, ...
        'VariableNames', arrayfun(@(x) sprintf('PC%d', x), 1:n_attr, 'UniformOutput', false), ...
        'RowNames', attr_labels);
    writetable(loading_table, fullfile(output_dir, 'pca_loadings.xlsx'), ...
        'WriteRowNames', true);
    
    % 调用工具函数: 按 abs(loading) 降序重排 + 写入新 sheet
    reformat_pca_loadings(fullfile(output_dir, 'pca_loadings.xlsx'));
    
    fprintf('  数值结果已保存到: %s\n', output_dir);
end
