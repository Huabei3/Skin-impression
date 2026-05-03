% analyze_table_diff2.m
% 分析 VIVO_table 有但 VIVO_noCAT_table 无的行

clear; clc;

load('D:\work\VIVOskinExpe\analyze\AnalyseResults_p\efit_p\scaled\resTable\Peggy_VIVO_table.mat', 'fit_table');
VIVO_table = fit_table;

load('D:\work\VIVOskinExpe\analyze\AnalyseResults_p\noCAT\scaled\no_fit\resTable\original_unscaled\Peggy_VIVO_table.mat', 'fit_table');
VIVO_noCAT_table = fit_table;

fprintf('VIVO_table 行数: %d\n', height(VIVO_table));
fprintf('VIVO_noCAT_table 行数: %d\n', height(VIVO_noCAT_table));

% 生成组合键 (model_id + scene + observer_type + attribute)
% 字段是 cell 套 string，先用 cellfun 转 char 再拼接
keys_table  = strcat(cellfun(@char, VIVO_table.model_id, 'UniformOutput', false), '_', ...
                     cellfun(@char, VIVO_table.scene, 'UniformOutput', false), '_', ...
                     cellfun(@char, VIVO_table.observer_type, 'UniformOutput', false), '_', ...
                     cellfun(@char, VIVO_table.attribute, 'UniformOutput', false));

keys_noCAT = strcat(cellfun(@char, VIVO_noCAT_table.model_id, 'UniformOutput', false), '_', ...
                     cellfun(@char, VIVO_noCAT_table.scene, 'UniformOutput', false), '_', ...
                     cellfun(@char, VIVO_noCAT_table.observer_type, 'UniformOutput', false), '_', ...
                     cellfun(@char, VIVO_noCAT_table.attribute, 'UniformOutput', false));

% 找出在 table 中但不在 noCAT 中的行索引
[in_table_not_noCAT, loc] = ismember(keys_table, keys_noCAT);
rows_only_in_table = find(~in_table_not_noCAT);
fprintf('\n===== VIVO_table 有但 VIVO_noCAT_table 无的行数: %d =====\n', length(rows_only_in_table));

if ~isempty(rows_only_in_table)
    diff_table = VIVO_table(rows_only_in_table, :);
    
    % 按 model_id 统计
    fprintf('\n--- 按 model_id 统计 ---\n');
    model_ids = unique(diff_table.model_id);
    for i = 1:length(model_ids)
        cnt = sum(strcmp(diff_table.model_id, model_ids{i}));
        fprintf('  %s: %d 行\n', char(model_ids{i}), cnt);
    end
    
    % 按 observer_type 统计
    fprintf('\n--- 按 observer_type 统计 ---\n');
    obs_types = unique(diff_table.observer_type);
    for i = 1:length(obs_types)
        cnt = sum(strcmp(diff_table.observer_type, obs_types{i}));
        fprintf('  %s: %d 行\n', char(obs_types{i}), cnt);
    end
    
    % 按 scene 统计
    fprintf('\n--- 按 scene 统计 ---\n');
    scenes = unique(diff_table.scene);
    for i = 1:length(scenes)
        cnt = sum(strcmp(diff_table.scene, scenes{i}));
        fprintf('  %s: %d 行\n', char(scenes{i}), cnt);
    end
    
    % 按 attribute 统计
    fprintf('\n--- 按 attribute 统计 ---\n');
    attrs = unique(diff_table.attribute);
    for i = 1:length(attrs)
        cnt = sum(strcmp(diff_table.attribute, attrs{i}));
        fprintf('  %s: %d 行\n', char(attrs{i}), cnt);
    end
    
    % 保存差异行到文件
    save('D:\work\VIVOskinExpe\skin_model\evaluation_rendering\render_code\table_diff_rows.mat', 'diff_table');
    fprintf('\n差异行已保存到 table_diff_rows.mat\n');
    
    % 显示所有差异行的详细信息
    fprintf('\n--- 所有差异行详细信息 ---\n');
    disp(diff_table(:, {'model_id', 'scene', 'observer_type', 'attribute'}));
else
    fprintf('没有差异行。\n');
end

fprintf('\n分析完成。\n');
