close all; % 关闭所有图窗
clc;       % 清空命令窗口
clear;     % 清除工作区所有变量
addpath('utils\')
%% 定义所有需要处理的 attribute
% attributes = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
attributes = [1];
attribute_names = ["Preference", "Attractiveness", "Feminine", "Cooperative", ...
    "Youth", "Healthy", "Fidelity", "Harmony", "Fair", "Ruddy"];
nations = ["AS", "CA", "SA", "AF"];
nation_names=["Asian","Caucasian","South Asian","African","all"];
% nations = ["AS"];
% lastParts = {'f04i', 'f05i', 'f06i', 'm04i', 'm05i', 'm06i'};n_para = 21;iOr='i';

lastParts = {'f04i', 'f05i', 'f06i', 'm04i', 'm05i', 'm06i',...
'f01i', 'f02i', 'f03i', 'm01i', 'm02i', 'm03i',...
'f07i', 'f08i','m07i', 'm08i',...
'f09i', 'f10i','m09i', 'm10i'};n_para = 21;iOr='i';
%------------------------------------
% lastParts = {'f04r', 'f05r', 'f06r', 'm04r', 'm05r', 'm06r',...
% 'f01r', 'f02r', 'f03r', 'm01r', 'm02r', 'm03r',...
% 'f07r', 'f08r','m07r', 'm08r',...
% 'f09r', 'f10r','m09r', 'm10r'};n_para = 14;iOr='r';


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
% obs_types = ["non_model"];
obs_types = ["non_model"];
% obs_types = ["non_model", "model_group", "model"];
scale_type="scaled";

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
    indices_target = [1:7];
    % load("optimizedD\light_i.mat","CCT_light");
    % load("optimizedD\neutral_gray\i\gray_patch4\XYZw_all.mat", ...
    % "CCT_white_mean","XYZw_mean");
    % % CT = CCT_white_mean;
    % CT = [3000, 4000, 5000, 6000,6500, 7000, 8000,  ...
    %   3000, 4000, 5000, 6000,6500, 7000, 8000,  ...
    %   3000, 4000, 5000, 6000, 6500, 7000, 8000]';
    % for i_para=1:length(CT)
    %     XYZw_mean(i_para,:)=CCT2xyz(CT(i_para));
    % end
    load('optimizedD\neutral_gray\combi_XYZw_i.mat', 'XYZ_combi',"CCT_combi");
    CT=CCT_combi;
    XYZw_mean=XYZ_combi;
else
    indices_target = 1:14;    
    for i_nation=1:length(nations)
        model_tcp_mean_inds=[];
        for i_lastPart=nation_indices{i_nation}
            lastPart=lastParts{i_lastPart};
            load(fullfile("..\renderCode\light_r\model_light_mean", ...
                strcat(strrep(lastPart,"r",""),".mat")), ...
            "model_tcp_mean","XYZwpre_mea");
            XYZwpre_mea_inds(:,:,i_lastPart)=XYZwpre_mea;
            model_tcp_mean_inds=[model_tcp_mean_inds,model_tcp_mean];
        end
        XYZw_mean{i_nation}=nanmean(XYZwpre_mea_inds,3);
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
% Dtype = 'efit_p';
Dtype = 'noCAT';
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
            
            % 循环处理每个 attribute
            for i_attr = 1:length(attributes)
                attribute = attributes(i_attr);
                attribute_serial = strcat(sprintf("%02d", attribute), attribute_names(attribute));
                
                % 定义路径
                source_file = fullfile('AnalyseResults_p', Dtype,scale_type_origin, lastPart, obs_type, attribute_serial, 'ellipPara', 'fitRes.mat');
                
                % 加载数据
                if exist(source_file, 'file')
                    par_all_data = load(source_file);
                    par_all = par_all_data.par_all;
                    par_all=[par_all;nan(size(par_current,1)-size(par_all,1),size(par_all,2))];
                    par_current(:, :, i_subject, i_attr) = par_all;
                    lab_bf=[average_current(:, 1, i_subject), par_all(:,4:5)];
                    xyz_fit=[];lab_scaled=[];
                    if strcmp(scale_type,"scaled")
                        for i_para=1:size(par_all,1)                                
                            xyz_fit(i_para,:)=lab2xyz2(lab_bf(i_para,:),"user",wd65./wd65(2).*XYZw_LUT(2));
                            lab_scaled(i_para,:)=xyz2lab(xyz_fit(i_para,:),"user",wd65./wd65(2).*XYZw_white(i_para,2));
                        end
                        lab_fit_current(:, :, i_subject, i_attr) = lab_scaled;
                    elseif strcmp(scale_type,"unscaled")
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
        lab_fit_reshapedD65{i_obs, i_nation}=nanmean(lab_fit_current(indices_target,:),1);
        lab_fit_hD65{i_obs, i_nation}=atan2d(lab_fit_reshapedD65{i_obs, i_nation}(:,3), ...
            lab_fit_reshapedD65{i_obs, i_nation}(:,2));

        
        % average_reshaped只需要存储一次（不依赖于观察者类型）
        if i_obs == 1
            average_reshaped{i_nation} = average_current;
        end
        
        average_mean{i_obs, i_nation}=nanmean(average_reshaped{i_nation} ,3); 
        average_meanD65{i_obs, i_nation}=nanmean(average_mean{i_obs, i_nation}(indices_target,:),1);
        average_hD65{i_obs, i_nation}=atan2d(average_meanD65{i_obs, i_nation}(:,3), ...
            average_meanD65{i_obs, i_nation}(:,2));

        par_mean{i_obs,i_nation}=nanmean(par_reshaped{i_obs,i_nation},3);
        average_nation_temp(i_nation,:)=mean(average_mean{i_obs, i_nation}(indices_target,:));
        hue_ave_all{i_obs, i_nation, attribute}=atan2d(average_nation_temp(i_nation,3),average_nation_temp(i_nation,2));
    end
    average_nations{i_obs}=average_nation_temp;
end
%% 保存
output_folder=fullfile("ellip_pic_p", Dtype);
if ~exist(output_folder,"dir")
    mkdir(output_folder);
end
save(fullfile(output_folder,strcat("data_reshaped_",iOr,".mat")),"par_mean","average_mean", ...
    "lab_fit_reshaped","file_missing","par_reshaped","average_reshaped");
%% 计算全局坐标轴范围
% 初始化极值变量
lim_min_x = inf;  % a*轴最小边界初始化为正无穷
lim_min_y = inf;  % b*轴最小边界初始化为正无穷
lim_max_x = -inf; % a*轴最大边界初始化为负无穷
lim_max_y = -inf; % b*轴最大边界初始化为负无穷

% 遍历所有可能的数据组合计算全局极值
for i_nation = 1:length(nations)
    for i_obs = 1:length(obs_types)
        obs_type=obs_types(i_obs);
        % 获取当前人种的subject数量
        n_subjects = size(lab_fit_reshaped{i_obs, i_nation}, 3);
        if n_subjects == 0
            continue;
        end
        
        % 获取当前人种对应的lastPart索引
        curr_nation_indices = nation_indices{i_nation};
        

        for attribute = attributes
            lab = lab_fit_reshaped{i_obs,i_nation}(indices_target, :, :, attribute);
            lab_mean = nanmean(lab, 3);
            if ~all(isnan(lab_mean(:)))                
                lim_min_x = min(lim_min_x, min(lab_mean(:,2)));
                lim_max_x = max(lim_max_x, max(lab_mean(:,2)));
                lim_min_y = min(lim_min_y, min(lab_mean(:,3)));
                lim_max_y = max(lim_max_y, max(lab_mean(:,3)));
            end
        end

        
        % 考虑PMCC点
        lim_min_x = min(lim_min_x, labCh_PMCC(i_nation, 2));
        lim_max_x = max(lim_max_x, labCh_PMCC(i_nation, 2));
        lim_min_y = min(lim_min_y, labCh_PMCC(i_nation, 3));
        lim_max_y = max(lim_max_y, labCh_PMCC(i_nation, 3));
    end
end

% 添加边距
lim_min_x = lim_min_x - 1;
lim_max_x = lim_max_x + 1;
lim_min_y = lim_min_y - 1;
lim_max_y = lim_max_y + 1;

% 确保x和y轴范围相同，以保持等比例显示
range_x = lim_max_x - lim_min_x;
range_y = lim_max_y - lim_min_y;
max_range = max(range_x, range_y);

% 调整范围使x和y轴的刻度间隔相同
lim_min_x = (lim_min_x + lim_max_x - max_range) / 2;
lim_max_x = (lim_min_x + lim_max_x + max_range) / 2;
lim_min_y = (lim_min_y + lim_max_y - max_range) / 2;
lim_max_y = (lim_min_y + lim_max_y + max_range) / 2;


%% 绘图部分 - 按色温映射颜色
% output_folder=fullfile("ellip_pic_p", Dtype);
% if ~exist(output_folder,"dir")
%     mkdir(output_folder);
% end
% load(fullfile(output_folder,strcat("data_reshaped_",iOr,".mat")),"par_mean","average_mean", ...
%     "lab_fit_reshaped","file_missing","par_reshaped","average_reshaped");

output_folder1=fullfile("ellip_pic_p", "noCAT");
if ~exist(output_folder1,"dir")
    mkdir(output_folder1);
end
data_noCAT=load(fullfile(output_folder1,strcat("data_reshaped_",iOr,".mat")), ...
    "par_mean","average_mean", ...
    "lab_fit_reshaped","file_missing","par_reshaped","average_reshaped");
nan_record={};


% 创建从冷色(蓝色)到暖色(红色)的颜色映射
cmap = colormap('jet');
cmap = flipud(cmap);  % 翻转颜色映射，使蓝色对应高色温，红色对应低色温
load(fullfile("optimizedD\backGroundGray\XYZ_gray.mat"),"xyz_gray");
E=xyz_gray(:,2);

if iOr=='r'
    XYZw_used = XYZw_mean{i_nation};
elseif iOr=='i'
    XYZw_used = XYZw_mean;
end
for i_obs=1:length(obs_types)
    obs_type=obs_types(i_obs);
    for i_nation = 1:length(nations)
        nation=nations(i_nation);
        nation_name=nation_names(i_nation);
        nation_serial=strcat(sprintf("%02d",i_nation),nation_name);
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
        
        for attribute = [1]
            attribute_serial = strcat(sprintf("%02d", attribute), attribute_names(attribute));

            
            % 直接从lab_fit_reshaped获取数据
            lab_data = lab_fit_reshaped{i_obs,i_nation}(indices_target, :, :, attribute);
            lab_data1 = data_noCAT.lab_fit_reshaped{i_obs,i_nation}(indices_target, :, :, attribute);
            
            % 计算平均值并准备色温数据
            lab = nanmean(lab_data, 3); % 按受试者维度求平均
            lab1 = nanmean(lab_data1, 3); % 按受试者维度求平均
            %late CAT
            XYZ_bf=lab2xyz2(lab1,'d65_64');
            for i_para=1:size(lab1,1)
                D_pre(i_para,1)= calculateD(CT(i_para,1), 0, "efit_p",E(i_para,1));
                XYZt(i_para,:) = CAT16_D(XYZ_bf(i_para,:), ...
                    XYZw_used(i_para,:), wd65, D_pre(i_para,1));                
            end
            Labt = xyz2lab(XYZt, 'd65_64');
            %从最近的点转过去
            Labt_near=Labt;
            for i_para=[1]
                XYZt_near(i_para,:) = CAT16_D(XYZ_bf(i_para+1,:), ...
                    XYZw_used(i_para+1,:), XYZw_used(i_para,:), D_pre(i_para+1,1)); 

                XYZt_near(i_para+1,:) = CAT16_D(XYZ_bf(i_para,:), ...
                    XYZw_used(i_para,:), XYZw_used(i_para+1,:), D_pre(i_para,1));

            end
            Labt_near(1:2,:) = xyz2lab(XYZt_near(1:2,:), 'd65_64');

            %从D65转过去
            Labt_frD65=Labt;
            for i_para=1:size(lab1,1)
                XYZt_frD65(i_para,:) = CAT16_D(XYZ_bf(5,:), ...
                    XYZw_used(5,:), XYZw_used(i_para,:), D_pre(5,1)); 
            end
            Labt_frD65 = xyz2lab(XYZt_frD65, 'd65_64');
                        
            % 确保CT数据与lab数据维度匹配
            CT_for_plot = CT(indices_target);
            
            % 找到有效数据的索引
            valid_idx = ~all(isnan(lab), 2);
            lab_valid = lab(valid_idx, :);
            CT_valid = CT_for_plot(valid_idx);
            
            if ~isempty(lab_valid)
                % 归一化色温值用于颜色映射
                CT_min = min(CT_valid);
                CT_max = max(CT_valid);
                CT_norm = (CT_valid - CT_min) / (CT_max - CT_min);
                
                % 为每个点设置颜色
                figure(i_nation);hold on;
                for i_point = 1:size(lab_valid, 1)
                    % 根据归一化色温值获取颜色
                    color_idx = round(CT_norm(i_point) * (size(cmap, 1) - 1)) + 1;
                    point_color = cmap(color_idx, :);
                    
                    % 绘制散点
                    plot_style='o';

                    scatter(lab_valid(i_point, 2), lab_valid(i_point, 3), 20, plot_style, 'filled', ...
                        'MarkerFaceColor', point_color, 'MarkerEdgeColor', point_color, 'LineWidth', 0.5);
                    % text(lab_valid(i_point, 2), lab_valid(i_point, 3), ...
                    %     sprintf('%dK', round(CT_valid(i_point))), 'FontSize', 4, ...
                    %     'VerticalAlignment', 'top', 'Color', 'k');
                    
                    % scatter(lab1(i_point, 2), lab1(i_point, 3), 10, '^', 'filled', ...
                    %     'MarkerFaceColor', 'none', 'MarkerEdgeColor', ...
                    %     point_color, 'LineWidth', 0.5);
                    % text(lab1(i_point, 2), lab1(i_point, 3), ...
                    %     sprintf('%dK', round(CT_valid(i_point))), 'FontSize', 4, ...
                    %     'VerticalAlignment', 'top', 'Color', 'k');

                    % scatter(Labt_near(i_point, 2), Labt_near(i_point, 3), 10, 'd', 'filled', ...
                    %     'MarkerFaceColor', 'none', 'MarkerEdgeColor', ...
                    %     point_color, 'LineWidth', 0.5);
                    % text(Labt_near(i_point, 2), Labt_near(i_point, 3), ...
                    %     sprintf('%dK', round(CT_valid(i_point))), 'FontSize', 4, ...
                    %     'VerticalAlignment', 'top', 'Color', 'k');
                    % 
                    % scatter(Labt_frD65(i_point, 2), Labt_frD65(i_point, 3), 10, 's', 'filled', ...
                    %     'MarkerFaceColor', 'none', 'MarkerEdgeColor', ...
                    %     point_color, 'LineWidth', 0.5);
                    % text(Labt_frD65(i_point, 2), Labt_frD65(i_point, 3), ...
                    %     sprintf('%dK', round(CT_valid(i_point))), 'FontSize', 4, ...
                    %     'VerticalAlignment', 'top', 'Color', 'k');

                end
                hue_all{i_obs, i_nation, attribute}=nanmean(atan2d(lab_valid(:,3),lab_valid(:,2)),1);
                % nanmean(atan2d(Labt(:,3),Labt(:,2)))
                % max(atan2d(Labt(:,3),Labt(:,2)))
                % min(atan2d(Labt(:,3),Labt(:,2)))
                dE_eNl{i_obs,i_nation}=deltaE2000(Labt,lab_valid);
                dE_eNl_mean{i_obs,i_nation}=mean(deltaE2000(Labt,lab_valid));
                for i=1:size(lab_valid,1)
                    for j=1:size(lab_valid,1)
                        dE(i,j)=deltaE2000(lab_valid(i,:),lab_valid(j,:));
                    end
                end
                dE_labels{i_obs,i_nation}=nanmean(nanmean(dE));
                lab_valid(CT_valid<4200,:)=[];
                for i=1:size(lab_valid,1)
                    for j=1:size(lab_valid,1)
                        dE1(i,j)=deltaE2000(lab_valid(i,:),lab_valid(j,:));
                    end
                end
                dE_labels_del{i_obs,i_nation}=nanmean(nanmean(dE1));





                for i=1:size(lab1,1)
                    for j=1:size(lab1,1)
                        dE1(i,j)=deltaE2000(lab1(i,:),lab1(j,:));
                    end
                end
                dE_labels1{i_obs,i_nation}=nanmean(nanmean(dE1));
                disp("d")

            end
        end

        
        % 添加PMCC点
        lab = lab_fit_reshaped{i_obs,i_nation}(indices_target, :, :, 1);
        lab = nanmean(lab, 3); % 按受试者维度求平均
        lab = nanmean(lab, 1); % 按光源/环境维度求平均
        
        % 绘制原始PMCC点
        xyz_mean=lab2xyz2(lab,"d65_64");
        xyz_PMCC=lab2xyz2(labCh_PMCC(i_nation,1:3),"d65_64");
        xyz_PMCC=xyz_PMCC./xyz_PMCC(2).*xyz_mean(2);
        labCh_PMCC_pre(i_nation,:)=xyz2lab(xyz_PMCC,"d65_64");
        plot(labCh_PMCC(i_nation, 2), labCh_PMCC(i_nation, 3), 's', 'MarkerSize', 8, ...
            'MarkerFaceColor', 'm', 'MarkerEdgeColor', 'm');
        % plot(labCh_PMCC_pre(i_nation, 2), labCh_PMCC_pre(i_nation, 3), 's', 'MarkerSize', 8, ...
        %     'MarkerFaceColor', 'none', 'MarkerEdgeColor', 'm');
        
        % 添加图例、标签和标题
        xlabel('\textit{a*}', 'Interpreter', 'latex', 'FontSize', 12*2);
        ylabel('\textit{b*}', 'Interpreter', 'latex', 'FontSize', 12*2);
        title([nation_names(i_nation)],'FontSize', 12*2);
        
        % 添加颜色条表示色温
        if  i_nation==4
            cb = colorbar;
            cb.Label.String = 'color temperature (K)';
            cb.Label.Interpreter = 'latex';  % 设置解释器为LaTeX
            cb.Label.FontSize = 12;          % 可以调整字体大小
            caxis([2500,8500]);
            colormap(cmap);
        end
        
        % 设置坐标轴范围
        axis equal;
        % xlim([lim_min_x, lim_max_x]);
        % ylim([lim_min_y, lim_max_y]);
        xlim([0, 50]);
        ylim([0, 50]);
        
        % 绘制y=x参考线
        x = linspace(0, 50, 100);
        plot(x, x, 'k--', 'LineWidth', 0.8);
        
        % 保存图片
        save_folder = fullfile("ellip_pic_p", Dtype, "CT", scale_type,obs_type, iOr);
        if ~exist(save_folder, "dir")
            mkdir(save_folder);
        end
        exportgraphics(gcf, fullfile(save_folder, strcat(iOr,obs_type,nation_serial, '_CT.jpg')), 'Resolution', 300);
        % close(gcf);
    end
    % 合并所有图片
    save_folder = fullfile("ellip_pic_p", Dtype, "CT",scale_type, obs_type, iOr);
    concatenate_images1(save_folder, 4);  
    close all
end

 