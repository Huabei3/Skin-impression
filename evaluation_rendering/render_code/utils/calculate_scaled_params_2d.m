function [r_original, r_scaled, de_original, de_scaled, y_original, y_scaled,cen_scaled_lab] = calculate_scaled_params_2d(par_original, cen_summer,points_data, scores_data, dims_OPPO, ref_cen_lab, fit_type, ref_scale_lab)
    % 输入参数说明：
    % par_original: 原始拟合参数（如par_david/par_cherry/par_summer）
    % points_data: 待评价的lab点集（如points_Peggy_OPPO）
    % scores_data: 主观评分数据（如scores_Peggy_OPPO）
    % dims_OPPO: 维度索引（如dims_OPPO）
    % ref_cen_lab: 参考中心lab坐标（如par_Peggy_OPPO(1,5:6)）
    % fit_type: 拟合类型字符串（如"ellipsoidfit4"/"ellipsoidfit3_1"）
    
    % 1. 提取原始中心并缩放
    cen_original_lab=cen_summer;
    % cen_original_lab = par_original(1,5:6);
    xyz_cen_original = lab2xyz2(cen_original_lab, "d65_64");
    if nargin < 8 || isempty(ref_scale_lab)
        ref_scale_lab = ref_cen_lab;
    end
    ref_scale_xyz = lab2xyz2(ref_scale_lab,"d65_64");
    
    % 缩放逻辑：Y通道归一化（修正原脚本未定义变量bug）
    xyz_cen_scaled = xyz_cen_original ./ xyz_cen_original(2) .* ref_scale_xyz(2); 
    cen_scaled_lab = xyz2lab(xyz_cen_scaled, "d65_64");
    
    % 2. 更新参数
    par_scaled = par_original;
    par_scaled(1,5:6) = cen_scaled_lab(1,2:3);
    
    % 3. 计算原始y值、相关性、色差（一次性计算，避免重复）
    y_original = cal_y(par_original, points_data, fit_type);
    [r_original, ~] = corr(y_original(dims_OPPO(1,:),1), scores_data(dims_OPPO(1,:),1), 'Type', 'Pearson');
    de_original = deltaE2000(cen_original_lab, ref_cen_lab);
    
    % 4. 计算缩放后y值、相关性、色差
    y_scaled = cal_y(par_scaled, points_data, fit_type);
    [r_scaled, ~] = corr(y_scaled(dims_OPPO(1,:),1), scores_data(dims_OPPO(1,:),1), 'Type', 'Pearson');
    de_scaled = deltaE2000(cen_scaled_lab, ref_cen_lab);
end
