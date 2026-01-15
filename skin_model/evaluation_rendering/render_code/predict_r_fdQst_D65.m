close all;
clc;
clear;
% 确保路径正确指向您的utils文件夹
addpath("..\..\utils\"); 

%% --- 辅助函数定义 (为结构清晰，将核心计算逻辑封装) ---

function [par] = calculate_par_model(average_L, a_params)
    % 基于L*计算椭圆中心和轴长
    a_alpha = a_params.a_alpha;
    a_CL = a_params.a_CL;
    a_hue_angle = a_params.a_hue_angle;
    a_long_axis = a_params.a_long_axis;
    a_short_axis = a_params.a_short_axis;
    a_theta = a_params.a_theta;

    hue_angle=a_hue_angle(1).*average_L + a_hue_angle(2);
    chroma=a_CL(1).*log(average_L) + a_CL(2);
    long_axis=a_long_axis(1).*average_L.^3 + a_long_axis(2).*average_L.^2 +...
        a_long_axis(3).*average_L + a_long_axis(4);
    short_axis=a_short_axis(1).*average_L.^3 + a_short_axis(2).*average_L.^2 +...
        a_short_axis(3).*average_L + a_short_axis(4);
    theta=a_theta(1).*average_L + a_theta(2);
    alpha=a_alpha(1).*average_L + a_alpha(2);
    
    % 假设 calculate_par_from_ellipse 函数已定义，返回包含 a* 和 b* 的 par 向量
    [par] = calculate_par_from_ellipse(hue_angle, chroma, ...
            long_axis, short_axis, theta, alpha);
end

function par_out = apply_CT_interp(par_in, CT, i_nation, attribute, average_L, Dtype, pcn)
    % 应用颜色温度插值修正
    par_out = par_in;
    if CT < 5000 
        % 假设 CT_interpolation.mat 已在主脚本中加载到 CT_interpolation_data
        global CT_interpolation_data;
        if isempty(CT_interpolation_data)
            % 尝试加载，如果失败则跳过插值
             try
                load(fullfile("documents",Dtype,"CT_interpolation.mat"),'CT_interpolation_data');
                % 声明为全局变量以便下次使用
                global CT_interpolation_data;
             catch
                warning('无法加载 CT_interpolation.mat，跳过CT插值。');
                return; 
             end
        end

        CT_values=CT_interpolation_data{i_nation, attribute}.CT_7;
        
        % 预分配
        a_hue_angle = zeros(7, 2);
        a_CL = zeros(7, 2);
        hue_values = zeros(7, 1);
        chroma_values = zeros(7, 1);
        
        for i_CT=1:7
            a_hue_angle(i_CT,:)=CT_interpolation_data{i_nation, attribute}.a_hue_angle_all_CT(i_CT,:);
            hue_values(i_CT,1)=a_hue_angle(i_CT,1).*average_L + a_hue_angle(i_CT,2);
            a_CL(i_CT,:)=CT_interpolation_data{i_nation, attribute}.a_CL_all_CT(i_CT,:);
            chroma_values(i_CT,1)=a_CL(i_CT,1).*log(average_L) + a_CL(i_CT,2);
        end                

        % 假设 interp_by_CT 函数已定义
        chroma_interp = interp_by_CT(CT, CT_values, chroma_values);
        hue_interp = interp_by_CT(CT, CT_values, hue_values);
        a_interp=chroma_interp.*cosd(hue_interp);
        b_interp=chroma_interp.*sind(hue_interp);
        par_out(4:5)=[a_interp,b_interp];
    end
end


%% --- 主脚本开始 ---
% 模特名称列表
new_names = [ "f04", "f05", "f06", "m04", "m05", "m06",...
              "f01", "f02", "f03", "m01", "m02", "m03",...
              "f07", "f08","m07", "m08",...
              "f09", "f10","m09", "m10"];
iOr='r';
% 颜色标签列表
if iOr=='i'
    pcn = ["H3K", "H4K", "H5K", "H6K", "HD65", "H7K", "H8K", ...
           "M3K", "M4K", "M5K", "M6K", "MD65", "M7K", "M8K", ...
           "L3K", "L4K", "L5K", "L6K", "LD65", "L7K", "L8K"];
else
    pcn = ["rs01","rs02","rs03","rs04","rs05","rs06","rs07", ...
                 "rs08","rs09","rs10","rs11","rs12","rs13","rs14"];
end

% 属性列表
attributes_to_process = [1,2,3,4,5,6,7,8,9,10];
attribute_names = ["Preference", "Attractiveness", "Feminine", "Cooperative", ...
                   "Youth", "Healthy", "Fidelity","Harmony", "Fair", "Ruddy"];
filtered_attribute_names = attribute_names(attributes_to_process);

% 固定参数
Dtype="efit_p_free";
scale_type_origin="unscaled";
obs_type="non_model";
n_colors=3;
hue_values = linspace(0, 1, n_colors + 1);
hue_values = hue_values(1:end-1); 
hsv_matrix = [hue_values', 0.8 * ones(n_colors, 1), 0.8 * ones(n_colors, 1)];
colors = hsv2rgb(hsv_matrix);
% --- 预加载数据 ---
% LUT (用于direct_scale中的白点缩放)
datai_file = '..\..\calibration\display_model\datai_ipv35_3.mat';
if exist(datai_file, 'file')
    LUT=load(datai_file);
    XYZw_LUT=LUT.XYZw;
else
    XYZw_LUT = [94.813, 100.000, 107.262]; % 默认白点
end

% render_map (平均L*和CCT)
load(fullfile("documents",iOr,"render_data2.mat"),"render_map");

% CT_interpolation_data (设置为全局变量供 apply_CT_interp 使用)
global CT_interpolation_data;
try
    load(fullfile("documents",Dtype,"CT_interpolation.mat"),'CT_interpolation_data');
catch
    warning('无法加载 CT_interpolation.mat。CT插值将失败。');
    CT_interpolation_data = cell(5, 10); % 占位符
end

% 定义绘图输出目录
fdQst_draw_folder = fullfile('..\..\data', 'correlation_results','ab_center_plots'); % 更改输出文件夹名称
if ~exist(fdQst_draw_folder, 'dir')
    mkdir(fdQst_draw_folder);
end

% 全参数文件路径
model_fupara_file=fullfile("..\..\data\ellipse_para\model_fullpara",Dtype,obs_type);
% direct_scale源文件路径基准
source_dir_base=fullfile("D:\work\VIVOskinExpe\analyze\AnalyseResults_p_free\" + ...
                    Dtype,"50\unscaled\nation1\scaled\non_model", iOr);

for i_model=1:length(new_names)
    current_model_name = new_names(i_model);
    % 模拟 lastPart 的计算
    lastPart = char(strcat(current_model_name,iOr)); 
    model = lastPart(1:end-1);
    
    % 确保模特绘图文件夹存在
    model_draw_folder = fullfile(fdQst_draw_folder, lastPart);
    if ~exist(model_draw_folder, 'dir')
        mkdir(model_draw_folder);
    end
    
    [nation,i_nation,nation_serial]=find_nation(model); % 获取人种信息
    
    fprintf('--- 正在处理模特: %s ---\n', current_model_name);
    
    for attribute_idx_in_list = 1:length(attributes_to_process)
        attribute = attributes_to_process(attribute_idx_in_list);
        current_attribute_name = attribute_names(attribute);
        attribute_serial = strcat(sprintf("%02d", attribute), current_attribute_name);
        
        % 加载全参数数据
        fullpara_file=fullfile(model_fupara_file, strcat(attribute_serial,"_all_curve_params.mat"));
        if ~exist(fullpara_file, 'file')
            warning('找不到全参数文件: %s，跳过此属性。', fullpara_file);
            continue;
        end
        fullpara_data=load(fullpara_file);
        
        % 封装参数结构体
        a_params.a_alpha=fullpara_data.a_alpha_all(i_nation,:);
        a_params.a_CL=fullpara_data.a_CL_all(i_nation,:);
        a_params.a_hue_angle=fullpara_data.a_hue_angle_all(i_nation,:);
        a_params.a_long_axis=fullpara_data.a_long_axis_all(i_nation,:);
        a_params.a_short_axis=fullpara_data.a_short_axis_all(i_nation,:);
        a_params.a_theta=fullpara_data.a_theta_all(i_nation,:);

        % 初始化绘图数据
        coords_direct_scale = NaN(length(pcn), 2); % 坐标1: direct_scale
        coords_use_i = NaN(length(pcn), 2);        % 坐标2: use_i
        coords_fit_res = NaN(length(pcn), 2);      % 坐标3: fitRes_data

        % 设置 labNscore 和 fitRes 的路径
        if attribute_idx_in_list==7
            obs_type_used="model_group";
        else
            obs_type_used=obs_type;
        end
        fitRes_file_base=fullfile("D:\work\VIVOskinExpe\analyze\AnalyseResults_p_free" ,...
            Dtype,scale_type_origin,lastPart,obs_type_used,attribute_serial,"ellipPara", ...
            strcat("fitRes.mat")); 
        
        % 尝试加载 fitRes 数据
        try
            fitRes_data=load(fitRes_file_base);
            par_all_exist = true;
        catch
            warning('找不到拟合结果文件: %s', fitRes_file_base);
            par_all_exist = false;
        end
        % --- 绘图部分 ---
        figure(attribute); % 确保图窗可见
        hold on;

        for i_par = 1:length(pcn)
            current_pcn_name = pcn(i_par);
            
            % 1. 获取拟合结果中的坐标 (坐标3)
            if par_all_exist && i_par <= size(fitRes_data.par_all, 1)
                coords_fit_res(i_par, :) = fitRes_data.par_all(i_par, 4:5);
            end

            % 获取平均L*和CCT
            curr_struct = render_map(strcat(lastPart,lower(pcn(i_par))));
            average_L = curr_struct.average(1); 
            CT = curr_struct.CCT_val;
            
            % 2. 初始模型参数 (未缩放，未插值)
            par_model_base = calculate_par_model(average_L, a_params);
            
            % 3. CT插值修正后的参数 (作为 rs_type="use_i" 的基础)
            par_CT_interp = apply_CT_interp(par_model_base, CT, i_nation, attribute, average_L, Dtype, pcn);
            
            % 坐标2: rs_type="use_i" (CT插值修正，无direct_scale)
            coords_use_i(i_par, :) = par_CT_interp(4:5);
            
            % 4. direct_scale 缩放逻辑 (对应 rs_type="direct_scale")
            par_direct_scale = par_CT_interp; % 以 CT 插值结果为起点
            
            if strcmp(iOr,'r') % 只有当 iOr='r' 时才进行 direct_scale 缩放
                source_folder_scale = fullfile(source_dir_base, attribute_serial, nation_serial);
                i_indices=find_indices(i_par,iOr);
                full_path_scale=fullfile(source_folder_scale,strcat(num2str(i_indices),".mat"));
                
                if exist(full_path_scale,"file")
                    data = load(full_path_scale); 
                    scene_par=data.par;
                    Lab_scene=[data.average_indices_curr(1),scene_par(4:5)];
                    
                    % 假设 lab2xyz2 和 xyz2lab 函数已定义
                    XYZ_scene=lab2xyz2(Lab_scene,"d65_64");
                    Lab_pre=[average_L,par_direct_scale(4:5)];
                    XYZ_pre=lab2xyz2(Lab_pre,"d65_64");
                    
                    % 缩放逻辑
                    XYZ_scene_scaled=XYZ_scene./XYZ_scene(2).*XYZ_pre(2);
                    Lab_scene_scaled=xyz2lab(XYZ_scene_scaled,"d65_64");
                    
                    par_direct_scale(4:5)=Lab_scene_scaled(2:3);
                else
                    % 如果 direct_scale 源文件缺失，则 direct_scale 结果与 use_i 相同
                    % warning('找不到 direct_scale 源文件: %s', full_path_scale);
                    % par_direct_scale 保持 par_CT_interp 的值
                end
            end
            
            % 坐标1: rs_type="direct_scale"
            coords_direct_scale(i_par, :) = par_direct_scale(4:5);
                        % 1. 绘制 rs_type="direct_scale" (坐标1) 

            text(coords_direct_scale(i_par, 1), coords_direct_scale(i_par, 2), ...
                 num2str(i_par), 'Color', colors(1,:), 'FontSize', ...
                 8, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
    
            % 2. 绘制 rs_type="use_i" (坐标2) 

            text(coords_use_i(i_par, 1), coords_use_i(i_par, 2), ...
                 num2str(i_par), 'Color', colors(2,:), 'FontSize', 8, ...
                 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top');
    
            % 3. 绘制 fitRes_data (坐标3) 

            text(coords_fit_res(i_par, 1), coords_fit_res(i_par, 2), ...
                 num2str(i_par), 'Color', colors(3,:), 'FontSize', 8, ...
                 'HorizontalAlignment', 'left', 'VerticalAlignment', 'top');

        end % end for i_par



        title(sprintf('Model: %s, Attribute: %s, L*: %.2f to %.2f', ...
              lastPart, current_attribute_name, min(curr_struct.average(:,1)), max(curr_struct.average(:,1))));
        xlabel('a*');
        ylabel('b*');
        grid on;
        axis equal; % 确保 a* 和 b* 的比例尺一致


        % 保存图片
        save_file_name = fullfile(model_draw_folder, strcat(attribute_serial, '.png'));
        saveas(gcf, save_file_name);
        close(gcf); % 关闭当前图窗
        
        fprintf('  - 属性 %s 的图表已保存到: %s\n', current_attribute_name, save_file_name);

    end % end for attribute
end % end for i_model

fprintf('\n所有绘图已完成并保存到 %s 文件夹结构中。\n', fdQst_draw_folder);