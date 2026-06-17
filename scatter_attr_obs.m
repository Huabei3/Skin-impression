close all; % 关闭所有图�?
clc;       % 清空命令窗口
clear;     % 清除工作区所有变�?
scale_type = "unscaled"; % 新增：unscaled或scaled
addpath("utils\")
%% 定义所有需要处理的 attribute
attributes = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

nations = ["AS", "CA", "SA", "AF"];
interpreter_type="tex";
text_type="ch";

if strcmp(text_type,"eng")
    nation_names = ["Asian", "Caucasian", "South Asian", "African"];
    attribute_names_new = ["Preference", "Attractiveness", "Feminine", "Cooperative", ...
    "Youth", "Healthy", "Fidelity", "Harmony", "Fair", "Ruddy"];
elseif strcmp(text_type,"ch")
    nation_names = ["亚洲人", "高加索人", "南亚人", "非洲人"];
    attribute_names_new = ["喜好的", "有吸引力的", "女性化的", "友善的", ...
    "年轻的", "健康的", "真实还原的", "与环境适配的", "白皙的", "红润的"];
end
colors=[[0.7 0 0];[0 0.5 0];[0.2 0.2 1];
    [1 0 1];[0 0 0];[0.5 0.5 0.5];
    [1 0.5 0];[1, 0.75, 0.8];[0.6, 0.2, 0.8];[0.6, 0.4, 0.2]];
% 定义人种对应的lastParts索引
nation_indices = cell(5, 1); % 5个人种（包括"all"�?
% AS (Asian): f04i, f05i, f06i, m04i, m05i, m06i (索引1-6)
nation_indices{1} = 1:6;
% CA (Caucasian): f01i, f02i, f03i, m01i, m02i, m03i (索引7-12)
nation_indices{2} = 7:12;
% SA (South Asian): f07i, f08i, m07i, m08i (索引13-16)
nation_indices{3} = 13:16;
% AF (African): f09i, f10i, m09i, m10i (索引17-20)
nation_indices{4} = 17:20;
% all: 所有索�?(索引1-20)
nation_indices{5} = 1:20;

lastParts = {'f04i', 'f05i', 'f06i', 'm04i', 'm05i', 'm06i',...
'f01i', 'f02i', 'f03i', 'm01i', 'm02i', 'm03i',...
'f07i', 'f08i','m07i', 'm08i',...
'f09i', 'f10i','m09i', 'm10i'};n_para = 21;iOr='i';

% lastParts = {'f04r', 'f05r', 'f06r', 'm04r', 'm05r', 'm06r',...
% 'f01r', 'f02r', 'f03r', 'm01r', 'm02r', 'm03r',...
% 'f07r', 'f08r','m07r', 'm08r',...
% 'f09r', 'f10r','m09r', 'm10r'};n_para = 14;iOr='r';


if strcmp(iOr,"i")
    indices_target=[5];
    % indices_target=[5,12,19];
    load('optimizedD/neutral_gray/combi_XYZw_i.mat', 'XYZ_combi', 'CCT_combi');
    CT = CCT_combi;
    XYZw_mean = XYZ_combi;
elseif strcmp(iOr,"r")
    indices_target=1:14;
    for i_nation=1:length(nations)
        model_tcp_mean_inds=[];
        for i_lastPart=nation_indices{i_nation}
            lastPart=lastParts{i_lastPart};
            load(fullfile("..","renderCode","light_r","model_light_mean", ...
                strcat(strrep(lastPart,"r",""),".mat")), ...
                "model_tcp_mean","XYZwpre_mea");
            XYZwpre_mea_inds(:,:,i_lastPart)=XYZwpre_mea;
            model_tcp_mean_inds=[model_tcp_mean_inds,model_tcp_mean];
        end
        XYZw_mean{i_nation}=nanmean(XYZwpre_mea_inds,3);
        CT_nations{i_nation}=mean(model_tcp_mean_inds,2);
    end
end
load("documents\valid_attr.mat","map");
wd65 = [94.811, 100.00, 107.304];
datai_file = 'D:\work\VIVOskinExpe\renderCode\calibResults\datai_ipv18_3.mat';
LUT=load(datai_file);
XYZw_LUT=LUT.XYZw;
line_style = {'-',':','-.'};
plot_style = {'^','<','v'};
% length_color=3;
% hue_values = linspace(0, 1, length_color + 1);hue_values = hue_values(1:end-1);
% hsv_matrix = [hue_values', 0.8 * ones(length_color, 1), 0.8 * ones(length_color, 1)];
% colors = hsv2rgb(hsv_matrix);
genders = ["f", "m"];
gender_names=["female","male"];
obs_types = ["non_model", "model_group"];
% obs_types = ["non_model", "model_group", "model"];
% 定义人种对应的lastParts索引
nation_indices = cell(5, 1); % 5个人种（包括"all"�?
% AS (Asian): f04i, f05i, f06i, m04i, m05i, m06i (索引1-6)
nation_indices{1} = 1:6;
% CA (Caucasian): f01i, f02i, f03i, m01i, m02i, m03i (索引7-12)
nation_indices{2} = 7:12;
% SA (South Asian): f07i, f08i, m07i, m08i (索引13-16)
nation_indices{3} = 13:16;
% AF (African): f09i, f10i, m09i, m10i (索引17-20)
nation_indices{4} = 17:20;
% all: 所有索�?(索引1-20)
nation_indices{5} = 1:20;
% 初始化重塑后的数据结�?
average_reshaped = cell(5, 1); % 5个人�?
par_reshaped = cell(3, 5, 1);  % 3种观察者类�?× 5个人�?
lab_fit_reshaped = cell(3, 5, 1); % 3种观察者类�?× 5个人�?
labCh_PMCC=[[62.11	18.96	19.76	27.39	46.18];...
            [64.15	19.56	19.63	27.71	45.10];...
            [56.01	18.25	18.72	26.14	45.72];...
            [41.06	17.37	17.94	24.97	45.93]];
labCh_PMCC(end+1,:)=mean(labCh_PMCC,1);
file_missing={};
Dtype = 'efit_p';
scale_type_origin="unscaled";
variable_type = "nation";  % "nation": loop all nations, attribute=[1]; "attr": i_nation=1, attribute=1:10
% 定义一个函数来分离性别索引（此函数不再在主循环中使用，但保留）
function gender_indices = separate_genders(n_subjects, curr_nation_indices, lastParts)
    gender_indices = cell(2, 1); % f和m的索�?
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
% ===================== 新增：固定图片尺寸参�?=====================
% 定义图片尺寸（厘米）
fig_width_cm = 15;    % 图片宽度（厘米）
fig_height_cm = 15;   % 图片高度（厘米）
% 转换厘米为英寸（1英寸=2.54厘米�?
fig_width_in = fig_width_cm / 2.54;
fig_height_in = fig_height_cm / 2.54;
% 定义基础字体大小（按图片尺寸比例�?
base_font_size = 12;  % 基础字号
font_scale = fig_width_cm / 15;  % 按宽度比例缩放（15cm为基准）
label_font_size = base_font_size * 2 * font_scale;  % 对应�?2*2
text_font_size = 15 * font_scale;  % 对应原attribute数字�?5号字�?
title_font_size = base_font_size * 2 * font_scale;  % 标题字号
%=======================================
for i_obs = 1:length(obs_types)
    obs_type = obs_types(i_obs);
    
    for i_nation = 1:length(nations)
        % 获取当前人种的所有索�?
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

            white_file = fullfile("optimizedD\whiteSquare\XYZw_white", ...
            strcat(lastPart, ".mat"));
            load(white_file,"XYZw_white");
            % 加载平均肤色数据
            average_file = fullfile("aveSkin", lastPart, "autoNhand_scaleoverLUT.mat");
            if exist(average_file, 'file')
                average_data = load(average_file);
                average_bf=average_data.average_lab_all(:, 1:3);
                %late CAT
                XYZ_bf=lab2xyz2(average_bf,'d65_64');
                if strcmp(iOr,"i")
                    XYZwpre=XYZw_mean;
                else strcmp(iOr,"r")
                    XYZwpre=XYZw_mean{i_nation};
                end
                for i_para=1:size(average_bf,1)
                    if strcmp(iOr,"r")
                        CT=CT_nations{i_nation};
                    end
                        
                    D_pre(i_para,1)= calculateD(CT(i_para,1), 0, "efit_p");
                    XYZt(i_para,:) = CAT16_D(XYZ_bf(i_para,:), ...
                        XYZwpre(i_para,:), wd65, D_pre(i_para,1));
                end
                average_aft = xyz2lab(XYZt, 'd65_64');

                if strcmp(scale_type,"scaled")
                    xyz_ave=[];ave_scaled=[];
                    for i_para=1:size(average_aft,1)
                        xyz_ave(i_para,:)=lab2xyz2(average_aft(i_para,:),"user",wd65./wd65(2).*XYZw_LUT(2));
                        ave_scaled(i_para,:)=xyz2lab(xyz_ave(i_para,:),"user",wd65./wd65(2).*XYZw_white(i_para,2));
                    end
                    average_current(:, :, i_subject) = ave_scaled;
                else
                    average_current(:, :, i_subject) = average_aft;
                end
                average_unscaled(:, :, i_subject) = average_aft;
            else
                average_current(:, :, i_subject) = NaN(n_para, 3);
            end
            
            % 新增：根据iOr设置XYZw_used
            if strcmp(iOr,'r')
                XYZw_used = XYZw_mean{i_nation};
            elseif strcmp(iOr,'i')
                XYZw_used = XYZw_mean;
            end
            
            % 循环处理每个 attribute
            for i_attr = 1:length(attributes)
                attribute = attributes(i_attr);
                attribute_serial = strcat(sprintf("%02d", attribute), attribute_names_new(attribute));
                attribute_serial=ch2eng(attribute_serial);
                % 定义路径
                if i_attr==7
                    obs_type_used="model_group";
                else
                    obs_type_used=obs_type;
                end
                if strcmp(Dtype,"efit_p_free")
                    source_file = fullfile('AnalyseResults_p_free', ...
                        Dtype,scale_type_origin, lastPart, obs_type_used, ...
                        attribute_serial, 'ellipPara', 'fitRes.mat');
                elseif strcmp(Dtype,"efit_p")
                    source_file = fullfile('AnalyseResults_p', ...
                        Dtype,scale_type_origin, lastPart, obs_type_used, ...
                        attribute_serial, 'ellipPara', 'fitRes.mat');
                end
                % 加载数据
                if exist(source_file, 'file')
                    par_all_data = load(source_file);
                    par_all = par_all_data.par_all;
                    padding = NaN(size(par_current,1) - size(par_all,1), size(par_all, 2));
                    par_all = [par_all; padding];
                    par_current(:, :, i_subject, i_attr) = par_all;
                    lab_bf=[average_unscaled(:, 1, i_subject), par_all(:,4:5)];
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
        
        % average_reshaped只需要存储一次（不依赖于观察者类型）
        if i_obs == 1
            average_reshaped{i_nation} = average_current;
        end
        
        average_mean{i_nation}=nanmean(average_reshaped{i_nation} ,3);
        par_mean{i_obs,i_nation}=nanmean(par_reshaped{i_obs,i_nation},3);
    end
    % disp("d")
end
%% 保存
if strcmp(Dtype,"efit_p_free")
    save_folder_name=fullfile("ellip_pic_p_free",scale_type,text_type);
elseif strcmp(Dtype,"efit_p")
    save_folder_name=fullfile("ellip_pic_p",scale_type,text_type);
end
output_folder=fullfile(save_folder_name, Dtype,"attr");
if ~exist(output_folder,"dir")
    mkdir(output_folder);
end
save(fullfile(output_folder,strcat("data_reshaped_",iOr,".mat")),"par_mean","average_mean", ...
    "lab_fit_reshaped","file_missing","par_reshaped","average_reshaped");
%% 计算每个nation的坐标轴范围
% 初始化每个nation的极值变�?
nation_limits = struct();
    % 根据variable_type设置循环
    if strcmp(variable_type, "nation")
        nation_loop = 1:length(nations);
        attr_loop = [1];
    elseif strcmp(variable_type, "attr")
        nation_loop = 1;
        attr_loop = 1:length(attributes);
    end

    for i_nation = nation_loop
    nation_limits(i_nation).lim_min_x = inf;
    nation_limits(i_nation).lim_min_y = inf;
    nation_limits(i_nation).lim_max_x = -inf;
    nation_limits(i_nation).lim_max_y = -inf;
end
% 为每个nation分别计算坐标轴范�?
    % 根据variable_type设置循环
    if strcmp(variable_type, "nation")
        nation_loop = 1:length(nations);
        attr_loop = [1];
    elseif strcmp(variable_type, "attr")
        nation_loop = 1;
        attr_loop = 1:length(attributes);
    end

    for i_nation = nation_loop
    for i_obs = 1:length(obs_types)
        obs_type = obs_types(i_obs);
        % 获取当前人种的所�?subject
        n_subjects = size(lab_fit_reshaped{i_obs, i_nation}, 3);
        if n_subjects == 0
            continue;
        end
        
        % 处理所�?subject 的数据，不再区分性别
        for attribute = attributes
            lab = lab_fit_reshaped{i_obs,i_nation}(indices_target, :, :, attribute);
            if ~all(isnan(lab(:)))
                lab_mean = nanmean(nanmean(lab, 3),1);
                nation_limits(i_nation).lim_min_x = min(nation_limits(i_nation).lim_min_x, lab_mean(2));
                nation_limits(i_nation).lim_max_x = max(nation_limits(i_nation).lim_max_x, lab_mean(2));
                nation_limits(i_nation).lim_min_y = min(nation_limits(i_nation).lim_min_y, lab_mean(3));
                nation_limits(i_nation).lim_max_y = max(nation_limits(i_nation).lim_max_y, lab_mean(3));
            end
        end
    end
    
    % 为当前nation添加边距
    nation_limits(i_nation).lim_min_x = nation_limits(i_nation).lim_min_x - 1;
    nation_limits(i_nation).lim_max_x = nation_limits(i_nation).lim_max_x + 1;
    nation_limits(i_nation).lim_min_y = nation_limits(i_nation).lim_min_y - 1;
    nation_limits(i_nation).lim_max_y = nation_limits(i_nation).lim_max_y + 1;
    
    % 确保x和y轴范围相同，以保持等比例显示
    range_x = nation_limits(i_nation).lim_max_x - nation_limits(i_nation).lim_min_x;
    range_y = nation_limits(i_nation).lim_max_y - nation_limits(i_nation).lim_min_y;
    max_range = max(range_x, range_y);
    
    % 调整范围使x和y轴的刻度间隔相同
    center_x = (nation_limits(i_nation).lim_min_x + nation_limits(i_nation).lim_max_x) / 2;
    center_y = (nation_limits(i_nation).lim_min_y + nation_limits(i_nation).lim_max_y) / 2;
    
    nation_limits(i_nation).lim_min_x = center_x - max_range / 2;
    nation_limits(i_nation).lim_max_x = center_x + max_range / 2;
    nation_limits(i_nation).lim_min_y = center_y - max_range / 2;
    nation_limits(i_nation).lim_max_y = center_y + max_range / 2;
end
%% 绘图循环
res_matrix=[];curr=1;
nan_record={};
% obs_types=["non_model"];
    % 根据variable_type设置循环
    if strcmp(variable_type, "nation")
        nation_loop = 1:length(nations);
        attr_loop = [1];
    elseif strcmp(variable_type, "attr")
        nation_loop = 1;
        attr_loop = 1:length(attributes);
    end

    for i_nation = nation_loop
    nation=nations(i_nation);
    nation_serial=strcat(sprintf("%02d",i_nation),nation);
    
    % 获取当前人种的所有索�?
    curr_nation_indices = nation_indices{i_nation};
    
    if isempty(curr_nation_indices)
        continue; % 无该人种数据，跳�?
    end
    
    h1=figure(1);
    set(h1, ...
    'Units', 'inches', ...          % 单位设为英寸
    'Position', [1, 1, fig_width_in, fig_height_in], ...  % [�? �? �? 高]
    'Color', 'white', ...
    'PaperUnits', 'inches', ...     % 打印单位
    'PaperSize', [fig_width_in, fig_height_in], ...       % 打印尺寸
    'PaperPosition', [0, 0, fig_width_in, fig_height_in]);% 打印位置

    hold on;
    set(gcf, 'Color', 'white');
    
    % 添加PMCC�?
    % lab_PMCC = labCh_PMCC(i_nation,1:3);
    % plot(lab_PMCC(2), lab_PMCC(3), 's', 'MarkerSize', 8, ...
    %     'MarkerFaceColor', 'm', 'MarkerEdgeColor', 'm');
    
    % 使用第一�?attribute 的数据来计算 XYZ 均�?
    lab_pre = lab_fit_reshaped{1,i_nation}(indices_target, :, :, 1);
    lab_pre = nanmean(nanmean(lab_pre, 3), 1);
    xyz_mean=lab2xyz2(lab_pre,"d65_64");
    xyz_PMCC=lab2xyz2(labCh_PMCC(i_nation,1:3),"d65_64");
    xyz_PMCC=xyz_PMCC./xyz_PMCC(2).*xyz_mean(2);
    % labCh_PMCC_pre = xyz2lab(xyz_PMCC,"d65_64");
    % plot(labCh_PMCC_pre(2), labCh_PMCC_pre(3), 's', 'MarkerSize', 8, ...
    %     'MarkerFaceColor', 'none', 'MarkerEdgeColor', 'm');
    
    % 遍历不同的obs_type，将数据点画到同一张图�?
    for i_obs=1:length(obs_types)
        obs_type=obs_types(i_obs);
        
        % for attribute = attributes
        for attribute = attributes
            if strcmp(del_fair_ruddy, "true") && any(attribute == [9, 10])
                continue;
            end
            attribute_serial = strcat(sprintf("%02d", attribute), attribute_names_new(attribute));
            attribute_serial=ch2eng(attribute_serial);
            lab = lab_fit_reshaped{i_obs,i_nation}(indices_target, :, :, attribute);
            
            if all(isnan(lab(:)))
                continue;
            end
            
            lab_mean = nanmean(nanmean(lab, 3), 1);
            
            % 根据 obs_type 选择不同�?plot_style
            % if strcmp(obs_type, "non_model")
                plot_style_current = 'o'; % 'non_model'使用圆圈
            % elseif strcmp(obs_type, "model_group")
            %     plot_style_current = '^'; % 'model_group'使用上三�?
            % end
            
            % scatter(lab_mean(2), lab_mean(3), 30, plot_style_current,'filled', ...
            %     'MarkerFaceColor', colors(i_obs, :), 'MarkerEdgeColor', colors(i_obs,:));
            
            if strcmp(obs_type,'non_model')&&(attribute~=7||strcmp(text_type,'ch'))
                if attribute==7
                plot(lab_mean(2),lab_mean(3),'.','MarkerSize',15, ...
                    'MarkerFaceColor',"none", ...
                    'MarkerEdgeColor',colors(attribute,:),'LineWidth',1.5);
                else
                plot(lab_mean(2),lab_mean(3),'o','MarkerSize',5, ...
                    'MarkerFaceColor',"none", ...
                    'MarkerEdgeColor',colors(attribute,:),'LineWidth',1.5);
                end
            end
        end
        % 画箭头：从 non_model 指向 model_group
        for attribute = attributes
            if strcmp(del_fair_ruddy, "true") && any(attribute == [9, 10])
                continue;
            end
            lab_nm = lab_fit_reshaped{1, i_nation}(indices_target, :, :, attribute);
            lab_mg = lab_fit_reshaped{2, i_nation}(indices_target, :, :, attribute);
            if all(isnan(lab_nm(:))) || all(isnan(lab_mg(:)))
                continue;
            end
            lab_mean_nm = nanmean(nanmean(lab_nm, 3), 1);
            lab_mean_mg = nanmean(nanmean(lab_mg, 3), 1);
            dx = lab_mean_mg(2) - lab_mean_nm(2);
            dy = lab_mean_mg(3) - lab_mean_nm(3);
            if sqrt(dx^2 + dy^2) < 0.01, continue; end
            % quiver(lab_mean_nm(2), lab_mean_nm(3), dx, dy, 0, ...
            %     'MaxHeadSize', 0.5, 'AutoScale', 'off', ...
            %     'Color', colors(attribute, :), 'LineWidth', 1.2);
            % 提取起点和终点坐标
            x_start = lab_mean_nm(2);
            y_start = lab_mean_nm(3);
            x_end = x_start + dx;
            y_end = y_start + dy;
            
            % 绘制线段
            line([x_start, x_end], [y_start, y_end], ...
                 'Color', colors(attribute, :), ...
                 'LineWidth', 1.2);
            plot(x_end,y_end,'.','MarkerSize',15, ...
            'MarkerFaceColor',"none", ...
            'MarkerEdgeColor',colors(attribute,:),'LineWidth',1.5);
        end

    end
    ave=mean(average_mean{i_nation}(indices_target,:),1,"omitnan");
    if strcmp(text_type,"ch")
    scatter(ave(2), ave(3), 50, 'p','filled', ...
    'MarkerFaceColor', colors(i_obs+1, :), 'MarkerEdgeColor', 'k');
    end
    % 添加图例、标签和标题
    xlabel('a^{*}','Interpreter',interpreter_type,'FontName','Arial','FontAngle','italic', ...
        'FontSize',label_font_size);
    ylabel('b^{*}','Interpreter',interpreter_type,'FontName','Arial','FontAngle','italic', ...
        'FontSize',label_font_size);
    title(nation_names(i_nation),'FontSize', title_font_size);


    res_matrix=[res_matrix;lab_mean];
    res_cell{curr,1}=lab_mean;
    res_cell{curr,2}=strcat(iOr,nation_serial,attribute_serial);
    curr=curr+1;
    axis equal;
    if i_nation==4
        min_lim=6;max_lim=12;
    else
        min_lim=9;max_lim=20;
    end
    xlim([min_lim, max_lim]);
    ylim([min_lim, max_lim]);
    x = linspace(0, 25, 100);
    plot(x, x, 'k--');
    
    save_folder = fullfile(save_folder_name, Dtype,"attr", "comparison", ...
        iOr,text_type);
    if ~exist(save_folder, "dir")
        mkdir(save_folder);
    end
    if i_nation==5
        save_folder = fullfile(save_folder,nation);
        if ~exist(save_folder, "dir")
            mkdir(save_folder);
        end
    end
    ax = gca;
    targetFontSize=12;
    set(ax, 'FontSize', targetFontSize);
    xlabel('a^{*}', 'Interpreter',interpreter_type,'FontName','Arial','FontAngle','italic', 'FontSize', targetFontSize);
    ylabel('b^{*}', 'Interpreter',interpreter_type,'FontName','Arial','FontAngle','italic', 'FontSize', targetFontSize);
    yPos = ax.YLabel.Position;
    yPos(1) = yPos(1) - 5; % 数字越大，离得越�?
    ax.YLabel.Position = yPos;
    xPos = ax.XLabel.Position;
    xPos(2) = xPos(2) - 5; % 数字越大，离得越�?
    ax.XLabel.Position = xPos;
    set(findobj(gcf, 'Type', 'Text'), 'FontSize', targetFontSize); % 针对 LaTeX 标签
    
    % 保存�?.fig
    img_name=fullfile(save_folder, ...
        strcat(nation_serial, '_scatter_attr_comp_noarrow.jpg'));

    savefig(gcf, strrep(img_name,'jpg','fig'));

    exportgraphics(h1,img_name , ...
        'Resolution', 1500, ...
        'ContentType', 'image', ...
        'BackgroundColor', 'white');
    
    close(h1);
    

    save_folder1 = fullfile(save_folder_name, Dtype,"attr", "comparison", iOr, "C_h");
    if ~exist(save_folder1, "dir")
        mkdir(save_folder1);
    end
    if i_nation==5
        save_folder1 = fullfile(save_folder1,nation);
        if ~exist(save_folder1, "dir")
            mkdir(save_folder1);
        end
    end

end

%%
fullfile(pwd,save_folder)
% 图像拼接
opts.lim_min=0; 
opts.lim_max=40;  
opts.targetFontSize=12;
opts.margin=0.12;    
opts.label_type="obs";
opts.if_rotate=false;
opts.axis_limits=[9,19,9,19;9,19,9,19;9,19,9,19;7,11,7,11];
opts.axis_ticks=[2,2,2,1];
% opts.bar_interval=0.4;
adjust_fig(save_folder, opts);
%-----------------
%%
one_image_mode = "false";  % "true"时只取第一个fig文件，且隐藏subplot标签
del_fair_ruddy = "true";   % "true"时不绘制attribute==9:10的数据
s.labels_row1=attribute_names_new;
if strcmp(del_fair_ruddy, "true")
    s.labels_row1 = attribute_names_new(1:8);
end
if strcmp(text_type,"eng")
s.labels_row1(7)=[];
end
s.labels_row2 = {};
s.markers_row2 = {};
s.markers_colors = [];
s.markers_face_colors = [];
if strcmp(one_image_mode, "true")
    s.n_col1=3; 
else
    s.n_col1=5; 
end
s.n_col2=5;
s.if_label=true;
s.leg_x_shift=-0.08;


s.colors_row1 = colors;
if strcmp(del_fair_ruddy, "true")
    s.colors_row1 = colors(1:8,:);
end
if strcmp(text_type,"eng")
s.colors_row1(7,:)=[];
end
s.label_type="obs";
dir_figs=dir(fullfile(save_folder,"*adjusted.fig"));
clear("figFiles")
i_fig1=1;
for i_fig=1:length(dir_figs)
    if strcmp(one_image_mode, "true") && i_fig1 > 1
        break;  % one_image_mode只取第一个
    end
    figFiles{i_fig1}=dir_figs(i_fig).name;
    i_fig1=i_fig1+1;
end

s.fontSizeScale=1.2;
s.tickFontScale = 0.9;          
if strcmp(one_image_mode, "true")
    s.if_label = false;
    s.colGap1_scale = 1.5; 
    s.iconTextGap=0.04;
    s.leg_x_shift=-0.2;
    s.marginL=0.2;
    concatenate_figs_legend1(save_folder, figFiles, 1,"none","draw",s,0.09,1.2);
else
    s.colGap1_scale = 1.5; 
    s.iconTextGap=0.02;
    s.leg_x_shift=-0.2;
    s.marginL=0.2;
    concatenate_figs_legend1(save_folder, figFiles, 2,"none","draw",s,0.07,0.35);
end


% concatenate_images1(save_folder,2);
% concatenate_images1(fullfile(save_folder_name, Dtype,"attr", "comparison", iOr, "C_h"),2);
fullfile(pwd,save_folder)
%% 新增功能：计算deltaE2000矩阵和向量并保存到XLSX
output_excel_folder = fullfile(save_folder_name, Dtype, "attr", "deltaE2000", iOr);
if ~exist(output_excel_folder, "dir")
    mkdir(output_excel_folder);
end

    % 根据variable_type设置循环
    if strcmp(variable_type, "nation")
        nation_loop = 1:length(nations);
        attr_loop = [1];
    elseif strcmp(variable_type, "attr")
        nation_loop = 1;
        attr_loop = 1:length(attributes);
    end

    for i_nation = nation_loop
    nation = nations(i_nation);
    
    % 遍历不同观察者类�?
    for i_obs = 1:length(obs_types)
        obs_type = obs_types(i_obs);
        
        % 获取当前观察者和人种的数�?
        lab_data = lab_fit_reshaped{i_obs, i_nation}(indices_target, :, :, :);
        
        % 检查数据是否为�?
        if all(isnan(lab_data(:)))
            continue;
        end
        
        % 计算每个 attribute 的平�?LAB
        attr_lab_means = zeros(length(attributes), 3);
        for i_attr = 1:length(attributes)
            lab_mean = nanmean(nanmean(lab_data(:, :, :, i_attr), 3), 1);
            if ~all(isnan(lab_mean))
                attr_lab_means(i_attr, :) = lab_mean;
            else
                attr_lab_means(i_attr, :) = NaN;
            end
        end
        
        % 1. 计算不同 attribute 两两之间�?deltaE2000 矩阵
        num_attrs = length(attributes);
        deltaE_matrix = zeros(num_attrs, num_attrs);
        attr_h=atan2d(attr_lab_means(:,3),attr_lab_means(:,2));
        mean_h(i_obs,i_nation)=nanmean(attr_h);
        for i = 1:num_attrs
            for j = i:num_attrs
                lab1 = attr_lab_means(i, :);
                lab2 = attr_lab_means(j, :);
                if ~any(isnan(lab1)) && ~any(isnan(lab2)) && i~=j
                    dE = deltaE2000(lab1, lab2);
                    deltaE_matrix(i, j) = dE;
                    deltaE_matrix(j, i) = dE; % 矩阵对称
                else
                    deltaE_matrix(i, j) = NaN;
                    deltaE_matrix(j, i) = NaN;
                end
            end
        end
        deltaE_matrix_all{i_nation,i_obs}=deltaE_matrix;
        deltaE_matrix_mean{i_nation,i_obs}=nanmean(nanmean(deltaE_matrix));
        
        % 2. 计算每个 attribute �?ave �?deltaE2000 向量
        ave_lab_mean = nanmean(average_mean{i_nation}(indices_target, :), 1);
        deltaE_ave_vector = zeros(num_attrs, 1);
        for i = 1:num_attrs
            lab_attr = attr_lab_means(i, :);
            if ~any(isnan(lab_attr)) && ~any(isnan(ave_lab_mean))
                deltaE_ave_vector(i) = deltaE2000(lab_attr, ave_lab_mean);
            else
                deltaE_ave_vector(i) = NaN;
            end
        end
        deltaE_ave_vector_all{i_nation,i_obs}=deltaE_ave_vector;
        deltaE_ave_vector_mean{i_nation,i_obs}=nanmean(deltaE_ave_vector);
        

    end
end
deltaE_matrix_mean=deltaE_matrix_mean';
deltaE_ave_vector_mean=deltaE_ave_vector_mean';



fullfile(pwd,save_folder)
 
