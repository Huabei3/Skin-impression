%% draw_n_drop.m
% 基于 predict_fullpara_n_drop.m 的参数加载逻辑，
% 对每个 i_par 绘制一张图：
%   - par_fullpara  contour：黑色虚线
%   - 每个 i_drop 的 par_nd contour：不同颜色实线
% 保存至 D:\work\VIVOskinExpe\skin_model\data\correlation_results\
%        fullpara_n_drop\efit_p\new\ACSA\each_self\scene_types\check_pics
close all; clc; clear;

addpath("..\..\utils\");

%% ========== 基本参数（与 predict_fullpara_n_drop.m 一致）==========
wd65_64 = [94.811, 100.00, 107.304];
new_names = ["f04", "f05", "f06", "m04", "m05", "m06", ...
    "f01", "f02", "f03", "m01", "m02", "m03", ...
    "f07", "f08", "m07", "m08", ...
    "f09", "f10", "m09", "m10"];

iOrs = ['i', 'r'];
nation_names = ["Asian", "Caucasian", "South Asian", "African"];
n_attribute = 10;
target_score = 1;
score_type = "rela";
render_type = "srgb";
Dtype = "efit_p";
scale_type_origin = "unscaled";
obs_type = "non_model";
using_model_type = "each_self";
ablation_type = "scene_types";
version = "new";
nation_type = "ACSA";

scene_type_indices{1} = [1, 2, 4, 5, 6];
scene_type_indices{2} = [3, 7, 8, 10, 12];
scene_type_indices{3} = [13, 14];
scene_type_indices{4} = [9, 11];
n_scene_type = length(scene_type_indices);

rela_data_base_path = fullfile("D:\work\VIVOskinExpe\analyze\AnalyseResults_p", ...
    Dtype, "scaled", "contour_scene_type", obs_type);

% n_drop .mat 文件路径（与预处理输出一致）
output_mat_folder = fullfile("D:\work\VIVOskinExpe\analyze\AnalyseResults_p\efit_p\unscaled\model_fullpara", ...
    "d65\new\i\non_model\1_drop");

% VIVO_table
VIVO_table_folder = "D:\work\VIVOskinExpe\analyze\AnalyseResults_p\efit_p\scaled\resTable";
VIVO_table_file = fullfile(VIVO_table_folder, "Peggy_VIVO_table.mat");
VIVO_table_data = load(VIVO_table_file);
VIVO_table = VIVO_table_data.fit_table;

% VIVO_table 预索引
fprintf('正在预处理 VIVO_table 索引...\n');
scene_str    = cellfun(@string, VIVO_table.scene,         'UniformOutput', true);
model_str    = cellfun(@string, VIVO_table.model_id,      'UniformOutput', true);
observer_str = cellfun(@string, VIVO_table.observer_type, 'UniformOutput', true);
attr_str     = cellfun(@string, VIVO_table.attribute,     'UniformOutput', true);
fprintf('VIVO_table 索引预处理完成（%d 行）\n', length(scene_str));

% calibration
datai_file = '..\..\calibration\display_model\datai_ipv35_3.mat';
wd65 = [94.813, 100.000, 107.262];
LUT = load(datai_file);
XYZw_LUT = LUT.XYZw;
wd65_scaled = wd65 ./ 100 .* XYZw_LUT(2);

attribute_names = ["Preference", "Attractiveness", "Feminine", "Cooperative", ...
    "Youth", "Healthy", "Fidelity", "Harmony", "Fair", "Ruddy"];

% 输出图片目录
pic_save_dir = fullfile("D:\work\VIVOskinExpe\skin_model\data\correlation_results", ...
    "fullpara_n_drop", Dtype, version, nation_type, using_model_type, ablation_type, "check_pics");
if ~exist(pic_save_dir, 'dir')
    mkdir(pic_save_dir);
end

% 颜色列表（供不同 i_drop 使用，自动循环）
drop_colors = lines(20);   % 最多 20 种颜色

%% ========== 主循环：仅 i_iOr = 1 ==========
for i_iOr = 1   % 只处理 iOr = 'i'
    iOr = iOrs(i_iOr);  % 'i'

    if iOr == 'i'
        pcn = ["H3K", "H4K", "H5K", "H6K", "HD65", "H7K", "H8K", ...
            "M3K", "M4K", "M5K", "M6K", "MD65", "M7K", "M8K", ...
            "L3K", "L4K", "L5K", "L6K", "LD65", "L7K", "L8K"];
        indices_target = [5, 14, 19];
    else
        pcn = ["rs01", "rs02", "rs03", "rs04", "rs05", "rs06", "rs07", ...
            "rs08", "rs09", "rs10", "rs11", "rs12", "rs13", "rs14"];
        indices_target = 1:14;
    end

    nations = ["AS", "CA", "SA", "AF", "all"];
    nation_indices = cell(5, 1);
    nation_indices{1} = 1:6;
    nation_indices{2} = 7:12;
    nation_indices{3} = 13:16;
    nation_indices{4} = 17:20;
    nation_indices{5} = 1:20;

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

        % 加载 n_drop 参数
        n_drop_mat_file = fullfile(output_mat_folder, sprintf("%s_n_drop1.mat", nations{i_nation}));
        if exist(n_drop_mat_file, 'file')
            n_drop_params = load(n_drop_mat_file);
        else
            n_drop_params = struct();
        end
        drop_subj_list = fieldnames(n_drop_params);
        n_drop_subjects = length(drop_subj_list);

        % average（L* 输入）
        average_file = fullfile("aveSkin", lastPart, "autoNhand_scaleoverLUT.mat");
        avg_data = load(average_file);
        average = avg_data.average_lab_all(:, 1:3);

        fprintf('--- 正在绘图：模特 %s (nation=%s) ---\n', current_model_name, nations{i_nation});

        %% 遍历 indices_target 中每个 i_par
        for i_par = indices_target
            current_pcn_name = pcn(i_par);

            % 预索引 scene
            idx_scene_sub = contains(scene_str_sub, string(current_pcn_name), 'IgnoreCase', true);
            scene_rows = model_rows(idx_scene_sub);
            if isempty(scene_rows)
                fprintf('  [%s] i_par=%d 无 scene 数据，跳过\n', current_pcn_name, i_par);
                continue;
            end
            observer_str_scene = observer_str_sub(idx_scene_sub);
            attr_str_scene     = attr_str_sub(idx_scene_sub);

            %% 对所有 attribute 各画一张图
            for attribute = 1:n_attribute
                current_attribute_name = attribute_names(attribute);
                attribute_serial = strcat(sprintf("%02d", attribute), current_attribute_name);

                if attribute == 7
                    obs_type_used = "model_group";
                else
                    obs_type_used = obs_type;
                end

                % 从 VIVO_table 加载 lab_group / p_group
                idx_obs  = strcmp(observer_str_scene, obs_type_used);
                idx_attr = strcmp(attr_str_scene, current_attribute_name);
                idx = idx_obs & idx_attr;

                lab_group = [];
                p_group   = [];

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

                %% 计算 par_fullpara
                model_fupara_file = fullfile("D:\work\VIVOskinExpe\analyze\AnalyseResults_p", ...
                    "efit_p\unscaled\model_fullpara\d65", version, "i", obs_type);
                fullpara_data = load(fullfile(model_fupara_file, ...
                    strcat(attribute_serial, "_all_curve_params.mat")));

                a_alpha      = fullpara_data.a_alpha_all(i_nation, :);
                a_CL         = fullpara_data.a_CL_all(i_nation, :);
                a_hue_angle  = fullpara_data.a_hue_angle_all(i_nation, :);
                a_long_axis  = fullpara_data.a_long_axis_all(i_nation, :);
                a_short_axis = fullpara_data.a_short_axis_all(i_nation, :);
                a_theta      = fullpara_data.a_theta_all(i_nation, :);

                hue_angle  = a_hue_angle(1);
                chroma     = a_CL(1) .* log(average(i_par, 1)) + a_CL(2);
                long_axis  = a_long_axis(1) .* average(i_par,1).^3 + a_long_axis(2) .* average(i_par,1).^2 + ...
                    a_long_axis(3) .* average(i_par,1) + a_long_axis(4);
                short_axis = a_short_axis(1).* average(i_par,1).^3 + a_short_axis(2).* average(i_par,1).^2 + ...
                    a_short_axis(3).* average(i_par,1) + a_short_axis(4);
                theta      = a_theta(1);
                alpha      = a_alpha(1);

                par_fullpara = calculate_par_from_ellipse(hue_angle, chroma, ...
                    long_axis, short_axis, theta, alpha);

                % scene_types 平移（仅 iOr='r' 时生效，当前 iOr='i' 跳过）
                has_rela_data = false;
                if strcmp(ablation_type, "scene_types") && strcmp(iOr, 'r')
                    rela_file = fullfile(rela_data_base_path, ...
                        sprintf("%02d%s", attribute, attribute_names(attribute)), ...
                        strcat(nation_serial, ".mat"));
                    if exist(rela_file, 'file')
                        rela_data_loaded = load(rela_file);
                        scene_idx = i_par;
                        i_scene_type = [];
                        for st_idx = 1:n_scene_type
                            if ismember(scene_idx, scene_type_indices{st_idx})
                                i_scene_type = st_idx;
                                break;
                            end
                        end
                        if ~isempty(i_scene_type) && isfield(rela_data_loaded, 'rela_incre')
                            delta_a = rela_data_loaded.rela_incre(i_scene_type, 2) / 100;
                            delta_b = rela_data_loaded.rela_incre(i_scene_type, 3) / 100;
                            has_rela_data = true;
                            par_fullpara(4) = par_fullpara(4) * (1 + delta_a);
                            par_fullpara(5) = par_fullpara(5) * (1 + delta_b);
                        end
                    end
                end

                %% 开始绘图
                fig = figure('Visible', 'off');
                hold on;

                % --- 散点图（底层）---
                if ~isempty(lab_group) && ~isempty(p_group)
                    scatter(lab_group(:, 2), lab_group(:, 3), 40, p_group, 'filled');
                end

                % --- par_fullpara contour：黑色虚线 ---
                par = par_fullpara;
                check_data2 = par(4) + (-30:0.2:30);
                check_data3 = par(5) + (-30:0.2:30);
                [data2, data3] = meshgrid(check_data2, check_data3);
                y_fp = (1./(1 + par(6) * exp(sqrt(par(1) * (data2 - par(4)).^2 + par(2) * (data3 - par(5)).^2 + ...
                    par(3) * (data2 - par(4)) .* (data3 - par(5)))))) .* ...
                    ((par(1) * (data2 - par(4)).^2 + par(2) * (data3 - par(5)).^2 + ...
                    par(3) * (data2 - par(4)) .* (data3 - par(5))) >= 0);
                contour(data2, data3, y_fp, [0.5, 1], ...
                    'LineStyle', '--', 'LineColor', 'k', 'LineWidth', 2);
                % 标注中心点（fullpara）
                scatter(par_fullpara(4), par_fullpara(5), 60, 'k', 'filled', 'Marker', 'd');

                % --- 各 i_drop 的 par_nd contour：不同颜色实线 ---
                legend_handles = [];
                legend_labels  = {};

                for i_drop = 1:n_drop_subjects
                    drop_subj = drop_subj_list{i_drop};
                    attr_params = [];
                    try
                        attr_params = n_drop_params.(drop_subj).(current_attribute_name);
                    catch
                    end

                    if ~isempty(attr_params) && isstruct(attr_params)
                        p_drop = attr_params;
                        chroma_nd     = p_drop.a_C_L(1) .* log(average(i_par, 1)) + p_drop.a_C_L(2);
                        long_axis_nd  = p_drop.a_long_axis(1) .* average(i_par,1).^3 + p_drop.a_long_axis(2) .* average(i_par,1).^2 + ...
                            p_drop.a_long_axis(3) .* average(i_par,1) + p_drop.a_long_axis(4);
                        short_axis_nd = p_drop.a_short_axis(1).* average(i_par,1).^3 + p_drop.a_short_axis(2).* average(i_par,1).^2 + ...
                            p_drop.a_short_axis(3).* average(i_par,1) + p_drop.a_short_axis(4);
                        hue_nd    = p_drop.hue_angle + 90 - 360;
                        theta_nd  = p_drop.theta;
                        alpha_nd  = p_drop.alpha;

                        par_nd = calculate_par_from_ellipse(hue_nd, chroma_nd, long_axis_nd, short_axis_nd, theta_nd, alpha_nd);

                        if has_rela_data
                            par_nd(4) = par_nd(4) * (1 + delta_a);
                            par_nd(5) = par_nd(5) * (1 + delta_b);
                        end

                        % 计算 contour 数据
                        check_d2 = par_nd(4) + (-30:0.2:30);
                        check_d3 = par_nd(5) + (-30:0.2:30);
                        [d2, d3] = meshgrid(check_d2, check_d3);
                        y_nd = (1./(1 + par_nd(6) * exp(sqrt(par_nd(1) * (d2 - par_nd(4)).^2 + par_nd(2) * (d3 - par_nd(5)).^2 + ...
                            par_nd(3) * (d2 - par_nd(4)) .* (d3 - par_nd(5)))))) .* ...
                            ((par_nd(1) * (d2 - par_nd(4)).^2 + par_nd(2) * (d3 - par_nd(5)).^2 + ...
                            par_nd(3) * (d2 - par_nd(4)) .* (d3 - par_nd(5))) >= 0);

                        % 取颜色（按 i_drop 循环）
                        c_idx = mod(i_drop - 1, size(drop_colors, 1)) + 1;
                        c = drop_colors(c_idx, :);

                        [~, h_nd] = contour(d2, d3, y_nd, [0.5, 1], ...
                            'LineStyle', '-', 'LineColor', c, 'LineWidth', 1.5);

                        legend_handles(end + 1) = h_nd; %#ok<AGROW>
                        legend_labels{end + 1}  = strrep(drop_subj, '_', '\_'); %#ok<AGROW>
                    end
                end

                % --- 坐标轴参考线 ---
                all_a = lab_group(:, 2);
                all_b = lab_group(:, 3);
                lim_max = max(max(all_a), max(all_b)) + 10;
                lim_min = min(min(all_a), min(all_b)) - 10;
                line([0, 0],          [lim_min, lim_max], 'Color', [0.5 0.5 0.5], 'LineStyle', '--');
                line([lim_min, lim_max], [0, 0],          'Color', [0.5 0.5 0.5], 'LineStyle', '--');
                refline(1, 0);

                axis equal;
                xlim([lim_min, lim_max]);
                ylim([lim_min, lim_max]);
                xlabel('{\ita*}');
                ylabel('{\itb*}');
                title(sprintf('%s | %s | %s | %s', nation_serial, current_pcn_name, ...
                    current_model_name, current_attribute_name), 'Interpreter', 'none');
                colorbar;

                % 图例
                fp_patch = patch(NaN, NaN, 'k', 'LineStyle', '--', 'FaceColor', 'none', 'LineWidth', 2);
                if ~isempty(legend_handles)
                    legend([fp_patch, legend_handles], ['fullpara', legend_labels], ...
                        'Location', 'best', 'FontSize', 7, 'Interpreter', 'none');
                else
                    legend(fp_patch, {'fullpara'}, 'Location', 'best', 'FontSize', 7);
                end

                hold off;

                % --- 保存图片 ---
                pic_name = sprintf('%s_%s.png', nation_serial, current_pcn_name);
                % 如果同一 nation_serial+pcn 有多个 attribute，加 attribute 后缀以区分
                pic_name = sprintf('%s_%s_%s.png', nation_serial, current_pcn_name, attribute_serial);
                pic_path = fullfile(pic_save_dir, pic_name);
                saveas(fig, pic_path);
                close(fig);
                fprintf('  已保存: %s\n', pic_path);

            end % end attribute
        end % end i_par

        fprintf('  模特 %s 绘图完成\n', current_model_name);
    end % end i_model

    fprintf('\niOr=%s 绘图全部完成！图片保存在: %s\n', iOr, pic_save_dir);
end % end i_iOr

fprintf('\n========== Done! ==========\n');
