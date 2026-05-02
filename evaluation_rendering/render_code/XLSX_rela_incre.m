close all;
clc;
clear;
addpath("..\..\utils\");

%% ========== 配置 ==========
nation_names = ["Asian", "Caucasian", "South Asian", "African"];
n_nation = length(nation_names); % 4

Dtype = "efit_p";
version = "new";
obs_type = "non_model";

% 属性列表
attribute_names = ["Preference", "Attractiveness", "Feminine", "Cooperative", ...
                   "Youth", "Healthy", "Fidelity", "Harmony", "Fair", "Ruddy"];
n_attribute = length(attribute_names); % 10

% 场景列表 (rs01-rs14)
scene_names = ["rs01","rs02","rs03","rs04","rs05","rs06","rs07", ...
               "rs08","rs09","rs10","rs11","rs12","rs13","rs14"];
n_scenes = length(scene_names); % 14

% scene_type 分组定义（与 predict_fullpara_scenes.m 保持一致）
scene_type_names = ["indoor", "outdoor", "night", "backlit"];
scene_type_indices{1} = [1, 2, 4, 5, 6];   % indoor
scene_type_indices{2} = [3, 7, 8, 10, 12]; % outdoor
scene_type_indices{3} = [13, 14];          % night
scene_type_indices{4} = [9, 11];            % backlit
n_scene_type = length(scene_type_names); % 4

% rela_increment 数据路径
rela_data_base_path = fullfile("D:\work\VIVOskinExpe\analyze\AnalyseResults_p", ...
    Dtype, "scaled", "contour_scene_type", obs_type);

% 每个nation取一个代表性model来确定nation_serial
model_for_nation = ["f04", "f05", "f06", "m04", "m05", "m06", ...
                    "f01", "f02", "f03", "m01", "m02", "m03", ...
                    "f07", "f08", "m07", "m08", ...
                    "f09", "f10", "m09", "m10"];
nation_indices = cell(4, 1);
nation_indices{1} = 1:6;   % Asian
nation_indices{2} = 7:12;  % Caucasian
nation_indices{3} = 13:16; % South Asian
nation_indices{4} = 17:20; % African

% 输出路径
output_dir = fullfile('..\..\data', 'correlation_results', "fullpara", ...
    Dtype, version, "ACSA", "each_self");
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end
% 在mkdir之后立即获取绝对路径
output_dir = fullfile(pwd, output_dir);
xlsx_scenes_path = fullfile(output_dir, 'rela_incre_scenes.xlsx');
xlsx_types_path = fullfile(output_dir, 'rela_incre_scene_types.xlsx');

%% ========== 为每个nation确定nation_serial ==========
nation_serials = cell(n_nation, 1);
for i_nation = 1:n_nation
    rep_model = model_for_nation(nation_indices{i_nation}(1));
    [~, i_nat, ~] = find_nation(char(rep_model));
    nation_serials{i_nation} = sprintf("%02d%s", i_nat, nation_names(i_nation));
    fprintf('Nation %s -> nation_serial: %s\n', nation_names(i_nation), nation_serials{i_nation});
end

%% ========== 公共表头构建 ==========
% header: [scene name, Asian a_incre, Asian b_incre, Caucasian a_incre, ...]
function hdr = build_header(row_label, nation_names)
    hdr = {row_label};
    for i = 1:length(nation_names)
        hdr{end+1} = sprintf("%s a_incre", nation_names(i));
        hdr{end+1} = sprintf("%s b_incre", nation_names(i));
    end
end

header_scenes = build_header("scene name", nation_names);
header_types  = build_header("scene type name", nation_names);

%% ========== 删除已存在文件 ==========
if exist(xlsx_scenes_path, 'file')
    delete(xlsx_scenes_path);
end
if exist(xlsx_types_path, 'file')
    delete(xlsx_types_path);
end

%% ========== 遍历所有 attribute，逐个生成sheet ==========
fprintf('\n========== 开始收集 rela_incre 数据 ==========\n');

for attribute = 1:n_attribute
    attribute_name = attribute_names(attribute);
    attribute_serial = strcat(sprintf("%02d", attribute), attribute_name);
    sheet_name = sprintf("%02d%s", attribute, attribute_name);
    fprintf('\n--- 属性 %d: %s (sheet: %s) ---\n', attribute, attribute_name, sheet_name);

    % ---- 准备数据矩阵 ----
    data_scenes = cell(n_scenes, length(header_scenes));
    data_scenes(:, 1) = cellstr(scene_names');

    data_types = cell(n_scene_type, length(header_types));
    data_types(:, 1) = cellstr(scene_type_names');

    % ---- 遍历每个nation ----
    for i_nation = 1:n_nation
        nation_serial = nation_serials{i_nation};
        col_a = 1 + (i_nation - 1) * 2 + 1; % a_incre 列
        col_b = 1 + (i_nation - 1) * 2 + 2; % b_incre 列

        % 构建rela文件路径
        rela_file = fullfile(rela_data_base_path, ...
            sprintf("%02d%s", attribute, attribute_name), ...
            strcat(nation_serial, ".mat"));

        if ~exist(rela_file, 'file')
            fprintf('  [跳过] %s: 文件不存在\n', nation_serial);
            data_scenes(:, col_a) = {NaN};
            data_scenes(:, col_b) = {NaN};
            data_types(:, col_a)  = {NaN};
            data_types(:, col_b)  = {NaN};
            continue;
        end

        rela_data = load(rela_file);
        if attribute==7
            disp("d")
        end

        % ===== Sheet数据: scenes (rela_incre_scenes) =====
        if isfield(rela_data, 'rela_incre_scenes')
            for scene_idx = 1:n_scenes
                if size(rela_data.rela_incre_scenes, 1) >= scene_idx
                    data_scenes{scene_idx, col_a} = rela_data.rela_incre_scenes(scene_idx, 2);
                    data_scenes{scene_idx, col_b} = rela_data.rela_incre_scenes(scene_idx, 3);
                else
                    data_scenes{scene_idx, col_a} = NaN;
                    data_scenes{scene_idx, col_b} = NaN;
                end
            end
        else
            fprintf('  [警告] %s: 缺少 rela_incre_scenes\n', nation_serial);
            data_scenes(:, col_a) = {NaN};
            data_scenes(:, col_b) = {NaN};
        end

        % ===== Sheet数据: scene_types (rela_incre) =====
        if isfield(rela_data, 'rela_incre')
            for st_idx = 1:n_scene_type
                if size(rela_data.rela_incre, 1) >= st_idx
                    data_types{st_idx, col_a} = rela_data.rela_incre(st_idx, 2);
                    data_types{st_idx, col_b} = rela_data.rela_incre(st_idx, 3);
                else
                    data_types{st_idx, col_a} = NaN;
                    data_types{st_idx, col_b} = NaN;
                end
            end
        else
            fprintf('  [警告] %s: 缺少 rela_incre\n', nation_serial);
            data_types(:, col_a) = {NaN};
            data_types(:, col_b) = {NaN};
        end
    end % end for i_nation

    % ---- 写入Sheet到两个XLSX ----
    sheet1_data = [header_scenes; data_scenes];
    writetable(cell2table(sheet1_data), xlsx_scenes_path, 'Sheet', sheet_name);

    sheet2_data = [header_types; data_types];
    writetable(cell2table(sheet2_data), xlsx_types_path, 'Sheet', sheet_name);

    fprintf('  ✓ Sheet "%s" 已写入两个XLSX\n', sheet_name);
end % end for attribute

fprintf('\n========== 完成！==========\n');
fprintf('scenes文件: %s\n', xlsx_scenes_path);
fprintf('scene_types文件: %s\n', xlsx_types_path);


