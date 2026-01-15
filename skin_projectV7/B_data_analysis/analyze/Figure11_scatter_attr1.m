close all; % 关闭所有图窗
clc;       % 清空命令窗口
clear;     % 清除工作区所有变量
scale_type = "scaled"; % 新增：unscaled或scaled
scale_type_origin="unscaled";
% scale_time="early";
scale_time="late";
%% 定义所有需要处理的 attribute
attributes = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
attribute_names_new = ["Preference", "Attractiveness", "Feminine", "Cooperative", ...
    "Youth", "Healthy", "Fidelity", "Harmony", "Fair", "Ruddy"];
nations = ["AS", "CA", "SA", "AF", "all"];
nation_names=["Asian","Caucasian","South Asian","African","all"];
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
lastParts = {'f04i', 'f05i', 'f06i', 'm04i', 'm05i', 'm06i',...
'f01i', 'f02i', 'f03i', 'm01i', 'm02i', 'm03i',...
'f07i', 'f08i','m07i', 'm08i',...
'f09i', 'f10i','m09i', 'm10i'};n_para = 21;iOr='i';
% lastParts = {'f04r', 'f05r', 'f06r', 'm04r', 'm05r', 'm06r',...
% 'f01r', 'f02r', 'f03r', 'm01r', 'm02r', 'm03r',...
% 'f07r', 'f08r','m07r', 'm08r',...
% 'f09r', 'f10r','m09r', 'm10r'};n_para = 14;iOr='r';
if strcmp(iOr,"i")
    indices_target=5;
    % indices_target=[5,12,19];
    load('optimizedD/neutral_gray/combi_XYZw_i.mat', 'XYZ_combi', 'CCT_combi');
    CT = CCT_combi;
    XYZw_mean = XYZ_combi;
elseif strcmp(iOr,"r")
    indices_target=5;
    % indices_target=1:14;
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
datai_file = '..\..\A_characterization\display_model\datai_ipv18_3.mat';
LUT=load(datai_file);
XYZw_LUT=LUT.XYZw;
line_style = {'-',':','-.'};
plot_style = {'^','<','v'};
% colors = hsv(length(attributes));
n_scenetype=length(attributes);
hue_values = linspace(0, 1, n_scenetype + 1);hue_values = hue_values(1:end-1);
hsv_matrix = [hue_values', 0.8*ones(n_scenetype, 1),  0.8*ones(n_scenetype, 1)];
colors = hsv2rgb(hsv_matrix);

genders = ["f", "m"];
gender_names=["female","male"];

obs_types = ["non_model", "model_group"];
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
% 定义一个函数来分离性别索引

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
            for i_para=1:size(average_current(:, :, i_subject),1)    
                xyz_ave=lab2xyz2(average_current(i_para, :, i_subject),"user",wd65./wd65(2).*XYZw_LUT(2));
                ave_current_scaled(i_para, :, i_subject)=xyz2lab(xyz_ave,"user",wd65./wd65(2).*XYZw_white(i_para,2));
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
                
                % 定义路径
                if i_attr==7
                    obs_type_used="model_group";
                else
                    obs_type_used=obs_type;
                end
                if strcmp(scale_time,"early")
                    source_file = fullfile('AnalyseResults_p', Dtype,scale_type_origin,"scaled" ,lastPart, ...
                        obs_type_used, attribute_serial, 'ellipPara', 'fitRes.mat');
                else
                    source_file = fullfile('AnalyseResults_p', Dtype, scale_type_origin,lastPart, ...
                        obs_type_used, attribute_serial, 'ellipPara', 'fitRes.mat');
                end
                
                % 加载数据
                if exist(source_file, 'file')
                    par_all_data = load(source_file);
                    par_all = par_all_data.par_all;
                    padding = NaN(size(par_current,1) - size(par_all,1), size(par_all, 2));
                    par_all = [par_all; padding];
                    par_current(:, :, i_subject, i_attr) = par_all;
                    lab_bf=[average_current(:, 1, i_subject), par_all(:,4:5)];
                    xyz_fit=[];lab_scaled=[];
                    if strcmp(scale_type,"scaled")&&strcmp(scale_time,"late")
                        for i_para=1:size(par_all,1)                                
                            xyz_fit(i_para,:)=lab2xyz2(lab_bf(i_para,:),"user",wd65./wd65(2).*XYZw_LUT(2));
                            lab_scaled(i_para,:)=xyz2lab(xyz_fit(i_para,:),"user",wd65./wd65(2).*XYZw_white(i_para,2));
                        end
                        lab_fit_current(:, :, i_subject, i_attr) = lab_scaled;
                    elseif strcmp(scale_type,"unscaled")||strcmp(scale_time,"early")
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
        par_mean{i_obs,i_nation}=nanmean(par_reshaped{i_obs,i_nation},3);
    end
    % disp("d")
end
%% 保存
if strcmp(scale_time,"early")
    output_folder=fullfile("ellip_pic_p", Dtype,scale_type,"attr","early_scale");
    if ~exist(output_folder,"dir")
        mkdir(output_folder);
    end
else
    output_folder=fullfile("ellip_pic_p", Dtype,scale_type,"attr");
    if ~exist(output_folder,"dir")
        mkdir(output_folder);
    end
end
save(fullfile(output_folder,strcat("data_reshaped_",iOr,".mat")),"par_mean","average_mean", ...
    "lab_fit_reshaped","file_missing","par_reshaped","average_reshaped");
%% 计算每个nation的坐标轴范围
% 初始化每个nation的极值变量
nation_limits = struct();
% 为每个nation分别计算坐标轴范围
for i_nation = 1:length(nations)
    if i_nation==4
        nation_limits(i_nation).lim_min_x = 7;
        nation_limits(i_nation).lim_max_x = 15;
        nation_limits(i_nation).lim_min_y = 7;
        nation_limits(i_nation).lim_max_y = 15;
    else
        nation_limits(i_nation).lim_min_x = 9;
        nation_limits(i_nation).lim_max_x = 25;
        nation_limits(i_nation).lim_min_y = 9;
        nation_limits(i_nation).lim_max_y = 25;
    end
end
%%
nation_limits1 = struct();
% 为每个nation分别计算坐标轴范围
for i_nation = 1:length(nations)
    % if i_nation==4
    %     nation_limits1(i_nation).lim_min_x = 0;
    %     nation_limits1(i_nation).lim_max_x = 27;
    %     nation_limits1(i_nation).lim_min_y = 0;
    %     nation_limits1(i_nation).lim_max_y = 70;
    % else
        nation_limits1(i_nation).lim_min_x = 15;
        nation_limits1(i_nation).lim_max_x = 25;
        nation_limits1(i_nation).lim_min_y = 30;
        nation_limits1(i_nation).lim_max_y = 70;
    % end
end
%% 绘图循环
nan_record={};
for i_obs=1:length(obs_types)
    obs_type=obs_types(i_obs);
    for i_nation = 1:length(nations)
        nation=nations(i_nation);
        nation_serial=strcat(sprintf("%02d",i_nation),nation);
        
        % 获取当前人种的subject数量
        n_subjects = size(lab_fit_reshaped{i_obs, i_nation}, 3);
        if n_subjects == 0
            continue;
        end
        
        h1=figure(1);
        hold on;
        set(gcf, 'Color', 'white');
        for attribute = attributes
            attribute_serial = strcat(sprintf("%02d", attribute), attribute_names_new(attribute));
            
            % 直接从lab_fit_reshaped计算平均值
            lab = lab_fit_reshaped{i_obs,i_nation}(indices_target, :, :, attribute);
            lab = nanmean(lab, 3); 
            lab = nanmean(lab, 1); % 按光源/环境维度求平均
            
            % scatter(lab(2), lab(3), 30, 'o','filled', ...
            %     'MarkerFaceColor', colors(attribute, :));

            attribute_char=char(attribute_serial);
            converted_str = num2str(str2double(attribute_char(1:2)));
            text(lab(2), lab(3), ...
                converted_str, 'FontSize', 15, ...
                'VerticalAlignment', 'middle','Color',colors(attribute,:), ...
                'FontWeight', 'bold');
            attri_matrix(i_nation,attribute,:)=lab;
        end
        
        % 添加PMCC点
        lab = lab_fit_reshaped{i_obs,i_nation}(indices_target, :, :, 1);
        lab = nanmean(lab, 3); % 按受试者维度求平均
        lab = nanmean(lab, 1); % 按光源/环境维度求平均
        xyz_mean=lab2xyz2(lab,"d65_64");
        xyz_PMCC=lab2xyz2(labCh_PMCC(i_nation,1:3),"d65_64");
        %这是之前根据肤色像素亮度调节，好像不太对 
        % xyz_PMCC=xyz_PMCC./xyz_PMCC(2).*xyz_mean(2);
        labCh_PMCC_pre(i_nation,1:3)=xyz2lab(xyz_PMCC,"user",wd65./XYZw_white(indices_target,2).*XYZw_LUT(2));
        % plot(labCh_PMCC(i_nation, 2), labCh_PMCC(i_nation, 3), 's', 'MarkerSize', 8, ...
        %     'MarkerFaceColor', 'm', 'MarkerEdgeColor', 'm');
        % plot(labCh_PMCC_pre(i_nation, 2), labCh_PMCC_pre(i_nation, 3), 's', 'MarkerSize', 8, ...
        %     'MarkerFaceColor', 'none', 'MarkerEdgeColor', 'm');
        
        % 添加图例、标签和标题
        xlabel('\textit{a*}', 'Interpreter', 'latex', 'FontSize', 12*2);
        ylabel('\textit{b*}', 'Interpreter', 'latex', 'FontSize', 12*2);
        title([nation_names(i_nation)],'FontSize', 12*2);
        
        % 设置坐标轴范围和刻度
        axis equal;
        xlim([nation_limits(i_nation).lim_min_x, nation_limits(i_nation).lim_max_x]);
        ylim([nation_limits(i_nation).lim_min_y, nation_limits(i_nation).lim_max_y]);
            
        
        % 设置刻度间隔为1
        set(gca, 'XTick', ceil(nation_limits(i_nation).lim_min_x):3:floor(nation_limits(i_nation).lim_max_x));
        set(gca, 'YTick', ceil(nation_limits(i_nation).lim_min_y):3:floor(nation_limits(i_nation).lim_max_y));
        
        x = linspace(nation_limits(i_nation).lim_min_x, nation_limits(i_nation).lim_max_x, 100);
        plot(x, x,'Color', 'k', 'LineStyle', '--'); % 绘制y=x的直线
        
        % 保存图片
        if strcmp(scale_time,"early")
            save_folder = fullfile("ellip_pic_p", Dtype,scale_type,"attr1","early_scale", obs_type,iOr);
        else
            save_folder = fullfile("ellip_pic_p", Dtype,scale_type,"attr1", obs_type,iOr);
        end

        if ~exist(save_folder, "dir")
            mkdir(save_folder);
        end

        if i_nation==5
            save_folder_used=fullfile(save_folder,"all");
        else
            save_folder_used=save_folder;
        end
        if ~exist(save_folder_used, "dir")
            mkdir(save_folder_used);
        end
        exportgraphics(h1, fullfile(save_folder_used, ...
            strcat(nation_serial, '_scatter_attr.jpg')), ...
            'Resolution', 300);
        close(h1);
        h2=figure(2);
        hold on;
        set(gcf, 'Color', 'white');
        for attribute = attributes
            attribute_serial = strcat(sprintf("%02d", attribute), attribute_names_new(attribute));
            
            % 直接从lab_fit_reshaped计算平均值
            lab = lab_fit_reshaped{i_obs,i_nation}(indices_target, :, :, attribute);
            lab = nanmean(lab, 3); % 按受试者维度求平均
            lab = nanmean(lab, 1); % 按光源/环境维度求平均
            C=sqrt(lab(2).^2+lab(3).^2);
            h=atan2d(lab(3),lab(2));
            L=lab(1);
            attribute_char=char(attribute_serial);
            converted_str = num2str(str2double(attribute_char(1:2)));
            text(C, L, ...
                converted_str, 'FontSize', 15, ...
                'VerticalAlignment', 'middle','Color',colors(attribute,:), ...
                'FontWeight', 'bold');
        end
        % 添加PMCC点
        lab = lab_fit_reshaped{i_obs,i_nation}(indices_target, :, :, 1);
        lab = nanmean(lab, 3); % 按受试者维度求平均
        lab = nanmean(lab, 1); % 按光源/环境维度求平均
        xyz_mean=lab2xyz2(lab,"d65_64");
        xyz_PMCC=lab2xyz2(labCh_PMCC(i_nation,1:3),"d65_64");
        xyz_PMCC=xyz_PMCC./xyz_PMCC(2).*xyz_mean(2);
        % xyz_fit(i_para,:)=lab2xyz2(lab_bf(i_para,:),"user",wd65./wd65(2).*XYZw_LUT(2));
        % lab_scaled(i_para,:)=xyz2lab(xyz_fit(i_para,:),"user",wd65./wd65(2).*XYZw_white(i_para,2));
        labCh_PMCC_pre(i_nation,1:3)=xyz2lab(xyz_PMCC,"d65_64");
        labCh_PMCC_pre(i_nation,4)=sqrt(labCh_PMCC_pre(i_nation,2).^2+labCh_PMCC_pre(i_nation,3).^2);
        labCh_PMCC_pre(i_nation,5)=atan2d(labCh_PMCC_pre(i_nation,3),labCh_PMCC_pre(i_nation,2));
        if strcmp(scale_type,"scaled")
            plot(labCh_PMCC(i_nation, 4), labCh_PMCC(i_nation, 1), 's', 'MarkerSize', 8, ...
                'MarkerFaceColor', 'm', 'MarkerEdgeColor', 'm');
        else
            plot(labCh_PMCC_pre(i_nation, 4), labCh_PMCC_pre(i_nation, 1), 's', 'MarkerSize', 8, ...
                'MarkerFaceColor', 'none', 'MarkerEdgeColor', 'm');
        end
        
        % 添加图例、标签和标题
        xlabel('\textit{C*}_{ab}', 'Interpreter', 'latex', 'FontSize', 12*2);
        ylabel('\textit{L*}', 'Interpreter', 'latex', 'FontSize', 12*2);
        title([nation_names(i_nation)],'FontSize', 12*2);
        
        % 设置坐标轴范围 - 使用当前nation的范围
        axis equal;
        xlim([nation_limits1(i_nation).lim_min_x, nation_limits1(i_nation).lim_max_x]);
        ylim([nation_limits1(i_nation).lim_min_y, nation_limits1(i_nation).lim_max_y]);
        
        % 保存图片
        save_folder1 = fullfile("ellip_pic_p", Dtype,"attr1", obs_type,iOr,"C_h");
        if ~exist(save_folder1, "dir")
            mkdir(save_folder1);
        end
        exportgraphics(h2, fullfile(save_folder1, ...
            strcat(nation_serial, '_scatter_attr.jpg')), ...
            'Resolution', 300);
        close(h2);
    end
    % save(fullfile(save_folder,"nation_attri_lab.mat"),"attri_matrix");
    % concatenate_images1(save_folder,4);
    save_folder = fullfile("ellip_pic_p", Dtype,scale_type,"attr1", obs_type,iOr);
    concatenate_images1(save_folder,4);
    % save_folder1 = fullfile("ellip_pic_p", Dtype,scale_type,"attr1", obs_type,iOr,"C_h");
    % concatenate_images1(save_folder1,4);
end