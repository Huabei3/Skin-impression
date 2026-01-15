function par_adjusted = get_par_fr_SF(average_L, a_scale, a_CL, all_par)
% get_par_fr_SF 计算经过亮度和中心补偿后的椭圆参数。
% 此版本旨在“反向”调整参数，以使最终函数输出等效于原始函数乘以 scale_factor。
%
%   输入:
%     average_L: 当前图像的平均 L* 值。
%     a_scale: 从拟合曲线得到的缩放参数 a_scale。
%     a_CL: 从亮度补偿曲线得到的参数 a_CL。
%     all_par: 包含基准椭圆参数的 cell 数组 (all_par{1} 为基准参数)。
%
%   输出:
%     par_adjusted: 经过调整后的椭圆参数数组。

    % 1. 输入参数校验 (替代了文件加载和字段检查)
    if isempty(all_par) || ~iscell(all_par) || isempty(all_par{1}) || ~isnumeric(all_par{1})
        error('get_par_fr_SF:InvalidInput', 'all_par 结构不正确或 all_par{1} 为空或不是数值数组。');
    end
    if ~isnumeric(a_scale) || length(a_scale) < 2
        error('get_par_fr_SF:InvalidInput', 'a_scale 必须是包含至少两个元素的数值数组。');
    end
    if ~isnumeric(a_CL) || length(a_CL) < 2
        error('get_par_fr_SF:InvalidInput', 'a_CL 必须是包含至少两个元素的数值数组。');
    end
    
    % 获取原始基准参数 (即 all_par cell 数组的第一个元素)
    a1_base_original = all_par{1}; 
    
    % 2. 计算 scale_factor_val (用于反向调整 par(6))
    scale_factor_val = a_scale(1) .* log(average_L) + a_scale(2);

    % 防止 scale_factor_val 接近于零，以避免除以零的错误
    if abs(scale_factor_val) < eps 
        warning('get_par_fr_SF:DegenerateScaleFactor', '计算出的 scale_factor_val 接近于零 (%f)。这可能会导致除以零或无穷大值。', scale_factor_val);
        if scale_factor_val == 0
            scale_factor_val = eps; 
        end
    end

    % 3. 首先补偿 a1_base_original 的中心坐标 (a*, b*)
    par_adjusted = a1_base_original; % 从原始基准参数开始

    C_aft = (a_CL(1) .* log(average_L) + a_CL(2));
    
    % C_bf 代表原始基准中心到原点的距离。
    C_bf = sqrt(a1_base_original(4).^2 + a1_base_original(5).^2); 

    if C_bf ~= 0 
        par_adjusted(4:5) = a1_base_original(4:5) .* (C_aft ./ C_bf); 
    else
        fprintf('警告：基准中心在原点 (L*=%f)。中心补偿无法按比例进行。中心坐标将保持不变。\n', average_L);
    end
    
    % 4. 然后反向调整 par_adjusted(6)
    % 假设原始函数 f_base 乘以 scale_factor_val 等于 f_target。
    % 目标是找到 par_adjusted(6) 使得 f_adjusted(par_adjusted) = f_target。
    % 所以 par_adjusted(6) 应该被 scale_factor_val 除以。
    par_adjusted(6) = par_adjusted(6) ./ scale_factor_val;
    
    % par_adjusted(1:3) 保持不变 (它们是椭圆形状参数，不受整体乘数影响)
    % par_adjusted(4:5) 已经通过 C_aft/C_bf 调整
end