close all; % 关闭所有图窗
clc;       % 清空命令窗口
clear;     % 清除工作区所有变量
addpath("utils\")
%% 定义所有需要处理的 attribute
attributes = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

attribute_names_new = ["Preference", "Attractiveness", "Feminine", "Cooperative", ...
    "Youth", "Healthy", "Fidelity", "Harmony", "Fair", "Ruddy"];
nations = ["AS", "CA", "DA", "all"];

% lastParts = {'f04i', 'f05i', 'f06i', 'm04i', 'm05i', 'm06i',...
% 'f01i', 'f02i', 'f03i', 'm01i', 'm02i', 'm03i',...
% 'f07i', 'f08i','m07i', 'm08i',...
% 'f09i', 'f10i','m09i', 'm10i'};n_para = 21;iOr='i';

lastParts = {'f04r', 'f05r', 'f06r', 'm04r', 'm05r', 'm06r',...
'f01r', 'f02r', 'f03r', 'm01r', 'm02r', 'm03r',...
'f07r', 'f08r','m07r', 'm08r',...
'f09r', 'f10r','m09r', 'm10r'};n_para = 14;iOr='r';


load("documents\valid_attr.mat","map");


wd65 = [94.811, 100.00, 107.304];
datai_file = 'D:\work\VIVOskinExpe\renderCode\calibResults\datai_ipv18_3.mat';
LUT=load(datai_file);
XYZw_LUT=LUT.XYZw;
line_style = {'-',':','-.'};
plot_style = {'^','<','v'};

genders = ["f", "m"]; % 定义性别数组
% obs_types = ["model_group"];
obs_types = ["non_model"];
% obs_types = ["non_model", "model_group", "model"];
% 定义人种对应的lastParts索引
nation_indices = cell(5, 1); % 5个人种（包括"all"）
% AS (Asian): f04i, f05i, f06i, m04i, m05i, m06i (索引1-6)
nation_indices{1} = 1:6;
% CA (Caucasian): f01i, f02i, f03i, m01i, m02i, m03i (索引7-12)  
nation_indices{2} = 7:12;
% SA (South Asian & African): f07i, f08i, m07i, m08i (索引13-16),f09i, f10i, m09i, m10i (索引17-20)
% nation_indices{3} = 13:20;
% % all: 所有索引 (索引1-20)
% nation_indices{4} = 1:20;
nation_indices{3} = 13:16;
% all: 所有索引 (索引1-20)
nation_indices{4} = 17:20;

% 初始化重塑后的数据结构
average_reshaped = cell(5, 1); % 5个人种
labCh_PMCC=[[62.11	18.96	19.76	27.39	46.18];...
            [64.15	19.56	19.63	27.71	45.10];...
            [56.01	18.25	18.72	26.14	45.72];...
            [41.06	17.37	17.94	24.97	45.93]];
labCh_PMCC(end+1,:)=mean(labCh_PMCC,1);
file_missing={};
Dtype = 'efit_p';
% Dtype = 'efit_p_free';
scale_type_origin="unscaled";
if iOr=='i'
    picnames_groups = ["h3k","h4k","h5k","h6k","hd65","h7k","h8k",...
            "m3k","m4k","m5k","m6k","md65","m7k","m8k",...
             "l3k","l4k","l5k","l6k","ld65","l7k","l8k"];
elseif iOr=='r'
    picnames_groups = ["rs01","rs02","rs03","rs04","rs05","rs06","rs07", ...
             "rs08","rs09","rs10","rs11","rs12","rs13","rs14"];
end
scale_type="scaled";
if iOr=='i'
    target_indices{1}=5;
    target_indices{2}=12;
    target_indices{3}=19;
    % target_indices{4}=[1,8,15];
    % target_indices{5}=[2,9,16];
else
    target_indices{1}=[1,2,4,5,6];
    % target_indices{1}=[1,2,4,5];
    target_indices{2}=[7,8,9,10];
    target_indices{3}=[11,12];
    target_indices{4}=[13,14];
    % target_indices{5}=[6];
end
%% 直接按重塑后的结构加载和存储数据
for i_obs = 1:length(obs_types)
    obs_type = obs_types(i_obs);
    for i_para = 1:n_para        
        for i_nation = 1:length(nations)
            clear("lab_curr");clear("MSV_curr");
            % 获取当前人种的所有索引
            nation = nations(i_nation);
            curr_nation_indices = nation_indices{i_nation};
            n_subjects = length(curr_nation_indices);
            % 为每个subject加载数据
            for i_subject = 1:n_subjects
                subject_idx = curr_nation_indices(i_subject);
                lastPart = lastParts{subject_idx};
                iOr = lastPart(end);

                white_file = fullfile("optimizedD\whiteSquare\XYZw_white", ...
                    strcat(lastPart, ".mat"));
                load(white_file,"XYZw_white");

                average_file = fullfile("aveSkin", lastPart, "autoNhand_scaleoverLUT.mat");
                if exist(average_file, 'file')
                    average_data = load(average_file);
                    if strcmp(scale_type,"scaled")
                        for i_par=1:size(average_data.average_lab_all,1)
                            xyz_ave=lab2xyz2(average_data.average_lab_all(i_par,:),"user",wd65./wd65(2).*XYZw_LUT(2));
                            ave_scaled(i_par,:)=xyz2lab(xyz_ave,'user',wd65./wd65(2).*XYZw_white(i_par,2));
                        end
                        average_cur(i_subject,:,i_para,i_nation) = ave_scaled(i_para, :);
                    elseif strcmp(scale_type,"unscaled")
                        average_cur(i_subject,:,i_para,i_nation) = average_data.average_lab_all(i_para, :);
                    end                    
                else
                    average_cur(i_subject,:,i_para,i_nation) = NaN(1, 3);
                end
                % 循环处理每个 attribute
                % for attribute = [7]
                for attribute = 1:length(attributes)
                    attribute_serial = strcat(sprintf("%02d", attribute), attribute_names_new(attribute));
                    % 定义源文件路径
                    if attribute==7
                        obs_type_used="model_group";
                    else
                        obs_type_used=obs_type;
                    end
                    if strcmp(Dtype,"efit_p_free")
                        AnalyseResults_folder="AnalyseResults_p_free";
                    elseif strcmp(Dtype,"efit_p")
                        AnalyseResults_folder="AnalyseResults_p";
                    end
                    source_file = fullfile(AnalyseResults_folder, Dtype, scale_type_origin,lastPart, ...
                    obs_type_used, attribute_serial, 'labNscore', ...
                    strcat('labNscore_group', lastPart, picnames_groups{i_para}, '.mat'));

                    % 加载数据
                    if exist(source_file, 'file')
                        if ismember(attribute,[1,7])
                            load(source_file, "lab_group", "p_group", "picname_check");
                        else
                            load(source_file,  "p_group", "picname_check");
                        end
                    else
                        % 如果文件不存在，填充NaN
                        lab_group = NaN(33, 3);
                        MSV_group = NaN(33, 1);
                        file_missing{end+1,1} = lastPart;
                        file_missing{end,2} = obs_type;
                        file_missing{end,3} = attribute_serial;
                        file_missing{end,4} = picnames_groups{i_para};
                    end
                    if ismember(attribute,[1,7])
                        if strcmp(scale_type,"scaled")
                            xyz_fit=lab2xyz2(lab_group,'user',wd65./wd65(2).*XYZw_LUT(2));
                            lab_scaled=xyz2lab(xyz_fit,"user",wd65./wd65(2).*XYZw_white(i_para,2));
                            lab_curr(:,:,i_subject) = lab_scaled;
                        elseif strcmp(scale_type,"unscaled")
                            lab_curr(:,:,i_subject) = lab_group;
                        end
                    end
                    MSV_curr(:,i_subject, attribute) = p_group;
                    % MSV_curr(:,i_subject, attribute) = MSV_group;
                end
            end
            disp("d")
            % if ~exist('lab_curr', 'var')
            %     lab_curr=nan(n_para,3,n_subjects);
            %     MSV_curr=nan(n_para,n_subjects,length(attributes));
            % end
            lab_reshaped{i_obs, i_nation,i_para} = lab_curr;
            MSV_reshaped{i_obs, i_nation,i_para} = MSV_curr;
            if i_nation==2
                disp("d")
            end


        end


    end
    
    if i_obs == 1
        for i_nation = 1:length(nations)
                average_reshaped{i_obs,i_nation} = squeeze(average_cur(:,:,:,i_nation));
            for i_indices=1:length(target_indices)
                average_nations_cur(i_nation,:)=...
                    mean(mean(average_cur(:,:,target_indices{i_indices},i_nation),1,'omitnan'),3,'omitnan');
                average_nations{i_indices} =average_nations_cur;                
            end    
        end
    end



end

%% 保存数据
if strcmp(Dtype,"efit_p_free")
    ellip_pic_folder="ellip_pic_p_free";
elseif strcmp(Dtype,"efit_p")
    ellip_pic_folder="ellip_pic_p";
end
save_folder = fullfile(ellip_pic_folder, Dtype,"50",scale_type);
if ~exist(save_folder, "dir")
    mkdir(save_folder);
end
% % 保存重塑后的数据
% save(fullfile(save_folder, strcat("data_reshaped_", iOr, ".mat")), ...
%      "lab_reshaped", "MSV_reshaped", "average_reshaped");
% 
% fprintf('数据已成功保存到 %s\n', fullfile(save_folder, strcat("data_reshaped_", iOr, ".mat")));


%%
hue_values = linspace(0, 1, length(nations) + 1);
hue_values = hue_values(1:end-1); 
hsv_matrix = [hue_values', 0.8 * ones(length(nations), 1), 0.8 * ones(length(nations), 1)];
colors = hsv2rgb(hsv_matrix);
line_style = '-';  % 统一使用实线
plot_style = 'o';  % 统一使用圆形标记
for i_obs = 1:length(obs_types)
    obs_type = obs_types(i_obs);
    for i_indices = 1:length(target_indices)
    % for i_indices = [1:3]
        for attribute = [1]
        % for attribute = 1:length(attributes)
            attribute_serial = strcat(sprintf("%02d", attribute), ...
                attribute_names_new(attribute));
            figure(i_indices*10+attribute); hold on;
            for i_nation = 1:length(nations)
                % 获取当前人种的所有索引
                nation = nations(i_nation);
                curr_nation_indices = nation_indices{i_nation};
                n_subjects = length(curr_nation_indices);
                
                % 合并所有受试者数据
                lab_group = [];
                MSV_group = [];
                for i_subject = 1:n_subjects
                    % figure(100+i_subject);hold on;
                    for i_para=target_indices{i_indices}
                        subject_idx = curr_nation_indices(i_subject);
                        lastPart = lastParts{subject_idx};
                        lab_curr = lab_reshaped{i_obs, i_nation, i_para};
                        MSV_curr = MSV_reshaped{i_obs, i_nation, i_para};
                        MSV_group_curr= MSV_curr(:,i_subject,attribute);
                        lab_group_curr=lab_curr(:,:,i_subject);
                        p_ratio=sum(MSV_group_curr>0.5)./length(MSV_group_curr);
                        if (p_ratio<0.1||p_ratio>0.9)
                            disp("p_ratio not in range")
                            continue
                        end
                        lab_group = [lab_group; lab_curr(:,:,i_subject)];
                        MSV_group = [MSV_group; MSV_group_curr];

                    end
                end
                % 过滤掉MSV_group中全是NaN的行
                valid_rows = ~any(isnan(MSV_group), 2);  % 找出不全为NaN的行
                valid_rows = valid_rows&~any(isnan(lab_group), 2);  % 找出不全为NaN的行
                MSV_group = MSV_group(valid_rows, :);     % 过滤MSV_group
                lab_group = lab_group(valid_rows, :);     % 同步过滤lab_group
                % 检查数据有效性并处理
                if ~all(isnan(MSV_group(:)))
                    [par_mean, r_mean] = ...
                        calculate_weighted_or_simple_mean(MSV_group, lab_group);
                    mean_cen(1) = mean(lab_group(:,1),'omitnan');
                    mean_cen(2:3) = par_mean(1,4:5);

                    [par, r, y] = my_ellipsoidfit3_free(lab_group, MSV_group, mean_cen);
                    if i_nation==4 && i_indices==3
                        p_ratio=sum(MSV_group>0.5)./length(MSV_group);
                        disp(p_ratio)
                    end
                    parNr(i_indices,:) = [par, r];  % 移除性别维度
                    Contour50(par, lab_group, MSV_group, "nation1", ...
                        average_nations{i_indices}, ...  % 调整参数索引
                        colors(i_nation,:), line_style, ...
                        plot_style, "");
                    % scatter(lab_group(:,2),lab_group(:,3), 10, MSV_group, 'filled'); 

                    %保存ellipPara
                    nation_serial=strcat(num2str(i_nation),nation);
                    fitRes_folder=fullfile("AnalyseResults_p",Dtype,"50", ...
                        scale_type_origin,"nation1", scale_type,...
                        obs_type,iOr,attribute_serial,nation_serial);
                    if ~exist(fitRes_folder,"dir")
                        mkdir(fitRes_folder);
                    end
                    average_indices_curr=average_nations{i_indices}(i_nation,:);
                    save(fullfile(fitRes_folder,strcat(num2str(i_indices),".mat")), ...
                        "par","r","y","average_indices_curr");
                end
                parNr_all{i_obs, i_nation, attribute} = parNr;
                hue_all{i_obs, i_nation, attribute}=atan2d(par(5),par(4));
                plot(labCh_PMCC(i_nation,2), labCh_PMCC(i_nation,3), 's', 'MarkerSize', 5, ...
                'MarkerFaceColor', "none", 'MarkerEdgeColor',colors(i_nation,:));
            end

            output_folder = fullfile(save_folder,"nation1",iOr,obs_type);
            if ~exist(output_folder, "dir")
                mkdir(output_folder);
            end
            % 添加 45 度线
            % 添加 x=0 和 y=0 的轴
            lim_max=40;
            lim_min=-5;
            line([0, 0], [lim_min, lim_max], 'Color', 'k', 'LineStyle', '--'); % x=0
            line([lim_min, lim_max], [0, 0], 'Color', 'k', 'LineStyle', '--'); % y=0
            href = refline(1, 0);  % 创建参考线对象
            set(href, 'Color', 'k', 'LineStyle', '--');  % 设置属性

            h1=figure(i_indices*10+attribute);
            exportgraphics(h1, fullfile(output_folder, ...
                strcat(attribute_serial,num2str(i_indices), ".jpg")),"Resolution",150);
            % saveas(i_indices*10+attribute, fullfile(output_folder, ...
            %     strcat(attribute_serial,num2str(i_indices), ".jpg")));

        end

        
    end
    concatenate_images1(output_folder,5);
    save(fullfile(output_folder, ...
                strcat( "fitRes.mat")),"parNr_all");
    close all;
end            



% rgb_value = colors(3,:);
% imshow(ones(80) .* permute(rgb_value, [1, 3, 2]));