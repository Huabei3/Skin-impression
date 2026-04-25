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
iOr='i';
if iOr=='i'
    % 颜色标签列表（H=高照度，M=中照度，L=低照度，D65=标准光源）
    pcn = ["H3K", "H4K", "H5K", "H6K", "HD65", "H7K", "H8K", ...
           "M3K", "M4K", "M5K", "M6K", "MD65", "M7K", "M8K", ...
           "L3K", "L4K", "L5K", "L6K", "LD65", "L7K", "L8K"];
else
    pcn = ["rs01","rs02","rs03","rs04","rs05","rs06","rs07", ...
                 "rs08","rs09","rs10","rs11","rs12","rs13","rs14"];
end
nations = ["AS", "CA", "SA", "AF"];
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
% 校准数据路径（datai_ipv35_3.mat：LUT模型 显示模型的XYZ白点数据）
datai_file = '..\..\calibration\display_model\datai_ipv35_3.mat';
wd65=[94.813  100.000  107.262];
LUT=load(datai_file);
XYZw_LUT=LUT.XYZw;
wd65_scaled=wd65./100.*XYZw_LUT(2);
attributes_to_process = [1,7,8,9,10]; % 只处理这些属性
% 评估属性列表（1-10对应不同感知属性，需与attribute_names一一对应）
attribute_names = ["Preference", "Attractiveness", "Feminine", "Cooperative", ...
                   "Youth", "Healthy", "Fidelity","Harmony", "Fair", "Ruddy"];
% 过滤出需要处理的属性名称，用于Excel列标题
filtered_attribute_names = attribute_names(attributes_to_process);
% 新增检查：确保 filtered_attribute_names 不包含空字符串且非空
% 移除可能存在的空字符串
filtered_attribute_names = filtered_attribute_names(strlength(filtered_attribute_names) > 0);
if isempty(filtered_attribute_names)
    error('错误: 过滤后的属性名称为空。请检查 attributes_to_process 或 attribute_names。');
end
% 目标评分配置（rela=相对评分，abs=绝对评分；1=满分）
target_score=1; % 目标评分值（0-1之间，转换为百分比）
target_score_str=num2str(target_score*100); % 字符串化评分（用于路径命名）
score_type="rela"; % 评分类型
render_type="srgb";

Dtype="efit2";
obs_type="non_model";
% 加载标准Lab值（aveLab_D65_Asian.mat：亚洲人肤色在D65下的平均Lab值）
load("aveLab_D65_Asian.mat","labC_HD65");
lab_PMCC = [62.11, 18.96, 19.76];
labC_PMCC = [lab_PMCC, sqrt(lab_PMCC(1, 2)^2 + lab_PMCC(1, 3)^2)];
% 定义一个存储所有 nation 的唯一列表
all_nations = string.empty;
for i_model_temp = 1:length(new_names)
    % 确保 find_nation 函数能处理 string 类型的 model 名称
    [nation_temp,~,~] = find_nation(char(new_names(i_model_temp)));
    all_nations = [all_nations, nation_temp];
end
unique_nations = unique(all_nations);

% 定义图片保存根路径
base_plot_output_dir = fullfile('..\..\data', 'parameter_plots', iOr, obs_type);
if ~exist(base_plot_output_dir, 'dir')
    mkdir(base_plot_output_dir);
end

% 循环遍历每个 nation
for i_nation = 1:length(nations)
    nation = nations(i_nation);
    nation_serial=strcat(num2str(i_nation),nation);
    
    % 循环遍历每个属性
    for attribute_idx_in_list = 1:length(attributes_to_process)
        attribute = attributes_to_process(attribute_idx_in_list);
        current_attribute_name = attribute_names(attribute);
        attribute_serial = strcat(sprintf("%02d", attribute), current_attribute_name);
        
        % 为每个 nation 和 attribute 创建子目录
        attribute_plot_dir = fullfile(base_plot_output_dir, char(nation), char(attribute_serial));
        if ~exist(attribute_plot_dir, 'dir')
            mkdir(attribute_plot_dir);
        end

        % 循环遍历每个光源 (pcn)
        for i_par = 1:length(pcn)
            current_pcn_name = pcn(i_par);
            
            fprintf('--- 正在为 Nation: %s, 属性: %s, 光源: %s 生成参数图 ---\n', ...
                    nation, current_attribute_name, current_pcn_name);
            
            figure; % 为每个 pcn 创建新图窗
            hold on; % 允许在同一图窗上绘制多条曲线
            grid on;
            title_str = sprintf('Nation: %s, Attribute: %s, Light: %s', ...
                                char(nation), char(current_attribute_name), char(current_pcn_name));
            title(title_str, 'Interpreter', 'none');
            xlabel('a*'); % X轴标签改为 a*
            ylabel('b*'); % Y轴标签改为 b*
            
            has_data_to_plot = false; % 标记是否有数据可以绘制

            % 循环遍历每个模特
            par_inds=[];par_scaled_inds=[];
            for i_model=nation_indices{i_nation}
                model = new_names(i_model);
                lastPart=strcat(model,iOr); % 定义 lastPart
                
                [model_nation,~,~] = find_nation(char(model)); % 获取当前模型的 nation
                
              
                % 假设 select_type 函数已定义
                i_type=select_type(char(model)); 
                
                % 加载 fitRes.mat 获取 par_ind
                % 注意：par_all 应该是一个包含所有pcn数据的数组
                fitRes_file=fullfile("D:\work\VIVOskinExpe\analyze\AnalyseResults1\" ,...
                    Dtype,lastPart,obs_type,attribute_serial,"ellipPara","fitRes.mat");
                
                par_ind = []; % 初始化 par_ind
                if exist(fitRes_file,'file') == 2
                    fitRes_data=load(fitRes_file);
                    par_ind = fitRes_data.par_all(i_par,:); % 获取对应当前i_par的数据
                end
                par_inds=[par_inds;par_ind];
                
                % 加载 aveSkin 获取 average
                average_file = fullfile("aveSkin", lastPart, "autoNhand_scaleoverLUT.mat");
                average = []; % 初始化 average
                if exist(average_file, 'file') == 2
                    average_data = load(average_file);
                    average = average_data.average_lab_all(i_par, 1:3); % 获取对应当前i_par的平均Lab值
                end

                % 加载 a_scale 文件获取 par
                gender=char(model);gender=gender(1);
                fit_center_data_file = fullfile('D:\work\VIVOskinExpe\analyze\AnalyseResults1', ...
                    Dtype, 'scale_factor_fit_results', obs_type,"i", char(model_nation), gender);
                
                full_fit_center_file = fullfile(fit_center_data_file, ...
                                        strcat("a_scale_",attribute_serial,".mat"));
                
                par_scaled = []; % 初始化 par
                if exist(full_fit_center_file,'file') == 2
                    load(full_fit_center_file, ...
                                'a_scale', "a_CL","all_ave_curr_z","all_par");
                    if iOr == 'r'
                        source_folder = fullfile('D:\work\VIVOskinExpe\analyze\AnalyseResults1', ...
                            Dtype,'50',obs_type, ...
                            iOr,attribute_serial,nation_serial,gender);
                        full_path=fullfile(source_folder,strcat(pcn(i_par),".mat"));
                        data = load(full_path);
                        par_scaled = get_par_fr_SF(average(1), a_scale, a_CL, data.par); 
                    else
                        par_scaled = get_par_fr_SF(average(1), a_scale, a_CL, all_par{1});
                    end

                    par_scaled_inds=[par_scaled_inds;par_scaled];
                    
                    % 绘制 par_ind(4), par_ind(5)
                    plot(par_ind(4), par_ind(5), 'ro', 'MarkerSize', 8, 'LineWidth', 1.5, 'DisplayName', 'par\_ind'); % 红色圆圈
                    text(par_ind(4), par_ind(5), [' ', char(lastPart)], 'Color', 'r', 'FontSize', 8);
                    
                    % 绘制 par(4), par(5)
                    plot(par_scaled(4), par_scaled(5), 'bx', 'MarkerSize', 8, 'LineWidth', 1.5, 'DisplayName', 'par'); % 蓝色叉号
                    text(par_scaled(4), par_scaled(5), [' ', char(lastPart)], 'Color', 'b', 'FontSize', 8);
                end
            end
            
                % legend('show');
            hold off;
            
            % 保存图片，路径现在包含 pcn 名称
            plot_filename = fullfile(attribute_plot_dir, strcat(char(current_pcn_name), '.jpg'));
            saveas(gcf, plot_filename);
            fprintf('参数图已保存到: %s\n', plot_filename);
            close(gcf); % 关闭当前图窗以节省内存

        end % end for i_par
    end % end for attribute
end % end for i_nation

fprintf('\n所有参数图已生成并保存到 %s\n', base_plot_output_dir);