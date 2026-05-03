% analyze_table_diff.m
% 分析 VIVO_table 有但 VIVO_noCAT_table 无的行

clear; clc;

% 加载两个 table
load('D:\work\VIVOskinExpe\analyze\AnalyseResults_p\efit_p\scaled\resTable\Peggy_VIVO_table.mat', 'fit_table');
VIVO_table = fit_table;

load('D:\work\VIVOskinExpe\analyze\AnalyseResults_p\noCAT\scaled\no_fit\resTable\original_unscaled\Peggy_VIVO_table.mat', 'fit_table');
VIVO_noCAT_table = fit_table;

fprintf('VIVO_table 行数: %d\n', height(VIVO_table));
fprintf('VIVO_noCAT_table 行数: %d\n', height(VIVO_noCAT_table));

% 找出 VIVO_table 有但 VIVO_noCAT_table 无的行
% 通过组合键 (model_id, scene, observer_type, attribute) 来匹配

keys_table = strcat(string(VIVO_table.model_id), '_', ...
                    string(VIVO_table.scene), '_', ...
                    string(VIVO_table.observer_type), '_', ...
                    string(VIVO_table.attribute));

keys_noCAT = strcat(string(VIVO_noCAT_table.model_id), '_', ...
                     string(VIVO_noCAT_table.scene), '_', ...
                     string(VIVO_noCAT_table.observer_type), '_', ...
                     string(VIVO_noCAT_table.attribute));

% 找出在 table 中但不在 noCAT 中的 key
in_table_not_noCAT = ~ismember(keys_table, keys_noCAT);
fprintf('\n===== VIVO_table 有但 VIVO_noCAT_table 无的行数: %d =====\n', sum(in_table_not_noCAT));

if sum(in_table_not_noCAT) > 0
    diff_table = VIVO_table(in_table_not_noCAT, :);
    
    % 按 model_id 统计
    fprintf('\n--- 按 model_id 统计 ---\n');
    model_ids = unique(diff_table.model_id);
    for i = 1:length(model_ids)
        cnt = sum(strcmp(diff_table.model_id, model_ids{i}));
        fprintf('  %s: %d 行\n', string(model_ids{i}), cnt);
    end
    
    % 按 observer_type 统计
    fprintf('\n--- 按 observer_type 统计 ---\n');
    obs_types = unique(diff_table.observer_type);
    for i = 1:length(obs_types)
        cnt = sum(strcmp(diff_table.observer_type, obs_types{i}));
        fprintf('  %s: %d 行\n', string(obs_types{i}), cnt);
    end
    
    % 按 scene 统计
    fprintf('\n--- 按 scene 统计 ---\n');
    scenes = unique(diff_table.scene);
    for i = 1:length(scenes)
        cnt = sum(strcmp(diff_table.scene, scenes{i}));
        fprintf('  %s: %d 行\n', string(scenes{i}), cnt);
    end
    
    % 按 attribute 统计
    fprintf('\n--- 按 attribute 统计 ---\n');
    attrs = unique(diff_table.attribute);
    for i = 1:length(attrs)
        cnt = sum(strcmp(diff_table.attribute, attrs{i}));
        fprintf('  %s: %d 行\n', string(attrs{i}), cnt);
    end
    
    % 保存差异行到文件
    save('table_diff_rows.mat', 'diff_table');
    fprintf('\n差异行已保存到 table_diff_rows.mat\n');
    
    % 显示前10行详细信息
    fprintf('\n--- 前10行详细信息 ---\n');
    disp(diff_table(1:min(10,height(diff_table)), {'model_id', 'scene', 'observer_type', 'attribute'}));
end

% 反过来：找出 VIVO_noCAT_table 有但 VIVO_table 无的行
in_noCAT_not_table = ~ismember(keys_noCAT, keys_table);
fprintf('\n===== VIVO_noCAT_table 有但 VIVO_table 无的行数: %d =====\n', sum(in_noCAT_not_table));

if sum(in_noCAT_not_table) > 0
    diff_table2 = VIVO_noCAT_table(in_noCAT_not_table, :);
    fprintf('前10行详细信息:\n');
    disp(diff_table2(1:min(10,height(diff_table2)), {'model_id', 'scene', 'observer_type', 'attribute'}));
end

fprintf('\n分析完成。\n');
