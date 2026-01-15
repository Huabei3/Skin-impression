close all; % 关闭所有图窗
clc;       % 清空命令窗口
clear;     % 清除工作区所有变量
addpath("utils\")
%% 聚类参数设置 - 开关和参数控制
cluster_switch = true;  % 聚类功能总开关(true开启/false关闭)
cluster_method = 'kmeans++';  % 聚类方法: 'kmeans', 'kmeans++', 'bi-kmeans', 'DBSCAN', 'OPTICS', 'agglomerative'
num_clusters = 4;       % 聚类数量(适用于kmeans类方法)
dbscan_eps = 2;       % DBSCAN半径参数
dbscan_minpts = 3;      % DBSCAN最小点数
optics_xi = 0.05;       % OPTICS xi参数
agglo_linkage = 'ward'; % 层次聚类连接方式: 'ward', 'complete', 'average', 'single'

%% 定义所有需要处理的 attribute
attributes = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
attribute_names = ["Preference", "Attractiveness", "Feminine", "Cooperative", ...
    "Youth", "Healthy", "Fidelity", "Harmony", "Fair", "Ruddy"];
nations = ["AS", "CA", "SA", "AF"];
nation_names = ["Asian", "Caucasian", "South Asian", "African"];

% lastParts配置
lastParts = {'f04r', 'f05r', 'f06r', 'm04r', 'm05r', 'm06r',...
'f01r', 'f02r', 'f03r', 'm01r', 'm02r', 'm03r',...
'f07r', 'f08r','m07r', 'm08r',...
'f09r', 'f10r','m09r', 'm10r'};
n_para = 14;
iOr = 'r';

% 图片名称配置
if iOr == 'i'
    picnames_groups = ["h3k","h4k","h5k","h6k","hd65","h7k","h8k",...
                    "m3k","m4k","m5k","m6k","md65","m7k","m8k",...
                     "l3k","l4k","l5k","l6k","ld65","l7k","l8k"];
elseif iOr == 'r'
    picnames_groups = ["rs01","rs02","rs03","rs04","rs05","rs06","rs07", ...
             "rs08","rs09","rs10","rs11","rs12","rs13","rs14"];
    picnames_groups1=["1负一楼商场" ,"2负一楼vivo" ,"3下沉广场", "4学校饭堂" ,"5学校小卖部",...
        "6学校星巴克", "7草地顺光" ,"8草地侧光", "9草地逆光", "10阴天场景" ,...
        "11夕阳草地逆光", "12夕阳草地侧光", "13夜景小卖部门口", "14 极夜小卖部对面"];

end
lightness_type = "rela";

% 加载验证属性映射
load("documents\valid_attr.mat","map");

% 颜色相关配置
wd65 = [94.811, 100.00, 107.304];
datai_file = 'D:\work\VIVOskinExpe\renderCode\calibResults\datai_ipv18_3.mat';
LUT = load(datai_file);
XYZw_LUT = LUT.XYZw;
line_style = {'-', ':', '-.'};
plot_style = {'v', '^'};
genders = ["f", "m"]; % 定义性别数组
obs_types = ["non_model", "model_group"];

% 定义人种对应的lastParts索引
nation_indices = cell(5, 1); % 5个人种（包括"all"）
nation_indices{1} = 1:6;    % AS (Asian)
nation_indices{2} = 7:12;   % CA (Caucasian)
nation_indices{3} = 13:16;  % SA (South Asian)
nation_indices{4} = 17:20;  % AF (African)
nation_indices{5} = 1:20;   % all

% 加载CT数据
if iOr == 'i'
    indices_target = 1:21;
    load("optmizedD\light_i.mat","CCT_light");
    CT = CCT_light;
else
    indices_target = 1:14;    
    for i_nation = 1:length(nations)
        model_tcp_mean_inds = [];
        for i_lastPart = nation_indices{i_nation}
            load(fullfile("..\..\I_render_stimuli\light_r\model_tcp", ...
                strcat(lastParts{i_lastPart}(1:end-1), ".mat")), ...
            "model_tcp_mean");
            model_tcp_mean_inds = [model_tcp_mean_inds, model_tcp_mean];
        end
        CT_nations{i_nation} = mean(model_tcp_mean_inds, 2);
    end
end

% 初始化数据结构
average_reshaped = cell(5, 1); % 5个人种
par_reshaped = cell(3, 5, 1);  % 3种观察者类型 × 5个人种
lab_fit_reshaped = cell(3, 5, 1); % 3种观察者类型 × 5个人种
labCh_PMCC = [[62.11 18.96 19.76 27.39 46.18];...
              [64.15 19.56 19.63 27.71 45.10];...
              [56.01 18.25 18.72 26.14 45.72];...
              [41.06 17.37 17.94 24.97 45.93]];
labCh_PMCC(end+1, :) = mean(labCh_PMCC, 1);
file_missing = {};
Dtype = 'efit_p';

%% 定义性别分离函数
function gender_indices = separate_genders(n_subjects, curr_nation_indices, lastParts)
    gender_indices = cell(2, 1); % f和m的索引
    for i_subject = 1:n_subjects
        subject_idx = curr_nation_indices(i_subject);
        lastPart = lastParts{subject_idx};
        if lastPart(1) == 'f'
            gender_indices{1} = [gender_indices{1}, i_subject];
        elseif lastPart(1) == 'm'
            gender_indices{2} = [gender_indices{2}, i_subject];
        end
    end
end

%% 加载和存储数据
for i_obs = 1:length(obs_types)
    obs_type = obs_types(i_obs);
    
    for i_nation = 1:length(nations)
        nation = nations(i_nation);
        curr_nation_indices = nation_indices{i_nation};
        
        % 初始化数据数组
        n_subjects = length(curr_nation_indices);
        par_current = zeros(n_para, 6, n_subjects, length(attributes));
        lab_fit_current = zeros(n_para, 3, n_subjects, length(attributes));
        average_current = zeros(n_para, 3, n_subjects);
        
        % 加载每个subject数据
        for i_subject = 1:n_subjects
            subject_idx = curr_nation_indices(i_subject);
            lastPart = lastParts{subject_idx};
            iOr = lastPart(end);
            
            % 加载平均肤色数据
            average_file = fullfile("aveSkin", lastPart, "autoNhand_scaleoverLUT.mat");
            if exist(average_file, 'file')
                average_data = load(average_file);
                average_current(:, :, i_subject) = average_data.average_lab_all(:, 1:3);
            else
                average_current(:, :, i_subject) = NaN(n_para, 3);
            end
            
            % 加载白色方块数据
            white_file = fullfile("optimizedD\whiteSquare\XYZw_white", ...
                strcat(lastPart, ".mat"));
            load(white_file, "XYZw_white");
            
            % 处理每个attribute
            for i_attr = 1:length(attributes)
                attribute = attributes(i_attr);
                attribute_serial = strcat(sprintf("%02d", attribute), attribute_names(attribute));
                source_file = fullfile('AnalyseResults_p', Dtype, "unscaled",lastPart, obs_type, attribute_serial, 'ellipPara', 'fitRes.mat');
                
                if exist(source_file, 'file')
                    par_all_data = load(source_file);
                    par_all = par_all_data.par_all;
                    par_current(:, :, i_subject, i_attr) = par_all;
                    lab_bf = [average_current(:, 1, i_subject), par_all(:, 4:5)];
                    
                    % 处理亮度类型
                    if strcmp(lightness_type, "rela")
                        xyz_fit = [];
                        lab_scaled = [];
                        for i_para = 1:size(par_all, 1)                                
                            xyz_fit(i_para, :) = lab2xyz2(lab_bf(i_para, :), "user", wd65./wd65(2).*XYZw_LUT(2));
                            lab_scaled(i_para, :) = xyz2lab(xyz_fit(i_para, :), "user", wd65./wd65(2).*XYZw_white(i_para, 2));
                        end
                        lab_fit_current(:, :, i_subject, i_attr) = lab_scaled;
                    else
                        lab_fit_current(:, :, i_subject, i_attr) = lab_bf;
                    end
                else
                    par_current(:, :, i_subject, i_attr) = NaN(n_para, 6);
                    lab_fit_current(:, :, i_subject, i_attr) = NaN(n_para, 3);
                    file_missing{end+1, 1} = lastPart;
                    file_missing{end, 2} = obs_type;
                    file_missing{end, 3} = attribute_serial;
                end
            end
        end
        
        % 存储数据
        par_reshaped{i_obs, i_nation} = par_current;
        lab_fit_reshaped{i_obs, i_nation} = lab_fit_current;
        if i_obs == 1
            average_reshaped{i_nation} = average_current;
        end
        
        average_mean{i_obs, i_nation} = nanmean(average_reshaped{i_nation}, 3);       
        par_mean{i_obs, i_nation} = nanmean(par_reshaped{i_obs, i_nation}, 3);
        average_nation_temp(i_nation, :) = mean(average_mean{i_obs, i_nation}(indices_target, :));
    end
    average_nations{i_obs} = average_nation_temp;
end

%% 保存数据
output_folder = fullfile("ellip_pic_p", Dtype,"cluster",obs_type);
if ~exist(output_folder, "dir")
    mkdir(output_folder);
end
if strcmp(lightness_type, "abs")
    save(fullfile(output_folder, strcat("data_reshaped_abs", iOr, ".mat")), ...
        "par_mean", "average_mean", "lab_fit_reshaped", "file_missing", "par_reshaped", "average_reshaped");
else
    save(fullfile(output_folder, strcat("data_reshaped_", iOr, ".mat")), ...
        "par_mean", "average_mean", "lab_fit_reshaped", "file_missing", "par_reshaped", "average_reshaped");
end

%% 计算全局坐标轴范围
lim_min_x = inf;  % a*轴最小边界
lim_min_y = inf;  % b*轴最小边界
lim_max_x = -inf; % a*轴最大边界
lim_max_y = -inf; % b*轴最大边界

for i_nation = 1:length(nations)
    for i_obs = 1:length(obs_types)
        obs_type = obs_types(i_obs);
        n_subjects = size(lab_fit_reshaped{i_obs, i_nation}, 3);
        if n_subjects == 0
            continue;
        end
        
        % 计算属性数据极值
        for attribute = attributes
            lab = lab_fit_reshaped{i_obs, i_nation}(indices_target, :, :, attribute);
            lab_mean = nanmean(lab, 3);
            if ~all(isnan(lab_mean(:)))                
                lim_min_x = min(lim_min_x, min(lab_mean(:, 2)));
                lim_max_x = max(lim_max_x, max(lab_mean(:, 2)));
                lim_min_y = min(lim_min_y, min(lab_mean(:, 3)));
                lim_max_y = max(lim_max_y, max(lab_mean(:, 3)));
            end
        end
        
        % 考虑PMCC点
        lim_min_x = min(lim_min_x, labCh_PMCC(i_nation, 2));
        lim_max_x = max(lim_max_x, labCh_PMCC(i_nation, 2));
        lim_min_y = min(lim_min_y, labCh_PMCC(i_nation, 3));
        lim_max_y = max(lim_max_y, labCh_PMCC(i_nation, 3));
    end
end

% 调整坐标轴范围
lim_min_x = lim_min_x - 1;
lim_max_x = lim_max_x + 1;
lim_min_y = lim_min_y - 1;
lim_max_y = lim_max_y + 1;

% 保持等比例显示
range_x = lim_max_x - lim_min_x;
range_y = lim_max_y - lim_min_y;
max_range = max(range_x, range_y);
lim_min_x = (lim_min_x + lim_max_x - max_range) / 2;
lim_max_x = (lim_min_x + lim_max_x + max_range) / 2;
lim_min_y = (lim_min_y + lim_max_y - max_range) / 2;
lim_max_y = (lim_min_y + lim_max_y + max_range) / 2;

%% 绘图部分
nan_record = {};
cmap = colormap('jet');
hue_values = linspace(0, 1, n_para + 1);
hue_values = hue_values(1:end-1); 
hsv_matrix = [hue_values', 0.8 * ones(n_para, 1), 0.8 * ones(n_para, 1)];
colors = hsv2rgb(hsv_matrix);

% 初始化聚类结果存储
cluster_results = cell(length(nations), 1);

for i_obs = 1:length(obs_types)
    obs_type = obs_types(i_obs);
    
    for i_nation = 1:length(nations)
        nation = nations(i_nation);
        nation_serial = strcat(sprintf("%02d", i_nation), nation);
        if iOr == 'r'
            CT = CT_nations{i_nation};
        end
        
        n_subjects = size(lab_fit_reshaped{i_obs, i_nation}, 3);
        if n_subjects == 0
            continue;
        end
        
        curr_nation_indices = nation_indices{i_nation};        
        gender_indices = separate_genders(n_subjects, curr_nation_indices, lastParts);

        figure;
        hold on;
        set(gcf, 'Color', 'white');
        
        for attribute = [1]
            attribute_serial = strcat(sprintf("%02d", attribute), attribute_names(attribute));
            lab_data = lab_fit_reshaped{i_obs, i_nation}(indices_target, :, :, attribute);
            lab = nanmean(lab_data, 3); % 按受试者维度求平均
            valid_idx = ~all(isnan(lab), 2);
            lab_valid = lab(valid_idx, :);
            data_valid = lab(valid_idx, 1); % 使用L通道数据
            
            if ~isempty(lab_valid)
                % 聚类处理
                if cluster_switch && size(lab_valid, 1) >= num_clusters
                    % 提取a*和b*通道用于聚类
                    cluster_data = lab_valid(:, 2:3);
                    % 调用聚类函数
                    [labels, centers] = perform_clustering(cluster_data, cluster_method, ...
                        num_clusters, dbscan_eps, dbscan_minpts, optics_xi, agglo_linkage);
                    
                    % 核心修改：按b*值降序重新排序聚类索引
                    % 1. 获取按b*值降序排列的聚类中心索引
                    [~, sorted_indices] = sort(centers(:, 2), 'descend');
                    
                    % 2. 创建新旧索引映射
                    index_map = zeros(max(labels), 1);
                    for new_idx = 1:length(sorted_indices)
                        old_idx = sorted_indices(new_idx);
                        index_map(old_idx) = new_idx;
                    end
                    
                    % 3. 更新标签
                    new_labels = zeros(size(labels));
                    for i = 1:length(labels)
                        if labels(i) > 0  % 跳过噪声点（如果有）
                            new_labels(i) = index_map(labels(i));
                        else
                            new_labels(i) = labels(i);  % 保持噪声点不变
                        end
                    end
                    
                    % 4. 更新聚类中心顺序
                    new_centers = centers(sorted_indices, :);
                    
                    % 5. 使用新的标签和中心
                    labels = new_labels;
                    centers = new_centers;
                    
                    % 生成聚类颜色
                    cluster_colors = lines(max(labels) + 1);
                    
                    % 保存聚类结果
                    cluster_results{i_nation} = {labels, centers, picnames_groups(valid_idx), picnames_groups1(valid_idx)};
                end

                % 绘制聚类结果
                for i_point = 1:size(lab_valid, 1)
                    if cluster_switch
                        % 使用聚类颜色
                        marker_color = cluster_colors(labels(i_point) + 1, :);
                    else
                        % 使用原始颜色映射
                        marker_color = colors(i_point, :);
                    end
                    
                    % 绘制点
                    scatter(lab_valid(i_point, 2), lab_valid(i_point, 3), 50, marker_color, 'filled', ...
                        'marker', 'o', 'LineWidth', 1.5);
                    % 添加标签
                    text(lab_valid(i_point, 2) + 0.3, lab_valid(i_point, 3) + 0.3, ...
                         picnames_groups(i_point), 'FontSize', 6, ...
                        'VerticalAlignment', 'bottom', 'Color', marker_color);
                end

                % 绘制聚类中心
                if cluster_switch && ~isempty(centers)
                    for c = 1:size(centers, 1)
                        plot(centers(c, 1), centers(c, 2), 'kx', 'MarkerSize', 10, ...
                            'LineWidth', 2);
                    end
                end

                hue_all{i_obs, i_nation, attribute} = nanmean(atan2d(lab_valid(:, 3), lab_valid(:, 2)));
            end
        end

        % 添加PMCC点
        lab = lab_fit_reshaped{i_obs, i_nation}(indices_target, :, :, 1);
        lab = nanmean(lab, 3); % 按受试者维度求平均
        lab = nanmean(lab, 1); % 按光源/环境维度求平均
        
        % 绘制原始PMCC点
        xyz_mean = lab2xyz2(lab, "d65_64");
        xyz_PMCC = lab2xyz2(labCh_PMCC(i_nation, 1:3), "d65_64");
        xyz_PMCC = xyz_PMCC./xyz_PMCC(2).*xyz_mean(2);
        labCh_PMCC_pre(i_nation, :) = xyz2lab(xyz_PMCC, "d65_64");
        plot(labCh_PMCC(i_nation, 2), labCh_PMCC(i_nation, 3), 's', 'MarkerSize', 8, ...
            'MarkerFaceColor', 'm', 'MarkerEdgeColor', 'm');
        plot(labCh_PMCC_pre(i_nation, 2), labCh_PMCC_pre(i_nation, 3), 's', 'MarkerSize', 8, ...
            'MarkerFaceColor', 'none', 'MarkerEdgeColor', 'm');
        
        % 添加图例、标签和标题
        xlabel('{\ita*}', 'FontSize', 10);
        ylabel('{\itb*}', 'FontSize', 10);
        title(strcat(nation_names(i_nation), ' ', attribute_names(attribute), ...
               ' (', cluster_method, ' k=', num2str(num_clusters), ')'), 'FontSize', 12);
        
        % 设置坐标轴范围
        axis equal;
        xlim([lim_min_x, lim_max_x]);
        ylim([lim_min_y, lim_max_y]);
        
        % 绘制y=x参考线
        x = linspace(lim_min_x, lim_max_x, 100);
        plot(x, x, 'k--', 'LineWidth', 0.8);
        
        % 保存图片 - 修改保存路径："scene"改为"cluster"
        save_folder = fullfile("ellip_pic_p", Dtype, "cluster", lightness_type, obs_type, iOr);
        if ~exist(save_folder, "dir")
            mkdir(save_folder, 'recursive');
        end
        save_name = strcat(nation_serial, '_', cluster_method, '_k', num2str(num_clusters), '.jpg');
        exportgraphics(gcf, fullfile(save_folder, save_name), 'Resolution', 300);
        close(gcf);
    end
    
    % 合并所有图片
    save_folder = fullfile("ellip_pic_p", Dtype, "cluster", lightness_type, obs_type, iOr);
    concatenate_images1(save_folder, 4);   


    %% 将聚类结果导出到XLSX文件
    output_file = fullfile(save_folder, 'cluster_results_summary.xlsx');
    
    % 创建Excel写入对象
    if exist('output_file', 'file')
        delete(output_file);
    end
    
    % 为每个nation创建工作表并写入聚类结果
    for i_nation = 1:length(nations)
        nation = nations(i_nation);
        nation_name = nation_names(i_nation);
        
        % 获取当前nation的聚类结果
        if ~isempty(cluster_results{i_nation})
            labels = cluster_results{i_nation}{1};
            centers = cluster_results{i_nation}{2};
            sample_names = cluster_results{i_nation}{3};
            sample_names1 = cluster_results{i_nation}{4};
            
            % 创建工作表
            sheet_name = strcat(nation, '_', nation_name);
            
            % 写入标题行
            xlswrite(output_file, {strcat('cluster_', nation_name, ' (', cluster_method, ' k=', num2str(num_clusters), ')')}, sheet_name, 'A1');
            
            % 写入聚类中心（如果有）
            if ~isempty(centers)
                header = {'聚类中心', 'a*', 'b*'};
                xlswrite(output_file, header, sheet_name, 'A3');
                
                center_data = cell(size(centers, 1), 3);
                for c = 1:size(centers, 1)
                    center_data{c, 1} = ['类别', num2str(c)];
                    center_data{c, 2} = centers(c, 1);
                    center_data{c, 3} = centers(c, 2);
                end
                
                xlswrite(output_file, center_data, sheet_name, 'A4');
            end
            
            % 写入每个聚类的样本
            start_row = 18;
            unique_labels = unique(labels);
            
            for c = 1:length(unique_labels)
                label = unique_labels(c);
                cluster_indices = find(labels == label);
                cluster_samples{c,1} = cluster_indices;
                cluster_samples{c,2} = sample_names(cluster_indices);
                cluster_samples{c,3} = sample_names1(cluster_indices);
                
                % 写入类别标题
                category_header = {['类别 ', num2str(label), ' (共', num2str(length(cluster_indices)), '个样本)']};
                xlswrite(output_file, category_header, sheet_name, ['A', num2str(start_row)]);
                
                % 写入列标题
                col_headers = {'序号', '样本名称', '样本信息'}; % 新增'样本信息'列
                xlswrite(output_file, col_headers, sheet_name, ['A', num2str(start_row+1)]);
                
                % 准备样本数据
                sample_data = cell(length(cluster_indices), 3);
                for s = 1:length(cluster_indices)
                    sample_data{s, 1} = cluster_indices(s);
                    sample_data{s, 2} = cluster_samples{c,2}(s);
                    sample_data{s, 3} = cluster_samples{c,3}(s); % 新增此行
                end
                
                % 写入样本数据
                xlswrite(output_file, sample_data, sheet_name, ['A', num2str(start_row+2)]);
                
                % 更新下一个类别的起始行 (增加1以考虑新增的列标题行)
                start_row = start_row + length(cluster_indices) + 4;
            end
            save(fullfile(save_folder,strcat(nation,".mat")),"cluster_samples");
            % 自动调整列宽
            try
                % 使用COM接口调整列宽
                Excel = actxserver('Excel.Application');
                Excel.Visible = false;
                Workbook = Excel.Workbooks.Open(fullfile(pwd, output_file));
                Worksheet = Workbook.Sheets.Item(sheet_name);
                Worksheet.Columns.AutoFit;
                Workbook.Save;
                Workbook.Close;
                Excel.Quit;
                delete(Excel);
            catch
                warning('无法自动调整列宽，请手动调整Excel文件中的列宽。');
            end
        end
    end
    
    fprintf('聚类结果已成功导出到: %s\n', output_file);
end