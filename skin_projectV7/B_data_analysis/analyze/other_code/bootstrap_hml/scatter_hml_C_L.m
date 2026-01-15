close all; % 关闭所有图窗
clc;       % 清空命令窗口
clear;     % 清除工作区所有变量
%% 定义所有需要处理的 attribute
attributes = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

attribute_names = ["Preference", "Attractiveness", "Feminine", "Cooperative", ...
    "Youth", "Healthy", "Fidelity", "Harmony", "Fair", "Ruddy"];
nations = ["AS", "CA", "SA", "AF"];
nation_names = ["Asian", "Caucasian", "South Asian", "African"];

% lastParts = {'f04i', 'f05i', 'f06i', 'm04i', 'm05i', 'm06i',...
% 'f01i', 'f02i', 'f03i', 'm01i', 'm02i', 'm03i',...
% 'f07i', 'f08i','m07i', 'm08i',...
% 'f09i', 'f10i','m09i', 'm10i'};n_para = 21;iOr='i';

lastParts = {'f04r', 'f05r', 'f06r', 'm04r', 'm05r', 'm06r',...
'f01r', 'f02r', 'f03r', 'm01r', 'm02r', 'm03r',...
'f07r', 'f08r','m07r', 'm08r',...
'f09r', 'f10r','m09r', 'm10r'};n_para = 14;iOr='r';

if iOr =='i'
    picnames_groups = ["h3k","h4k","h5k","h6k","hd65","h7k","h8k",...
                    "m3k","m4k","m5k","m6k","md65","m7k","m8k",...
                     "l3k","l4k","l5k","l6k","ld65","l7k","l8k"];
elseif iOr=='r'
    picnames_groups = ["rs01","rs02","rs03","rs04","rs05","rs06","rs07", ...
             "rs08","rs09","rs10","rs11","rs12","rs13","rs14"];
end
lightness_type="abs";

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

%% 绘图部分 - 按lab_valid第一维度映射颜色
nan_record={};

% 创建从冷色(蓝色)到暖色(红色)的颜色映射
cmap = colormap('copper');
XYZw_gray_nations=[];
for i_nation = 1:length(nations)
    XYZw_gray_nations=[XYZw_gray_nations;XYZw_gray_mean{i_nation,1}];
end
valid_gray = ~all(isnan(XYZw_gray_nations), 2);
data_valid = XYZw_gray_nations(valid_gray,:);
data_min = min(data_valid(:,1));
data_max = max(data_valid(:,1));

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
            % data_for_color = lab(:, 1); % 使用lab的第一个维度数据
            data_for_color = XYZw_gray_mean{i_nation,1};
            
            % 找到有效数据的索引
            valid_idx = ~all(isnan(lab), 2);
            lab_valid = lab(valid_idx, :);
            data_valid = data_for_color(valid_idx);
            labCh_valid=lab_valid;
            labCh_valid(:,4)=sqrt(labCh_valid(:,2).^2+labCh_valid(:,3).^2);
            labCh_valid(:,5)=atan2d(labCh_valid(:,3),labCh_valid(:,2));
            
            if ~isempty(lab_valid)
                % 归一化数据用于颜色映射
                % data_min = min(data_valid(:,1));
                % data_max = max(data_valid(:,1));
                data_norm = (data_valid(:,1) - data_min) / (data_max - data_min);
                
                % 为每个点设置颜色
                for i_point = 1:size(lab_valid, 1)
                    % 根据归一化数据值获取颜色
                    % if iOr=='r'
                        color_idx = round(data_norm(i_point) * (size(cmap, 1) - 1)) + 1;
                        point_color = cmap(color_idx, :);
                    % else
                    %     if i_point<=7
                    %         point_color=colors(1,:);
                    %     elseif i_point<=14
                    %         point_color=colors(2,:);
                    %     else
                    %         point_color=colors(3,:);
                    %     end
                    % end
                    
                    if strcmp(iOr,"i")
                    scatter(labCh_valid(i_point, 4), labCh_valid(i_point, 1), 20, 'o', 'filled', ...
                        'MarkerFaceColor', point_color, 'MarkerEdgeColor', point_color, 'LineWidth', 0.5);
                    else
                    text(labCh_valid(i_point, 4), labCh_valid(i_point, 1), ...
                         num2str(i_point), 'FontSize', 10, ...
                         'VerticalAlignment', 'top', 'Color', point_color, ...
                         'FontWeight', 'bold');  % 新增字体加粗参数
                    end
                    
                end
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
        % if strcmp(lightness_type,"rela")
        %     plot(labCh_PMCC(i_nation, 2), labCh_PMCC(i_nation, 3), 's', 'MarkerSize', 8, ...
        %         'MarkerFaceColor', 'm', 'MarkerEdgeColor', 'm');
        % end
        % plot(labCh_PMCC_pre(i_nation, 2), labCh_PMCC_pre(i_nation, 3), 's', 'MarkerSize', 8, ...
        %     'MarkerFaceColor', 'none', 'MarkerEdgeColor', 'm');
        
        % 添加图例、标签和标题

        xlabel('\textit{C*}', 'Interpreter', 'latex', 'FontSize', 12*2);
        ylabel('\textit{L*}', 'Interpreter', 'latex', 'FontSize', 12*2);
        title([nation_names(i_nation)],'FontSize', 12*2);
        % title([nation_names(i_nation),   attribute_names(attribute)], 'FontSize', 12);
        
        % 添加颜色条表示数据值
        if  i_nation==4
        % if iOr == 'r' && i_nation==4
            cb = colorbar;
            % cb.Label.String = 'L*'; % 修改颜色条标签
            cb.Label.String = 'luminance (cd/m$^2$)';
            cb.Label.Interpreter = 'latex';  % 设置解释器为LaTeX
            cb.Label.FontSize = 12;          % 可以调整字体大小
            data_range = [data_min, data_max];
            % data_range = [0, 35];
            caxis(data_range);        
            colormap(cmap);
        end
        
        % 设置坐标轴范围
        axis equal;
        % xlim([lim_min_x, lim_max_x]);
        % ylim([lim_min_y, lim_max_y]);
        xlim([0, lim_max_x]);
        ylim([0, lim_max_y]);
        
        % 绘制y=x参考线
        % x = linspace(lim_min_x, lim_max_x, 100);
        % plot(x, x, 'k--', 'LineWidth', 0.8);
        
        % 保存图片
        save_folder = fullfile(ellip_pic_folder, Dtype, "hml_C_L",lightness_type, obs_type, iOr);
        if ~exist(save_folder, "dir")
            mkdir(save_folder, 'recursive');
        end
        exportgraphics(gcf, fullfile(save_folder, strcat(nation_serial, '_L.jpg')), 'Resolution', 300);
        close(gcf);
    end
    % 合并所有图片
    save_folder = fullfile(ellip_pic_folder, Dtype, "hml_C_L", lightness_type,obs_type, iOr);
    concatenate_images1noSerial(save_folder, 4);   
end


%%
% folder="D:\work\VIVOskinExpe\renderCode\dsp\f01\r\jpg\noCard";
% concatenate_images1(folder,7);   