clc; clear; close all;
addpath("..\utils\");

% All-in-one evaluation for five sources: david / cherry / summer / OPPO / peggy
% Reference: compare/predict_compare.m

%% -------------------- Common data loading --------------------
cherry_fitRes_file = fullfile("D:\work\ZJU_entire_skin\Cherry\software\skin colour\鏁版嵁鍒嗘瀽\鍒嗘瀽杩囩▼\res\nation\weighted\fitRes\ellipPara.mat");
cherry_fitRes_data = load(cherry_fitRes_file);

summer_table_file = fullfile("D:\work\ZJU_entire_skin\Summer\Data\Haisi skin\3. Test experiment\4. Model\res\resTable\Summer_table.mat");
summer_table_data = load(summer_table_file);
summer_table_all = summer_table_data.fit_table;

% Filtered summer table (CCT=6500, scene contains "cat") for summer/cherry/david
summer_table = summer_table_all;
cct_values = cell2mat(summer_table.CCT);
idx_cct = cct_values == 6500;
if iscell(summer_table.scene)
    scene_chars = cellfun(@char, summer_table.scene, 'UniformOutput', false);
    idx_scene = cellfun(@(x) contains(x, "cat"), scene_chars);
else
    idx_scene = contains(summer_table.scene, "cat");
end
idx = idx_cct & idx_scene;
summer_table = summer_table(idx, :);

david_table_file = fullfile("D:\work\ZJU_entire_skin\David\Naturalness model\Jason's final project\data analysis\res\separate_skin_methods\resTable\quality\David_table.mat");
david_table_data = load(david_table_file);
david_table = david_table_data.fit_table;

David_fitRes_folder_CATed = fullfile("D:\work\ZJU_entire_skin\David\Naturalness model\Jason's final project\data analysis\res\CATed\fitRes");
David_fitRes_file_CATed = fullfile(David_fitRes_folder_CATed, "fitRes.mat");
David_fitRes_data_CATed = load(David_fitRes_file_CATed);

% Raw david fitRes (used in cherry section in predict_compare.m)
David_fitRes_folder_raw = "D:\work\ZJU_entire_skin\David\Naturalness model\Jason's final project\data analysis\res\fitRes";
David_fitRes_file_raw = fullfile(David_fitRes_folder_raw, "fitRes.mat");
David_fitRes_data_raw = load(David_fitRes_file_raw);

% Cherry table for cherry evaluation
cherry_table_file = fullfile("D:\work\ZJU_entire_skin\Cherry\software\skin colour\鏁版嵁鍒嗘瀽\鍒嗘瀽杩囩▼\resTable\manual\cherry_ellipse_fits.mat");
cherry_table_data = load(cherry_table_file);
cherry_table = cherry_table_data.fit_table;
idx = strcmp(cherry_table.observer_type, "weighted(o:30,s:30,c:31)");
cherry_table = cherry_table(idx, :);

% OPPO (Peggy_OPPO) table for OPPO evaluation
Peggy_OPPO_folder = "D:\work\project_code_backup\OPPOskinExpe\analyzeResult_scaled\AnalyseResults_p\display\rela\efit_p\resTable";
Peggy_OPPO_file = fullfile(Peggy_OPPO_folder, "Peggy_OPPO_table.mat");
Peggy_OPPO_data = load(Peggy_OPPO_file);
Peggy_OPPO_table = Peggy_OPPO_data.fit_table(1:52,:);

lastParts_OPPO = ["inLab","indoorAdd","outdoorAdd","sunsetAdd","nightAdd"];

output_folder = fullfile("res", "all_in_one_5sources");
if ~exist(output_folder, "dir")
    mkdir(output_folder);
end

%% -------------------- Evaluation on SUMMER --------------------
n_summer = size(summer_table, 1);
summer_r_david = nan(n_summer,1);
summer_r_cherry = nan(n_summer,1);
summer_r_summer = nan(n_summer,1);
summer_r_OPPO = nan(n_summer,1);
summer_r_peggy = nan(n_summer,1);
summer_de_david = nan(n_summer,1);
summer_de_cherry = nan(n_summer,1);
summer_de_summer = nan(n_summer,1);
summer_de_OPPO = nan(n_summer,1);
summer_de_peggy = nan(n_summer,1);

for i_img = 1:n_summer
    if strcmp(summer_table.model_ethnicity{i_img}, "Oriental")
        i_david = 4;
        i_cherry = 3;
    elseif strcmp(summer_table.model_ethnicity{i_img}, "Caucasian")
        i_david = 5;
        i_cherry = 4;
    elseif strcmp(summer_table.model_ethnicity{i_img}, "African")
        i_david = 0;
        i_cherry = 1;
    elseif strcmp(summer_table.model_ethnicity{i_img}, "South Asian")
        i_david = 0;
        i_cherry = 2;
    end

    % david
    if i_david > 0
        par_david = David_fitRes_data_CATed.par(i_david,:);
        cen_david = par_david(1,5:7);
    else
        par_david = nan(1,8);
        cen_david = nan(1,3);
    end

    % summer (reference)
    par_summer = summer_table.par{i_img};
    cen_summer = summer_table.lab_center{i_img};
    points_summer = summer_table.lab_values{i_img};
    scores_summer = summer_table.opinion_scores{i_img};
    xyz_cen_summer = lab2xyz(cen_summer, "d65_64");

    y_summer = cal_y(par_summer, points_summer, "ellipsoidfit5");
    summer_r_summer(i_img,1) = corr(y_summer(1:17,1), scores_summer(1:17,1), 'Type', 'Pearson');
    summer_de_summer(i_img,1) = deltaE2000(cen_summer, cen_summer);

    % david (scale to summer)
    lab_cen_david = cen_david;
    xyz_cen_david = lab2xyz2(lab_cen_david, "d65_64");
    xyz_cen_david1 = xyz_cen_david ./ xyz_cen_david(2) .* xyz_cen_summer(2);
    lab_cen_david1 = xyz2lab(xyz_cen_david1, "d65_64");
    par_david(1,5:7) = lab_cen_david1;
    cen_david = par_david(1,5:7);

    y_david = cal_y(par_david, points_summer, "ellipsoidfit4");
    summer_r_david(i_img,1) = corr(y_david, scores_summer, 'Type', 'Pearson');
    summer_de_david(i_img,1) = deltaE2000(cen_david, cen_summer);

    % cherry (scale to summer)
    par_cherry = cherry_fitRes_data.par_all(i_cherry,:);
    cen_cherry = par_cherry(1,5:7);
    lab_cen_cherry = cen_cherry;
    xyz_cen_cherry = lab2xyz2(lab_cen_cherry, "d65_64");
    xyz_cen_cherry1 = xyz_cen_cherry ./ xyz_cen_cherry(2) .* xyz_cen_summer(2);
    lab_cen_cherry1 = xyz2lab(xyz_cen_cherry1, "d65_64");
    par_cherry(1,5:7) = lab_cen_cherry1;
    cen_cherry = par_cherry(1,5:7);

    y_cherry = cal_y(par_cherry, points_summer, "ellipsoidfit3_1");
    summer_r_cherry(i_img,1) = corr(y_cherry, scores_summer, 'Type', 'Pearson');
    summer_de_cherry(i_img,1) = deltaE2000(cen_cherry, cen_summer);

    % peggy
    [y_peggy, par_peggy, ~] = predict_my(points_summer(1,1), points_summer, 1, "01Preference");
    cen_peggy = [points_summer(1,1), par_peggy(1,4:5)];
    summer_r_peggy(i_img,1) = corr(y_peggy, scores_summer, 'Type', 'Pearson');
    summer_de_peggy(i_img,1) = deltaE2000(cen_peggy, cen_summer);

    % OPPO (scale to summer)
    lastPart_OPPO = "inLab";
    OPPO_folder = fullfile("D:\work\project_code_backup\OPPOskinExpe\analyzeResult_scaled\" + ...
        "AnalyseResults_p\display\rela\efit_p\scene", lastPart_OPPO, "ellipPara_scaled");
    OPPO_data = load(fullfile(OPPO_folder, "fitRes_level.mat"));
    par_OPPO = OPPO_data.par;
    cen_OPPO = par_OPPO(1,5:7);

    lab_cen_OPPO = cen_OPPO;
    xyz_cen_OPPO = lab2xyz2(lab_cen_OPPO, "d65_64");
    xyz_cen_OPPO1 = xyz_cen_OPPO ./ xyz_cen_OPPO(2) .* xyz_cen_summer(2);
    lab_cen_OPPO1 = xyz2lab(xyz_cen_OPPO1, "d65_64");
    par_OPPO(1,5:7) = lab_cen_OPPO1;
    cen_OPPO = par_OPPO(1,5:7);

    y_OPPO = cal_y(par_OPPO, points_summer, "ellipsoidfit5");
    summer_r_OPPO(i_img,1) = corr(y_OPPO, scores_summer, 'Type', 'Pearson');
    summer_de_OPPO(i_img,1) = deltaE2000(cen_OPPO, cen_summer);
end

result_summer = [nanmean(summer_de_david), mean(summer_de_cherry), ...
    nanmean(summer_de_summer), mean(summer_de_OPPO), mean(summer_de_peggy)];

%% -------------------- Evaluation on CHERRY --------------------
dim_idxs_david = [2:17;18:33;34:49];
dim_idxs_cherry = [1:16;33:48;17:32];
summer_ethnicities = ["African","Caucasian","Oriental","South Asian"];
order = [1, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, ...
    2, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, ...
    3, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, ...
    4, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 5, 6, 7, 8, 9];
idx_used = zeros(length(order),1);
for idx = 1:length(order)
    idx_used(idx,1) = find(order==idx);
end

n_cherry = size(cherry_table, 1);
cherry_r_david = nan(n_cherry,1);
cherry_r_cherry = nan(n_cherry,1);
cherry_r_summer = nan(n_cherry,1);
cherry_r_OPPO = nan(n_cherry,1);
cherry_r_peggy = nan(n_cherry,1);
cherry_de_david = nan(n_cherry,1);
cherry_de_cherry = nan(n_cherry,1);
cherry_de_summer = nan(n_cherry,1);
cherry_de_OPPO = nan(n_cherry,1);
cherry_de_peggy = nan(n_cherry,1);

for i_img = 1:n_cherry
    cherry_ethnicity = cherry_table.model_ethnicity{i_img};
    cherry_ethnicity = strrep(cherry_ethnicity, "(YY)", "");
    cherry_ethnicity = strrep(cherry_ethnicity, "(YO)", "");

    if strcmp(cherry_ethnicity, "African")
        i_cherry = 1;
    elseif strcmp(cherry_ethnicity, "South Asian")
        i_cherry = 2;
    elseif strcmp(cherry_ethnicity, "Oriental")
        i_cherry = 3;
    elseif strcmp(cherry_ethnicity, "Caucasian")
        i_cherry = 4;
    end

    % cherry (reference)
    par_cherry = cherry_table.par{i_img}; par_cherry = par_cherry';
    cen_cherry = par_cherry(1,5:7);
    par_cherry1 = cherry_fitRes_data.par_all(i_cherry,:);
    cen_cherry1 = par_cherry1(1,5:7);
    points_cherry = cherry_table.lab_values{i_img};
    scores_cherry = cherry_table.opinion_scores{i_img};
    points_cherry = points_cherry(idx_used,:);
    scores_cherry = scores_cherry(idx_used,:);
    xyz_cen_cherry = lab2xyz2(cen_cherry, "d65_64");

    y_cherry = cal_y(par_cherry1, points_cherry, "ellipsoidfit3_1");
    cherry_r_cherry(i_img,1) = corr(y_cherry, scores_cherry, 'Type', 'Pearson');
    cherry_de_cherry(i_img,1) = deltaE2000(cen_cherry1, cen_cherry);

    % david (scale to cherry)
    if strcmp(cherry_ethnicity, "Caucasian")
        par_david = David_fitRes_data_raw.par(5,:);
        cen_david = David_fitRes_data_raw.par(5,5:7);
    elseif strcmp(cherry_ethnicity, "Asian") || strcmp(cherry_ethnicity, "Oriental")
        par_david = David_fitRes_data_raw.par(4,:);
        cen_david = David_fitRes_data_raw.par(4,5:7);
    else
        par_david = nan(1,8);
        cen_david = nan(1,3);
    end
    lab_cen_david = cen_david;
    xyz_cen_david = lab2xyz2(lab_cen_david, "d65_64");
    xyz_cen_david1 = xyz_cen_david ./ xyz_cen_david(2) .* xyz_cen_cherry(2);
    lab_cen_david1 = xyz2lab(xyz_cen_david1, "d65_64");
    par_david(1,5:7) = lab_cen_david1;
    cen_david = par_david(1,5:7);

    y_david = cal_y(par_david, points_cherry, "ellipsoidfit4");
    cherry_r_david(i_img,1) = corr(y_david(dim_idxs_cherry(1,:),1), scores_cherry(dim_idxs_cherry(1,:),1), 'Type', 'Pearson');
    cherry_de_david(i_img,1) = deltaE2000(par_david(1,5:7), par_cherry(1,5:7));

    % summer (scale to cherry)
    for i_match = 1:length(summer_ethnicities)
        if strcmp(cherry_ethnicity, summer_ethnicities(i_match))
            break
        end
    end
    par_summer = summer_table.par{i_match};
    cen_summer = summer_table.lab_center{i_match};

    lab_cen_summer = cen_summer;
    xyz_cen_summer = lab2xyz2(lab_cen_summer, "d65_64");
    xyz_cen_summer1 = xyz_cen_summer ./ xyz_cen_summer(2) .* xyz_cen_cherry(2);
    lab_cen_summer1 = xyz2lab(xyz_cen_summer1, "d65_64");
    par_summer(1,5:7) = lab_cen_summer1;
    cen_summer = par_summer(1,5:7);

    y_summer = cal_y(par_summer, points_cherry, "ellipsoidfit5");
    cherry_r_summer(i_img,1) = corr(y_summer(dim_idxs_cherry(1,:),1), scores_cherry(dim_idxs_cherry(1,:),1), 'Type', 'Pearson');
    cherry_de_summer(i_img,1) = deltaE2000(cen_summer, par_cherry(1,5:7));

    % peggy
    [y_peggy, par_peggy, ~] = predict_my(points_cherry(1,1), points_cherry, 1, "01Preference");
    cherry_r_peggy(i_img,1) = corr(y_peggy(dim_idxs_cherry(1,:),1), scores_cherry(dim_idxs_cherry(1,:),1), 'Type', 'Pearson');
    cherry_de_peggy(i_img,1) = deltaE2000([par_cherry(1,5), par_peggy(1,4:5)], par_cherry(1,5:7));

    % OPPO (scale to cherry)
    lastPart_OPPO = "inLab";
    OPPO_folder = fullfile("D:\work\project_code_backup\OPPOskinExpe\analyzeResult_scaled\" + ...
        "AnalyseResults_p\display\rela\efit_p\scene", lastPart_OPPO, "ellipPara_scaled");
    OPPO_data = load(fullfile(OPPO_folder, "fitRes_level.mat"));
    par_OPPO = OPPO_data.par;
    cen_OPPO = par_OPPO(1,5:7);

    lab_cen_OPPO = cen_OPPO;
    xyz_cen_OPPO = lab2xyz2(lab_cen_OPPO, "d65_64");
    xyz_cen_OPPO1 = xyz_cen_OPPO ./ xyz_cen_OPPO(2) .* xyz_cen_cherry(2);
    lab_cen_OPPO1 = xyz2lab(xyz_cen_OPPO1, "d65_64");
    par_OPPO(1,5:7) = lab_cen_OPPO1;
    cen_OPPO = par_OPPO(1,5:7);

    y_OPPO = cal_y(par_OPPO, points_cherry, "ellipsoidfit5");
    cherry_r_OPPO(i_img,1) = corr(y_OPPO, scores_cherry, 'Type', 'Pearson');
    cherry_de_OPPO(i_img,1) = deltaE2000(cen_OPPO, cen_cherry);
end

cherry_de_all = [cherry_de_david, cherry_de_summer, cherry_de_cherry, cherry_de_OPPO, cherry_de_peggy];
result_cherry = nanmean(cherry_de_all, 1);

%% -------------------- Evaluation on DAVID --------------------
n_david = size(david_table, 1);
david_r_david = nan(n_david,1);
david_r_cherry = nan(n_david,1);
david_r_summer = nan(n_david,1);
david_r_OPPO = nan(n_david,1);
david_r_peggy = nan(n_david,1);
david_de_david = nan(n_david,1);
david_de_cherry = nan(n_david,1);
david_de_summer = nan(n_david,1);
david_de_OPPO = nan(n_david,1);
david_de_peggy = nan(n_david,1);

for i_img = 1:n_david
    points_david = david_table.lab_values{i_img};
    scores_david = david_table.opinion_scores{i_img};

    if ismember(david_table.model_id{i_img}, ["skin_1","skin_5","skin_7","skin_9","skin_10"])
        i_cherry = 3;
        i_summer = 3;
        i_david = 4;
    else
        i_cherry = 4;
        i_summer = 2;
        i_david = 5;
    end
    if ismember(david_table.model_id{i_img}, ["skin_9","skin_10"])
        i_OPPO = 4;
    else
        i_OPPO = 2;
    end

    % david (reference + group)
    if i_david > 0
        par_david1 = David_fitRes_data_CATed.par(i_david,:);
        cen_david1 = par_david1(1,5:7);
    else
        par_david1 = nan(1,8);
        cen_david1 = nan(1,3);
    end
    par_david = david_table.par{i_img};
    cen_david = par_david(1,5:7);
    xyz_cen_David = lab2xyz2(cen_david, "d65_64");

    lab_cen_david = cen_david;
    xyz_cen_david = lab2xyz2(lab_cen_david, "d65_64");
    xyz_cen_david1 = xyz_cen_david ./ xyz_cen_david(2) .* xyz_cen_David(2);
    lab_cen_david1 = xyz2lab(xyz_cen_david1, "d65_64");
    par_david(1,5:7) = lab_cen_david1;
    cen_david = par_david(1,5:7);

    y_david = cal_y(par_david1, points_david, "ellipsoidfit4");
    david_r_david(i_img,1) = corr(y_david, scores_david, 'Type', 'Pearson');
    david_de_david(i_img,1) = deltaE2000(cen_david1, cen_david);

    % cherry (scale to david)
    par_cherry = cherry_fitRes_data.par_all(i_cherry,:);
    cen_cherry = par_cherry(1,5:7);
    lab_cen_cherry = cen_cherry;
    xyz_cen_cherry = lab2xyz2(lab_cen_cherry, "d65_64");
    xyz_cen_cherry1 = xyz_cen_cherry ./ xyz_cen_cherry(2) .* xyz_cen_David(2);
    lab_cen_cherry1 = xyz2lab(xyz_cen_cherry1, "d65_64");
    par_cherry(1,5:7) = lab_cen_cherry1;
    cen_cherry = par_cherry(1,5:7);

    y_cherry = cal_y(par_cherry, points_david, "ellipsoidfit3_1");
    david_r_cherry(i_img,1) = corr(y_cherry(1:17,1), scores_david(1:17,1), 'Type', 'Pearson');
    david_de_cherry(i_img,1) = deltaE2000(cen_cherry, cen_david);

    % summer (scale to david)
    par_summer = summer_table.par{i_summer}; par_summer = par_summer';
    cen_summer = summer_table.lab_center{i_summer};
    lab_cen_summer = cen_summer;
    xyz_cen_summer = lab2xyz2(lab_cen_summer, "d65_64");
    xyz_cen_summer1 = xyz_cen_summer ./ xyz_cen_summer(2) .* xyz_cen_David(2);
    lab_cen_summer1 = xyz2lab(xyz_cen_summer1, "d65_64");
    cen_summer = lab_cen_summer1;
    par_summer(1,5:6) = cen_summer(1,2:3);

    y_summer = cal_y(par_summer, points_david, "ellipsoidfit5");
    david_r_summer(i_img,1) = corr(y_summer(1:17,1), scores_david(1:17,1), 'Type', 'Pearson');
    david_de_summer(i_img,1) = deltaE2000(cen_summer, par_david(1,5:7));

    % peggy
    [y_peggy, par_peggy, ~] = predict_my(points_david(1,1), points_david, 1, "01Preference");
    cen_peggy = [points_david(1,1), par_peggy(1,4:5)];
    david_r_peggy(i_img,1) = corr(y_peggy(1:17,1), scores_david(1:17,1), 'Type', 'Pearson');
    david_de_peggy(i_img,1) = deltaE2000(cen_peggy, cen_david);

    % OPPO (scale to david)
    lastPart_OPPO = char(lastParts_OPPO(i_OPPO));
    OPPO_folder = fullfile("D:\work\project_code_backup\OPPOskinExpe\analyzeResult_scaled\" + ...
        "AnalyseResults_p\display\rela\efit_p\scene", lastPart_OPPO, "ellipPara_scaled");
    OPPO_data = load(fullfile(OPPO_folder, "fitRes_level.mat"));
    par_OPPO = OPPO_data.par;
    cen_OPPO = par_OPPO(1,5:7);

    lab_cen_OPPO = cen_OPPO;
    xyz_cen_OPPO = lab2xyz2(lab_cen_OPPO, "d65_64");
    xyz_cen_OPPO1 = xyz_cen_OPPO ./ xyz_cen_OPPO(2) .* xyz_cen_David(2);
    lab_cen_OPPO1 = xyz2lab(xyz_cen_OPPO1, "d65_64");
    par_OPPO(1,5:7) = lab_cen_OPPO1;
    cen_OPPO = par_OPPO(1,5:7);

    y_OPPO = cal_y(par_OPPO, points_david, "ellipsoidfit5");
    david_r_OPPO(i_img,1) = corr(y_OPPO, scores_david, 'Type', 'Pearson');
    david_de_OPPO(i_img,1) = deltaE2000(cen_OPPO, cen_david);
end

result_david = [nanmean(david_de_david), mean(david_de_cherry), mean(david_de_summer), mean(david_de_OPPO), mean(david_de_peggy)];

%% -------------------- Evaluation on OPPO (Peggy_OPPO) --------------------
dims_OPPO = [1:16;33:48;17:32];
par_YY = cherry_fitRes_data.par_all(3,:);
par_david = David_fitRes_data_CATed.par(4,:);

n_OPPO = size(Peggy_OPPO_table, 1);
OPPO_r_david = nan(n_OPPO,1);
OPPO_r_cherry = nan(n_OPPO,1);
OPPO_r_summer = nan(n_OPPO,1);
OPPO_r_OPPO = nan(n_OPPO,1);
OPPO_r_peggy = nan(n_OPPO,1);
OPPO_de_david = nan(n_OPPO,1);
OPPO_de_cherry = nan(n_OPPO,1);
OPPO_de_summer = nan(n_OPPO,1);
OPPO_de_OPPO = nan(n_OPPO,1);
OPPO_de_peggy = nan(n_OPPO,1);

for i_img = 1:n_OPPO
    points_OPPO = Peggy_OPPO_table.lab_values{i_img};
    scores_OPPO = Peggy_OPPO_table.opinion_scores{i_img};
    par_OPPO = Peggy_OPPO_table.par{i_img};
    cen_OPPO = par_OPPO(1,5:7);

    % scene-level OPPO parameters
    for i_OPPO = 1:length(lastParts_OPPO)
        if contains(Peggy_OPPO_table.scene{i_img}, lastParts_OPPO(i_OPPO))
            break
        end
    end
    lastPart_OPPO = char(lastParts_OPPO(i_OPPO));
    OPPO_folder = fullfile("D:\work\project_code_backup\OPPOskinExpe\analyzeResult_scaled\" + ...
        "AnalyseResults_p\display\rela\efit_p\scene", lastPart_OPPO, "ellipPara_scaled");
    OPPO_data = load(fullfile(OPPO_folder, "fitRes_level.mat"));
    par_OPPO_scene = OPPO_data.par;
    cen_OPPO_scene = par_OPPO_scene(1,5:7);
    xyz_cen_OPPO_scene = lab2xyz2(cen_OPPO_scene, "d65_64");

    % OPPO (scene-level scaled to per-image OPPO)
    lab_cen_OPPO = cen_OPPO;
    xyz_cen_OPPO = lab2xyz2(lab_cen_OPPO, "d65_64");
    xyz_cen_OPPO1 = xyz_cen_OPPO_scene ./ xyz_cen_OPPO_scene(2) .* xyz_cen_OPPO(2);
    lab_cen_OPPO1 = xyz2lab(xyz_cen_OPPO1, "d65_64");
    par_OPPO_scene1(1,5:7) = lab_cen_OPPO1;
    cen_OPPO_scene = par_OPPO_scene1(1,5:7);

    y_OPPO = cal_y(par_OPPO, points_OPPO, "ellipsoidfit5");
    OPPO_r_OPPO(i_img,1) = corr(y_OPPO, scores_OPPO, 'Type', 'Pearson');
    OPPO_de_OPPO(i_img,1) = deltaE2000(cen_OPPO, cen_OPPO_scene);

    % david (scale to per-image OPPO)
    lab_cen_david = par_david(1,5:7);
    xyz_cen_david = lab2xyz2(lab_cen_david, "d65_64");
    xyz_cen_david1 = xyz_cen_david ./ xyz_cen_david(2) .* xyz_cen_OPPO(2);
    lab_cen_david1 = xyz2lab(xyz_cen_david1, "d65_64");
    par_david(1,5:7) = lab_cen_david1;
    cen_david = par_david(1,5:7);

    y_david = cal_y(par_david, points_OPPO, "ellipsoidfit4");
    OPPO_r_david(i_img,1) = corr(y_david, scores_OPPO, 'Type', 'Pearson');
    OPPO_de_david(i_img,1) = deltaE2000(cen_david, cen_OPPO);

    % cherry (scale to per-image OPPO)
    par_cherry = par_YY;
    cen_cherry = par_cherry(1,5:7);
    lab_cen_cherry = cen_cherry;
    xyz_cen_cherry = lab2xyz2(lab_cen_cherry, "d65_64");
    xyz_cen_cherry1 = xyz_cen_cherry ./ xyz_cen_cherry(2) .* xyz_cen_OPPO(2);
    lab_cen_cherry1 = xyz2lab(xyz_cen_cherry1, "d65_64");
    par_cherry(1,5:7) = lab_cen_cherry1;
    cen_cherry = par_cherry(1,5:7);

    y_cherry = cal_y(par_cherry, points_OPPO, "ellipsoidfit3_1");
    OPPO_r_cherry(i_img,1) = corr(y_cherry(1:17,1), scores_OPPO(1:17,1), 'Type', 'Pearson');
    OPPO_de_cherry(i_img,1) = deltaE2000(cen_cherry, cen_OPPO);

    % summer (scale to per-image OPPO)
    par_summer = summer_table_all.par{14}';
    cen_summer = summer_table_all.lab_center{14};
    lab_cen_summer = cen_summer;
    xyz_cen_summer = lab2xyz2(lab_cen_summer, "d65_64");
    xyz_cen_summer1 = xyz_cen_summer ./ xyz_cen_summer(2) .* xyz_cen_OPPO(2);
    lab_cen_summer1 = xyz2lab(xyz_cen_summer1, "d65_64");
    par_summer(1,5:7) = lab_cen_summer1;
    cen_summer = par_summer(1,5:7);

    y_summer = cal_y(par_summer, points_OPPO, "ellipsoidfit5");
    OPPO_r_summer(i_img,1) = corr(y_summer, scores_OPPO, 'Type', 'Pearson');
    OPPO_de_summer(i_img,1) = deltaE2000(cen_summer, cen_OPPO);

    % peggy
    [y_peggy, par_peggy, ~] = predict_my(points_OPPO(1,1), points_OPPO, 1, "01Preference");
    OPPO_r_peggy(i_img,1) = corr(y_peggy(dims_OPPO(1,:),1), scores_OPPO(dims_OPPO(1,:),1), 'Type', 'Pearson');
    cen_peggy = [par_OPPO(1,5), par_peggy(1,4:5)];
    OPPO_de_peggy(i_img,1) = deltaE2000(cen_peggy, par_OPPO(1,5:7));
end

result_OPPO = [mean(OPPO_de_david), mean(OPPO_de_cherry), mean(OPPO_de_summer), mean(OPPO_de_OPPO), mean(OPPO_de_peggy)];

%% -------------------- Summary --------------------
source_names = ["david","cherry","summer","OPPO","peggy"];
target_names = ["david","cherry","summer","OPPO"];
result_all = [result_david; result_cherry; result_summer; result_OPPO];
result_table = array2table(result_all, "VariableNames", source_names, "RowNames", target_names);

disp(result_table);
save(fullfile(output_folder, "predict_all_in_one_5sources.mat"), ...
    "result_all", "result_table", ...
    "result_david", "result_cherry", "result_summer", "result_OPPO", ...
    "david_de_david", "david_de_cherry", "david_de_summer", "david_de_OPPO", "david_de_peggy", ...
    "cherry_de_david", "cherry_de_cherry", "cherry_de_summer", "cherry_de_OPPO", "cherry_de_peggy", ...
    "summer_de_david", "summer_de_cherry", "summer_de_summer", "summer_de_OPPO", "summer_de_peggy", ...
    "OPPO_de_david", "OPPO_de_cherry", "OPPO_de_summer", "OPPO_de_OPPO", "OPPO_de_peggy");

