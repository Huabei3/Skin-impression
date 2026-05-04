function [y,par,characteristics] = predict_my(L,lab_group,i_nation,attribute_serial,ablation_type,scene_idx)
% PREDICT_MY  STIM肤色印象预测函数
%   [y,par,characteristics] = predict_my(L,lab_group,i_nation,attribute_serial)
%   [y,par,characteristics] = predict_my(L,lab_group,i_nation,attribute_serial,ablation_type,scene_idx)
%
% 输入:
%   L              - 明度标量
%   lab_group      - Nx3 Lab值矩阵
%   i_nation       - 人种索引 (1=Asian, 2=Caucasian, 3=South Asian, 4=African)
%   attribute_serial - 属性序列号，如 "01Preference"
%   ablation_type  - (可选) 消融实验类型，默认 ""
%                     "scene_types" 时根据场景类别增加increment
%   scene_idx      - (可选) 场景索引 (1-14 对应 rs01-rs14)，仅 scene_types 时使用
%
% 输出:
%   y              - 预测印象值
%   par            - 椭圆参数 [a1,a2,a3,a4,a5,a6]
%   characteristics - [chroma, hue_angle, long_axis, short_axis, theta, alpha]

    version="new";
    obs_type="non_model";
    model_fupara_file=fullfile("D:\work\VIVOskinExpe\analyze\AnalyseResults_p\" , ...
        "efit_p\unscaled\model_fullpara\d65",version,"i", obs_type);

    % 默认参数处理
    if nargin < 5 || isempty(ablation_type)
        ablation_type = "";
    end
    if nargin < 6 || isempty(scene_idx)
        scene_idx = [];
    end

    fullpara_data=load(fullfile(model_fupara_file, ...
        strcat(attribute_serial,"_all_curve_params.mat")));
    
    a_alpha=fullpara_data.a_alpha_all(i_nation,:);
    a_CL=fullpara_data.a_CL_all(i_nation,:);
    a_hue_angle=fullpara_data.a_hue_angle_all(i_nation,:);
    a_long_axis=fullpara_data.a_long_axis_all(i_nation,:);
    a_short_axis=fullpara_data.a_short_axis_all(i_nation,:);
    a_theta=fullpara_data.a_theta_all(i_nation,:);
    if strcmp(version,"new")
        hue_angle=a_hue_angle(1);
        chroma=a_CL(1).*log(L) + a_CL(2);
        long_axis=a_long_axis(1).*L.^3 + a_long_axis(2).*L.^2 +...
            a_long_axis(3).*L + a_long_axis(4);
        short_axis=a_short_axis(1).*L.^3 + a_short_axis(2).*L.^2 +...
            a_short_axis(3).*L + a_short_axis(4);
        theta=a_theta(1);
        alpha=a_alpha(1);
    else
        hue_angle=a_hue_angle(1).*L + a_hue_angle(2);
        chroma=a_CL(1).*log(L) + a_CL(2);
        long_axis=a_long_axis(1).*L.^3 + a_long_axis(2).*L.^2 +...
            a_long_axis(3).*L + a_long_axis(4);
        short_axis=a_short_axis(1).*L.^3 + a_short_axis(2).*L.^2 +...
            a_short_axis(3).*L + a_short_axis(4);
        theta=a_theta(1).*L + a_theta(2);
        alpha=a_alpha(1).*L + a_alpha(2);
    end
    characteristics=[chroma,hue_angle,long_axis,short_axis,theta,alpha];
    [par] = calculate_par_from_ellipse(hue_angle, chroma, ...
            long_axis, short_axis, theta, alpha);

    % ========== scene_types: 根据场景类别增加 increment ==========
    if strcmp(ablation_type, "scene_types") && ~isempty(scene_idx)
        nation_names=["Asian","Caucasian","South Asian","African"];
        nation_serial=sprintf("%02d%s",i_nation,nation_names(i_nation));

        % 从 attribute_serial 提取属性编号和名称
        if length(attribute_serial) >= 2
            attribute = str2double(attribute_serial(1:2));
        else
            attribute = str2double(attribute_serial);
        end
        attribute_names = ["Preference", "Attractiveness", "Feminine", "Cooperative", ...
                           "Youth", "Healthy", "Fidelity","Harmony", "Fair", "Ruddy"];

        % scene_type_indices 定义（对应 rs01-rs14 的分组）
        scene_type_indices{1} = [1, 2, 4, 5, 6];   % indoor
        scene_type_indices{2} = [3, 7, 8, 10, 12]; % outdoor
        scene_type_indices{3} = [13, 14];          % night
        scene_type_indices{4} = [9, 11];            % 另一分组
        n_scene_type = length(scene_type_indices);

        % rela_increment 数据路径
        rela_data_base_path = fullfile("D:\work\VIVOskinExpe\analyze\AnalyseResults_p", ...
            "efit_p", "scaled", "contour_scene_type", "non_model");
        rela_file = fullfile(rela_data_base_path, ...
            attribute_serial, ...
            strcat(nation_serial, ".mat"));

        if exist(rela_file, 'file')
            rela_data = load(rela_file);
            % 找到当前 scene_idx 所属的 scene_type
            i_scene_type = [];
            for st_idx = 1:n_scene_type
                if ismember(scene_idx, scene_type_indices{st_idx})
                    i_scene_type = st_idx;
                    break;
                end
            end

            if ~isempty(i_scene_type) && isfield(rela_data, 'rela_incre')
                % rela_incre: n_scene_type × 3 (L*, a*, b*)
                delta_a = rela_data.rela_incre(i_scene_type, 2) / 100;
                delta_b = rela_data.rela_incre(i_scene_type, 3) / 100;
                par(4) = par(4) * (1 + delta_a);  % a* 平移
                par(5) = par(5) * (1 + delta_b);  % b* 平移
            end
        end
    end

    y = calculate_y(lab_group(:,2), lab_group(:,3), par); 
end
