close all; % 关闭所有图窗
clc;       % 清空命令窗口
clear;     % 清除工作区所有变量
addpath("utils\")
%% 定义所有需要处理的 attribute
attributes = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
attribute_names_new = ["Preference", "Attractiveness", "Feminine", "Cooperative", ...
    "Youth", "Healthy", "Fidelity", "Harmony", "Fair", "Ruddy"];
nations = ["AS", "CA", "SA", "AF"];
lastParts = {'f04i', 'f05i', 'f06i', 'm04i', 'm05i', 'm06i',...
'f01i', 'f02i', 'f03i', 'm01i', 'm02i', 'm03i',...
'f07i', 'f08i','m07i', 'm08i',...
'f09i', 'f10i','m09i', 'm10i'};n_para = 21;iOr='i';
% lastParts = {'f04r', 'f05r', 'f06r', 'm04r', 'm05r', 'm06r',...
% 'f01r', 'f02r', 'f03r', 'm01r', 'm02r', 'm03r',...
% 'f07r', 'f08r','m07r', 'm08r',...
% 'f09r', 'f10r','m09r', 'm10r'};n_para = 14;iOr='r';
if iOr == 'i'
    indices_target = [5, 12, 19];
else
    % indices_target = [1:5,7:8,10,12:14];
    indices_target = [1:8,10,12:14];
    % indices_target = 1:14;
end
load("documents\valid_attr.mat","map");
wd65 = [94.811, 100.00, 107.304];
datai_file = 'D:\work\VIVOskinExpe\renderCode\calibResults\datai_ipv18_3.mat';
LUT=load(datai_file);
XYZw_LUT=LUT.XYZw;
% 定义线条样式和散点样式（根据i_obs索引选择）
line_styles = {'-', '--', ':', '-.'};  % 为不同i_obs设置不同线条样式
plot_styles = {'o', '+', 'd', '^'};    % 为不同i_obs设置不同散点样式
genders = ["f", "m"]; % 定义性别数组
% 生成色相值（H），范围从0到1
hue_values = linspace(0, 1, length(nations) + 1);hue_values = hue_values(1:end-1);
hsv_matrix = [hue_values', 0.8 * ones(length(nations), 1), 0.8 * ones(length(nations), 1)];
colors = hsv2rgb(hsv_matrix);
obs_types = ["non_model", "model_group", "model"]; % 初始定义所有观察者类型
% 定义人种对应的lastParts索引
nation_indices = cell(5, 1); % 5个人种（包括"all"）
% AS (Asian): f04i, f05i, f06i, m04i, m05i, m06i (索引1-6)
nation_indices{1} = 1:6;
% CA (Caucasian): f01i, f02i, f03i, m01i, m02i, m03i (索引7-12)
nation_indices{2} = 7:12;
% SA (South Asian): f07i, f08i, m07i, m08i (索引13-16)
nation_indices{3} = 13:16;
% AF (African): f09i, f10i, m09i, m10i (索引17-20)
nation_indices{4} = 17:20;
% all: 所有索引 (索引1-20)
nation_indices{5} = 1:20;
% 初始化重塑后的数据结构
average_reshaped = cell(5, 1); % 5个人种
par_reshaped = cell(3, 5, 1);  % 3种观察者类型 × 5个人种
lab_fit_reshaped = cell(3, 5, 1); % 3种观察者类型 × 5个人种
labCh_PMCC=[[62.11	18.96	19.76	27.39	46.18];...
            [64.15	19.56	19.63	27.71	45.10];...
            [56.01	18.25	18.72	26.14	45.72];...
            [41.06	17.37	17.94	24.97	45.93]];
labCh_PMCC(end+1,:)=mean(labCh_PMCC,1);
file_missing={};
Dtype = 'efit_p';
scale_type_origin="unscaled";
% 定义一个函数来分离性别索引 (此函数未在主逻辑中调用，但保留)
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
%% 直接按重塑后的结构加载和存储数据
for i_obs = 1:length(obs_types)
    obs_type = obs_types(i_obs);
    
    for i_nation = 1:length(nations)
        % 获取当前人种的所有索引
        nation=nations(i_nation);
        curr_nation_indices = nation_indices{i_nation};
        
        % 为当前人种组合初始化数据数组
        n_subjects = length(curr_nation_indices);
        par_current = zeros(n_para, 6, n_subjects, length(attributes));
        lab_fit_current = zeros(n_para, 3, n_subjects, length(attributes));
        average_current = zeros(n_para, 3, n_subjects);
        
        % 为每个subject加载数据
        for i_subject = 1:n_subjects
            subject_idx = curr_nation_indices(i_subject);
            lastPart = lastParts{subject_idx};
            
            % 加载平均肤色数据
            average_file = fullfile("aveSkin", lastPart, "autoNhand_scaleoverLUT.mat");
            if exist(average_file, 'file')
                average_data = load(average_file);
                average_current(:, :, i_subject) = average_data.average_lab_all(:, 1:3);
            else
                average_current(:, :, i_subject) = NaN(n_para, 3);
            end
            white_file = fullfile("optimizedD\whiteSquare\XYZw_white", ...
                strcat(lastPart, ".mat"));
            load(white_file,"XYZw_white");
            
            % 循环处理每个 attribute
            for i_attr = 1:length(attributes)
                attribute = attributes(i_attr);
                attribute_serial = strcat(sprintf("%02d", attribute), attribute_names_new(attribute));
                
                % 定义路径
                if i_attr ==7
                    obs_type_used="model_group";
                else
                    obs_type_used=obs_type;
                end
                if strcmp(Dtype,"efit_p_free")
                    AnalyseResults_folder="AnalyseResults_p_free";
                elseif strcmp(Dtype,"efit_p")
                    AnalyseResults_folder="AnalyseResults_p";
                end
                source_file = fullfile(AnalyseResults_folder, Dtype, ...
                    scale_type_origin,lastPart, obs_type_used, attribute_serial, ...
                    'ellipPara', 'fitRes.mat');
                
                % 加载数据
                if exist(source_file, 'file')
                    par_all_data = load(source_file);
                    par_all = par_all_data.par_all;
                    par_all=[par_all;nan(size(par_current,1)-size(par_all,1),size(par_all,2))];
                    par_current(:, :, i_subject, i_attr) = par_all;                    
                    lab_bf=[average_current(:, 1, i_subject), par_all(:,4:5)];
                    lab_fit_current(:, :, i_subject, i_attr) = lab_bf;
                    
                else
                    par_current(:, :, i_subject, i_attr) = NaN(n_para, 6);
                    lab_fit_reshaped{i_obs, i_nation} = NaN(n_para, 3, n_subjects, length(attributes));
                    file_missing{end+1,1}=lastPart;
                    file_missing{end,2}=obs_type;
                    file_missing{end,3}=attribute_serial;
                end
            end
        end
        
        % 存储到重塑后的数据结构中
        par_reshaped{i_obs, i_nation} = par_current;
        lab_fit_reshaped{i_obs, i_nation} = lab_fit_current;
        
        % average_reshaped只需要存储一次（不依赖于观察者类型）
        if i_obs == 1
            average_reshaped{i_nation} = average_current;
        end
        
        average_mean{i_obs, i_nation}=mean(average_reshaped{i_nation} ,3,"omitnan");       
        par_mean{i_obs,i_nation}=mean(par_reshaped{i_obs,i_nation},3,"omitnan");
        average_nation_temp(i_nation,:)=mean(average_mean{i_obs, i_nation}(indices_target,:));
        
    end
    average_nations{i_obs}=average_nation_temp;
end
%% 保存加载的数据
if strcmp(Dtype,"efit_p_free")
    ellip_pic_folder="ellip_pic_p_free";
elseif strcmp(Dtype,"efit_p")
    ellip_pic_folder="ellip_pic_p";
end
output_folder_base = fullfile(ellip_pic_folder, Dtype);
if ~exist(output_folder_base,"dir")
    mkdir(output_folder_base);
end
save(fullfile(output_folder_base, strcat("data_unscaled_reshaped_",iOr,".mat")),"par_mean","average_mean", ...
    "lab_fit_reshaped","file_missing","par_reshaped","average_reshaped");
%% 为每个观察者类型、人种和属性分别处理数据（按人种分组拟合）
% 定义绘图和分析所使用的观察者类型
obs_types_plotting = ["non_model", "model_group"]; 
% 仅当iOr为'i'时加载'r'数据
r_data_loaded = []; % 初始化为空
if iOr == 'i'
    r_data_file_path = fullfile(output_folder_base, strcat("data_unscaled_reshaped_r.mat"));
    if exist(r_data_file_path, 'file')
        r_data_loaded = load(r_data_file_path, ...
            "par_mean", "average_mean", ...
            "lab_fit_reshaped", "file_missing", "par_reshaped", "average_reshaped");
    else
        warning('Warning: data_unscaled_reshaped_r.mat not found for iOr=''i''. ''r'' data will not be plotted or analyzed.');
    end
end
% 遍历观察者类型
for i_obs = 1:length(obs_types_plotting)
    obs_type = obs_types_plotting(i_obs);
    
    % 确保线条样式和散点样式索引在有效范围内
    line_style_idx = min(i_obs, length(line_styles));
    plot_style_idx = min(i_obs, length(plot_styles));
    
    % --- 扩展为3组数据: i_self, r_vs_i, r_self ---
    % 新增：初始化rho和promi的存储矩阵（与r、RMSE结构一致）
    r_values_for_excel = zeros(length(attributes), length(nations) * 3); 
    rmse_values_for_excel = zeros(length(attributes), length(nations) * 3);
    rho_values_for_excel = zeros(length(attributes), length(nations) * 3); % Spearman相关系数
    promi_values_for_excel = zeros(length(attributes), length(nations) * 3); % 显著性
    
    % 构建扩展后的excel列名（新增rho和promi的列名）
    excel_col_names_temp = strings(1, length(nations) * 3); 
    excel_col_names_rmse_temp = strings(1, length(nations) * 3);
    excel_col_names_rho_temp = strings(1, length(nations) * 3); % rho列名
    excel_col_names_promi_temp = strings(1, length(nations) * 3); % promi列名
    
    for col_idx = 1:length(nations)
        % 原有r和RMSE的列名
        excel_col_names_temp(col_idx) = nations(col_idx) + "_i_self_corr"; % i自身拟合的Pearson相关
        excel_col_names_temp(col_idx + length(nations)) = nations(col_idx) + "_r_vs_i_corr"; % r对i拟合的Pearson相关
        excel_col_names_temp(col_idx + 2*length(nations)) = nations(col_idx) + "_r_self_corr"; % r自身拟合的Pearson相关
        
        excel_col_names_rmse_temp(col_idx) = nations(col_idx) + "_i_self_RMSE";
        excel_col_names_rmse_temp(col_idx + length(nations)) = nations(col_idx) + "_r_vs_i_RMSE";
        excel_col_names_rmse_temp(col_idx + 2*length(nations)) = nations(col_idx) + "_r_self_RMSE";
        
        % 新增rho和promi的列名
        excel_col_names_rho_temp(col_idx) = nations(col_idx) + "_i_self_rho"; % i自身拟合的Spearman相关
        excel_col_names_rho_temp(col_idx + length(nations)) = nations(col_idx) + "_r_vs_i_rho"; % r对i拟合的Spearman相关
        excel_col_names_rho_temp(col_idx + 2*length(nations)) = nations(col_idx) + "_r_self_rho"; % r自身拟合的Spearman相关
        
        excel_col_names_promi_temp(col_idx) = nations(col_idx) + "_i_self_promi"; % i自身拟合的显著性
        excel_col_names_promi_temp(col_idx + length(nations)) = nations(col_idx) + "_r_vs_i_promi"; % r对i拟合的显著性
        excel_col_names_promi_temp(col_idx + 2*length(nations)) = nations(col_idx) + "_r_self_promi"; % r自身拟合的显著性
    end
    
    % 整合列名
    excel_col_names = excel_col_names_temp;
    excel_col_names_rmse = excel_col_names_rmse_temp;
    excel_col_names_rho = excel_col_names_rho_temp; % 新增rho列名
    excel_col_names_promi = excel_col_names_promi_temp; % 新增promi列名
    
    % 遍历属性
    for attribute = attributes
        attribute_serial = strcat(sprintf("%02d", attribute), attribute_names_new(attribute));
        % 创建新的图形窗口
        h1 = figure(attribute);
        hold on;
        set(gcf, 'Color', 'white');
        h2 = figure(10+attribute);
        hold on;
        set(gcf, 'Color', 'white');
        h3 = figure(20+attribute);
        hold on;
        set(gcf, 'Color', 'white');
        
        % 初始化拟合参数存储
        a_CL_all = zeros(length(nations), 2);

        r_CL_all_i_self = zeros(length(nations), 1);
        r_CL_all_r_vs_i = zeros(length(nations), 1); 
        r_CL_all_r_self = zeros(length(nations), 1); 
        
        RMSE_CL_all_i_self = zeros(length(nations), 1);
        RMSE_CL_all_r_vs_i = zeros(length(nations), 1);
        RMSE_CL_all_r_self = zeros(length(nations), 1);

        rho_all_i_self= zeros(length(nations), 1);
        rho_all_r_vs_i= zeros(length(nations), 1);
        rho_all_r_self= zeros(length(nations), 1);
        
        promi_all_i_self=zeros(length(nations), 1);
        promi_all_r_vs_i=zeros(length(nations), 1);
        promi_all_r_self=zeros(length(nations), 1);
        
        % 按人种分组处理
        for i_nation = 1:length(nations)
            nation = nations(i_nation);
            
            % 获取当前人种的lastPart索引
            curr_nation_indices = nation_indices{i_nation};
            
            if attribute==7
                i_obs_used=2; % For attribute 7, use model_group observer type
            else
                i_obs_used=i_obs; % Otherwise, use the current observer type
            end
            % --- 处理当前 'iOr' 模式的数据 (用于拟合曲线) ---
            lab_data_current_i = lab_fit_reshaped{i_obs_used, i_nation}(indices_target, :, :, attribute);
            % 重组数据为 (n_targets*n_subjects)×3 的矩阵
            [n_targets_i, ~, n_subjects_i] = size(lab_data_current_i);
            lab_g_i = reshape(permute(lab_data_current_i, [1 3 2]), n_targets_i * n_subjects_i, 3);
            % 检查并移除包含NaN的行
            valid_rows_i = ~any(isnan(lab_g_i), 2);  % 找出所有不包含NaN的行
            lab_g_valid_i = lab_g_i(valid_rows_i, :);  % 提取有效行
            
            % 仅当存在有效数据时执行后续操作
            afinal_i = []; % Initialize afinal_i for scope
            if ~isempty(lab_g_valid_i)
                % 提取L和C值进行曲线拟合
                L_i = lab_g_valid_i(:, 1);  % L*值
                C_i = sqrt(lab_g_valid_i(:, 2).^2 + lab_g_valid_i(:, 3).^2);  % C*值 = sqrt(a*² + b*²)
                
                % 确保数据有效
                valid_indices_i = ~isnan(L_i) & ~isnan(C_i) & L_i > 0;
                L_valid_i = L_i(valid_indices_i);
                C_valid_i = C_i(valid_indices_i);
                
                % 如果有足够的数据点进行拟合
                if length(L_valid_i) > 3
                    % 定义拟合模型
                    f = @(a,xdata)(a(1).*log(xdata)+a(2));
                    
                    % 多次随机初始化以找到最佳拟合
                    rmax_i = -inf; % Initialize with negative infinity for correlation
                    RMSE_final = inf;
                    rho_final=-inf;
                    promi_final=-inf;
                    for t = 1:500
                        a0 = [rand, rand];
                        options = optimset('MaxFunEvals', 200000, 'Display', 'off'); % Turn off display for cleaner output
                        a = lsqcurvefit(f, a0, L_valid_i, C_valid_i, [-inf, -inf], [inf, inf], options);
                        y = f(a, L_valid_i);
                        
                        r = corr(y, C_valid_i);
                        current_RMSE = sqrt(mean((C_valid_i - y).^2))./mean(C_valid_i,1,"omitnan");  
                        [rho, promi] = ...
                            spearman_correlation(y, C_valid_i);
                        if r >= rmax_i || isnan(rmax_i) % Handle cases where rmax_i might be NaN initially
                            rmax_i = r;
                            RMSE_final = current_RMSE;
                            rho_final=rho;
                            promi_final=promi;
                            afinal_i = a;
                        end
                    end
                    
                    % 保存拟合结果
                    r_CL_all_i_self(i_nation) = rmax_i;
                    RMSE_CL_all_i_self(i_nation) = RMSE_final;
                    rho_all_i_self(i_nation)=rho_final;
                    promi_all_i_self(i_nation)=promi_final;
                    
                    % 根据i_obs选择线条样式
                    line_style = line_styles{line_style_idx};
                    % 绘制拟合曲线

                    a_CL_all(i_nation,:) = afinal_i;
                    figure(attribute);
                    x_fit_i = min(L_valid_i):0.1:max(L_valid_i);
                    y_fit_i = f(afinal_i, x_fit_i);
                    plot(y_fit_i, x_fit_i, 'Color', colors(i_nation, :), ...
                        'LineWidth', 1.5, 'LineStyle', line_style); % 加粗线条
                    scatter(C_valid_i, L_valid_i, 8, colors(i_nation, :), ...
                        'o', 'filled', 'MarkerFaceAlpha', 0.6); 

                end
            end
            
            % --- 叠加 'r' 数据散点并计算与 'i' 曲线的相关性和RMSE (仅当iOr == 'i'时) ---
            if iOr == 'i' && ~isempty(r_data_loaded) && ~isempty(afinal_i) % 确保i数据拟合成功
                % 使用 1:14 索引
                lab_data_r = r_data_loaded.lab_fit_reshaped{i_obs_used, i_nation}(1:14, :, :, attribute);
                [n_targets_r, ~, n_subjects_r] = size(lab_data_r);
                lab_g_r = reshape(permute(lab_data_r, [1 3 2]), n_targets_r * n_subjects_r, 3);
                valid_rows_r = ~any(isnan(lab_g_r), 2);
                lab_g_valid_r = lab_g_r(valid_rows_r, :);
                %加载r的para
                file_C_Lpara_r=fullfile(ellip_pic_folder,Dtype,"C_L_iNr\r",obs_type, ...
                strcat(attribute_serial,"_curve_params.mat"));
                if exist(file_C_Lpara_r,'file')
                    data_C_Lpara_r=load(file_C_Lpara_r);        
                    a_r=data_C_Lpara_r.a_CL_all;
                else
                    warning('r data parameter file not found: %s', file_C_Lpara_r);
                    a_r = nan(length(nations), 2);
                end
                
                if ~isempty(lab_g_valid_r)
                    L_r = lab_g_valid_r(:, 1);
                    C_r = sqrt(lab_g_valid_r(:, 2).^2 + lab_g_valid_r(:, 3).^2);
                    valid_indices_r = ~isnan(L_r) & ~isnan(C_r) & L_r > 0;
                    L_valid_r = L_r(valid_indices_r);
                    C_valid_r = C_r(valid_indices_r);
                    if length(L_valid_r) > 1 % 至少需要2个点来计算相关性
                        % 使用i数据拟合的afinal_i来计算y值
                        y_from_i_fit_for_r_data = f(afinal_i, L_valid_r);
                        
                        % 使用r数据拟合的a_r来计算y值
                        y_from_r_fit_for_r_data = a_r(i_nation,1)*log(L_valid_r)+a_r(i_nation,2);
                        
                        % 计算r数据散点与i拟合曲线的相关性
                        r_val_r_vs_i = corr(y_from_i_fit_for_r_data, C_valid_r);
                        r_val_r_vs_r = corr(y_from_r_fit_for_r_data, C_valid_r);
                        
                        r_CL_all_r_vs_i(i_nation) = r_val_r_vs_i;
                        r_CL_all_r_self(i_nation) = r_val_r_vs_r;
                        
                        % 计算RMSE
                        rmse_val_r_vs_i = sqrt(mean((C_valid_r - y_from_i_fit_for_r_data).^2))./mean(C_valid_r,1,"omitnan");
                        rmse_val_r_vs_r = sqrt(mean((C_valid_r - y_from_r_fit_for_r_data).^2))./mean(C_valid_r,1,"omitnan");
                        
                        RMSE_CL_all_r_vs_i(i_nation) = rmse_val_r_vs_i;
                        RMSE_CL_all_r_self(i_nation) = rmse_val_r_vs_r;
                        
                        % 计算Spearman相关和显著性
                        [rho_r_vs_i, promi_r_vs_i] = spearman_correlation(C_valid_r, y_from_i_fit_for_r_data);
                        [rho_r_vs_r, promi_r_vs_r] = spearman_correlation(C_valid_r, y_from_r_fit_for_r_data);
                        
                        rho_all_r_vs_i(i_nation) = rho_r_vs_i;
                        rho_all_r_self(i_nation) = rho_r_vs_r;
                        promi_all_r_vs_i(i_nation) = promi_r_vs_i;
                        promi_all_r_self(i_nation) = promi_r_vs_r;

                        % 绘制'r'数据散点，使用指定大小8，且不构建图例
                        figure(10+attribute);
                        x_fit_i = min(L_valid_i):0.1:max(L_valid_i);
                        y_fit_i = f(afinal_i, x_fit_i);
                        plot(y_fit_i, x_fit_i, 'Color', colors(i_nation, :), ...
                        'LineWidth', 1.5, 'LineStyle', line_style); % 加粗线条
                        scatter_style_r = plot_styles{plot_style_idx}; 
                        scatter(C_valid_r, L_valid_r, 8, colors(i_nation, :), ...
                            scatter_style_r, 'filled', 'MarkerFaceAlpha', 0.6); 


                        figure(20+attribute);
                        x_fit_r = min(L_valid_r):0.1:max(L_valid_r);
                        y_fit_r = f(a_r(i_nation,:), x_fit_r);
                        plot(y_fit_r, x_fit_r, 'Color', colors(i_nation, :), ...
                        'LineWidth', 1.5, 'LineStyle', line_style); % 加粗线条
                        scatter_style_r = plot_styles{plot_style_idx}; 
                        scatter(C_valid_r, L_valid_r, 8, colors(i_nation, :), ...
                            scatter_style_r, 'filled', 'MarkerFaceAlpha', 0.6); 
                    end
                end
            end
            
            % 存储当前 attribute 和 nation 的所有指标到Excel矩阵
            % 1. Pearson相关系数（原有）
            r_values_for_excel(attribute, i_nation) = r_CL_all_i_self(i_nation);
            r_values_for_excel(attribute, i_nation + length(nations)) = r_CL_all_r_vs_i(i_nation);
            r_values_for_excel(attribute, i_nation + 2*length(nations)) = r_CL_all_r_self(i_nation);
            
            % 2. RMSE（原有）
            rmse_values_for_excel(attribute, i_nation) = RMSE_CL_all_i_self(i_nation);
            rmse_values_for_excel(attribute, i_nation + length(nations)) = RMSE_CL_all_r_vs_i(i_nation);
            rmse_values_for_excel(attribute, i_nation + 2*length(nations)) = RMSE_CL_all_r_self(i_nation);
            
            % 3. Spearman相关系数（新增）
            rho_values_for_excel(attribute, i_nation) = rho_all_i_self(i_nation);
            rho_values_for_excel(attribute, i_nation + length(nations)) = rho_all_r_vs_i(i_nation);
            rho_values_for_excel(attribute, i_nation + 2*length(nations)) = rho_all_r_self(i_nation);
            
            % 4. 显著性（新增）
            promi_values_for_excel(attribute, i_nation) = promi_all_i_self(i_nation);
            promi_values_for_excel(attribute, i_nation + length(nations)) = promi_all_r_vs_i(i_nation);
            promi_values_for_excel(attribute, i_nation + 2*length(nations)) = promi_all_r_self(i_nation);
            
            disp("d")
        end % end for i_nation
        % 亮度实验曲线（注释保留）
        % x2 = 10:0.1:70;
        % y2 = 6.7421*log(x2)-9.9816;
        % plot(y2, x2, 'Color', 'k', 'LineWidth', 1, 'LineStyle', ':');
        
        % --------------i-self-------------------
        figure(attribute);
        ylabel('L^*', 'FontSize', 12, 'FontAngle', 'italic');
        xlabel('C^*', 'FontSize', 12, 'FontAngle', 'italic');
        % title([attribute_names_new(attribute)],'FontSize', 12*2);
        grid on;
        
        % 设置坐标轴范围和刻度间隔
        axis equal; % 保持坐标轴比例一致
        interval = 10;  
        xticks(0:interval:35);
        yticks(0:interval:80);
        ylim([0, 80]);
        xlim([0, 35]);
        % 保存图片
        output_folder_curves = fullfile(output_folder_base, 'C_L_iNr', obs_type,iOr, 'curve_fit',"i_self");
        if ~exist(output_folder_curves, 'dir')
            mkdir(output_folder_curves);
        end
        exportgraphics(h1, fullfile(output_folder_curves, strcat(attribute_serial, '.jpg')), 'Resolution', 300);
        
        % ----------------i-vs-r-----------------
        figure(10+attribute);
        ylabel('L^*', 'FontSize', 12, 'FontAngle', 'italic');
        xlabel('C^*', 'FontSize', 12, 'FontAngle', 'italic');
        % title([attribute_names_new(attribute),""], 'FontSize', 14); 
        grid on;
        
        % 设置坐标轴范围和刻度间隔
        axis equal; % 保持坐标轴比例一致
        interval = 10;  
        xticks(0:interval:35);
        yticks(0:interval:80);
        ylim([0, 80]);
        xlim([0, 35]);
        % 保存图片
        output_folder_curves = fullfile(output_folder_base, 'C_L_iNr', obs_type,iOr, 'curve_fit',"i_vs_r");
        if ~exist(output_folder_curves, 'dir')
            mkdir(output_folder_curves);
        end
        exportgraphics(h2, fullfile(output_folder_curves, strcat(attribute_serial, '.jpg')), 'Resolution', 300);
        % -------------r-self--------------------
        figure(20+attribute);
        ylabel('L^*', 'FontSize', 12, 'FontAngle', 'italic');
        xlabel('C^*', 'FontSize', 12, 'FontAngle', 'italic');
        % title([attribute_names_new(attribute),""], 'FontSize', 14); 
        grid on;
        
        % 设置坐标轴范围和刻度间隔
        axis equal; % 保持坐标轴比例一致
        interval = 10;  
        xticks(0:interval:35);
        yticks(0:interval:80);
        ylim([0, 80]);
        xlim([0, 35]);
        % 保存图片
        output_folder_curves = fullfile(output_folder_base, 'C_L_iNr', obs_type,iOr, 'curve_fit',"r_self");
        if ~exist(output_folder_curves, 'dir')
            mkdir(output_folder_curves);
        end
        exportgraphics(h3, fullfile(output_folder_curves, strcat(attribute_serial, '.jpg')), 'Resolution', 300);
        %--------------------------------

        % 保存拟合参数
        output_folder_params = fullfile(output_folder_base, 'C_L_iNr', iOr, obs_type);
        if ~exist(output_folder_params, 'dir')
            mkdir(output_folder_params);
        end
        save(fullfile(output_folder_params, strcat(attribute_serial, '_curve_params.mat')), ...
            'a_CL_all', ...
            'r_CL_all_i_self', 'r_CL_all_r_vs_i', 'RMSE_CL_all_i_self', 'RMSE_CL_all_r_vs_i', ...
            'r_CL_all_r_self', 'RMSE_CL_all_r_self', ...
            'rho_all_i_self', 'rho_all_r_vs_i','rho_all_r_self', ...
            'promi_all_i_self', 'promi_all_r_vs_i','promi_all_r_self',...
            'nations', 'attribute', 'obs_type');
        
        close(h1); close(h2);close(h3);
    end % end for attribute
    concatenate_images1(output_folder_curves, 5);
    % 导出当前i_obs的所有指标到XLSX文件（新增rho和promi工作表）
    r_excel_output_folder = fullfile(AnalyseResults_folder,Dtype,scale_type_origin,"sum_list", ...
        'C_L', 'check_iNr');
    if ~exist(r_excel_output_folder, 'dir')
        mkdir(r_excel_output_folder);
    end
    
    excel_filename = fullfile(r_excel_output_folder, strcat('correlation_rmse_rho_promi_values_', iOr, '_', obs_type, '.xlsx'));
    
    % 构建表头（统一使用属性名作为第一列）
    attribute_names_cell = cellstr(attribute_names_new(attributes)); 
    header_row_left = "Attribute";
    
    % -------------------------- 1. Pearson相关系数工作表 --------------------------
    full_header_r = [cellstr(header_row_left), cellstr(excel_col_names)];
    data_to_write_r = [cellstr(attribute_names_new(attributes))', num2cell(r_values_for_excel)];
    
    % -------------------------- 2. RMSE工作表 --------------------------
    full_header_rmse = [cellstr(header_row_left), cellstr(excel_col_names_rmse)];
    data_to_write_rmse = [cellstr(attribute_names_new(attributes))', num2cell(rmse_values_for_excel)];
    
    % -------------------------- 3. Spearman相关系数（rho）工作表（新增） --------------------------
    full_header_rho = [cellstr(header_row_left), cellstr(excel_col_names_rho)];
    data_to_write_rho = [cellstr(attribute_names_new(attributes))', num2cell(rho_values_for_excel)];
    
    % -------------------------- 4. 显著性（promi）工作表（新增） --------------------------
    full_header_promi = [cellstr(header_row_left), cellstr(excel_col_names_promi)];
    data_to_write_promi = [cellstr(attribute_names_new(attributes))', num2cell(promi_values_for_excel)];


    % 写入Excel（4个工作表分别存储不同指标）
    writecell([full_header_r; data_to_write_r], excel_filename, 'Sheet', 'Pearson_Corr');
    writecell([full_header_rmse; data_to_write_rmse], excel_filename, 'Sheet', 'RMSE');
    writecell([full_header_rho; data_to_write_rho], excel_filename, 'Sheet', 'Spearman_Rho'); % 新增
    writecell([full_header_promi; data_to_write_promi], excel_filename, 'Sheet', 'Significance_Promi'); % 新增
    
    disp(strcat('写入 Excel 文件：',excel_filename, obs_type));
end % end for i_obs