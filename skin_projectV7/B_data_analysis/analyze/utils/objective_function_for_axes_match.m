function cost = objective_function_for_axes_match(scale_factor_val, a1_base, a_CL, average_L, A_target, B_target)
% objective_function_for_axes_match 优化目标函数，使调整后的椭圆轴长平均值接近目标值。
%   sf: 当前迭代的 scale_factor 值。
%   a1_base: 原始基准椭圆参数。
%   a_CL: 亮度补偿参数 (从 C_L_data.a_CL_all 加载)。
%   average_L: 当前图像的平均 L* 值。
%   A_target, B_target: 目标椭圆（当前 hml 椭圆）的长轴和短轴。

    % 1. 创建一个临时的椭圆参数，从基准参数开始
    par_adjusted = a1_base; 

    % 2. 应用亮度补偿到椭圆中心 (a*, b*)
    % 这一步与 get_par_fr_SF 中的亮度补偿逻辑相同。
    C_aft = (a_CL(1) .* log(average_L) + a_CL(2));
    C_bf = sqrt(a1_base(4).^2 + a1_base(5).^2); 
    if C_bf ~= 0 && ~isnan(C_bf) && ~isinf(C_bf)
        par_adjusted(4:5) = a1_base(4:5) .* (C_aft ./ C_bf); 
    end
    
    % 3. 应用当前 scale_factor_val 到 par(6)
    % 我们的目标是调整 par(6) 来改变椭圆的大小。
    % 在您的原始代码中，f1 的等高线是 f1_base_func(x,y) .* scale_factor_values(i_hml)。
    % 这意味着 par(6) 应该是 par_base(6) / scale_factor_val。
    if scale_factor_val ~= 0 && ~isnan(scale_factor_val) && ~isinf(scale_factor_val)
        par_adjusted(6) = par_adjusted(6) ./ scale_factor_val;
    else
        % 如果 scale_factor_val 无效（例如为零或非数字），则返回一个很大的成本
        cost = Inf;
        return;
    end

    % 4. 计算调整后椭圆的轴长
    % 确保 calculate_ellipse_axes_from_par 函数在 MATLAB 路径中
    [A_opt, B_opt, ~] = calculate_ellipse_axes_from_par(par_adjusted);

    % 5. 计算目标函数值 (最小化轴长平均值的平方差)
    if isnan(A_opt) || isnan(B_opt)
        % 如果计算出的轴长无效（例如不是真实的椭圆），则给予最大惩罚
        cost = Inf; 
    else
        % 计算目标椭圆和优化后椭圆的平均轴长
        target_avg_axis = (A_target + B_target) / 2;
        opt_avg_axis = (A_opt + B_opt) / 2;
        
        % 成本函数：平均轴长差异的平方
        cost = (target_avg_axis - opt_avg_axis)^2;
        
        % 您也可以根据需要尝试其他成本函数，例如：
        % cost = abs(target_avg_axis - opt_avg_axis); % 绝对误差
        % cost = (A_target - A_opt)^2 + (B_target - B_opt)^2; % A和B分别的平方误差和
    end
end