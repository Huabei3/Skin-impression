%% organize_pca_figures.m
% 后处理: 将 PCA 分析输出的图片整理到分类文件夹 + 生成2×2拼接图
%
% 用法: organize_pca_figures(base_dir, iOr_dirname, race_defs, text_language)
%       text_language = 'eng' | 'ch'  → 控制所有文字语言
%
% Kenzie, 2026-06-16

function organize_pca_figures(base_dir, iOr_dirname, race_defs, text_language)

% 标签定义: 从外部传入 text_language ('eng'/'ch')
if nargin < 4
    text_language = 'eng';  % 默认英文
end

if strcmp(text_language, 'ch')
    race_labels_short = {'亚洲人', '高加索人', '南亚人', '非洲人'};
else
    race_labels_short = {'Asian', 'Caucasian', 'South Asian', 'African'};
end

    iOr_path = fullfile(base_dir, iOr_dirname);
    if ~exist(iOr_path, 'dir')
        warning('目录不存在: %s, 跳过', iOr_path);
        return;
    end
    
    % ===== 确定环境后缀 (sepaiOr_1 时可能有 i/r) =====
    all_subdirs = dir(iOr_path);
    all_subdirs = all_subdirs([all_subdirs.isdir]);
    all_subdirs = all_subdirs(~ismember({all_subdirs.name}, {'.', '..'}));
    
    % 收集所有非 comparison、非 figures、非 _cache 的子目录作为分析结果目录
    result_dirs = {};
    env_tags = {};
    for d = 1:length(all_subdirs)
        name = all_subdirs(d).name;
        if ~startsWith(name, 'comparison') && ~startsWith(name, 'figures') ...
                && ~startsWith(name, '_')
            result_dirs{end+1} = name; %#ok<AGROW>
            % 提取环境标签 (i/r)
            if endsWith(name, '_i')
                env_tags{end+1} = 'i'; %#ok<AGROW>
            elseif endsWith(name, '_r')
                env_tags{end+1} = 'r'; %#ok<AGROW>
            else
                env_tags{end+1} = ''; %#ok<AGROW>
            end
        end
    end
    
    if isempty(result_dirs)
        fprintf('  无分析结果子目录, 跳过\n');
        return;
    end
    
    % 获取唯环境标签
    unique_envs = unique(env_tags);
    unique_envs = unique_envs(~cellfun(@isempty, unique_envs));
    if isempty(unique_envs)
        unique_envs = {''};  % 无环境区分
    end
    
    % ===== 对每个环境分别整理 =====
    for e = 1:length(unique_envs)
        env = unique_envs{e};
        if isempty(env)
            env_suffix = '';
            env_label = '';
        else
            env_suffix = ['_', env];
            env_label = ['_', env];
        end
        
        % 该环境下的结果目录
        if isempty(env)
            env_result_dirs = result_dirs;
        else
            env_match = strcmp(env_tags, env);
            env_result_dirs = result_dirs(env_match);
        end
        
        % 子文件夹名映射: 00_merged, 01_AS, 02_CA, 03_SA, 04_AF
        race_short = containers.Map;
        race_short('00_merged') = 'merged';
        for r = 1:size(race_defs, 1)
            race_short(race_defs{r, 3}) = race_defs{r, 1};  % 01_AS -> AS, etc.
        end
        
        % ===== 图类型定义 =====
        fig_types = {
            'pca_score_pc23.png',       'pca_score_pc23';
            'pca_loadings_heatmap.png', 'loading_heatmap';
            'correlation_heatmap.png',  'correlation_heatmap';
            'pca_scree_plot.png',       'scree_plot';
        };
        
        % ===== 创建分类文件夹 =====
        figures_base = fullfile(iOr_path, ['figures', env_suffix]);
        
        folder_names = {'pca_score_pc23', 'loading_heatmap', 'correlation_heatmap', 'scree_plot', 'figs', 'comparison', 'montage'};
        for f = 1:length(folder_names)
            fpath = fullfile(figures_base, folder_names{f});
            if ~exist(fpath, 'dir')
                mkdir(fpath);
            end
        end
        
        fprintf('\n=== 整理图片 [%s%s] ===\n', iOr_dirname, env_label);
        
        % ===== 复制 PNG 到分类文件夹 =====
        for d = 1:length(env_result_dirs)
            src_subdir = env_result_dirs{d};
            
            % 去除 _i / _r 后缀以获得基础子目录名 (如 01_AS_i -> 01_AS)
            base_subdir = src_subdir;
            if endsWith(base_subdir, '_i') || endsWith(base_subdir, '_r')
                base_subdir = base_subdir(1:end-2);
            end
            
            if ~isKey(race_short, base_subdir)
                continue;
            end
            short_name = race_short(base_subdir);
            src_dir = fullfile(iOr_path, src_subdir);
            
            % 复制各类型 PNG
            for t = 1:size(fig_types, 1)
                src_file = fullfile(src_dir, fig_types{t, 1});
                dst_folder = fullfile(figures_base, fig_types{t, 2});
                dst_file = fullfile(dst_folder, [short_name, env_suffix, '.png']);
                if exist(src_file, 'file')
                    copyfile(src_file, dst_file);
                end
            end
            
            % 复制所有 .fig 文件到 figs/
            fig_files = dir(fullfile(src_dir, '*.fig'));
            for ff = 1:length(fig_files)
                src_fig = fullfile(src_dir, fig_files(ff).name);
                [~, fname, ~] = fileparts(fig_files(ff).name);
                dst_fig = fullfile(figures_base, 'figs', [short_name, env_suffix, '_', fname, '.fig']);
                copyfile(src_fig, dst_fig);
            end
        end
        
        % 复制 comparison 图
        comp_src_dir = fullfile(iOr_path, ['comparison', env_suffix]);
        if exist(comp_src_dir, 'dir')
            comp_files = dir(fullfile(comp_src_dir, '*.png'));
            for cf = 1:length(comp_files)
                copyfile(fullfile(comp_src_dir, comp_files(cf).name), ...
                    fullfile(figures_base, 'comparison', comp_files(cf).name));
            end
            comp_fig_files = dir(fullfile(comp_src_dir, '*.fig'));
            for cf = 1:length(comp_fig_files)
                copyfile(fullfile(comp_src_dir, comp_fig_files(cf).name), ...
                    fullfile(figures_base, 'figs', comp_fig_files(cf).name));
            end
        end
        
        % ===== 生成 2×2 拼接图 (仅4个人种, 不含 merged) =====
        %   从 .fig 文件重建 → 去原标题 → 加人种标签 → 高清导出 → 拼图
        race_order = {'AS', 'CA', 'SA', 'AF'};
        
        % 图类型 → .fig 文件名后缀 映射
        fig_name_map = {
            'pca_score_pc23',       'pca_score_pc23';
            'loading_heatmap',      'pca_loadings_heatmap';
            'correlation_heatmap',  'correlation_heatmap';
            'scree_plot',           'pca_scree_plot';
        };
        fig_map = containers.Map(fig_name_map(:,1), fig_name_map(:,2));
        
        % 临时目录
        temp_dir = fullfile(figures_base, 'montage', '_temp');
        if ~exist(temp_dir, 'dir')
            mkdir(temp_dir);
        end
        
        for t = 1:size(fig_types, 1)
            fig_type_name = fig_types{t, 2};
            if ~isKey(fig_map, fig_type_name)
                continue;
            end
            fig_suffix = fig_map(fig_type_name);
            
            % 收集4个人种的 .fig 路径
            fig_paths = {};
            for r = 1:length(race_order)
                fig_file = fullfile(figures_base, 'figs', ...
                    [race_order{r}, env_suffix, '_', fig_suffix, '.fig']);
                if exist(fig_file, 'file')
                    fig_paths{end+1} = fig_file; %#ok<AGROW>
                end
            end
            
            if length(fig_paths) < 4
                continue;
            end
            
            % ---- Step 1: 从 .fig 逐个导出高清临时 PNG ----
            temp_pngs = cell(4, 1);
            fig_w = 5.5;  % inches, 单子图宽度
            fig_h = 4.5;  % inches, 单子图高度
            
            for r = 1:4
                src_fig = openfig(fig_paths{r}, 'invisible');
                
                % 调整尺寸
                set(src_fig, 'Units', 'inches', ...
                    'Position', [1, 1, fig_w, fig_h], ...
                    'Color', 'white');
                
                % 去除原 title，替换为简洁人种标签
                src_ax = findobj(src_fig, 'Type', 'axes');
                if ~isempty(src_ax)
                    src_ax = src_ax(1);
                    title(src_ax, race_labels_short{r}, ...
                        'FontSize', 14, 'FontWeight', 'bold');
                    set(src_ax, 'FontSize', 10);
                end
                
                % 高清导出
                temp_pngs{r} = fullfile(temp_dir, sprintf('_temp_%s_%d.png', fig_type_name, r));
                exportgraphics(src_fig, temp_pngs{r}, ...
                    'Resolution', 300, ...
                    'ContentType', 'image', ...
                    'BackgroundColor', 'white');
                close(src_fig);
            end
            
            % ---- Step 2: 读回4张高清图，拼成 2×2 ----
            imgs = cell(4, 1);
            for r = 1:4
                imgs{r} = imread(temp_pngs{r});
            end
            
            % 统一尺寸
            h_list = cellfun(@(x) size(x,1), imgs);
            w_list = cellfun(@(x) size(x,2), imgs);
            h_out = min(h_list);
            w_out = min(w_list);
            for r = 1:4
                if size(imgs{r},1) ~= h_out || size(imgs{r},2) ~= w_out
                    imgs{r} = imresize(imgs{r}, [h_out, w_out]);
                end
            end
            
            % 添加间距 (约一个 textFont = ~15px 白色分隔)
            gap_h = round(h_out * 0.04);  % 水平间距
            gap_v = round(h_out * 0.04);  % 垂直间距
            
            % 创建白色分隔条
            gap_col = 255 * ones(h_out, gap_h, 3, 'uint8');     % 水平分隔
            gap_row = 255 * ones(gap_v, w_out*2 + gap_h, 3, 'uint8'); % 垂直分隔
            
            top_row = [imgs{1}, gap_col, imgs{2}];
            bottom_row = [imgs{3}, gap_col, imgs{4}];
            montage_img = [top_row; gap_row; bottom_row];
            
            % 保存高清拼接图
            montage_file = fullfile(figures_base, 'montage', ...
                [fig_type_name, '_2x2', env_suffix, '.png']);
            imwrite(montage_img, montage_file, 'png');
            
            fprintf('  已生成 2×2: %s  (%d×%d px)\n', fig_type_name, ...
                size(montage_img, 2), size(montage_img, 1));
            
            % 清理临时文件
            for r = 1:4
                if exist(temp_pngs{r}, 'file')
                    delete(temp_pngs{r});
                end
            end
        end
        
        % 删除临时目录
        if exist(temp_dir, 'dir')
            rmdir(temp_dir, 's');
        end
        
        fprintf('  整理完成: %s\n', figures_base);
    end
    
    fprintf('\n  organize_pca_figures 完成\n');
end
