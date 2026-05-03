% analyze_diff_simple.m
% 只负责把差异行写入 Excel，不做任何 unique 操作

clear; clc;

load('D:\work\VIVOskinExpe\analyze\AnalyseResults_p\efit_p\scaled\resTable\Peggy_VIVO_table.mat', 'fit_table');
T1 = fit_table;  % VIVO_table

load('D:\work\VIVOskinExpe\analyze\AnalyseResults_p\noCAT\scaled\no_fit\resTable\original_unscaled\Peggy_VIVO_table.mat', 'fit_table');
T2 = fit_table;  % VIVO_noCAT_table

fprintf('VIVO_table 行数: %d\n', height(T1));
fprintf('VIVO_noCAT_table 行数: %d\n', height(T2));

% 方法：直接逐行比较四个字段，找出 T1 有但 T2 无的行
% 这样做可以避免 cell/string 嵌套导致的 unique 报错
count_only_T1 = 0;
count_only_T2 = 0;

% 为了效率，先构建 T2 的 key set（用普通 cellstr）
keys2_cell = {};
for i = 1:height(T2)
    k = sprintf('%s|%s|%s|%s', ...
        char(T2.model_id{i}), char(T2.scene{i}), ...
        char(T2.observer_type{i}), char(T2.attribute{i}));
    keys2_cell{i} = k;
end
keys2_set = containers.Map(keys2_cell, 1:height(T2));

fprintf('正在比较...\n');

% 找出 T1 有但 T2 无的行
diff_rows = [];
for i = 1:height(T1)
    k = sprintf('%s|%s|%s|%s', ...
        char(T1.model_id{i}), char(T1.scene{i}), ...
        char(T1.observer_type{i}), char(T1.attribute{i}));
    if ~isKey(keys2_set, k)
        diff_rows = [diff_rows; i];  %#ok<AGROW>
    end
end

fprintf('T1 有但 T2 无的行数: %d\n', length(diff_rows));

if ~isempty(diff_rows)
    diff_T1 = T1(diff_rows, {'model_id', 'scene', 'observer_type', 'attribute'});
    output_file = 'D:\work\VIVOskinExpe\skin_model\evaluation_rendering\render_code\table_diff.xlsx';
    writetable(diff_T1, output_file);
    fprintf('差异行已写入: %s\n', output_file);
    
    % 用 containers.Map 做统计（避免 unique 报错）
    % 按 model_id 统计
    fprintf('\n--- 按 model_id 统计 ---\n');
    map_m = containers.Map;
    for i = 1:length(diff_rows)
        m = char(diff_T1.model_id{i});
        if isKey(map_m, m)
            map_m(m) = map_m(m) + 1;
        else
            map_m(m) = 1;
        end
    end
    keys_m = map_m.keys;
    for i = 1:length(keys_m)
        fprintf('  %s: %d 行\n', keys_m{i}, map_m(keys_m{i}));
    end
    
    % 按 observer_type 统计
    fprintf('\n--- 按 observer_type 统计 ---\n');
    map_o = containers.Map;
    for i = 1:length(diff_rows)
        o = char(diff_T1.observer_type{i});
        if isKey(map_o, o)
            map_o(o) = map_o(o) + 1;
        else
            map_o(o) = 1;
        end
    end
    keys_o = map_o.keys;
    for i = 1:length(keys_o)
        fprintf('  %s: %d 行\n', keys_o{i}, map_o(keys_o{i}));
    end
    
    % 按 scene 统计
    fprintf('\n--- 按 scene 统计 ---\n');
    map_s = containers.Map;
    for i = 1:length(diff_rows)
        s = char(diff_T1.scene{i});
        if isKey(map_s, s)
            map_s(s) = map_s(s) + 1;
        else
            map_s(s) = 1;
        end
    end
    keys_s = map_s.keys;
    for i = 1:length(keys_s)
        fprintf('  %s: %d 行\n', keys_s{i}, map_s(keys_s{i}));
    end
    
    % 按 attribute 统计
    fprintf('\n--- 按 attribute 统计 ---\n');
    map_a = containers.Map;
    for i = 1:length(diff_rows)
        a = char(diff_T1.attribute{i});
        if isKey(map_a, a)
            map_a(a) = map_a(a) + 1;
        else
            map_a(a) = 1;
        end
    end
    keys_a = map_a.keys;
    for i = 1:length(keys_a)
        fprintf('  %s: %d 行\n', keys_a{i}, map_a(keys_a{i}));
    end
end

% 找出 T2 有但 T1 无的行
fprintf('\n正在反向比较...\n');
keys1_cell = {};
for i = 1:height(T1)
    k = sprintf('%s|%s|%s|%s', ...
        char(T1.model_id{i}), char(T1.scene{i}), ...
        char(T1.observer_type{i}), char(T1.attribute{i}));
    keys1_cell{i} = k;
end
keys1_set = containers.Map(keys1_cell, 1:height(T1));

diff_rows2 = [];
for i = 1:height(T2)
    k = sprintf('%s|%s|%s|%s', ...
        char(T2.model_id{i}), char(T2.scene{i}), ...
        char(T2.observer_type{i}), char(T2.attribute{i}));
    if ~isKey(keys1_set, k)
        diff_rows2 = [diff_rows2; i];  %#ok<AGROW>
    end
end

fprintf('T2 有但 T1 无的行数: %d\n', length(diff_rows2));
if ~isempty(diff_rows2)
    diff_T2 = T2(diff_rows2, {'model_id', 'scene', 'observer_type', 'attribute'});
    output_file2 = 'D:\work\VIVOskinExpe\skin_model\evaluation_rendering\render_code\table_diff_noCAT_only.xlsx';
    writetable(diff_T2, output_file2);
    fprintf('T2 独有行已写入: %s\n', output_file2);
end

fprintf('\n完成。\n');
