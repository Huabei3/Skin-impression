close all; % 关闭所有图窗
clc;       % 清空命令窗口
clear;     % 清除工作区所有变量
%% 定义所有需要处理的 attribute
attributes = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

attribute_names = ["Preference", "Attractiveness", "Feminine", "Cooperative", ...
    "Youth", "Healthy", "Fidelity", "Harmony", "Fair", "Ruddy"];
nations = ["AS", "CA", "SA", "AF"];
nation_names = ["Asian", "Caucasian", "South Asian", "African"];

lastParts = {'f04i', 'f05i', 'f06i', 'm04i', 'm05i', 'm06i',...
'f01i', 'f02i', 'f03i', 'm01i', 'm02i', 'm03i',...
'f07i', 'f08i','m07i', 'm08i',...
'f09i', 'f10i','m09i', 'm10i'};n_para = 21;iOr='i';

% lastParts = {'f04r', 'f05r', 'f06r', 'm04r', 'm05r', 'm06r',...
% 'f01r', 'f02r', 'f03r', 'm01r', 'm02r', 'm03r',...
% 'f07r', 'f08r','m07r', 'm08r',...
% 'f09r', 'f10r','m09r', 'm10r'};n_para = 14;iOr='r';

if iOr =='i'
    picnames_groups = ["h3k","h4k","h5k","h6k","hd65","h7k","h8k",...
                    "m3k","m4k","m5k","m6k","md65","m7k","m8k",...
                     "l3k","l4k","l5k","l6k","ld65","l7k","l8k"];
elseif iOr=='r'
    picnames_groups = ["rs01","rs02","rs03","rs04","rs05","rs06","rs07", ...
             "rs08","rs09","rs10","rs11","rs12","rs13","rs14"];
end
lightness_type="rela";

load("documents\valid_attr.mat","map");

scale_type_origin="unscaled";

wd65 = [94.811, 100.00, 107.304];
datai_file = 'D:\work\VIVOskinExpe\renderCode\calibResults\datai_ipv18_3.mat';
LUT=load(datai_file);
XYZw_LUT=LUT.XYZw;
line_style = {'-',':','-.'};
plot_style = {'v','^'};

genders = ["f", "m"]; % 定义性别数组
% 生成色相值（H），范围从0到1
hue_values = linspace(0, 1, length(nations) + 1);hue_values = hue_values(1:end-1); 
hsv_matrix = [hue_values', 0.8 * ones(length(nations), 1), 0.8 * ones(length(nations), 1)];
colors = hsv2rgb(hsv_matrix);

obs_types = ["non_model"];
% obs_types = ["non_model", "model_group", "model"];
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



if iOr == 'i'
    indices_target = [1:21];
    load("optimizedD\light_i.mat","CCT_light");
    CT = CCT_light;
else
    indices_target = 1:14;    
    for i_nation=1:length(nations)
        model_tcp_mean_inds=[];
        for i_lastPart=nation_indices{i_nation}
            load(fullfile("..\renderCode\light_r\model_tcp", ...
                strcat(lastParts{i_lastPart}(1:end-1),".mat")), ...
            "model_tcp_mean");
            model_tcp_mean_inds=[model_tcp_mean_inds,model_tcp_mean];
        end
        CT_nations{i_nation}=mean(model_tcp_mean_inds,2);
    end
end
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
% Dtype = 'efit_p_free';
Dtype = 'efit_p';
% 定义一个函数来分离性别索引
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
        clear("XYZw_gray_current");
        clear("lastPart_current");
        % 为每个subject加载数据
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
            white_file = fullfile("optimizedD\whiteSquare\XYZw_white", ...
                strcat(lastPart, ".mat"));
            load(white_file,"XYZw_white");
            xyz_gray_file=fullfile("optimizedD\backGroundGray",lastPart);
            clear("xyz_gray");
            load(xyz_gray_file,"xyz_gray");
            if strcmp(iOr,"i")
                order=[1,2,3,4,7,5,6,...
                    15,16,17,18,21,19,20,...
                    8,9,10,11,14,12,13];
                xyz_gray_sorted=xyz_gray(order,:);
            else
                xyz_gray_sorted=xyz_gray;
            end
            XYZw_gray_current(:, :, i_subject)=xyz_gray_sorted;
            lastPart_current{i_subject,1}=lastPart;
            
            % 循环处理每个 attribute
            for i_attr = 1:length(attributes)
                attribute = attributes(i_attr);
                attribute_serial = strcat(sprintf("%02d", attribute), attribute_names(attribute));
                
                % 定义路径
                if strcmp(Dtype,"efit_p_free")
                    AnalyseResults_folder="AnalyseResults_p_free";
                elseif strcmp(Dtype,"efit_p")
                    AnalyseResults_folder="AnalyseResults_p";
                end
                source_file = fullfile(AnalyseResults_folder, Dtype, scale_type_origin,lastPart, obs_type, attribute_serial, 'ellipPara', 'fitRes.mat');
                
                % 加载数据
                if exist(source_file, 'file')
                    par_all_data = load(source_file);
                    par_all = par_all_data.par_all;
                    par_all=[par_all;...
                        nan(size(par_current,1)-size(par_all,1),size(par_all,2))];
                    par_current(:, :, i_subject, i_attr) = par_all;
                    lab_bf=[average_current(:, 1, i_subject), par_all(:,4:5)];
                    if strcmp(lightness_type,"rela")
                        xyz_fit=[];lab_scaled=[];
                        for i_para=1:size(par_all,1)                                
                            xyz_fit(i_para,:)=lab2xyz2(lab_bf(i_para,:),"user",wd65./wd65(2).*XYZw_LUT(2));
                            lab_scaled(i_para,:)=xyz2lab(xyz_fit(i_para,:),"user",wd65./wd65(2).*XYZw_white(i_para,2));
                        end
                        lab_fit_current(:, :, i_subject, i_attr) = lab_scaled;
                    else
                        lab_fit_current(:, :, i_subject, i_attr) = lab_bf;
                    end
                    
                else
                    par_current(:, :, i_subject, i_attr) = NaN(n_para, 6);
                    lab_fit_current(:, :, i_subject, i_attr) = NaN(n_para, 3);
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
        
        average_mean{i_obs, i_nation}=nanmean(average_reshaped{i_nation} ,3);    
        XYZw_gray_all_nations{i_nation,1}=XYZw_gray_current;
        XYZw_gray_all_nations{i_nation,2}=lastPart_current;
        XYZw_gray_mean{i_nation,1}=nanmean(XYZw_gray_current,3);
        par_mean{i_obs,i_nation}=nanmean(par_reshaped{i_obs,i_nation},3);
        average_nation_temp(i_nation,:)=mean(average_mean{i_obs, i_nation}(indices_target,:));
        
    end
    average_nations{i_obs}=average_nation_temp;
end
save(fullfile("documents",iOr,"XYZw_gray_nations.mat"),"XYZw_gray_mean","XYZw_gray_all_nations");
%% 保存
if strcmp(Dtype,"efit_p_free")
    ellip_pic_folder="ellip_pic_p_free";
elseif strcmp(Dtype,"efit_p")
    ellip_pic_folder="ellip_pic_p";
end
output_folder=fullfile(ellip_pic_folder, Dtype);
if ~exist(output_folder,"dir")
    mkdir(output_folder);
end
if strcmp(lightness_type,"abs")
    save(fullfile(output_folder,strcat("data_reshaped_abs",iOr,".mat")),"par_mean","average_mean", ...
    "lab_fit_reshaped","file_missing","par_reshaped","average_reshaped");
else
    save(fullfile(output_folder,strcat("data_reshaped_",iOr,".mat")),"par_mean","average_mean", ...
        "lab_fit_reshaped","file_missing","par_reshaped","average_reshaped");
end
%% 计算全局坐标轴范围
% 初始化极值变量
% lim_min_x = inf;  % a*轴最小边界初始化为正无穷
% lim_min_y = inf;  % b*轴最小边界初始化为正无穷
% lim_max_x = -inf; % a*轴最大边界初始化为负无穷
% lim_max_y = -inf; % b*轴最大边界初始化为负无穷
% 
% % 遍历所有可能的数据组合计算全局极值
% for i_nation = 1:length(nations)
%     for i_obs = 1:length(obs_types)
%         obs_type=obs_types(i_obs);
%         % 获取当前人种的subject数量
%         n_subjects = size(lab_fit_reshaped{i_obs, i_nation}, 3);
%         if n_subjects == 0
%             continue;
%         end
% 
%         % 获取当前人种对应的lastPart索引
%         curr_nation_indices = nation_indices{i_nation};
% 
% 
%         for attribute = attributes
%             lab = lab_fit_reshaped{i_obs,i_nation}(indices_target, :, :, attribute);            
%             lab_mean = nanmean(lab, 3);
% 
%             if ~all(isnan(lab_mean(:)))                
%                 lim_min_x = min(lim_min_x, min(lab_mean(:,2)));
%                 lim_max_x = max(lim_max_x, max(lab_mean(:,2)));
%                 lim_min_y = min(lim_min_y, min(lab_mean(:,3)));
%                 lim_max_y = max(lim_max_y, max(lab_mean(:,3)));
%             end
%         end
% 
% 
%         % 考虑PMCC点
%         lim_min_x = min(lim_min_x, labCh_PMCC(i_nation, 2));
%         lim_max_x = max(lim_max_x, labCh_PMCC(i_nation, 2));
%         lim_min_y = min(lim_min_y, labCh_PMCC(i_nation, 3));
%         lim_max_y = max(lim_max_y, labCh_PMCC(i_nation, 3));
%     end
% end
% 
% % 添加边距
% lim_min_x = lim_min_x - 1;
% lim_max_x = lim_max_x + 1;
% lim_min_y = lim_min_y - 1;
% lim_max_y = lim_max_y + 1;
% 
% % 确保x和y轴范围相同，以保持等比例显示
% range_x = lim_max_x - lim_min_x;
% range_y = lim_max_y - lim_min_y;
% max_range = max(range_x, range_y);
% 
% % 调整范围使x和y轴的刻度间隔相同
% lim_min_x = (lim_min_x + lim_max_x - max_range) / 2;
% lim_max_x = (lim_min_x + lim_max_x + max_range) / 2;
% lim_min_y = (lim_min_y + lim_max_y - max_range) / 2;
% lim_max_y = (lim_min_y + lim_max_y + max_range) / 2;
%%
lim_min_x = 0;
lim_max_x = 30;
lim_min_y = 20;
lim_max_y = 75;


%% 绘图部分 - 按C*值映射颜色
nan_record={};

% 创建从冷色(蓝色)到暖色(红色)的颜色映射
cmap = colormap('copper');
XYZw_gray_nations=[];
for i_nation = 1:length(nations)
    XYZw_gray_nations=[XYZw_gray_nations;XYZw_gray_mean{i_nation,1}];
end

% 为C*值准备颜色映射范围
C_star_values = [];
% 存储所有数据用于拔靴法分析
all_data_for_bootstrap = struct();
data_counter = 1;

for i_obs=1:length(obs_types)
    for i_nation = 1:length(nations)
        % 获取数据
        lab_data = lab_fit_reshaped{i_obs,i_nation}(indices_target, :, :, 1);
        lab = nanmean(lab_data, 3); % 按受试者维度求平均
        valid_idx = ~all(isnan(lab), 2);
        lab_valid = lab(valid_idx, :);
        
        if ~isempty(lab_valid)
            % 计算C*值
            C_star = sqrt(lab_valid(:,2).^2 + lab_valid(:,3).^2);
            C_star_values = [C_star_values; C_star];
            
            % 存储用于拔靴法分析的数据
            all_data_for_bootstrap(data_counter).i_obs = i_obs;
            all_data_for_bootstrap(data_counter).i_nation = i_nation;
            all_data_for_bootstrap(data_counter).lab_valid = lab_valid;
            all_data_for_bootstrap(data_counter).XYZw_gray = XYZw_gray_mean{i_nation,1}(valid_idx);
            data_counter = data_counter + 1;
        end
    end
end

% 计算C*值的范围用于颜色映射
c_min = min(C_star_values);
c_max = max(C_star_values);

% =========================================================================
% 拔靴法中介效应分析函数 - 修正版本
% =========================================================================
function [results] = bootstrap_mediation_analysis(X, M, Y, n_boot, conf_level)
    % X: 自变量（亮度值）
    % M: 中介变量（L*值）
    % Y: 因变量（C*值）
    % n_boot: 拔靴法抽样次数
    % conf_level: 置信水平（如0.95）
    
    n = length(X);
    results = struct();
    
    % 第一步：总效应模型 Y ~ X
    [b_total, bint_total, r_total, rint_total, stats_total] = regress(Y, [ones(n,1), X]);
    results.total_effect = b_total(2); % c路径
    results.total_p = stats_total(3); % p值
    
    % 第二步：中介效应模型 M ~ X
    [b_a, bint_a, r_a, rint_a, stats_a] = regress(M, [ones(n,1), X]);
    results.a_path = b_a(2); % a路径
    results.a_p = stats_a(3);
    
    % 第三步：直接效应模型 Y ~ X + M
    % 使用 regress 但需要手动计算统计量
    X_matrix = [ones(n,1), X, M];
    [b_direct, bint_direct] = regress(Y, X_matrix);
    results.direct_effect = b_direct(2); % c'路径
    results.b_path = b_direct(3); % b路径
    
    % 手动计算p值
    y_hat = X_matrix * b_direct;
    residuals = Y - y_hat;
    RSS = sum(residuals.^2);
    TSS = sum((Y - mean(Y)).^2);
    R_squared = 1 - RSS/TSS;
    k = size(X_matrix, 2); % 预测变量数量
    df_residual = n - k;
    MSE = RSS / df_residual;
    
    % 计算系数的标准误
    XtX_inv = inv(X_matrix' * X_matrix);
    se_b = sqrt(diag(MSE * XtX_inv));
    
    % 计算t统计量和p值
    t_stats = b_direct ./ se_b;
    p_values = 2 * (1 - tcdf(abs(t_stats), df_residual));
    
    results.direct_p = p_values(2);
    results.b_p = p_values(3);
    results.R_squared = R_squared;
    results.MSE = MSE;
    
    % 计算间接效应 a*b
    results.indirect_effect = results.a_path * results.b_path;
    
    % 拔靴法抽样
    boot_indirect = zeros(n_boot, 1);
    boot_direct = zeros(n_boot, 1);
    boot_a = zeros(n_boot, 1);
    boot_b = zeros(n_boot, 1);
    
    for i = 1:n_boot
        % 有放回抽样
        indices = randi(n, n, 1);
        X_boot = X(indices);
        M_boot = M(indices);
        Y_boot = Y(indices);
        
        % 估计a路径
        b_a_boot = regress(M_boot, [ones(n,1), X_boot]);
        a_boot = b_a_boot(2);
        
        % 估计b和c'路径
        X_matrix_boot = [ones(n,1), X_boot, M_boot];
        b_direct_boot = regress(Y_boot, X_matrix_boot);
        b_boot = b_direct_boot(3);
        c_prime_boot = b_direct_boot(2);
        
        boot_indirect(i) = a_boot * b_boot;
        boot_direct(i) = c_prime_boot;
        boot_a(i) = a_boot;
        boot_b(i) = b_boot;
    end
    
    % 计算置信区间
    alpha = 1 - conf_level;
    ci_lower = alpha/2 * 100;
    ci_upper = (1 - alpha/2) * 100;
    
    results.boot_indirect_ci = prctile(boot_indirect, [ci_lower, ci_upper]);
    results.boot_direct_ci = prctile(boot_direct, [ci_lower, ci_upper]);
    results.boot_a_ci = prctile(boot_a, [ci_lower, ci_upper]);
    results.boot_b_ci = prctile(boot_b, [ci_lower, ci_upper]);
    results.boot_indirect_mean = mean(boot_indirect);
    results.boot_indirect_std = std(boot_indirect);
    
    % 判断中介类型（基于拔靴法置信区间）
    indirect_ci_lower = results.boot_indirect_ci(1);
    indirect_ci_upper = results.boot_indirect_ci(2);
    direct_ci_lower = results.boot_direct_ci(1);
    direct_ci_upper = results.boot_direct_ci(2);
    
    if indirect_ci_lower > 0 && indirect_ci_upper > 0
        % 间接效应显著
        if direct_ci_lower <= 0 && direct_ci_upper >= 0
            results.mediation_type = '完全中介';
            results.mediation_significant = true;
            results.direct_significant = false;
        else
            results.mediation_type = '部分中介';
            results.mediation_significant = true;
            results.direct_significant = true;
        end
    else
        % 间接效应不显著
        if direct_ci_lower > 0 || direct_ci_upper < 0
            results.mediation_type = '无中介（直接效应）';
            results.mediation_significant = false;
            results.direct_significant = true;
        else
            results.mediation_type = '无显著关系';
            results.mediation_significant = false;
            results.direct_significant = false;
        end
    end
    
    % 计算效应占比（如果总效应显著）
    if results.total_p < 0.05
        results.prop_mediated = abs(results.indirect_effect / results.total_effect) * 100;
    else
        results.prop_mediated = 0;
    end
    
    % 存储更多统计信息
    results.n = n;
    results.conf_level = conf_level;
    results.n_boot = n_boot;
end

% =========================================================================
% 简化版本的中介分析（如果上面的函数太复杂）
% =========================================================================
function [simple_results] = simple_mediation_analysis(X, M, Y, n_boot)
    % 简化的中介分析，只计算拔靴法置信区间
    
    n = length(X);
    simple_results = struct();
    
    % 计算原始路径系数
    b_total = regress(Y, [ones(n,1), X]);
    b_a = regress(M, [ones(n,1), X]);
    b_direct = regress(Y, [ones(n,1), X, M]);
    
    simple_results.total_effect = b_total(2);
    simple_results.a_path = b_a(2);
    simple_results.direct_effect = b_direct(2);
    simple_results.b_path = b_direct(3);
    simple_results.indirect_effect = b_a(2) * b_direct(3);
    
    % 拔靴法
    boot_indirect = zeros(n_boot, 1);
    boot_direct = zeros(n_boot, 1);
    
    for i = 1:n_boot
        indices = randi(n, n, 1);
        X_boot = X(indices);
        M_boot = M(indices);
        Y_boot = Y(indices);
        
        a_boot = regress(M_boot, [ones(n,1), X_boot]);
        b_direct_boot = regress(Y_boot, [ones(n,1), X_boot, M_boot]);
        
        boot_indirect(i) = a_boot(2) * b_direct_boot(3);
        boot_direct(i) = b_direct_boot(2);
    end
    
    simple_results.boot_indirect_ci = prctile(boot_indirect, [2.5, 97.5]);
    simple_results.boot_direct_ci = prctile(boot_direct, [2.5, 97.5]);
    
    % 判断中介类型
    if simple_results.boot_indirect_ci(1) > 0
        if simple_results.boot_direct_ci(1) > 0 || simple_results.boot_direct_ci(2) < 0
            simple_results.mediation_type = '部分中介';
        else
            simple_results.mediation_type = '完全中介';
        end
    else
        simple_results.mediation_type = '无中介';
    end
end

% =========================================================================
% 执行拔靴法分析
% =========================================================================
fprintf('=== 拔靴法中介效应分析 ===\n');
fprintf('检验: 亮度(X) → L*(M) → C*(Y) 的路径\n\n');

mediation_results = cell(length(obs_types), length(nations));
significant_mediations = 0;

% 创建结果表格
result_table = table();
row_counter = 1;

for i_obs=1:length(obs_types)
    for i_nation = 1:length(nations)
        % 获取当前组合的数据
        found_data = false;
        for k = 1:length(all_data_for_bootstrap)
            if all_data_for_bootstrap(k).i_obs == i_obs && ...
               all_data_for_bootstrap(k).i_nation == i_nation
                lab_valid = all_data_for_bootstrap(k).lab_valid;
                X = all_data_for_bootstrap(k).XYZw_gray; % 亮度作为X
                M = lab_valid(:, 1); % L*作为M
                Y = sqrt(lab_valid(:,2).^2 + lab_valid(:,3).^2); % C*作为Y
                
                % 移除NaN值
                valid = ~isnan(X) & ~isnan(M) & ~isnan(Y);
                X = X(valid);
                M = M(valid);
                Y = Y(valid);
                
                if length(X) < 10
                    fprintf('观测类型: %s, 人种: %s - 数据不足(<10)\n', ...
                        obs_types(i_obs), nations(i_nation));
                    mediation_results{i_obs, i_nation} = [];
                    found_data = true;
                    break;
                end
                
                % 标准化数据（可选）
                % X_norm = (X - mean(X)) / std(X);
                % M_norm = (M - mean(M)) / std(M);
                % Y_norm = (Y - mean(Y)) / std(Y);
                
                % 执行拔靴法中介分析（使用简化版本）
                try
                    results = simple_mediation_analysis(X, M, Y, 5000);
                    mediation_results{i_obs, i_nation} = results;
                    
                    % 添加到结果表格
                    result_table.obs_type{row_counter} = obs_types(i_obs);
                    result_table.nation{row_counter} = nations(i_nation);
                    result_table.n_samples(row_counter) = length(X);
                    result_table.total_effect(row_counter) = results.total_effect;
                    result_table.indirect_effect(row_counter) = results.indirect_effect;
                    result_table.direct_effect(row_counter) = results.direct_effect;
                    result_table.indirect_ci_lower(row_counter) = results.boot_indirect_ci(1);
                    result_table.indirect_ci_upper(row_counter) = results.boot_indirect_ci(2);
                    result_table.direct_ci_lower(row_counter) = results.boot_direct_ci(1);
                    result_table.direct_ci_upper(row_counter) = results.boot_direct_ci(2);
                    result_table.mediation_type{row_counter} = results.mediation_type;
                    result_table.is_mediated(row_counter) = contains(results.mediation_type, '中介');
                    
                    % 打印结果
                    fprintf('观测类型: %s, 人种: %s (n=%d)\n', ...
                        obs_types(i_obs), nations(i_nation), length(X));
                    fprintf('总效应: %.4f\n', results.total_effect);
                    fprintf('间接效应: %.4f, 95%% CI: [%.4f, %.4f]\n', ...
                        results.indirect_effect, results.boot_indirect_ci(1), results.boot_indirect_ci(2));
                    fprintf('直接效应: %.4f, 95%% CI: [%.4f, %.4f]\n', ...
                        results.direct_effect, results.boot_direct_ci(1), results.boot_direct_ci(2));
                    fprintf('中介类型: %s\n', results.mediation_type);
                    fprintf('----------------------------------------\n');
                    
                    if contains(results.mediation_type, '中介')
                        significant_mediations = significant_mediations + 1;
                    end
                    
                    row_counter = row_counter + 1;
                    
                catch ME
                    fprintf('分析失败: %s, %s - %s\n', ...
                        obs_types(i_obs), nations(i_nation), ME.message);
                    mediation_results{i_obs, i_nation} = [];
                end
                
                found_data = true;
                break;
            end
        end
        
        if ~found_data
            mediation_results{i_obs, i_nation} = [];
        end
    end
end

fprintf('\n=== 总结 ===\n');
fprintf('总共有 %d 个显著的中介效应（完全或部分中介）\n', significant_mediations);
fprintf('占总分析组合的 %.1f%%\n', significant_mediations/(length(obs_types)*length(nations))*100);

% 显示结果表格
disp('详细结果表格:');
disp(result_table);

% 保存结果到文件
if exist('ellip_pic_folder', 'var')
    save_folder = fullfile(ellip_pic_folder, 'mediation_results');
    if ~exist(save_folder, "dir")
        mkdir(save_folder);
    end
    writetable(result_table, fullfile(save_folder, 'mediation_analysis_results.csv'));
    save(fullfile(save_folder, 'mediation_results.mat'), 'mediation_results', 'result_table');
end

% =========================================================================
% 可视化中介分析结果
% =========================================================================
for i_obs=1:length(obs_types)
    % 跳过没有数据的观测类型
    has_data = false;
    for i_nation = 1:length(nations)
        if ~isempty(mediation_results{i_obs, i_nation})
            has_data = true;
            break;
        end
    end
    
    if ~has_data
        continue;
    end
    
    figure('Position', [100, 100, 1200, 800]);
    set(gcf, 'Color', 'white');
    
    plot_count = 0;
    for i_nation = 1:length(nations)
        if ~isempty(mediation_results{i_obs, i_nation})
            plot_count = plot_count + 1;
            results = mediation_results{i_obs, i_nation};
            
            subplot(2, 3, plot_count);
            hold on;
            
            % 绘制路径图
            x_pos = [0.2, 0.5, 0.8];
            y_pos = [0.5, 0.5, 0.5];
            
            % 节点
            plot(x_pos(1), y_pos(1), 'bo', 'MarkerSize', 30, 'MarkerFaceColor', 'b');
            text(x_pos(1), y_pos(1), '亮度', 'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'bottom', 'FontSize', 10, 'FontWeight', 'bold');
            
            plot(x_pos(2), y_pos(2), 'go', 'MarkerSize', 30, 'MarkerFaceColor', 'g');
            text(x_pos(2), y_pos(2), 'L*', 'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'bottom', 'FontSize', 10, 'FontWeight', 'bold');
            
            plot(x_pos(3), y_pos(3), 'ro', 'MarkerSize', 30, 'MarkerFaceColor', 'r');
            text(x_pos(3), y_pos(3), 'C*', 'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'bottom', 'FontSize', 10, 'FontWeight', 'bold');
            
            % 绘制箭头函数
            draw_arrow = @(x1,y1,x2,y2) annotation('arrow', [x1 x2], [y1 y2], ...
                'LineWidth', 1.5, 'HeadWidth', 10, 'HeadLength', 10);
            
            % 路径 a: X -> M
            if results.boot_indirect_ci(1) > 0
                draw_arrow(0.25, 0.5, 0.45, 0.5);
                text(0.35, 0.55, sprintf('a=%.3f', results.a_path), ...
                    'FontSize', 9, 'FontWeight', 'bold', 'Color', 'g');
            else
                draw_arrow(0.25, 0.5, 0.45, 0.5);
                text(0.35, 0.55, sprintf('a=%.3f', results.a_path), 'FontSize', 9);
            end
            
            % 路径 b: M -> Y
            if results.boot_indirect_ci(1) > 0
                draw_arrow(0.55, 0.5, 0.75, 0.5);
                text(0.65, 0.55, sprintf('b=%.3f', results.b_path), ...
                    'FontSize', 9, 'FontWeight', 'bold', 'Color', 'g');
            else
                draw_arrow(0.55, 0.5, 0.75, 0.5);
                text(0.65, 0.55, sprintf('b=%.3f', results.b_path), 'FontSize', 9);
            end
            
            % 路径 c': X -> Y (直接)
            if results.boot_direct_ci(1) > 0 || results.boot_direct_ci(2) < 0
                draw_arrow(0.25, 0.48, 0.75, 0.48);
                text(0.5, 0.43, sprintf('c''=%.3f', results.direct_effect), ...
                    'FontSize', 9, 'FontWeight', 'bold', 'Color', 'b');
            else
                draw_arrow(0.25, 0.48, 0.75, 0.48);
                text(0.5, 0.43, sprintf('c''=%.3f', results.direct_effect), 'FontSize', 9);
            end
            
            % 标题
            title_str = sprintf('%s\n%s', nations(i_nation), results.mediation_type);
            if contains(results.mediation_type, '中介')
                title(title_str, 'FontSize', 10, 'Color', 'g', 'FontWeight', 'bold');
            else
                title(title_str, 'FontSize', 10);
            end
            
            % 添加置信区间信息
            text(0.05, 0.15, sprintf('间接效应CI:\n[%.3f, %.3f]', ...
                results.boot_indirect_ci(1), results.boot_indirect_ci(2)), ...
                'FontSize', 8, 'Units', 'normalized');
            
            axis off;
            xlim([0, 1]);
            ylim([0, 1]);
        end
    end
    
    if plot_count > 0
        % suptitle(sprintf('中介效应分析 - 观测类型: %s', obs_types(i_obs)));
        
        if exist('ellip_pic_folder', 'var')
            save_folder = fullfile(ellip_pic_folder, Dtype, "mediation_analysis");
            if ~exist(save_folder, "dir")
                mkdir(save_folder);
            end
            exportgraphics(gcf, fullfile(save_folder, sprintf('mediation_%s.jpg', obs_types(i_obs))), 'Resolution', 300);
        end
        close(gcf);
    end
end

% =========================================================================
% 继续原始的可视化代码（使用C*值颜色编码）
% =========================================================================
for i_obs=1:length(obs_types)
    obs_type=obs_types(i_obs);
    for i_nation = 1:length(nations)
        nation=nations(i_nation);
        nation_serial=strcat(sprintf("%02d",i_nation),nation);
        if iOr=='r'
            CT=CT_nations{i_nation};
        end
        % 获取当前人种的subject数量
        n_subjects = size(lab_fit_reshaped{i_obs, i_nation}, 3);
        if n_subjects == 0
            continue;
        end
        
        % 获取当前人种对应的lastPart索引
        curr_nation_indices = nation_indices{i_nation};        
        % 分离性别索引
        gender_indices = separate_genders(n_subjects, curr_nation_indices, lastParts);

        figure;
        hold on;
        set(gcf, 'Color', 'white');
        
        for attribute = [1]
            attribute_serial = strcat(sprintf("%02d", attribute), attribute_names(attribute));
            
            % 直接从lab_fit_reshaped获取数据
            lab_data = lab_fit_reshaped{i_obs,i_nation}(indices_target, :, :, attribute);
            
            % 计算平均值并准备数据
            lab = nanmean(lab_data, 3); % 按受试者维度求平均
            
            % 确保数据维度匹配
            data_for_color = lab(:, 1); % 使用lab的第一个维度数据
            
            % 找到有效数据的索引
            valid_idx = ~any(isnan(lab), 2);
            lab_valid = lab(valid_idx, :);
            data_valid = data_for_color(valid_idx);
            
            % 准备绘图数据
            labCh_valid = lab_valid;
            labCh_valid(:,4) = sqrt(labCh_valid(:,2).^2 + labCh_valid(:,3).^2); % C*值
            labCh_valid(:,5) = atan2d(labCh_valid(:,3), labCh_valid(:,2)); % h角度
            
            % 获取当前人种的XYZw_gray_mean作为横坐标
            x_data = XYZw_gray_mean{i_nation,1};
            x_data = x_data(valid_idx); % 与有效数据对齐
            
            if ~isempty(lab_valid) && ~isempty(x_data)
                % 使用C*值进行颜色编码
                C_star_data = labCh_valid(:,4);
                C_star_norm = (C_star_data - c_min) / (c_max - c_min);
                
                % 为每个点设置颜色
                for i_point = 1:size(lab_valid, 1)
                    % 根据C*值获取颜色
                    color_idx = round(C_star_norm(i_point) * (size(cmap, 1) - 1)) + 1;
                    point_color = cmap(color_idx, :);
                    
                    % 使用XYZw_gray_mean作为横坐标，L*作为纵坐标
                    if strcmp(iOr,"i")
                        scatter(x_data(i_point), labCh_valid(i_point, 1), 20, 'o', 'filled', ...
                            'MarkerFaceColor', point_color, 'MarkerEdgeColor', point_color, 'LineWidth', 0.5);
                    else
                        text(x_data(i_point), labCh_valid(i_point, 1), ...
                             num2str(i_point), 'FontSize', 10, ...
                             'VerticalAlignment', 'top', 'Color', point_color, ...
                             'FontWeight', 'bold');
                    end
                end
                
                % 在图中添加中介分析结果摘要
                if ~isempty(mediation_results{i_obs, i_nation})
                    results = mediation_results{i_obs, i_nation};
                    annotation_text = sprintf(['中介分析结果:\n' ...
                        '间接效应(a*b): %.3f\n' ...
                        '95%% CI: [%.3f, %.3f]\n' ...
                        '直接效应(c''): %.3f\n' ...
                        '95%% CI: [%.3f, %.3f]\n' ...
                        '类型: %s'], ...
                        results.indirect_effect, ...
                        results.boot_indirect_ci(1), results.boot_indirect_ci(2), ...
                        results.direct_effect, ...
                        results.boot_direct_ci(1), results.boot_direct_ci(2), ...
                        results.mediation_type);
                    
                    % 根据中介类型设置文本颜色
                    if contains(results.mediation_type, '中介')
                        text_color = 'green';
                    else
                        text_color = 'black';
                    end
                    
                    text(0.02, 0.98, annotation_text, 'Units', 'normalized', ...
                        'VerticalAlignment', 'top', 'HorizontalAlignment', 'left', ...
                        'FontSize', 8, 'BackgroundColor', 'white', 'EdgeColor', 'black', ...
                        'Color', text_color);
                end
            end
        end
        
        % 添加图例、标签和标题
        xlabel('Luminance', 'FontSize', 12*2);
        ylabel('\textit{L*}', 'Interpreter', 'latex', 'FontSize', 12*2);
        title([nation_names(i_nation)], 'FontSize', 12*2);
        
        % 添加颜色条表示C*值
        if i_nation == 4
            cb = colorbar;
            cb.Label.String = 'C* (Chroma)';
            cb.Label.Interpreter = 'latex';
            cb.Label.FontSize = 12;
            caxis([c_min, c_max]);
            colormap(cmap);
        end
        
        % 设置坐标轴范围
        axis equal;
        
        % 自动调整坐标轴范围或使用预设值
        if exist('lim_max_x', 'var') && exist('lim_max_y', 'var')
            x_max = max(max(x_data), lim_max_x); % 取数据和预设值的最大值
            xlim([0, x_max]);
            ylim([0, lim_max_y]);
        else
            % 自动计算范围
            x_vals = [];
            y_vals = [];
            for i_pt = 1:length(nations)
                if ~isempty(XYZw_gray_mean{i_pt,1})
                    x_vals = [x_vals; XYZw_gray_mean{i_pt,1}];
                end
                if ~isempty(lab_fit_reshaped{i_obs,i_pt})
                    lab_temp = nanmean(lab_fit_reshaped{i_obs,i_pt}(indices_target,:,:,1), 3);
                    y_vals = [y_vals; lab_temp(:,1)];
                end
            end
            xlim([0, max(x_vals)*1.1]);
            ylim([0, max(y_vals)*1.1]);
        end
        
        % 保存图片
        save_folder = fullfile(ellip_pic_folder, Dtype, "hml_bootstrap", lightness_type, obs_type, iOr);
        if ~exist(save_folder, "dir")
            mkdir(save_folder);
        end
        exportgraphics(gcf, fullfile(save_folder, strcat(nation_serial, '_L.jpg')), 'Resolution', 300);
        close(gcf);
    end
    
    % 合并所有图片
    save_folder = fullfile(ellip_pic_folder, Dtype, "hml_bootstrap", lightness_type, obs_type, iOr);
    concatenate_images1noSerial(save_folder, 4);   
end
%%
% folder="D:\work\VIVOskinExpe\renderCode\dsp\f01\r\jpg\noCard";
% concatenate_images1(folder,7);   