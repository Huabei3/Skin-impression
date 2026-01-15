close all; clc; clear;
%% 定义参数
attributes = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
attribute_names_new = ["Preference", "Attractiveness", "Feminine", "Cooperative", ...
    "Youth", "Healthy", "Fidelity", "Harmony", "Fair", "Ruddy"];
nations = ["AS", "CA", "SA", "AF"];
nation_names = ["Asian","Caucasian","South Asian","African"];
lastParts = {'f04i', 'f05i', 'f06i', 'm04i', 'm05i', 'm06i',...
'f01i', 'f02i', 'f03i', 'm01i', 'm02i', 'm03i',...
'f07i', 'f08i','m07i', 'm08i',...
'f09i', 'f10i','m09i', 'm10i'};n_para = 21;iOr='i';
% lastParts = {'f04r', 'f05r', 'f06r', 'm04r', 'm05r', 'm06r',...
% 'f01r', 'f02r', 'f03r', 'm01r', 'm02r', 'm03r',...
% 'f07r', 'f08r','m07r', 'm08r',...
% 'f09r', 'f10r','m09r', 'm10r'};n_para = 14;iOr='r';
load("documents\valid_attr.mat", "map");
wd65 = [94.811, 100.00, 107.304];
datai_file = 'D:\work\VIVOskinExpe\renderCode\calibResults\datai_ipv18_3.mat';
LUT = load(datai_file);
XYZw_LUT = LUT.XYZw;
colors = hsv(length(attributes));
obs_types = ["non_model", "model_group", "model"];
% 定义人种对应的lastParts索引
nation_indices = cell(5, 1);
nation_indices{1} = 1:6;     % AS (Asian)
nation_indices{2} = 7:12;    % CA (Caucasian)
nation_indices{3} = 13:16;   % SA (South Asian)
nation_indices{4} = 17:20;   % AF (African)
nation_indices{5} = 1:20;    % all
% 加载数据
Dtype = "efit_p";
output_folder = fullfile("ellip_pic_p", Dtype);
load(fullfile(output_folder, strcat("data_reshaped_", iOr, ".mat")), "lab_fit_reshaped");

%% 色差计算
obs_types_to_use = ["non_model"];
all_intra_group_results = {};
all_inter_group_results = {};

for i_obs = 1:length(obs_types_to_use)
    obs_type = obs_types_to_use(i_obs);
    
    for i_nation = 1:length(nations)
        curr_nation_indices = nation_indices{i_nation};
        
        % 存储所有属性的平均Lab值，用于组间色差计算
        mean_lab_for_nation_attrs = zeros(length(attributes), 3);
        
        % --- 第一部分：计算组内色差 ---
        for i_attr = 1:length(attributes)
            attribute = attributes(i_attr);
            attribute_name = attribute_names_new(attribute);
            
            % 收集当前人种、属性下所有lastPart的数据
            all_lab_data = [];
            if i_attr == 7
                i_obs_used = 2;
                continue
            else
                i_obs_used = i_obs;
            end
            
            for i_lastPart_idx = 1:length(curr_nation_indices)
                L_data = lab_fit_reshaped{i_obs_used, i_nation}(:, 1, i_lastPart_idx, attribute);
                a_data = lab_fit_reshaped{i_obs_used, i_nation}(:, 2, i_lastPart_idx, attribute);
                b_data = lab_fit_reshaped{i_obs_used, i_nation}(:, 3, i_lastPart_idx, attribute);
                
                valid_indices = ~isnan(L_data) & ~isnan(a_data) & ~isnan(b_data);
                
                lab_data = [L_data(valid_indices), a_data(valid_indices), b_data(valid_indices)];
                all_lab_data = [all_lab_data; lab_data];
            end
            
            % 计算组内两两色差的平均值
            mean_intra_group_deltaE = 0;
            if size(all_lab_data, 1) > 1
                for i = 1:size(all_lab_data, 1)
                    for j = i+1:size(all_lab_data, 1)
                        deltaE_values(i,j) = deltaE2000(all_lab_data(i,:), all_lab_data(j,:));
                    end
                end
                deltaE_values(deltaE_values == 0) = NaN;
                mean_intra_group_deltaE = mean(mean(deltaE_values,'omitnan'),'omitnan');
            end
            
            % 存储结果
            new_row = {
                char(obs_type), ...
                char(nations(i_nation)), ...
                attribute, ...
                char(attribute_name), ...
                mean_intra_group_deltaE
            };
            all_intra_group_results(end+1, :) = new_row;
            
            % 存储该属性的平均Lab值，用于后续组间计算
            if ~isempty(all_lab_data)
                mean_lab_for_nation_attrs(i_attr, :) = mean(all_lab_data, 1);
            else
                mean_lab_for_nation_attrs(i_attr, :) = NaN;
            end
        end % End of i_attr loop for intra-group calculation
        
        % --- 第二部分：计算组间色差 ---
        % 移除包含NaN的行
        valid_mean_labs = mean_lab_for_nation_attrs(~any(isnan(mean_lab_for_nation_attrs), 2), :);
        
        mean_inter_group_deltaE = 0;
        if size(valid_mean_labs, 1) > 1
            for i = 1:size(valid_mean_labs, 1)
                for j = i+1:size(valid_mean_labs, 1)
                    deltaE_values1(i,j) = deltaE2000(valid_mean_labs(i,:), valid_mean_labs(j,:), XYZw_LUT);
                end
            end
            deltaE_values1(deltaE_values1 == 0) = NaN;
            mean_inter_group_deltaE = mean(mean(deltaE_values1,'omitnan'),'omitnan');
        end
        
        % 存储结果
        new_row_inter = {
            char(obs_type), ...
            char(nations(i_nation)), ...
            mean_inter_group_deltaE
        };
        all_inter_group_results(end+1, :) = new_row_inter;
        [mean_intra_group_deltaE,mean_inter_group_deltaE]
        disp("d")
    end % End of i_nation loop
end % End of i_obs loop

%% 保存最终结果到两个不同的文件
output_folder1 = fullfile(output_folder, "deltaE_results");
if ~exist(output_folder1, "dir")
    mkdir(output_folder1);
end

% 保存组内色差结果
header_intra = {'ObserverType', 'Nation', 'AttributeID', 'AttributeName', 'Mean_Intra_Group_DeltaE'};
results_with_header_intra = [header_intra; all_intra_group_results];
xlsx_file_intra = fullfile(output_folder1, strcat(iOr, '_IntraGroup_DeltaE.xlsx'));
xlswrite(xlsx_file_intra, results_with_header_intra);
fprintf('Intra-group DeltaE results saved to: %s\n', xlsx_file_intra);

% 保存组间色差结果
header_inter = {'ObserverType', 'Nation', 'Mean_Inter_Group_DeltaE'};
results_with_header_inter = [header_inter; all_inter_group_results];
xlsx_file_inter = fullfile(output_folder1, strcat(iOr, '_InterGroup_DeltaE.xlsx'));
xlswrite(xlsx_file_inter, results_with_header_inter);
fprintf('Inter-group DeltaE results saved to: %s\n', xlsx_file_inter);


