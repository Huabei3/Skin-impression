%% predict_fullpara_n_drop.m
% 基于 predict_fullpara_ablation.m (ablation_type="scene_types") 修改
% 核心改进：对每个 (nation, attribute) 组合，分别用：
%   1. 原 fullpara 参数（全部训练集拟合）
%   2. n_drop CV 拟合的参数（每个 Drop_subj 一组）
% 在 VIVO rendered image 数据上计算 corr/dE/rmse，并对比
% 同时将 xlsx 中的参数转为 .mat 文件
close all; clc; clear;

%% ========== 预处理：xlsx → .mat ==========
fprintf('========== 预处理：xlsx 转 .mat ==========\n');
n_drop = 1;

xlsx_file = fullfile("D:\work\VIVOskinExpe\analyze\AnalyseResults_p\efit_p\unscaled\model_fullpara_n_drop", ...
    "d65\new\i\non_model\drop_1", sprintf("n_drop_cv_results_n%d.xlsx", n_drop));

output_mat_folder = fullfile("D:\work\VIVOskinExpe\analyze\AnalyseResults_p\efit_p\unscaled\model_fullpara", ...
    "d65\new\i\non_model\1_drop");
if ~exist(output_mat_folder, 'dir')
    mkdir(output_mat_folder);
end

nations_sheets = {"AS", "CA", "SA", "AF", "all"};
% 列索引（1-based）
COL = struct();
COL.Attr       = 1;
COL.Drop_subj  = 2;
COL.a_C1       = 8;
COL.a_C2       = 9;
COL.a_la1      = 10;
COL.a_la2      = 11;
COL.a_la3      = 12;
COL.a_la4      = 13;
COL.a_sa1      = 14;
COL.a_sa2      = 15;
COL.a_sa3      = 16;
COL.a_sa4      = 17;
COL.hue_angle  = 18;
COL.theta      = 19;
COL.alpha      = 20;

for i_n = 1:length(nations_sheets)
    nation = nations_sheets{i_n};
    [num, txt, raw] = xlsread(xlsx_file, nation);
    n_rows = size(raw, 1);

    subj_struct = struct();
    for r = 2:n_rows
        drop_subj = raw{r, COL.Drop_subj};
        if ischar(drop_subj) || isstring(drop_subj)
            drop_subj = strtrim(string(drop_subj));
            if ~isfield(subj_struct, drop_subj)
                subj_struct.(drop_subj) = struct();
            end
            attr = strtrim(string(raw{r, COL.Attr}));
            s = struct();
            s.a_C_L      = [raw{r, COL.a_C1}, raw{r, COL.a_C2}];
            s.a_long_axis= [raw{r, COL.a_la1}, raw{r, COL.a_la2}, raw{r, COL.a_la3}, raw{r, COL.a_la4}];
            s.a_short_axis=[raw{r, COL.a_sa1}, raw{r, COL.a_sa2}, raw{r, COL.a_sa3}, raw{r, COL.a_sa4}];
            s.hue_angle  = raw{r, COL.hue_angle};
            s.theta      = raw{r, COL.theta};
            s.alpha      = raw{r, COL.alpha};
            subj_struct.(drop_subj).(attr) = s;
        end
    end

    mat_file = fullfile(output_mat_folder, sprintf("%s_n_drop1.mat", nation));
    save(mat_file, '-struct', 'subj_struct');
    fprintf('  [%s] %d subjects saved -> %s\n', nation, length(fieldnames(subj_struct)), mat_file);
end
fprintf('xlsx → .mat 完成！\n\n');

%% ========== 主脚本：与 predict_fullpara_ablation.m (scene_types) 相同的逻辑 ==========
addpath("..\..\utils\");

wd65_64 = [94.811, 100.00, 107.304];
new_names = ["f04", "f05", "f06", "m04", "m05", "m06",...
    "f01", "f02", "f03", "m01", "m02", "m03",...
    "f07", "f08", "m07", "m08",...
    "f09", "f10", "m09", "m10"];

iOrs = ['i', 'r'];
nation_names = ["Asian", "Caucasian", "South Asian", "African"];
n_attribute = 10;
target_score = 1;
target_score_str = num2str(target_score * 100);
score_type = "rela";
render_type = "srgb";
Dtype = "efit_p";
scale_type_origin = "unscaled";
obs_type = "non_model";
using_model_type = "each_self";

ablation_type = "scene_types";

if_draw_pics = "false";
except_abnormal = "true";

scene_type_indices{1} = [1, 2, 4, 5, 6];
scene_type_indices{2} = [3, 7, 8, 10, 12];
scene_type_indices{3} = [13, 14];
scene_type_indices{4} = [9, 11];
n_scene_type = length(scene_type_indices);

rela_data_base_path = fullfile("D:\work\VIVOskinExpe\analyze\AnalyseResults_p", ...
    Dtype, "scaled", "contour_scene_type", obs_type);

nation_type = "ACSA";
version = "new";

VIVO_table_folder = "D:\work\VIVOskinExpe\analyze\AnalyseResults_p\efit_p\scaled\resTable";
VIVO_table_file = fullfile(VIVO_table_folder, "Peggy_VIVO_table.mat");
VIVO_table_data = load(VIVO_table_file);
VIVO_table = VIVO_table_data.fit_table;

%% VIVO_table 预索引
fprintf('正在预处理 VIVO_table 索引...\n');
scene_str    = cellfun(@string, VIVO_table.scene,          'UniformOutput', true);
model_str    = cellfun(@string, VIVO_table.model_id,       'UniformOutput', true);
observer_str = cellfun(@string, VIVO_table.observer_type,  'UniformOutput', true);
attr_str     = cellfun(@string, VIVO_table.attribute,      'UniformOutput', true);
fprintf('VIVO_table 索引预处理完成（%d 行）\n', length(scene_str));

p_pre = cell(20, n_attribute);
p_visual = cell(20, n_attribute);

for i_iOr = 1:2
    iOr = iOrs(i_iOr);

    if iOr == 'i'
        pcn = ["H3K", "H4K", "H5K", "H6K", "HD65", "H7K", "H8K", ...
            "M3K", "M4K", "M5K", "M6K", "MD65", "M7K", "M8K", ...
            "L3K", "L4K", "L5K", "L6K", "LD65", "L7K", "L8K"];
    else
        pcn = ["rs01", "rs02", "rs03", "rs04", "rs05", "rs06", "rs07", ...
            "rs08", "rs09", "rs10", "rs11", "rs12", "rs13", "rs14"];
    end

    max_classify = 0;
    if max_classify == 1
        nation_type = "ACD";
        nations = ["AS", "CA", "DA", "all"];
        nation_indices = cell(5, 1);
        nation_indices{1} = 1:6;
        nation_indices{2} = 7:12;
        nation_indices{3} = 13:20;
        nation_indices{4} = 1:20;
        label_type = "nation_max";
    else
        nation_type = "ACSA";
        nations = ["AS", "CA", "SA", "AF", "all"];
        nation_indices = cell(5, 1);
        nation_indices{1} = 1:6;   % AS: f04-06, m04-06
        nation_indices{2} = 7:12;  % CA: f01-03, m01-03
        nation_indices{3} = 13:16; % SA: f07-08, m07-08
        nation_indices{4} = 17:20; % AF: f09-10, m09-10
        nation_indices{5} = 1:20;  % all
        label_type = "nation";
    end

    datai_file = '..\..\calibration\display_model\datai_ipv35_3.mat';
    wd65 = [94.813, 100.000, 107.262];
    LUT = load(datai_file);
    XYZw_LUT = LUT.XYZw;
    wd65_scaled = wd65 ./ 100 .* XYZw_LUT(2);

    attributes_to_process = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    n_attr_total = length(attributes_to_process);
    attribute_names = ["Preference", "Attractiveness", "Feminine", "Cooperative", ...
        "Youth", "Healthy", "Fidelity", "Harmony", "Fair", "Ruddy"];

    % 输出目录
    output_dir = fullfile('..\..\data', 'correlation_results', "fullpara_n_drop", ...
        Dtype, version, nation_type, using_model_type, ablation_type);
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end

    % 每个 nation 单独一个 xlsx，Sheet 名 = model_name（如 f04i_r）
    % 预先创建 nation 子目录
    for i_n_nation = 1:length(nations)
        nation_dir = fullfile(output_dir, nations{i_n_nation});
        if ~exist(nation_dir, 'dir'), mkdir(nation_dir); end
    end

    % ===== nation 级 accumulator =====
    % nation_acc{ni}.model_names : cellstr of model names in this nation
    % nation_acc{ni}.cmp_r{model_idx} : cell (n_pcn x n_methods), row=pcn, col=method
    % nation_acc{ni}.cmp_dE / cmp_rmse : same
    % nation_acc{ni}.method_names{model_idx} : cellstr of method names for this model
    nation_acc = cell(5, 1);
    for ni = 1:5
        nation_acc{ni} = struct();
        nation_acc{ni}.model_names = {};
        nation_acc{ni}.cmp_r = {};
        nation_acc{ni}.cmp_dE = {};
        nation_acc{ni}.cmp_rmse = {};
        nation_acc{ni}.method_names = {};
    end

    % ========== for i_model ==========
    for i_model = 1:length(new_names)
        current_model_name = new_names(i_model);
        source_folder = fullfile('mask', strcat(current_model_name, iOr));
        source_folder = char(source_folder);
        slashes = strfind(source_folder, '\');
        lastPart = source_folder(slashes(1, end) + 1:end);
        model = lastPart(1:end - 1);

        if ismember(lastPart, ["f04i", "f05i", "f06i", "m04i", "m06i"])
            if_wei = 0;
        else
            if_wei = 1;
        end
        if ismember(lastPart, ["m02i", "m03i"])
            if_2mask = 1;
        else
            if_2mask = 0;
        end

        i_type = select_type(model);

        %% 预索引：VIVO_table
        idx_model = strcmp(model_str, current_model_name);
        model_rows = find(idx_model);
        if isempty(model_rows)
            fprintf('--- 模特 %s 在 VIVO_table 中无数据，跳过 ---\n', current_model_name);
            continue;
        end
        scene_str_sub    = scene_str(model_rows);
        observer_str_sub = observer_str(model_rows);
        attr_str_sub     = attr_str(model_rows);

        %% 找当前 model 所属 nation
        [~, i_nation, ~] = find_nation(model);
        nation_serial = sprintf("%02d%s", i_nation, nation_names(i_nation));

        % 加载 n_drop 参数（当前 model 所属 nation 的所有 Drop_subj）
        n_drop_mat_file = fullfile(output_mat_folder, sprintf("%s_n_drop1.mat", nations{i_nation}));
        if exist(n_drop_mat_file, 'file')
            n_drop_params = load(n_drop_mat_file);
        else
            n_drop_params = struct();
        end
        drop_subj_list = fieldnames(n_drop_params);
        n_drop_subjects = length(drop_subj_list);

        % method_names: col 1=fullpara, col 2..end=各 Drop_subj
        method_names = [{'fullpara'}; drop_subj_list(:)];
        n_methods = length(method_names);

        % 将此 model 加入 nation accumulator（如尚未加入）
        mi = find(strcmp(nation_acc{i_nation}.model_names, string(current_model_name)));
        if isempty(mi)
            mi = length(nation_acc{i_nation}.model_names) + 1;
            nation_acc{i_nation}.model_names{mi} = string(current_model_name);
            nation_acc{i_nation}.method_names{mi} = method_names;
            % 为每个 pcn 初始化 accumulator（行=pcn，列=methods）
            nation_acc{i_nation}.cmp_r{mi}    = cell(length(pcn), n_methods);
            nation_acc{i_nation}.cmp_dE{mi}   = cell(length(pcn), n_methods);
            nation_acc{i_nation}.cmp_rmse{mi} = cell(length(pcn), n_methods);
        end

        fprintf('--- 正在处理模特: %s (nation=%s, %d n_drop subjects) ---\n', ...
            current_model_name, nations{i_nation}, n_drop_subjects);

        for i_par = 1:length(pcn)
            current_pcn_name = pcn(i_par);

            % 预索引 scene
            idx_scene_sub = contains(scene_str_sub, string(current_pcn_name), 'IgnoreCase', true);
            scene_rows = model_rows(idx_scene_sub);
            if isempty(scene_rows)
                for col = 1:n_methods
                    nation_acc{i_nation}.cmp_r{mi}{i_par, col}    = NaN;
                    nation_acc{i_nation}.cmp_dE{mi}{i_par, col}   = NaN;
                    nation_acc{i_nation}.cmp_rmse{mi}{i_par, col} = NaN;
                end
                continue;
            end
            observer_str_scene = observer_str_sub(idx_scene_sub);
            attr_str_scene     = attr_str_sub(idx_scene_sub);

            for attribute_idx_in_list = 1:length(attributes_to_process)
                attribute = attributes_to_process(attribute_idx_in_list);
                current_attribute_name = attribute_names(attribute);
                attribute_serial = strcat(sprintf("%02d", attribute), current_attribute_name);

                if attribute_idx_in_list == 7
                    obs_type_used = "model_group";
                else
                    obs_type_used = obs_type;
                end

                % 从 VIVO_table 加载 lab_group / p_group
                idx_obs  = strcmp(observer_str_scene, obs_type_used);
                idx_attr = strcmp(attr_str_scene, current_attribute_name);
                idx = idx_obs & idx_attr;

                lab_group = [];
                p_group = [];

                if any(idx)
                    row_idx = scene_rows(idx);
                    row_idx = row_idx(1);
                    lab_group = VIVO_table.lab_values{row_idx};
                    p_group   = VIVO_table.opinion_scores{row_idx};
                else
                    labNscore_file = fullfile("D:\work\VIVOskinExpe\analyze\AnalyseResults_p", ...
                        Dtype, scale_type_origin, lastPart, obs_type_used, attribute_serial, "labNscore", ...
                        strcat("labNscore_group", lower(lastPart), lower(current_pcn_name), ".mat"));
                    if exist(labNscore_file, 'file') == 2
                        ld = load(labNscore_file, "lab_group", "p_group");
                        lab_group = ld.lab_group;
                        p_group   = ld.p_group;
                    end
                end

                if isempty(lab_group) || isempty(p_group)
                    continue;
                end

                % ========== 加载 fullpara 参数（用于 Method 1）==========
                model_fupara_file = fullfile("D:\work\VIVOskinExpe\analyze\AnalyseResults_p", ...
                    "efit_p\unscaled\model_fullpara\d65", version, "i", obs_type);
                fullpara_data = load(fullfile(model_fupara_file, ...
                    strcat(attribute_serial, "_all_curve_params.mat")));

                a_alpha     = fullpara_data.a_alpha_all(i_nation, :);
                a_CL        = fullpara_data.a_CL_all(i_nation, :);
                a_hue_angle = fullpara_data.a_hue_angle_all(i_nation, :);
                a_long_axis = fullpara_data.a_long_axis_all(i_nation, :);
                a_short_axis= fullpara_data.a_short_axis_all(i_nation, :);
                a_theta     = fullpara_data.a_theta_all(i_nation, :);

                % 加载 average（L* 输入）
                average_file = fullfile("aveSkin", lastPart, "autoNhand_scaleoverLUT.mat");
                avg_data = load(average_file);
                average = avg_data.average_lab_all(:, 1:3);

                % 计算 fullpara 椭圆参数
                hue_angle = a_hue_angle(1);
                chroma    = a_CL(1) .* log(average(i_par, 1)) + a_CL(2);
                long_axis = a_long_axis(1) .* average(i_par,1).^3 + a_long_axis(2) .* average(i_par,1).^2 + ...
                    a_long_axis(3) .* average(i_par,1) + a_long_axis(4);
                short_axis= a_short_axis(1).* average(i_par,1).^3 + a_short_axis(2).* average(i_par,1).^2 + ...
                    a_short_axis(3).* average(i_par,1) + a_short_axis(4);
                theta     = a_theta(1);
                alpha     = a_alpha(1);

                par_fullpara = calculate_par_from_ellipse(hue_angle, chroma, ...
                    long_axis, short_axis, theta, alpha);

                % scene_types 平移
                rela_file = fullfile(rela_data_base_path, ...
                    sprintf("%02d%s", attribute, attribute_names(attribute)), ...
                    strcat(nation_serial, ".mat"));
                has_rela_data = false;
                if strcmp(ablation_type, "scene_types") && strcmp(iOr, 'r')
                    if exist(rela_file, 'file')
                        rela_data = load(rela_file);
                        scene_idx = i_par;
                        i_scene_type = [];
                        for st_idx = 1:n_scene_type
                            if ismember(scene_idx, scene_type_indices{st_idx})
                                i_scene_type = st_idx;
                                break;
                            end
                        end
                        if ~isempty(i_scene_type) && isfield(rela_data, 'rela_incre')
                            delta_a = rela_data.rela_incre(i_scene_type, 2) / 100;
                            delta_b = rela_data.rela_incre(i_scene_type, 3) / 100;
                            has_rela_data = true;
                            par_fullpara(4) = par_fullpara(4) * (1 + delta_a);
                            par_fullpara(5) = par_fullpara(5) * (1 + delta_b);
                        end
                    end
                end

                % 计算 y_fullpara
                y_fullpara = calculate_y(lab_group(:, 2), lab_group(:, 3), par_fullpara);

                % ========== 计算 Method 1 (fullpara) 和 Method 2+ (n_drop) ==========
                method_r    = zeros(n_methods, 1);
                method_dE   = zeros(n_methods, 1);
                method_rmse = zeros(n_methods, 1);

                L_mean = mean(lab_group(:, 1));
                ab_mean_actual = mean(lab_group(:, 2:3), 1, 'omitnan');

                % Method 1: fullpara
                if ~isempty(y_fullpara) && ~isempty(p_group) && numel(y_fullpara) == numel(p_group) && numel(y_fullpara) > 1
                    method_r(1)    = corr(y_fullpara, p_group, 'Type', 'Pearson');
                    ab_mean_predicted = mean([y_fullpara, y_fullpara], 1);
                    method_dE(1)  = deltaE2000([L_mean, ab_mean_actual], [L_mean, ab_mean_predicted]);
                    p_g = p_group; p_g(p_g == 0) = NaN;
                    method_rmse(1)= nanmean(abs(p_g - y_fullpara));
                else
                    method_r(1) = NaN; method_dE(1) = NaN; method_rmse(1) = NaN;
                end

                % Methods 2..n: n_drop subjects
                for i_drop = 1:n_drop_subjects
                    drop_subj = drop_subj_list{i_drop};
                    attr_params = [];
                    try
                        attr_params = n_drop_params.(drop_subj).(current_attribute_name);
                    catch
                    end

                    if ~isempty(attr_params) && isstruct(attr_params)
                        p_drop = attr_params;
                        chroma_nd    = p_drop.a_C_L(1) .* log(average(i_par, 1)) + p_drop.a_C_L(2);
                        long_axis_nd = p_drop.a_long_axis(1) .* average(i_par,1).^3 + p_drop.a_long_axis(2) .* average(i_par,1).^2 + ...
                            p_drop.a_long_axis(3) .* average(i_par,1) + p_drop.a_long_axis(4);
                        short_axis_nd= p_drop.a_short_axis(1).* average(i_par,1).^3 + p_drop.a_short_axis(2).* average(i_par,1).^2 + ...
                            p_drop.a_short_axis(3).* average(i_par,1) + p_drop.a_short_axis(4);
                        hue_nd = p_drop.hue_angle + 90 - 360;
                        theta_nd = p_drop.theta;
                        alpha_nd = p_drop.alpha;

                        par_nd = calculate_par_from_ellipse(hue_nd, chroma_nd, long_axis_nd, short_axis_nd, theta_nd, alpha_nd);

                        if has_rela_data
                            par_nd(4) = par_nd(4) * (1 + delta_a);
                            par_nd(5) = par_nd(5) * (1 + delta_b);
                        end

                        y_nd = calculate_y(lab_group(:, 2), lab_group(:, 3), par_nd);

                        if ~isempty(y_nd) && numel(y_nd) == numel(p_group) && numel(y_nd) > 1
                            method_r(1 + i_drop)    = corr(y_nd, p_group, 'Type', 'Pearson');
                            ab_mean_predicted_nd = mean([y_nd, y_nd], 1);
                            method_dE(1 + i_drop)  = deltaE2000([L_mean, ab_mean_actual], [L_mean, ab_mean_predicted_nd]);
                            p_g_nd = p_group; p_g_nd(p_g_nd == 0) = NaN;
                            method_rmse(1 + i_drop)= nanmean(abs(p_g_nd - y_nd));
                        else
                            method_r(1 + i_drop) = NaN; method_dE(1 + i_drop) = NaN; method_rmse(1 + i_drop) = NaN;
                        end
                    else
                        method_r(1 + i_drop) = NaN; method_dE(1 + i_drop) = NaN; method_rmse(1 + i_drop) = NaN;
                    end
                end

                % 存入 nation accumulator（每个 method 占一列）
                for i_m = 1:n_methods
                    nation_acc{i_nation}.cmp_r{mi}{i_par, i_m}    = method_r(i_m);
                    nation_acc{i_nation}.cmp_dE{mi}{i_par, i_m}   = method_dE(i_m);
                    nation_acc{i_nation}.cmp_rmse{mi}{i_par, i_m} = method_rmse(i_m);
                end

            end % end attribute
        end % end i_par

        fprintf('  模特 %s 完成（含 %d n_drop subjects）\n', current_model_name, n_drop_subjects);
    end % end i_model

    % ========== 写 xlsx：每个 nation 一个文件，Sheet = model_name ==========
    for ni = 1:5
        if isempty(nation_acc{ni}.model_names), continue; end
        n_models_ni = length(nation_acc{ni}.model_names);

        xlsx_path = fullfile(output_dir, nations{ni}, ...
            strcat(iOr, '_', nations{ni}, '_comparison.xlsx'));
        if exist(xlsx_path, 'file'), delete(xlsx_path); end

        for mi = 1:n_models_ni
            model_name_cur = nation_acc{ni}.model_names{mi};
            method_names_cur = nation_acc{ni}.method_names{mi};
            n_methods_cur = length(method_names_cur);
            n_pcn = length(pcn);

            % 提取数值矩阵（n_pcn × n_methods_cur）
            num_r    = zeros(n_pcn, n_methods_cur);
            num_dE   = zeros(n_pcn, n_methods_cur);
            num_rmse = zeros(n_pcn, n_methods_cur);
            for ip = 1:n_pcn
                for i_m = 1:n_methods_cur
                    v_r   = nation_acc{ni}.cmp_r{mi}{ip, i_m};
                    v_dE  = nation_acc{ni}.cmp_dE{mi}{ip, i_m};
                    v_rmse= nation_acc{ni}.cmp_rmse{mi}{ip, i_m};
                    if isnumeric(v_r) && ~isnan(v_r),   num_r(ip,i_m)    = double(v_r);   else num_r(ip,i_m)    = NaN; end
                    if isnumeric(v_dE)&& ~isnan(v_dE),  num_dE(ip,i_m)   = double(v_dE);  else num_dE(ip,i_m)   = NaN; end
                    if isnumeric(v_rmse)&&~isnan(v_rmse),num_rmse(ip,i_m)= double(v_rmse);else num_rmse(ip,i_m)=NaN; end
                end
            end

            % 行均值、列均值
            row_mean  = nanmean(num_r, 2);       % n_pcn × 1
            col_mean  = nanmean(num_r, 1)';      % n_methods_cur × 1
            grand_r   = nanmean(col_mean);       % scalar

            % 构建 sheet 表（cell 格式，直接 writecell）
            % 表头行 = ['pcn/method', method_names..., 'mean']
            hdr = [{'pcn/method'}, method_names_cur(:)', {'mean'}];
            % 数据行 = [pcn_names, num_r, row_mean]
            data_rows = cell(n_pcn + 1, n_methods_cur + 2);
            for ip = 1:n_pcn
                data_rows{ip, 1} = pcn{ip};
                for i_m = 1:n_methods_cur
                    data_rows{ip, 1 + i_m} = num_r(ip, i_m);
                end
                data_rows{ip, n_methods_cur + 2} = row_mean(ip);
            end
            % mean 行
            data_rows{n_pcn + 1, 1} = 'mean';
            for i_m = 1:n_methods_cur
                data_rows{n_pcn + 1, 1 + i_m} = col_mean(i_m);
            end
            data_rows{n_pcn + 1, n_methods_cur + 2} = grand_r;

            sheet_r = [hdr; data_rows];

            % dE sheet 同理
            row_mean_dE  = nanmean(num_dE, 2);
            col_mean_dE = nanmean(num_dE, 1)';
            grand_dE     = nanmean(col_mean_dE);
            data_rows_dE = cell(n_pcn + 1, n_methods_cur + 2);
            for ip = 1:n_pcn
                data_rows_dE{ip, 1} = pcn{ip};
                for i_m = 1:n_methods_cur
                    data_rows_dE{ip, 1 + i_m} = num_dE(ip, i_m);
                end
                data_rows_dE{ip, n_methods_cur + 2} = row_mean_dE(ip);
            end
            data_rows_dE{n_pcn + 1, 1} = 'mean';
            for i_m = 1:n_methods_cur
                data_rows_dE{n_pcn + 1, 1 + i_m} = col_mean_dE(i_m);
            end
            data_rows_dE{n_pcn + 1, n_methods_cur + 2} = grand_dE;
            sheet_dE = [hdr; data_rows_dE];

            % rmse sheet 同理
            row_mean_rmse  = nanmean(num_rmse, 2);
            col_mean_rmse = nanmean(num_rmse, 1)';
            grand_rmse    = nanmean(col_mean_rmse);
            data_rows_rmse = cell(n_pcn + 1, n_methods_cur + 2);
            for ip = 1:n_pcn
                data_rows_rmse{ip, 1} = pcn{ip};
                for i_m = 1:n_methods_cur
                    data_rows_rmse{ip, 1 + i_m} = num_rmse(ip, i_m);
                end
                data_rows_rmse{ip, n_methods_cur + 2} = row_mean_rmse(ip);
            end
            data_rows_rmse{n_pcn + 1, 1} = 'mean';
            for i_m = 1:n_methods_cur
                data_rows_rmse{n_pcn + 1, 1 + i_m} = col_mean_rmse(i_m);
            end
            data_rows_rmse{n_pcn + 1, n_methods_cur + 2} = grand_rmse;
            sheet_rmse = [hdr; data_rows_rmse];

            % Sheet 名 = 去掉 'i' 的 model 名（char 类型，writecell 要求）
            sheet_base = char(strrep(string(model_name_cur), 'i', ''));  % e.g. "f04"
            writecell(sheet_r,    xlsx_path, 'Sheet', sheet_base);
            writecell(sheet_dE,   xlsx_path, 'Sheet', [sheet_base, '_dE']);
            writecell(sheet_rmse, xlsx_path, 'Sheet', [sheet_base, '_rmse']);
        end
        fprintf('  Nation [%s] xlsx 已写入: %s\n', nations{ni}, xlsx_path);
    end

    fprintf('\n所有结果已保存到 %s\n', output_dir);
end % end i_iOr

fprintf('\n========== Done! ==========\n');

%% ========== 辅助函数 ==========

function val = ifelse(cond, a, b)
    if cond, val = a; else, val = b; end
end
