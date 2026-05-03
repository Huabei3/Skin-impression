% analyze_diff_to_excel.m
% 分析 VIVO_table 有但 VIVO_noCAT_table 无的行，输出到 Excel

clear; clc;

load('D:\work\VIVOskinExpe\analyze\AnalyseResults_p\efit_p\scaled\resTable\Peggy_VIVO_table.mat', 'fit_table');
T1 = fit_table;

load('D:\work\VIVOskinExpe\analyze\AnalyseResults_p\noCAT\scaled\no_fit\resTable\original_unscaled\Peggy_VIVO_table.mat', 'fit_table');
T2 = fit_table;

fprintf('VIVO_table 行数: %d\n', height(T1));
fprintf('VIVO_noCAT_table 行数: %d\n', height(T2));

% 生成组合键
keys1 = strcat(cellfun(@char, T1.model_id, 'UniformOutput', false), '_', ...
               cellfun(@char, T1.scene, 'UniformOutput', false), '_', ...
               cellfun(@char, T1.observer_type, 'UniformOutput', false), '_', ...
               cellfun(@char, T1.attribute, 'UniformOutput', false));

keys2 = strcat(cellfun(@char, T2.model_id, 'UniformOutput', false), '_', ...
               cellfun(@char, T2.scene, 'UniformOutput', false), '_', ...
               cellfun(@char, T2.observer_type, 'UniformOutput', false), '_', ...
               cellfun(@char, T2.attribute, 'UniformOutput', false));

% 在 T1 中但不在 T2 中的行
in_T2 = ismember(keys1, keys2);
rows_only_T1 = find(~in_T2);
fprintf('VIVO_table 有但 noCAT 无的行数: %d\n', length(rows_only_T1));

if ~isempty(rows_only_T1)
    % 提取差异行
    diff_T1 = T1(rows_only_T1, {'model_id', 'scene', 'observer_type', 'attribute'});
    
    % 输出到 Excel
    output_file = 'D:\work\VIVOskinExpe\skin_model\evaluation_rendering\render_code\table_diff.xlsx';
    writetable(diff_T1, output_file);
    fprintf('差异行已写入: %s\n', output_file);
    
    % 统计
    fprintf('\n--- 按 model_id 统计 ---\n');
    [models, ~, idx_m] = unique(diff_T1.model_id);
    for i = 1:length(models)
        fprintf('  %s: %d 行\n', string(models{i}), sum(idx_m == i));
    end
    
    fprintf('\n--- 按 observer_type 统计 ---\n');
    [obs, ~, idx_o] = unique(diff_T1.observer_type);
    for i = 1:length(obs)
        fprintf('  %s: %d 行\n', string(obs{i}), sum(idx_o == i));
    end
    
    fprintf('\n--- 按 scene 统计 ---\n');
    [scenes, ~, idx_s] = unique(diff_T1.scene);
    for i = 1:length(scenes)
        fprintf('  %s: %d 行\n', string(scenes{i}), sum(idx_s == i));
    end
    
    fprintf('\n--- 按 attribute 统计 ---\n');
    [attrs, ~, idx_a] = unique(diff_T1.attribute);
    for i = 1:length(attrs)
        fprintf('  %s: %d 行\n', string(attrs{i}), sum(idx_a == i));
    end
else
    fprintf('没有差异行。\n');
end

% 反过来：在 T2 中但不在 T1 中的行
in_T1 = ismember(keys2, keys1);
rows_only_T2 = find(~in_T1);
fprintf('\nVIVO_noCAT_table 有但 VIVO_table 无的行数: %d\n', length(rows_only_T2));

if ~isempty(rows_only_T2)
    diff_T2 = T2(rows_only_T2, {'model_id', 'scene', 'observer_type', 'attribute'});
    output_file2 = 'D:\work\VIVOskinExpe\skin_model\evaluation_rendering\render_code\table_diff_noCAT_only.xlsx';
    writetable(diff_T2, output_file2);
    fprintf('noCAT 独有行已写入: %s\n', output_file2);
end

fprintf('\n完成。\n');
