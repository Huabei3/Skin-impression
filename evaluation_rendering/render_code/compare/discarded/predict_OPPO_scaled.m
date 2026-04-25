%% 新增带缩放计算的OPPO评价脚本
clear; clc; close all;

% -------------------------- 1. 基础配置与数据加载 --------------------------
dims_OPPO = [1:16;33:48;17:32];

% Peggy OPPO数据
Peggy_OPPO_folder = "D:\work\project_code_backup\OPPOskinExpe\analyzeResult_scaled\AnalyseResults_p\display\rela\efit_p\resTable";
Peggy_OPPO_file = fullfile(Peggy_OPPO_folder, "Peggy_OPPO_table.mat");
Peggy_OPPO_data = load(Peggy_OPPO_file);
Peggy_OPPO_table = Peggy_OPPO_data.fit_table(1:52,:);

% Cherry数据
cherry_fitRes_file = fullfile("D:\work\ZJU_entire_skin\Cherry\software\skin colour\数据分析\分析过程\res\nation\weighted\fitRes\ellipPara.mat");
cherry_fitRes_data = load(cherry_fitRes_file);
par_YY = cherry_fitRes_data.par_all(3,:);

% Summer数据
summer_table_file = fullfile("D:\work\ZJU_entire_skin\Summer\Data\Haisi skin\3. Test experiment\4. Model\res\resTable\Summer_table.mat");
summer_table_data = load(summer_table_file);
summer_table = summer_table_data.fit_table;

% David数据
David_fitRes_folder = fullfile("D:\work\ZJU_entire_skin\David\Naturalness model\Jason's final project\data analysis\res\CATed\fitRes");
David_fitRes_file = fullfile(David_fitRes_folder, "fitRes.mat");
David_fitRes_data = load(David_fitRes_file);
par_david = David_fitRes_data.par(4,:);
cen_david = par_david(1,5:7);

% 图像路径配置
OPPO_ori_img_folder = "D:\work\ZJU_entire_skin\ZJU_skin_database\A_images\Peggy_OPPO\original_imgs\i";
OPPO_mask_folder = fullfile(OPPO_ori_img_folder, "mask");
dir_OPPO_ori_img = dir(fullfile(OPPO_ori_img_folder, "*.jpg"));
dir_OPPO_mask = dir(fullfile(OPPO_mask_folder, "*.jpg"));
OPPO_ori_img_folder = "D:\work\ZJU_entire_skin\ZJU_skin_database\A_images\Peggy_OPPO\original_imgs\r\cropped";
OPPO_mask_folder = fullfile(OPPO_ori_img_folder, "mask");
dir_OPPO_ori_img = [dir_OPPO_ori_img;dir(fullfile(OPPO_ori_img_folder,"*.jpg"))];
dir_OPPO_mask = [dir_OPPO_mask;dir(fullfile(OPPO_mask_folder,"*.jpg"))];

% 输出文件夹
output_folder = fullfile("res","pic","on_Peggy_OPPO_scaled");
if ~exist(output_folder,"dir")
    mkdir(output_folder);
end

% -------------------------- 2. 初始化结果数组 --------------------------
% 原始结果
r_david = zeros(size(Peggy_OPPO_table,1),1);
r_cherry = zeros(size(Peggy_OPPO_table,1),1);
r_summer = zeros(size(Peggy_OPPO_table,1),1);
r_peggy = zeros(size(Peggy_OPPO_table,1),1);
de_david = zeros(size(Peggy_OPPO_table,1),1);
de_cherry = zeros(size(Peggy_OPPO_table,1),1);
de_summer = zeros(size(Peggy_OPPO_table,1),1);
de_peggy = zeros(size(Peggy_OPPO_table,1),1);

% 缩放后结果
r_david_scaled = zeros(size(Peggy_OPPO_table,1),1);
r_cherry_scaled = zeros(size(Peggy_OPPO_table,1),1);
r_summer_scaled = zeros(size(Peggy_OPPO_table,1),1);
de_david_scaled = zeros(size(Peggy_OPPO_table,1),1);
de_cherry_scaled = zeros(size(Peggy_OPPO_table,1),1);
de_summer_scaled = zeros(size(Peggy_OPPO_table,1),1);

% -------------------------- 3. 循环处理每张图片 --------------------------
for i_img = 1:size(Peggy_OPPO_table,1)
    % 提取当前图片数据
    points_Peggy_OPPO = Peggy_OPPO_table.lab_values{i_img};
    scores_Peggy_OPPO = Peggy_OPPO_table.opinion_scores{i_img};
    source_name = Peggy_OPPO_table.source{i_img};
    par_Peggy_OPPO = Peggy_OPPO_table.par{i_img};
    % ref_cen_lab = par_Peggy_OPPO(1,5:7); % 参考中心（Peggy OPPO）
    ref_cen_lab=points_Peggy_OPPO(end,:);
   
    % 匹配原始图像和掩码
    source_name1 = strrep(source_name,"Peggy_OPPO_","");
    for i_match = 1:length(dir_OPPO_ori_img)
        img_name = strrep(dir_OPPO_ori_img(i_match).name,".jpg","");
        img_name = strrep(img_name,".JPG","");
        img_name = strrep(img_name,"cropped_","");
        if strcmp(img_name,source_name1)
            break
        end
    end
    
    % 加载并处理图像
    ori_img = imread(fullfile(dir_OPPO_ori_img(i_match).folder,dir_OPPO_ori_img(i_match).name));
    mask = imread(fullfile(dir_OPPO_mask(i_match).folder,dir_OPPO_mask(i_match).name));
    ori_img = double(ori_img);
    sz = size(ori_img);
    ori_img_lin = reshape(ori_img,[sz(1)*sz(2),sz(3)]);
    xyz_img_lin = srgb2xyz(ori_img_lin);
    lab_img_lin = xyz2lab(xyz_img_lin,"d65_64");
    [logicalIndex,~] = read_bull(mask,0);
    average = mean(lab_img_lin(~logicalIndex, :));
    
    % -------------------------- 3.1 David（原始+缩放） --------------------------
    % 直接一次性获取所有结果，无需额外计算r_david
    [r_david(i_img,1), r_david_scaled(i_img,1), ...
        de_david(i_img,1), de_david_scaled(i_img,1), ~, ~,cen_david_scaled] = ...
        calculate_scaled_params(par_david, points_Peggy_OPPO, scores_Peggy_OPPO, dims_OPPO, ref_cen_lab, "ellipsoidfit4");

    
    % 渲染David效果（可选启用）
    % render_lab_adjusted_image(lab_img_lin, logicalIndex, average, par_david(1,5:7), sz, output_folder, "cen_david", img_name);
    % render_lab_adjusted_image(lab_img_lin, logicalIndex, average, par_david_scaled(1,5:7), sz, output_folder, "cen_david_scaled", img_name);
    
    % -------------------------- 3.2 Cherry（原始+缩放） --------------------------
    [r_cherry(i_img,1), r_cherry_scaled(i_img,1), ...
        de_cherry(i_img,1), de_cherry_scaled(i_img,1), ~, ~,cen_cherry_scaled] = ...
        calculate_scaled_params(par_YY, points_Peggy_OPPO, scores_Peggy_OPPO, dims_OPPO, ref_cen_lab, "ellipsoidfit3_1");

    
    % 渲染Cherry效果（可选启用）
    % render_lab_adjusted_image(lab_img_lin, logicalIndex, average, par_YY(1,5:7), sz, output_folder, "cen_cherry", img_name);
    % render_lab_adjusted_image(lab_img_lin, logicalIndex, average, par_YY_scaled(1,5:7), sz, output_folder, "cen_cherry_scaled", img_name);
    
    % -------------------------- 3.3 Summer（原始+缩放） --------------------------
    par_summer = summer_table.par{14}';
    cen_summer=summer_table.lab_center{14};
    [r_summer(i_img,1), r_summer_scaled(i_img,1),...
        de_summer(i_img,1), de_summer_scaled(i_img,1), ~, ~,cen_summer_scaled] = ...
        calculate_scaled_params_2d(par_summer,cen_summer, points_Peggy_OPPO, scores_Peggy_OPPO, dims_OPPO, ref_cen_lab, "ellipsoidfit5");
    
    % 渲染Summer效果（可选启用）
    % render_lab_adjusted_image(lab_img_lin, logicalIndex, average, summer_table.lab_center{14}, sz, output_folder, "cen_summer", img_name);
    % render_lab_adjusted_image(lab_img_lin, logicalIndex, average, par_summer_scaled(1,5:7), sz, output_folder, "cen_summer_scaled", img_name);
    
    % -------------------------- 3.4 Peggy（仅原始） --------------------------
    [y_peggy,par_peggy,~] = predict_my(points_Peggy_OPPO(1,1),points_Peggy_OPPO,1,"01Preference");
    [r_peggy(i_img,1)] = corr(y_peggy(dims_OPPO(1,:),1), scores_Peggy_OPPO(dims_OPPO(1,:),1), 'Type', 'Pearson');    
    cen_peggy = [par_Peggy_OPPO(1,5),par_peggy(1,4:5)];
    de_peggy(i_img,1) = deltaE2000(cen_peggy, ref_cen_lab);

    % -------------------------- 3.5 绘制散点图（复用原逻辑） --------------------------
    % a-b图
    figure(1); hold on;
    plot(points_Peggy_OPPO(dims_OPPO(1,:),2),points_Peggy_OPPO(dims_OPPO(1,:),3),  'o', 'Color', 'b', 'MarkerSize', 6);
    plot(par_peggy(1,4),par_peggy(1,5),  's', 'Color', 'r','MarkerFaceColor','r', 'MarkerSize', 6);
    % plot(par_YY(1,6),par_YY(1,7),  'p', 'Color', 'g','MarkerFaceColor','g', 'MarkerSize', 6);
    % plot(summer_table.lab_center{14}(1,2),summer_table.lab_center{14}(1,3),  'p', 'Color', 'k','MarkerFaceColor','k', 'MarkerSize', 6);    
    
    plot(cen_david_scaled(1,2),cen_david_scaled(1,3),  'p', 'Color', 'b', 'MarkerFaceColor','r','MarkerSize', 6);
    plot(cen_cherry_scaled(1,2),cen_cherry_scaled(1,3),  'p', 'Color', 'g', 'MarkerFaceColor','g','MarkerSize', 6);
    plot(cen_summer_scaled(1,2),cen_summer_scaled(1,3),  'p', 'Color', 'k','MarkerFaceColor','k', 'MarkerSize', 6);  
    
    plot(par_Peggy_OPPO(1,6),par_Peggy_OPPO(1,7),  '^', 'Color', 'b','MarkerFaceColor','b', 'MarkerSize', 6);
    output_subfolder = fullfile(output_folder,"a_b");
    if ~exist(output_subfolder,"dir")
        mkdir(output_subfolder);
    end
    exportgraphics(gcf,fullfile(output_subfolder,strcat(source_name,".jpg")));
    close(gcf);

    % L-a图
    figure(2); hold on;
    plot(points_Peggy_OPPO(dims_OPPO(2,:),2),points_Peggy_OPPO(dims_OPPO(2,:),1),  'o', 'Color', 'b', 'MarkerSize', 6);
    plot(par_peggy(1,4),points_Peggy_OPPO(1,1),  's', 'Color', 'r', 'MarkerFaceColor','r','MarkerSize', 6);
    % plot(par_YY(1,6),par_YY(1,5),  'p', 'Color', 'g','MarkerFaceColor','g', 'MarkerSize', 6);
    % plot(summer_table.lab_center{14}(1,2),summer_table.lab_center{14}(1,1),  'p', 'Color', 'k','MarkerFaceColor','k', 'MarkerSize', 6);    
    
    plot(cen_david_scaled(1,2),cen_david_scaled(1,1),  'p', 'Color', 'b', 'MarkerFaceColor','r','MarkerSize', 6);
    plot(cen_cherry_scaled(1,2),cen_cherry_scaled(1,1),  'p', 'Color', 'g', 'MarkerFaceColor','g','MarkerSize', 6);
    plot(cen_summer_scaled(1,2),cen_summer_scaled(1,1),  'p', 'Color', 'k','MarkerFaceColor','k', 'MarkerSize', 6);  
    
    
    
    plot(par_Peggy_OPPO(1,6),par_Peggy_OPPO(1,5),  '^', 'Color', 'b','MarkerFaceColor','b', 'MarkerSize', 6);
    output_subfolder = fullfile(output_folder,"L_a");
    if ~exist(output_subfolder,"dir")
        mkdir(output_subfolder);
    end
    exportgraphics(gcf,fullfile(output_subfolder,strcat(source_name,".jpg")));
    close(gcf);

    % L-b图
    figure(3); hold on;
    plot(points_Peggy_OPPO(dims_OPPO(3,:),3),points_Peggy_OPPO(dims_OPPO(3,:),1),  'o', 'Color', 'b', 'MarkerSize', 6);
    plot(par_peggy(1,5),points_Peggy_OPPO(1,1),  's', 'Color', 'r', 'MarkerFaceColor','r','MarkerSize', 6);
    % plot(par_YY(1,7),par_YY(1,5),  'p', 'Color', 'g', 'MarkerFaceColor','g','MarkerSize', 6);
    % plot(summer_table.lab_center{14}(1,3),summer_table.lab_center{14}(1,1),  'p', 'Color', 'k','MarkerFaceColor','k', 'MarkerSize', 6);    
    
    
    plot(cen_david_scaled(1,3),cen_david_scaled(1,1),  'p', 'Color', 'b', 'MarkerFaceColor','r','MarkerSize', 6);
    plot(cen_cherry_scaled(1,3),cen_cherry_scaled(1,1),  'p', 'Color', 'g', 'MarkerFaceColor','g','MarkerSize', 6);
    plot(cen_summer_scaled(1,3),cen_summer_scaled(1,1),  'p', 'Color', 'k','MarkerFaceColor','k', 'MarkerSize', 6);   
    
    plot(par_Peggy_OPPO(1,7),par_Peggy_OPPO(1,5),  '^', 'Color', 'b','MarkerFaceColor','b', 'MarkerSize', 6);
    output_subfolder = fullfile(output_folder,"L_b");
    if ~exist(output_subfolder,"dir")
        mkdir(output_subfolder);
    end
    exportgraphics(gcf,fullfile(output_subfolder,strcat(source_name,".jpg")));
    close(gcf);
end

% -------------------------- 4. 结果汇总与保存 --------------------------
% 原始结果汇总
r_all = [r_david,r_cherry,r_summer,r_peggy];
de_all = [de_david,de_cherry,de_summer,de_peggy];

% 缩放后结果汇总（David/Cherry/Summer）
r_all_scaled = [r_david_scaled,r_cherry_scaled,r_summer_scaled, zeros(size(r_peggy))]; % Peggy无缩放
de_all_scaled = [de_david_scaled,de_cherry_scaled,de_summer_scaled, zeros(size(de_peggy))];

% 计算均值（原始）
de_all_mean(1,:) = mean(de_all(1:14,:),1);
de_all_mean(2,:) = mean(de_all(15:24,:),1);
de_all_mean(3,:) = mean(de_all(25:34,:),1);
de_all_mean(4,:) = mean(de_all(35:44,:),1);
de_all_mean(5,:) = mean(de_all(45:52,:),1);
de_all_mean(6,:) = mean(de_all,1);

% 计算均值（缩放后）
de_all_mean_scaled(1,:) = mean(de_all_scaled(1:14,:),1);
de_all_mean_scaled(2,:) = mean(de_all_scaled(15:24,:),1);
de_all_mean_scaled(3,:) = mean(de_all_scaled(25:34,:),1);
de_all_mean_scaled(4,:) = mean(de_all_scaled(35:44,:),1);
de_all_mean_scaled(5,:) = mean(de_all_scaled(45:52,:),1);
de_all_mean_scaled(6,:) = mean(de_all_scaled,1);

% 保存结果
save(fullfile(output_folder,"predict_compare_scaled.mat"), ...
    "r_all","de_all","de_all_mean", ...
    "r_all_scaled","de_all_scaled","de_all_mean_scaled");

