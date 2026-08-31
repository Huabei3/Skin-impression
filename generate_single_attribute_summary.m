%% generate_single_attribute_summary.m
% 生成 single_attribute 模型对比汇总表
% 列: 4人种×i, 4人种×r, 4人种×combined
% 行: conventional, max, sing_model, 5 model_variations, single_ellipse, DBCNN, MANIQA
close all; clc; clear;

%% 配置
nations_en = {'AS', 'CA', 'SA', 'AF'};
n_models  = [21, 14];  % i有21个scene, r有14个scene
w_i = n_models(1);
w_r = n_models(2);
w_total = w_i + w_r;

% conventional 数据文件
conv_file = fullfile('D:\work\VIVOskinExpe\skin_model\data\correlation_results', ...
    'fullpara_devide_validation', 'efit_p', 'new', 'devide_validation', ...
    'validation_prediction_results.xlsx');

% sing_model 数据目录
sing_dir = fullfile('D:\work\VIVOskinExpe\skin_model\data\correlation_results', ...
    'fullpara_devide_validation', 'efit_p', 'new', 'devide_validation', 'sing_head');

% single_ellipse 数据基础目录
ellipse_base = fullfile('D:\work\VIVOskinExpe\analyze\AnalyseResults_p', ...
    'efit_p', 'unscaled');

% 每个人种对应的验证模特
validation_models = {'m05', 'm02', 'm08', 'm09'};

% 输出文件
output_dir = fullfile('D:\work\VIVOskinExpe\skin_model\data\correlation_results', ...
    'fullpara_devide_validation', 'efit_p', 'new', 'devide_validation');
output_file = fullfile(output_dir, 'single_attribute_summary.xlsx');

%% model_variation 列表
model_variations = {'full_v1_loss_mask', 'full_v3_loss_mask', ...
    'ablation_concat_loss_mask_v3', 'ablation_face_only_loss_mask_v3', ...
    'ablation_resnet50_loss_mask_v3', ...
    'ablation_mobilenetv3s_v3', 'ablation_se_fusion_v3', ...
    'ablation_stat_stream_v3', 'ablation_vitb16_v3', ...
    'ablation_cross_attn_v3', ...
    'ablation_lab_center_v3', 'ablation_bce_loss_v3', ...
    'ablation_mscman_backbone_v3'};
n_variations = length(model_variations);

% model_variation 数据目录
var_dir = fullfile(output_dir, 'test_results');

% DBCNN 数据文件 (在 test_results_old 下)
pred_full_file = fullfile(output_dir, 'test_results_old', 'test_predictions_full');

% 对比模型 (NIMA / TOPIQ_NR_Face / TReS / MANIQA) 数据目录 (直接在 output_dir 下)
cmp_models = {'NIMA', 'TOPIQ_NR_Face', 'TReS'};
n_cmp = length(cmp_models);
cmp_dir = fullfile(output_dir, 'results');

% 行索引定义
ROW_CONVENTIONAL = 2;
ROW_MAX = 3;
ROW_SING_MODEL = 4;
ROW_VAR_START = 5;           % model_variations 从 row5 开始
ROW_SINGLE_ELLIPSE = ROW_VAR_START + n_variations;
ROW_DBCNN = ROW_SINGLE_ELLIPSE + 1;
ROW_MANIQA = ROW_SINGLE_ELLIPSE + 2;
ROW_CMP_START = ROW_MANIQA + 1;      % 对比模型 NIMA/TOPIQ_NR_Face/TReS 起始行
n_rows = ROW_CMP_START + n_cmp - 1;  % 最后一个数据行的行号 = 总行数(含header)

%% 初始化结果: 12行(1 header + 11 model) × 14列(1 label + 12 data + 1 mean)
summary = cell(n_rows, 14);
summary{1, 1} = 'model';
col_offset = 0;
for k = 1:3
    if k == 1, suffix = '_i'; elseif k == 2, suffix = '_r'; else, suffix = '_all'; end
    for i = 1:4
        summary{1, col_offset + i + 1} = [nations_en{i}, suffix];
    end
    col_offset = col_offset + 4;
end
summary{1, 14} = 'mean';  % 末列: AS_all/CA_all/SA_all/AF_all 的平均

summary{ROW_CONVENTIONAL, 1} = 'conventional';
summary{ROW_MAX, 1} = 'max';
summary{ROW_SING_MODEL, 1} = 'sing_model';
for v = 1:n_variations
    summary{ROW_VAR_START + v - 1, 1} = model_variations{v};
end
summary{ROW_SINGLE_ELLIPSE, 1} = 'single_ellipse';
summary{ROW_DBCNN, 1} = 'DBCNN';
summary{ROW_MANIQA, 1} = 'MANIQA';
for m = 1:n_cmp
    summary{ROW_CMP_START + m - 1, 1} = cmp_models{m};
end

%% a) conventional: 从 validation_prediction_results.xlsx 读取
fprintf('===== a) conventional =====\n');
for i_nation = 1:4
    nation = nations_en{i_nation};

    % i 类型: {nation} sheet, Preference列, mean行=最后一行
    % 使用 readtable 正确处理首行表头 + 首列文本 (scene名和"mean")
    try
        T_i = readtable(conv_file, 'Sheet', nation);
        val_i = T_i.Preference(end);
    catch
        % fallback: readcell 取最后一行的第2列
        C_i = readcell(conv_file, 'Sheet', nation);
        val_i = C_i{end, 2};
    end
    fprintf('  %s_i: %.6f\n', nation, val_i);

    % r 类型: {nation}_r sheet
    try
        T_r = readtable(conv_file, 'Sheet', [nation, '_r']);
        val_r = T_r.Preference(end);
    catch
        C_r = readcell(conv_file, 'Sheet', [nation, '_r']);
        val_r = C_r{end, 2};
    end
    fprintf('  %s_r: %.6f\n', nation, val_r);

    % 加权平均 (21*i + 14*r) / 35 ≈ 3:2
    val_comb = (w_i * val_i + w_r * val_r) / w_total;
    fprintf('  %s_all: %.6f\n', nation, val_comb);

    summary{ROW_CONVENTIONAL, 1 + i_nation} = val_i;       % i
    summary{ROW_CONVENTIONAL, 5 + i_nation} = val_r;       % r
    summary{ROW_CONVENTIONAL, 9 + i_nation} = val_comb;    % combined
end

%% b) max: 从 max.xlsx 读取 all 数据，i和r留空
fprintf('\n===== b) max =====\n');
max_file = fullfile(output_dir, 'max.xlsx');
if exist(max_file, 'file')
    % 读取数据 (readcell 能同时处理数字和文本)
    C_max = readcell(max_file, 'Sheet', 'Sheet1');
    % 第1行是表头: 实验条件, AS, CA, SA, AF, all
    % 第2行是数据
    max_data = C_max(2, 2:5);  % AS, CA, SA, AF 四个单元格
    max_vals = zeros(1, 4);
    for j = 1:4
        val_raw = max_data{j};
        if isnumeric(val_raw)
            max_vals(j) = val_raw;
        elseif ischar(val_raw) || isstring(val_raw)
            % 提取前导数字 (如 "0.85（与AF平均）" → 0.85)
            num_str = regexp(char(val_raw), '^[\d.]+', 'match', 'once');
            if ~isempty(num_str)
                max_vals(j) = str2double(num_str);
            else
                max_vals(j) = NaN;
            end
        else
            max_vals(j) = NaN;
        end
        fprintf('  %s: %.4f\n', nations_en{j}, max_vals(j));
    end

    % i 和 r 留空 (不赋值 = 保持为 [] )
    % all 填入读取值
    for j = 1:4
        summary{ROW_MAX, 9 + j} = max_vals(j);  % combined
    end
else
    fprintf('  max.xlsx 文件不存在: %s\n', max_file);
end

%% c) sing_model: 从 test_results_{nation}.xlsx PerGroup sheet 读取
fprintf('\n===== c) sing_model =====\n');
for i_nation = 1:4
    nation = nations_en{i_nation};
    test_file = fullfile(sing_dir, sprintf('test_results_%s.xlsx', nation));

    if ~exist(test_file, 'file')
        fprintf('  文件不存在: %s\n', test_file);
        continue;
    end

    % 读取 PerGroup sheet
    T = readtable(test_file, 'Sheet', 'PerGroup');

    % 提取 iOr 和 Pearson_r 列
    iOr_col = string(T.iOr);
    r_col = T.Pearson_r;

    % 分组平均 (使用 contains 更健壮)
    val_i = nanmean(r_col(contains(iOr_col, 'i', 'IgnoreCase', true)));
    val_r = nanmean(r_col(contains(iOr_col, 'r', 'IgnoreCase', true)));
    val_all = nanmean(r_col);  % 所有行的平均

    fprintf('  %s: i=%.6f, r=%.6f, all=%.6f\n', nation, val_i, val_r, val_all);

    summary{ROW_SING_MODEL, 1 + i_nation} = val_i;
    summary{ROW_SING_MODEL, 5 + i_nation} = val_r;
    summary{ROW_SING_MODEL, 9 + i_nation} = val_all;
end

%% d) model_variations: 从 test_results_{var}_{nation}.xlsx 读取
fprintf('\n===== d) model_variations =====\n');
for v = 1:n_variations
    var_name = model_variations{v};
    fprintf('  --- %s ---\n', var_name);
    for i_nation = 1:4
        nation = nations_en{i_nation};
        var_file = fullfile(var_dir, sprintf('test_results_%s_%s.xlsx', var_name, nation));

        if ~exist(var_file, 'file')
            fprintf('    文件不存在: %s\n', var_file);
            continue;
        end

        % 读取 PerGroup_01Preference sheet
        T = readtable(var_file, 'Sheet', 'PerGroup_01Preference');
        iOr_col = string(T.iOr);
        r_col = T.Pearson_r;
        % 若含非数值(如"N/A"), readtable返回cell, 需转为数值
        if iscell(r_col)
            r_col_num = NaN(size(r_col));
            for kk = 1:numel(r_col)
                if isnumeric(r_col{kk})
                    r_col_num(kk) = r_col{kk};
                else
                    r_col_num(kk) = str2double(string(r_col{kk}));
                end
            end
            r_col = r_col_num;
        end

        % 分组平均
        val_i = nanmean(r_col(contains(iOr_col, 'i', 'IgnoreCase', true)));
        val_r = nanmean(r_col(contains(iOr_col, 'r', 'IgnoreCase', true)));
        val_all = nanmean(r_col);

        fprintf('    %s: i=%.6f, r=%.6f, all=%.6f\n', nation, val_i, val_r, val_all);

        summary{ROW_VAR_START + v - 1, 1 + i_nation} = val_i;
        summary{ROW_VAR_START + v - 1, 5 + i_nation} = val_r;
        summary{ROW_VAR_START + v - 1, 9 + i_nation} = val_all;
    end
end

%% e) single_ellipse: 从 fitRes.mat 读取 parNr_all(:,7) 均值
fprintf('\n===== e) single_ellipse =====\n');
for i_nation = 1:4
    model = validation_models{i_nation};

    % i 类型
    fitRes_file_i = fullfile(ellipse_base, [model, 'i'], 'non_model', ...
        '01Preference', 'ellipPara', 'fitRes.mat');
    if exist(fitRes_file_i, 'file')
        data = load(fitRes_file_i);
        vals_i = data.parNr_all(:, 7);
        val_i = nanmean(vals_i);
        n_i = length(vals_i);
    else
        val_i = NaN;
        n_i = 0;
        fprintf('  %si 文件不存在\n', model);
    end

    % r 类型
    fitRes_file_r = fullfile(ellipse_base, [model, 'r'], 'non_model', ...
        '01Preference', 'ellipPara', 'fitRes.mat');
    if exist(fitRes_file_r, 'file')
        data = load(fitRes_file_r);
        vals_r = data.parNr_all(:, 7);
        val_r = nanmean(vals_r);
        n_r = length(vals_r);
    else
        val_r = NaN;
        n_r = 0;
        fprintf('  %sr 文件不存在\n', model);
    end

    % 加权平均
    if ~isnan(val_i) && ~isnan(val_r)
        val_comb = (n_i * val_i + n_r * val_r) / (n_i + n_r);
    elseif ~isnan(val_i)
        val_comb = val_i;
    elseif ~isnan(val_r)
        val_comb = val_r;
    else
        val_comb = NaN;
    end

    fprintf('  %s: i=%.6f (%d scenes), r=%.6f (%d scenes), all=%.6f\n', ...
        model, val_i, n_i, val_r, n_r, val_comb);

    summary{ROW_SINGLE_ELLIPSE, 1 + i_nation} = val_i;
    summary{ROW_SINGLE_ELLIPSE, 5 + i_nation} = val_r;
    summary{ROW_SINGLE_ELLIPSE, 9 + i_nation} = val_comb;
end

%% f) DBCNN: 从 test_predictions_full → DBCNN_{nation}_test sheet 读取 PLCC
fprintf('\n===== f) DBCNN =====\n');
for i_nation = 1:4
    nation = nations_en{i_nation};
    dbcnn_sheet = sprintf('DBCNN_%s_test', nation);
    try
        T = readtable(pred_full_file, 'Sheet', dbcnn_sheet, 'FileType', 'spreadsheet');
        scene_col = string(T.scene);
        plcc_vals = T.PLCC;

        % i: h3k ~ md65 (不以 'rs' 开头)
        mask_i = ~startsWith(scene_col, 'rs');
        val_i = nanmean(plcc_vals(mask_i));
        % r: rs01 ~ rs14 (以 'rs' 开头)
        mask_r = startsWith(scene_col, 'rs');
        val_r = nanmean(plcc_vals(mask_r));
        % all: 全部行
        val_all = nanmean(plcc_vals);

        fprintf('  %s: i=%.6f, r=%.6f, all=%.6f\n', nation, val_i, val_r, val_all);
    catch
        fprintf('  %s: Sheet %s 读取失败\n', nation, dbcnn_sheet);
        val_i = NaN; val_r = NaN; val_all = NaN;
    end

    summary{ROW_DBCNN, 1 + i_nation} = val_i;
    summary{ROW_DBCNN, 5 + i_nation} = val_r;
    summary{ROW_DBCNN, 9 + i_nation} = val_all;
end

%% g) MANIQA: 从 cmp_dir (与NIMA/TOPIQ_NR_Face/TReS同目录) 读取
fprintf('\n===== g) MANIQA =====\n');
for i_nation = 1:4
    nation = nations_en{i_nation};
    maniqa_file = fullfile(cmp_dir, sprintf('test_MANIQA_%s.xlsx', nation));

    if ~exist(maniqa_file, 'file')
        fprintf('  文件不存在: %s\n', maniqa_file);
        continue;
    end

    % 读取 PerGroup sheet: Model | iOr | Scene | n_samples | Pearson_r | MAE
    T = readtable(maniqa_file, 'Sheet', 'PerGroup');
    iOr_col = string(T.iOr);
    r_col = T.Pearson_r;
    % 若含非数值(如"N/A"), readtable返回cell, 需转为数值
    if iscell(r_col)
        r_col_num = NaN(size(r_col));
        for kk = 1:numel(r_col)
            if isnumeric(r_col{kk})
                r_col_num(kk) = r_col{kk};
            else
                r_col_num(kk) = str2double(string(r_col{kk}));
            end
        end
        r_col = r_col_num;
    end

    % 分组平均
    val_i = nanmean(r_col(contains(iOr_col, 'i', 'IgnoreCase', true)));
    val_r = nanmean(r_col(contains(iOr_col, 'r', 'IgnoreCase', true)));
    val_all = nanmean(r_col);

    fprintf('  %s: i=%.6f, r=%.6f, all=%.6f\n', nation, val_i, val_r, val_all);

    summary{ROW_MANIQA, 1 + i_nation} = val_i;
    summary{ROW_MANIQA, 5 + i_nation} = val_r;
    summary{ROW_MANIQA, 9 + i_nation} = val_all;
end

%% h) 对比模型 NIMA / TOPIQ_NR_Face / TReS: 从 results\test_{model}_{nation}.xlsx PerGroup sheet 读取
fprintf('\n===== h) 对比模型 (NIMA / TOPIQ_NR_Face / TReS) =====\n');
for m = 1:n_cmp
    cmp_name = cmp_models{m};
    fprintf('  --- %s ---\n', cmp_name);
    for i_nation = 1:4
        nation = nations_en{i_nation};
        cmp_file = fullfile(cmp_dir, sprintf('test_%s_%s.xlsx', cmp_name, nation));

        if ~exist(cmp_file, 'file')
            fprintf('    文件不存在: %s\n', cmp_file);
            continue;
        end

        % 读取 PerGroup sheet: Model | iOr | Scene | n_samples | Pearson_r | MAE
        T = readtable(cmp_file, 'Sheet', 'PerGroup');
        iOr_col = string(T.iOr);
        r_col = T.Pearson_r;
        % 若含非数值(如"N/A"), readtable返回cell, 需转为数值
        if iscell(r_col)
            r_col_num = NaN(size(r_col));
            for kk = 1:numel(r_col)
                if isnumeric(r_col{kk})
                    r_col_num(kk) = r_col{kk};
                else
                    r_col_num(kk) = str2double(string(r_col{kk}));
                end
            end
            r_col = r_col_num;
        end

        % 分组平均
        val_i = nanmean(r_col(contains(iOr_col, 'i', 'IgnoreCase', true)));
        val_r = nanmean(r_col(contains(iOr_col, 'r', 'IgnoreCase', true)));
        val_all = nanmean(r_col);

        fprintf('    %s: i=%.6f, r=%.6f, all=%.6f\n', nation, val_i, val_r, val_all);

        summary{ROW_CMP_START + m - 1, 1 + i_nation} = val_i;
        summary{ROW_CMP_START + m - 1, 5 + i_nation} = val_r;
        summary{ROW_CMP_START + m - 1, 9 + i_nation} = val_all;
    end
end

%% 计算 mean 列 (AS_all, CA_all, SA_all, AF_all 的平均, omitnan)
fprintf('\n===== 计算 mean 列 =====\n');
for row = 2:n_rows
    vals = {summary{row, 10}, summary{row, 11}, summary{row, 12}, summary{row, 13}};
    all_numeric = cellfun(@(x) isnumeric(x) && ~isempty(x), vals);
    if all(all_numeric)
        summary{row, 14} = nanmean(cell2mat(vals));
    else
        summary{row, 14} = NaN;
    end
    if isnumeric(summary{row, 14}) && ~isnan(summary{row, 14})
        fprintf('  %s: mean = %.4f\n', summary{row, 1}, summary{row, 14});
    else
        fprintf('  %s: mean = -\n', summary{row, 1});
    end
end

%% 保存 Sheet1
fprintf('\n===== 保存 Sheet1 =====\n');
writecell(summary, output_file);
fprintf('已保存 Sheet1: %s\n', output_file);

%% ========== 生成论文格式 Sheet2 ==========
fprintf('\n========== 生成论文格式 Sheet2 ==========\n');

% 新行头名称、对应 summary 行号、原始英文名
new_names  = {'STIM', 'Deepskin', ...
              '消融组1', '消融组2', '消融组3', '消融组4', '消融组5', ...
              '消融组6', '消融组7', '消融组8', '消融组9', '消融组10', ...
              '对照组1', '对照组2', '对照组3', '对照组4', '对照组5', '理论最优'};
src_rows   = [ROW_CONVENTIONAL, ROW_VAR_START+1, ...
              ROW_VAR_START+11, ...                                         % 消融组1: ablation_bce_loss_v3
              ROW_SING_MODEL, ...                                           % 消融组2: sing_model
              ROW_VAR_START+5, ...                                          % 消融组3: ablation_mobilenetv3s_v3
              ROW_VAR_START+4, ...                                          % 消融组4: ablation_resnet50_loss_mask_v3
              ROW_VAR_START+8, ...                                          % 消融组5: ablation_vitb16_v3
              ROW_VAR_START+9, ...                                          % 消融组6: ablation_cross_attn_v3
              ROW_VAR_START+6, ...                                          % 消融组7: ablation_se_fusion_v3
              ROW_VAR_START+0, ...                                          % 消融组8: full_v1_loss_mask
              ROW_VAR_START+3, ...                                          % 消融组9: ablation_face_only_loss_mask_v3
              ROW_VAR_START+7, ...                                          % 消融组10: ablation_stat_stream_v3
              ROW_DBCNN, ROW_MANIQA, ...
              ROW_CMP_START+0, ...                                          % 对照组3: NIMA
              ROW_CMP_START+1, ...                                          % 对照组4: TOPIQ_NR_Face
              ROW_CMP_START+2, ...                                          % 对照组5: TReS
              ROW_SINGLE_ELLIPSE];
orig_names = {'conventional', 'full_v3_loss_mask', ...
    'ablation_bce_loss_v3', 'sing_model', ...
    'ablation_mobilenetv3s_v3', 'ablation_resnet50_loss_mask_v3', ...
    'ablation_vitb16_v3', 'ablation_cross_attn_v3', ...
    'ablation_se_fusion_v3', 'full_v1_loss_mask', ...
    'ablation_face_only_loss_mask_v3', 'ablation_stat_stream_v3', ...
    'DBCNN', 'MANIQA', 'NIMA', 'TOPIQ_NR_Face', 'TReS', 'single_ellipse'};
n_new_models = length(new_names);

% 中文人种名
race_cn = {'亚洲人', '高加索人', '南亚人', '非洲人'};

% === 构建未转置表格: (n_new_models+1)行 × 15列 ===
% 列: 模型 | 亚洲人_i | ... | mean | 英文原名
paper_tab = cell(n_new_models + 1, 15);

% 表头
paper_tab{1, 1} = '模型';
co = 0;
for k = 1:3
    if k == 1, sfx = '_i'; elseif k == 2, sfx = '_r'; else, sfx = '_all'; end
    for j = 1:4
        paper_tab{1, co + j + 1} = [race_cn{j}, sfx];
    end
    co = co + 4;
end
paper_tab{1, 14} = 'mean';
paper_tab{1, 15} = '英文原名';

% 填充数据
for i = 1:n_new_models
    r = src_rows(i);
    paper_tab{i+1, 1} = new_names{i};
    for c = 2:14
        paper_tab{i+1, c} = summary{r, c};
    end
    paper_tab{i+1, 15} = orig_names{i};
    fprintf('  %s <- %s (%s)\n', new_names{i}, summary{r, 1}, orig_names{i});
end

% === 行列对换: 15行 × (n_new_models+1)列 ===
% 转置后: 每行是一个 metric, 每列是一个模型
n_paper_rows = 15;
n_paper_cols_before = n_new_models + 1;
paper_final = cell(n_paper_rows, n_paper_cols_before);
for r = 1:n_paper_rows
    for c = 1:n_paper_cols_before
        paper_final{r, c} = paper_tab{c, r};
    end
end

% === 拆分第一列: {人种}_{iOr} → 人种列 + iOr列 ===
n_paper_cols = n_paper_cols_before + 1;  % 11列
paper_split = cell(n_paper_rows, n_paper_cols);
for r = 1:n_paper_rows
    label = string(paper_final{r, 1});
    if r == 1
        paper_split{r, 1} = '人种';
        paper_split{r, 2} = 'iOr';
    elseif endsWith(label, '_i')
        paper_split{r, 1} = char(extractBefore(label, '_i'));
        paper_split{r, 2} = 'i';
    elseif endsWith(label, '_r')
        paper_split{r, 1} = char(extractBefore(label, '_r'));
        paper_split{r, 2} = 'r';
    elseif endsWith(label, '_all')
        paper_split{r, 1} = char(extractBefore(label, '_all'));
        paper_split{r, 2} = 'all';
    else
        % mean 或 英文原名: 人种列放标签, iOr列留空
        paper_split{r, 1} = paper_final{r, 1};
        paper_split{r, 2} = [];
    end
    for c = 2:n_paper_cols_before
        paper_split{r, c + 1} = paper_final{r, c};
    end
end

% 写入 Sheet2
writecell(paper_split, output_file, 'Sheet', '论文格式');
fprintf('已保存论文格式 Sheet\n');

%% 打印汇总表 (Sheet1)
fprintf('\n========== 汇总 (Sheet1) ==========\n');
fprintf('%-25s', 'model');
suffixes = {'_i', '_r', '_all'};
for k = 1:3
    for i_n = 1:4
        fprintf('  %-8s', [nations_en{i_n}, suffixes{k}]);
    end
end
fprintf('  %-8s', 'mean');
fprintf('\n');
for row = 2:n_rows
    fprintf('%-25s', summary{row, 1});
    for col = 2:14
        if ~isempty(summary{row, col}) && isnumeric(summary{row, col}) && ~isnan(summary{row, col})
            fprintf('  %8.4f', summary{row, col});
        else
            fprintf('  %8s', '-');
        end
    end
    fprintf('\n');
end

%% 打印论文格式 (Sheet2, 转置后)
fprintf('\n========== 论文格式 (Sheet2, 转置后) ==========\n');
for r = 1:n_paper_rows
    fprintf('%-8s', paper_split{r, 1});
    ior = paper_split{r, 2};
    if isempty(ior)
        fprintf('  %-4s', '');
    else
        fprintf('  %-4s', char(ior));
    end
    for c = 3:n_paper_cols
        val = paper_split{r, c};
        if ~isempty(val) && isnumeric(val) && ~isnan(val)
            fprintf('  %8.4f', val);
        elseif ischar(val) || isstring(val)
            fprintf('  %-20s', char(val));
        else
            fprintf('  %8s', '-');
        end
    end
    fprintf('\n');
end

%% ========== DeltaE 汇总 Sheet ==========
fprintf('\n========== DeltaE 汇总 Sheet ==========\n');

exp_names_de = {'ablation_lab_center_v3', 'ablation_bce_loss_v3'};
n_de_exps = length(exp_names_de);

attr_serials = {'01Preference', '02Attractiveness', '03Feminine', '04Cooperative', ...
    '05Youth', '06Healthy', '07Fidelity', '08Harmony', '09Fair', '10Ruddy'};
n_attrs = length(attr_serials);

de_types = {'DeltaE', 'DeltaE_PerGroup', 'DeltaE_RawData'};
n_de_types = length(de_types);

n_de_rows = 1 + n_de_exps * n_de_types;  % header + 6 data rows
n_de_cols = 15;  % exp_name | type | AS_i~AF_all(12) | mean
de_summary = cell(n_de_rows, n_de_cols);

% Header
de_summary{1, 1} = 'exp_name';
de_summary{1, 2} = 'DeltaE_type';
col_offset = 0;
for k = 1:3
    if k == 1, suffix = '_i'; elseif k == 2, suffix = '_r'; else, suffix = '_all'; end
    for i = 1:4
        de_summary{1, col_offset + i + 2} = [nations_en{i}, suffix];
    end
    col_offset = col_offset + 4;
end
de_summary{1, n_de_cols} = 'mean';

for e = 1:n_de_exps
    exp_name = exp_names_de{e};
    fprintf('  --- %s ---\n', exp_name);

    for t = 1:n_de_types
        de_type = de_types{t};
        row_idx = 1 + (e-1)*n_de_types + t;
        de_summary{row_idx, 1} = exp_name;
        de_summary{row_idx, 2} = de_type;

        for i_nation = 1:4
            nation = nations_en{i_nation};
            var_file = fullfile(var_dir, sprintf('test_results_%s_%s.xlsx', exp_name, nation));

            if ~exist(var_file, 'file')
                continue;
            end

            % 跨所有属性收集数据
            vals_all = [];
            vals_i = [];
            vals_r = [];

            for a = 1:n_attrs
                attr = attr_serials{a};
                sheet_name = [de_type, '_', attr];

                try
                    T = readtable(var_file, 'Sheet', sheet_name);
                catch
                    continue;
                end

                switch de_type
                    case 'DeltaE'
                        % DeltaE_{attr}: Metric | Value
                        mask = strcmp(string(T.Metric), 'mean_DE2000');
                        if any(mask)
                            val = T.Value(mask);
                            if isnumeric(val)
                                vals_all = [vals_all; val(1)];
                            end
                        end
                    case 'DeltaE_PerGroup'
                        % DeltaE_PerGroup_{attr}: Model | iOr | Scene | n_samples | mean_DE2000
                        iOr_col = string(T.iOr);
                        de_col = T.mean_DE2000;
                        if iscell(de_col)
                            de_col_num = NaN(size(de_col));
                            for kk = 1:numel(de_col)
                                if isnumeric(de_col{kk})
                                    de_col_num(kk) = de_col{kk};
                                else
                                    de_col_num(kk) = str2double(string(de_col{kk}));
                                end
                            end
                            de_col = de_col_num;
                        end
                        vals_i = [vals_i; de_col(contains(iOr_col, 'i', 'IgnoreCase', true))];
                        vals_r = [vals_r; de_col(contains(iOr_col, 'r', 'IgnoreCase', true))];
                    case 'DeltaE_RawData'
                        % DeltaE_RawData_{attr}: ... | ior | scene | DE2000
                        ior_col = string(T.ior);
                        de_col = T.DE2000;
                        if iscell(de_col)
                            de_col_num = NaN(size(de_col));
                            for kk = 1:numel(de_col)
                                if isnumeric(de_col{kk})
                                    de_col_num(kk) = de_col{kk};
                                else
                                    de_col_num(kk) = str2double(string(de_col{kk}));
                                end
                            end
                            de_col = de_col_num;
                        end
                        vals_i = [vals_i; de_col(contains(ior_col, 'i', 'IgnoreCase', true))];
                        vals_r = [vals_r; de_col(contains(ior_col, 'r', 'IgnoreCase', true))];
                end
            end

            % 计算均值
            switch de_type
                case 'DeltaE'
                    val_all = nanmean(vals_all);
                    val_i = NaN; val_r = NaN;
                case {'DeltaE_PerGroup', 'DeltaE_RawData'}
                    val_i = nanmean(vals_i);
                    val_r = nanmean(vals_r);
                    val_all = nanmean([vals_i; vals_r]);
            end

            fprintf('    %s [%s]: i=%.4f, r=%.4f, all=%.4f\n', nation, de_type, val_i, val_r, val_all);

            if ~isnan(val_i)
                de_summary{row_idx, 2 + i_nation} = val_i;       % cols 3-6: _i
            end
            if ~isnan(val_r)
                de_summary{row_idx, 6 + i_nation} = val_r;       % cols 7-10: _r
            end
            if ~isnan(val_all)
                de_summary{row_idx, 10 + i_nation} = val_all;    % cols 11-14: _all
            end
        end
    end
end

% 计算 mean 列 (AS_all, CA_all, SA_all, AF_all 的平均)
for row = 2:n_de_rows
    vals = {de_summary{row, 11}, de_summary{row, 12}, de_summary{row, 13}, de_summary{row, 14}};
    all_numeric = cellfun(@(x) isnumeric(x) && ~isempty(x), vals);
    if all(all_numeric)
        de_summary{row, n_de_cols} = nanmean(cell2mat(vals));
    else
        de_summary{row, n_de_cols} = NaN;
    end
end

% 写入新 sheet
writecell(de_summary, output_file, 'Sheet', 'DeltaE汇总');
fprintf('已保存 DeltaE汇总 Sheet\n');

% 打印
fprintf('\n========== DeltaE 汇总 ==========\n');
fprintf('%-30s %-18s', 'exp_name', 'DeltaE_type');
suffixes = {'_i', '_r', '_all'};
for k = 1:3
    for i_n = 1:4
        fprintf('  %-8s', [nations_en{i_n}, suffixes{k}]);
    end
end
fprintf('  %-8s\n', 'mean');
for row = 2:n_de_rows
    fprintf('%-30s %-18s', de_summary{row, 1}, de_summary{row, 2});
    for col = 3:n_de_cols
        if ~isempty(de_summary{row, col}) && isnumeric(de_summary{row, col}) && ~isnan(de_summary{row, col})
            fprintf('  %8.4f', de_summary{row, col});
        else
            fprintf('  %8s', '-');
        end
    end
    fprintf('\n');
end

fprintf('\n完成！\n');
