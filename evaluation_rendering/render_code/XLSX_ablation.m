%% XLSX_ablation.m
%  从不同 ablation_type 的结果 XLSX 中提取汇总数据，生成一张对比表
%
%  输出路径: D:\work\VIVOskinExpe\skin_model\data\correlation_results\fullpara\efit_p\new\ACSA\each_self\ablation_comparison.xlsx
%
%  表结构:
%  ─────────────────────────────────────────────────────────────────
%            | Lab r | Lab RMSE | Lab ΔE | Field r | Field RMSE | Field ΔE
%  ─────────────────────────────────────────────────────────────────
%  scene_types     ...     ...       ...      ...       ...        ...
%  no_scene_types  ...     ...       ...      ...       ...        ...
%  full_CAT        ...     ...       ...      ...       ...        ...
%  no_nation       ...     ...       ...      ...       ...        ...
%  no_L_depend     ...     ...       ...      ...       ...        ...
%  ─────────────────────────────────────────────────────────────────
%
%  数据来源: 每个 ablation_type/{iOr}_non_model_{metric}.xlsx 的 "mean" sheet
%            → 末行末列 = 所有 model × 所有光源 × 所有属性的全局均值

clear; clc;

%% 配置
base_dir = 'D:\work\VIVOskinExpe\skin_model\data\correlation_results\fullpara\efit_p\new\ACSA\each_self';
obs_type = 'non_model';
metrics  = {'r', 'rmse', 'dE'};       % 指标后缀
iOrs     = {'i', 'r'};                 % i = 实景(illumination), o = 实验室(observe)
ablation_types = {'scene_types', 'no_scene_types', 'full_CAT', 'no_nation', 'no_L_depend'};
% ablation_types = { 'no_nation'};
% 列标题
col_headers = {'Lab r', 'Lab RMSE', 'Lab ΔE', 'Field r', 'Field RMSE', 'Field ΔE'};

% iOr 到展示名的映射（iOr 在文件名中: i=室内/实验, o=室外/实景）
% 根据 predict_fullpara_ablation.m 的 iOrs=['i','r']，但实际输出文件名用 iOr
% 用户描述: "实验室内" = o (observe, 室内可控光源), "实景" = i (illumination, 室外)


%% 提取数据
n_ablation = length(ablation_types);
result = NaN(n_ablation, 6);  % 6列: lab_r, lab_rmse, lab_dE, field_r, field_rmse, field_dE

for i = 1:n_ablation
    atype = ablation_types{i};
    fprintf('处理 %s ...\n', atype);

    col_idx_lab   = 0;
    col_idx_field = 3;

    for m = 1:3
        metric = metrics{m};

        % --- Lab (室内) ---
        fname_lab = fullfile(base_dir, atype, sprintf('%s%s_%s.xlsx', "i", obs_type, metric));
        val_lab = read_mean_sheet_tail(fname_lab);
        result(i, col_idx_lab + m) = val_lab;

        % --- Field (实景) ---
        fname_field = fullfile(base_dir, atype, sprintf('%s%s_%s.xlsx', "r", obs_type, metric));
        val_field = read_mean_sheet_tail(fname_field);
        result(i, col_idx_field + m) = val_field;
    end
end

%% 构建输出表格
T = array2table(result, 'VariableNames', col_headers, 'RowNames', ablation_types);

%% 保存
output_path = fullfile(base_dir, 'ablation_comparison.xlsx');
writetable(T, output_path, 'WriteRowNames', true);
fprintf('\n✅ 已保存到: %s\n', output_path);

%% 显示
disp(T);

%% ========== 辅助函数 ==========
function val = read_mean_sheet_tail(xlsx_path)
% 读取 xlsx_path 中名为 "mean" 的 sheet，返回末行末列的数值
% 如果不存在 mean sheet 或读取失败，返回 NaN

    val = NaN;

    if ~exist(xlsx_path, 'file')
        fprintf('  ⚠ 文件不存在: %s\n', xlsx_path);
        return;
    end

    try
        % 检查是否有 mean sheet
        [~, sheets] = xlsfinfo(xlsx_path);
        if ~ismember('mean', sheets)
            fprintf('  ⚠ 未找到 mean sheet: %s\n', xlsx_path);
            return;
        end

        % 读取 mean sheet
        T = readtable(xlsx_path, 'Sheet', 'mean');

        % 取最后一行最后一列的数值
        % 注意: writetable 带 WriteRowNames=true 时，第一列是行名
        % 最后一列是数据列（排除行名列），最后一行是 mean 行
        last_row = height(T);
        data_cols = T.Properties.VariableNames;  % 排除了行名列
        last_col = data_cols{end};

        v = T{last_row, last_col};
        if isnumeric(v)
            val = v;
        else
            num = str2double(char(v));
            if ~isnan(num)
                val = num;
            else
                fprintf('  ⚠ 无法解析数值 (%s): %s\n', xlsx_path, char(v));
            end
        end
    catch ME
        fprintf('  ⚠ 读取失败 (%s): %s\n', xlsx_path, ME.message);
    end
end
