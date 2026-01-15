close all;
clc;
clear;
addpath("..\..\utils\"); % 确保路径正确指向您的utils文件夹
%%
% 模特名称列表（f=女性，m=男性，数字为编号）
new_names = [ "f04", "f05", "f06", "m04", "m05", "m06",...
              "f01", "f02", "f03", "m01", "m02", "m03",...
              "f07", "f08","m07", "m08",...
              "f09", "f10","m09", "m10"];
% iOr='r';
iOrs=['i','r'];
n_attribute=10;

% 目标评分配置（rela=相对评分，abs=绝对评分；1=满分）
target_score=1; % 目标评分值（0-1之间，转换为百分比）
target_score_str=num2str(target_score*100); % 字符串化评分（用于路径命名）
score_type="rela"; % 评分类型
render_type="srgb";
Dtype="efit_p";
scale_type_origin="unscaled";
obs_type="non_model";
using_model_type="each_self";
% using_model_type="all";

nation_type="ACSA";




p_pre = cell(20, n_attribute);
p_visual = cell(20, n_attribute);
for i_iOr=1:2
    iOr=iOrs(i_iOr);
    % 颜色标签列表（H=高照度，M=中照度，L=低照度，D65=标准光源）
    if iOr=='i'
        % 颜色标签列表（H=高照度，M=中照度，L=低照度，D65=标准光源）
        pcn = ["H3K", "H4K", "H5K", "H6K", "HD65", "H7K", "H8K", ...
               "M3K", "M4K", "M5K", "M6K", "MD65", "M7K", "M8K", ...
               "L3K", "L4K", "L5K", "L6K", "LD65", "L7K", "L8K"];
    else
        pcn = ["rs01","rs02","rs03","rs04","rs05","rs06","rs07", ...
                     "rs08","rs09","rs10","rs11","rs12","rs13","rs14"];
    end
    max_classify=0;
    if max_classify==1
        nation_type="ACD";
        nations = ["AS", "CA", "DA", "all"];
        nation_indices = cell(5, 1); % 5个人种（包括"all"）
        % AS (Asian): f04i, f05i, f06i, m04i, m05i, m06i (索引1-6)
        nation_indices{1} = 1:6;
        % CA (Caucasian): f01i, f02i, f03i, m01i, m02i, m03i (索引7-12)  
        nation_indices{2} = 7:12;
        % DA (South Asian & African): f07i, f08i, m07i, m08i (索引13-20)
        nation_indices{3} = 13:20;
        % all: 所有索引 (索引1-20)
        nation_indices{4} = 1:20;
        label_type="nation_max";
    else
        nation_type="ACSA";
        nations = ["AS", "CA", "SA", "AF","all"];
        nation_indices = cell(5, 1); % 5个人种（包括"all"）
        nation_indices{1} = 1:6;
        nation_indices{2} = 7:12;
        nation_indices{3} = 13:16;
        nation_indices{4} = 17:20;
        nation_indices{5} = 1:20;
        label_type="nation";
    end
    % 校准数据路径（datai_ipv35_3.mat：LUT模型 显示模型的XYZ白点数据）
    datai_file = '..\..\calibration\display_model\datai_ipv35_3.mat';
    wd65=[94.813  100.000  107.262];
    LUT=load(datai_file);
    XYZw_LUT=LUT.XYZw;
    wd65_scaled=wd65./100.*XYZw_LUT(2);
    attributes_to_process = [1,2,3,4,5,6,7,8,9,10];
    n_attribute=length(attributes_to_process);
    % attributes_to_process = [1,6,7,8,9,10]; % 只处理这些属性
    % 评估属性列表（1-10对应不同感知属性，需与attribute_names一一对应）
    attribute_names = ["Preference", "Attractiveness", "Feminine", "Cooperative", ...
                       "Youth", "Healthy", "Fidelity","Harmony", "Fair", "Ruddy"];
    % 过滤出需要处理的属性名称，用于Excel列标题
    filtered_attribute_names = attribute_names(attributes_to_process);
    % **新增检查：确保 filtered_attribute_names 不包含空字符串且非空**
    % 移除可能存在的空字符串
    filtered_attribute_names = filtered_attribute_names(strlength(filtered_attribute_names) > 0);
    if isempty(filtered_attribute_names)
        error('错误: 过滤后的属性名称为空。请检查 attributes_to_process 或 attribute_names。');
    end

    % 确保输出目录存在
    output_dir = fullfile('..\..\data', 'correlation_results',"fullpara",Dtype,nation_type,using_model_type);
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end
    % 定义输出Excel文件的完整路径
    excel_output_path_r = fullfile(output_dir,strcat(iOr,obs_type,'_r.xlsx'));
    excel_output_path_dE = fullfile(output_dir,strcat(iOr,obs_type,'_dE.xlsx'));
    excel_output_path_rmse = fullfile(output_dir,strcat(iOr,obs_type,'_rmse.xlsx'));
    % 如果文件已存在，则删除，确保每次都是新的开始
    if exist(excel_output_path_r, 'file')
        delete(excel_output_path_r);
    end
    if exist(excel_output_path_dE, 'file')
        delete(excel_output_path_dE);
    end
    if exist(excel_output_path_rmse, 'file')
        delete(excel_output_path_rmse);
    end
    
    % 加载标准Lab值（aveLab_D65_Asian.mat：亚洲人肤色在D65下的平均Lab值）
    load("aveLab_D65_Asian.mat","labC_HD65");
    lab_PMCC = [62.11, 18.96, 19.76];
    labC_PMCC = [lab_PMCC, sqrt(lab_PMCC(1, 2)^2 + lab_PMCC(1, 3)^2)];
    
    for i_model=1:length(new_names)
        current_model_name = new_names(i_model);
        source_folder=fullfile('mask',strcat(current_model_name,iOr));
        source_folder=char(source_folder);
        slashes = strfind(source_folder, '\');
        lastPart=source_folder(slashes(1,end)+1:end);
        model = lastPart(1:end-1);
        
        % 提取肤色时是否给边缘像素赋予透明度
        % 权重开关（判断是否为特定模型，需说明模型差异：如f04i等模型不使用权重）
        if ismember(lastPart,["f04i","f05i","f06i","m04i","m06i"])
            if_wei=0;
        else
            if_wei=1;
        end
        if ismember(lastPart,["m02i","m03i"])
            if_2mask=1;
        else
            if_2mask=0;
        end
        
        i_type=select_type(model); % 假设 select_type 函数已定义
        
        % 创建用于存储当前model所有相关性的表格数据
        correlation_table_data = cell(length(pcn) + 1, length(filtered_attribute_names) + 1);
        dE_table_data = cell(length(pcn) + 1, length(filtered_attribute_names) + 1);
        rmse_table_data = cell(length(pcn) + 1, length(filtered_attribute_names) + 1);
        
        % 设置表格的左上角单元格标题
        correlation_table_data{1, 1} = '光源/属性';
        dE_table_data{1, 1} = '光源/属性';
        rmse_table_data{1, 1} = '光源/属性';
        
        % 设置第一列为pcn名称
        correlation_table_data(2:end, 1) = cellstr(pcn');
        dE_table_data(2:end, 1) = cellstr(pcn');
        rmse_table_data(2:end, 1) = cellstr(pcn');
        
        % 设置第一行为attribute名称
        correlation_table_data(1, 2:end) = cellstr(filtered_attribute_names);
        dE_table_data(1, 2:end) = cellstr(filtered_attribute_names);
        rmse_table_data(1, 2:end) = cellstr(filtered_attribute_names);
        
        % 保存路径规则：
        % rendered/[观察者组别类]/[目标评分百分比]/[模特编号]/[光源]/[属性编号_序号]/[L*a*b*坐标].jpg
        save_folder=fullfile('rendered',render_type,obs_type,target_score_str,lastPart);
        if ~exist(save_folder, 'dir')
            mkdir(save_folder);
        end
        fprintf('--- 正在处理模特: %s ---\n', current_model_name);
    
        for i_par = 1:length(pcn)
            current_pcn_name = pcn(i_par);
            
            % 获取当前光源（pcn）对应的行索引
            row_idx_in_table = i_par + 1; % +1 是因为第一行是表头
            
            for attribute_idx_in_list = 1:length(attributes_to_process)
                attribute = attributes_to_process(attribute_idx_in_list);
                
                current_attribute_name = attribute_names(attribute);
                attribute_serial = strcat(sprintf("%02d", attribute), current_attribute_name);
                [nation,i_nation,nation_serial]=find_nation(model); % 假设 find_nation 函数已定义
    
                if attribute_idx_in_list==7
                    obs_type_used="model_group";
                else
                    obs_type_used=obs_type;
                end
                labNscore_file=fullfile("D:\work\VIVOskinExpe\analyze\AnalyseResults_p\" ,...
                    Dtype,scale_type_origin,lastPart,obs_type_used,attribute_serial,"labNscore", ...
                    strcat("labNscore_group",lower(lastPart),lower(current_pcn_name),".mat")); % 修改这里，lastPart应该在lower之前
                
                average_file = fullfile("aveSkin", lastPart, "autoNhand_scaleoverLUT.mat");
                average_data = load(average_file);
                average = average_data.average_lab_all(:, 1:3);
                
                lab_group = [];
                p_group = [];
                
                if exist(labNscore_file,'file') == 2
                    load(labNscore_file,  "lab_group","p_group","picname_group");
                else
                    fprintf('警告: 找不到文件 %s，跳过此组合。\n', labNscore_file);
                    correlation_table_data{row_idx_in_table, attribute_idx_in_list + 1} = NaN; % 标记为NaN
                    rmse_table_data{row_idx_in_table, attribute_idx_in_list + 1} = NaN; % 标记为NaN
                    continue;
                end
                
                % model_fupara_file=fullfile("..\..\data\ellipse_para\model_fullpara",
                % Dtype,obs_type);
                model_fupara_file=fullfile("D:\work\VIVOskinExpe\analyze\AnalyseResults_p\" , ...
                    "efit_p\unscaled\model_fullpara\d65\i", obs_type);
                
                
                fullpara_data=load(fullfile(model_fupara_file, ...
                    strcat(attribute_serial,"_all_curve_params.mat")));
                if strcmp(using_model_type,"each_self")
                    i_nation_used=i_nation;
                elseif strcmp(using_model_type,"all")
                    i_nation_used=4;
                end
    
                a_alpha=fullpara_data.a_alpha_all(i_nation_used,:);
                a_CL=fullpara_data.a_CL_all(i_nation_used,:);
                a_hue_angle=fullpara_data.a_hue_angle_all(i_nation_used,:);
                a_long_axis=fullpara_data.a_long_axis_all(i_nation_used,:);
                a_short_axis=fullpara_data.a_short_axis_all(i_nation_used,:);
                a_theta=fullpara_data.a_theta_all(i_nation_used,:);
                
                hue_angle=a_hue_angle(1).*average(i_par,1) + a_hue_angle(2);
                chroma=a_CL(1).*log(average(i_par,1)) + a_CL(2);
                long_axis=a_long_axis(1).*average(i_par,1).^3 + a_long_axis(2).*average(i_par,1).^2 +...
                    a_long_axis(3).*average(i_par,1) + a_long_axis(4);
                short_axis=a_short_axis(1).*average(i_par,1).^3 + a_short_axis(2).*average(i_par,1).^2 +...
                    a_short_axis(3).*average(i_par,1) + a_short_axis(4);
                theta=a_theta(1).*average(i_par,1) + a_theta(2);
                alpha=a_alpha(1).*average(i_par,1) + a_alpha(2);
                
                % if iOr=='r'
                %     source_folder=fullfile("D:\work\VIVOskinExpe\analyze\AnalyseResults_p\" + ...
                %         Dtype,"50\unscaled\nation1\scaled\non_model", iOr,attribute_serial,nation_serial);
                %     i_indices=find_indices(i_par,iOr);
                %     full_path=fullfile(source_folder,strcat(num2str(i_indices),".mat"));
                %     if ~exist(full_path,"file")
                %         continue
                %     end
                %     data = load(full_path); 
                %     scene_par=data.par;
                %     [C_curr, alpha_curr,  theta_curr, long_axis_curr, short_axis_curr, hue_curr] = calculate_ellipse_parameters(scene_par);
                %     C_pre=a_CL(1).*log(data.average_indices_curr(1))+ a_CL(2);
                %     chroma=chroma.*(C_curr./C_pre);
                %     long_axis_pre=a_long_axis(1).*data.average_indices_curr(1).^3 + a_long_axis(2).*data.average_indices_curr(1).^2 +...
                %         a_long_axis(3).*data.average_indices_curr(1) + a_long_axis(4);
                %     short_axis_pre=a_short_axis(1).*data.average_indices_curr(1).^3 + a_short_axis(2).*data.average_indices_curr(1).^2 +...
                %         a_short_axis(3).*data.average_indices_curr(1) + a_short_axis(4);
                %     long_axis=long_axis.*(long_axis_curr./long_axis_pre);
                %     short_axis=short_axis.*(short_axis_curr./short_axis_pre);
                % 
                %     hue_angle=atan2d(scene_par(5),scene_par(4));
                % end
                
                [par] = calculate_par_from_ellipse(hue_angle, chroma, ...
                        long_axis, short_axis, theta, alpha);
                y = calculate_y(lab_group(:,2), lab_group(:,3), par); % 假设 calculate_y 函数已定义
                
                % ======================================
                % 计算 y 和 p_group 之间的相关系数和rmse
                % ======================================
                if ~isempty(y) && ~isempty(p_group) && numel(y) == numel(p_group) && numel(y) > 1
                    % 计算相关系数 (r)
                    correlation_coefficient = corr(y, p_group, 'Type', 'Pearson');
                    correlation_table_data{row_idx_in_table, attribute_idx_in_list + 1} = correlation_coefficient;
                    p_pre_temp=p_pre{i_model,attribute};
                    p_pre_temp=[p_pre_temp;y];
                    p_pre{i_model,1}=p_pre_temp;
                    p_visual_temp=p_visual{i_model,attribute};
                    p_visual_temp=[p_visual_temp;p_group];
                    p_visual{i_model,1}=p_visual_temp;
                    % if attribute==1
                    %     output_dir_pic=fullfile(output_dir,"pic", ...
                    %         iOr,attribute_serial,current_model_name);
                    %     if ~exist(output_dir_pic,"dir")
                    %         mkdir(output_dir_pic)
                    %     end
                        % output_file=fullfile(output_dir_pic, ...
                        %     strcat(iOr,attribute_serial,current_model_name,pcn(i_par),".jpg"));
                        % plot_scatter_with_45line(y, ...
                        %     p_group, output_file);
                        % if i_par==length(pcn)
                        %     concatenate_images1(output_dir_pic,7);
                        % end
                    % end
                    
                    % 计算 色差
                    [par_mean, r_mean] = calculate_weighted_or_simple_mean( p_group, lab_group);
                    L=mean(lab_group(:,1));
                    dE = deltaE2000([L,par(4:5)], [L,par_mean(4:5)]);
                    dE_table_data{row_idx_in_table, attribute_idx_in_list + 1} = dE;
                    % 计算 rmse
                    p_group(p_group==0)=NaN;
                    rmse = nanmean(abs((p_group - y) ));                
                    rmse_table_data{row_idx_in_table, attribute_idx_in_list + 1} = rmse;
    
                    % fprintf('  - 光源: %s, 属性: %s, 相关系数 = %.4f, rmse = %.2f%%\n', ...
                    %     current_pcn_name, current_attribute_name, correlation_coefficient, rmse);
                else
                    fprintf('警告: 无法计算模特 %s, 光源 %s, 属性 %s 的相关性或rmse。原因：y或p_group为空或大小不匹配或数据不足。\n', ...
                            current_model_name, current_pcn_name, current_attribute_name);
                    correlation_table_data{row_idx_in_table, attribute_idx_in_list + 1} = NaN;
                    rmse_table_data{row_idx_in_table, attribute_idx_in_list + 1} = NaN;
                end
            end % end for attribute
        end % end for i_par
    
        % 处理并保存相关性结果
        processed_r_data = process_and_summarize(correlation_table_data, pcn, filtered_attribute_names);
        writematrix(processed_r_data, excel_output_path_r, 'Sheet', char(current_model_name));
        fprintf('模特 %s 的相关性结果已写入Excel的Sheet: %s\n', current_model_name, excel_output_path_r);
    
        % 处理并保存dE结果
        processed_dE_data = process_and_summarize(dE_table_data, pcn, filtered_attribute_names);
        writematrix(processed_dE_data, excel_output_path_dE, 'Sheet', char(current_model_name));
        fprintf('模特 %s 的相关性结果已写入Excel的Sheet: %s\n', current_model_name, excel_output_path_dE);
        % 处理并保存rmse结果
        processed_rmse_data = process_and_summarize(rmse_table_data, pcn, filtered_attribute_names);
        writematrix(processed_rmse_data, excel_output_path_rmse, 'Sheet', char(current_model_name));
        fprintf('模特 %s 的rmse结果已写入Excel的Sheet: %s\n', current_model_name, excel_output_path_rmse);
    end % end for i_model
    
    fprintf('\n所有结果已保存到 %s 和 %s\n', excel_output_path_r, excel_output_path_rmse);
    
    %%
    write_mean_summary(excel_output_path_r, new_names, nation_indices(1:4), nations);
    write_mean_summary(excel_output_path_dE, new_names, nation_indices(1:4), nations);
    write_mean_summary(excel_output_path_rmse, new_names, nation_indices(1:4), nations);
end


save(fullfile(output_dir,"p_vNp.mat"),"p_pre","p_visual");


%% 画图



% n_nation=length(nations);
% p_pre_nation=cell(n_nation,n_attribute);
% p_visual_nation=cell(n_nation,n_attribute);
% for attribute = 1:n_attribute    
%     current_attribute_name = attribute_names(attribute);
%     attribute_serial = strcat(sprintf("%02d", attribute), current_attribute_name);
%     % for i_nation=1:n_nation
%     %     for i_model=nation_indices{i_nation}
%     %         % current_model_name = new_names(i_model);
%     %         p_pre_temp=p_pre_nation{i_nation,1};
%     %         p_pre_temp=[p_pre_temp;p_pre{i_model,1}];
%     %         p_pre_nation{i_nation,1}=p_pre_temp;
%     % 
%     %         p_visual_temp=p_visual_nation{i_nation,1};
%     %         p_visual_temp=[p_visual_temp;p_visual{i_model,1}];
%     %         p_visual_nation{i_nation,1}=p_visual_temp;
%     %     end
%     %     output_dir_pic=fullfile(output_dir,"pic",attribute_serial);
%     %     if ~exist(output_dir_pic,"dir")
%     %         mkdir(output_dir_pic)
%     %     end
%     %     output_file=fullfile(output_dir_pic, ...
%     %         strcat(nations(i_nation),".jpg"));
%     %     plot_scatter_with_45line(p_visual_nation{i_nation,1}, ...
%     %         p_pre_nation{i_nation,1}, output_file);
%     % end
%     output_dir_pic=fullfile(output_dir,"pic",attribute_serial);
%     if ~exist(output_dir_pic,"dir")
%         mkdir(output_dir_pic)
%     end
%     concatenate_images1(output_dir_pic,4);
% end

%% 辅助函数
function val = nan_if_empty(x)
    if isempty(x)
        val = NaN;
    else
        val = x;
    end
end

function result_cell = process_and_summarize(table_data, pcn, attribute_names)
    data_to_process = table_data(2:end, 2:end);
    processed_data = cellfun(@(x) nan_if_empty(x), data_to_process, 'UniformOutput', false);
    numeric_data = cell2mat(processed_data);
    
    % 计算行和列的均值
    row_mean = nanmean(numeric_data, 2);
    col_mean = nanmean(numeric_data, 1);
    
    % 构建新的结果矩阵
    result_numeric = [numeric_data, row_mean];
    result_numeric = [result_numeric; [col_mean, nanmean(col_mean)]];
    
    % 转换为 cell 格式并添加表头和行名
    result_cell = num2cell(result_numeric);
    result_cell = [[table_data(2:end, 1); "mean"], result_cell];
    result_cell = [[table_data(1,:), "mean"]; result_cell];
end