function [C_all, alpha_values,  theta, long_axis, short_axis, hue_angle] = calculate_ellipse_parameters(par_all_valid)
    % calculate_ellipse_parameters 计算椭圆参数和色调角
    %
    % 输入:
    %   par_all_valid - 包含椭圆参数的矩阵，每行代表一个椭圆。
    %                   列顺序应为 [par1, par2, par3, par4, par5, par6]。
    %
    % 输出:
    %   C_all        - 向量，每个椭圆的C值。
    %   alpha_values - 向量，每个椭圆的alpha值。
    %   lambda00     - 向量，椭圆协方差矩阵的(0,0)元素。
    %   lambda01     - 向量，椭圆协方差矩阵的(0,1)元素。
    %   lambda10     - 向量，椭圆协方差矩阵的(1,0)元素。
    %   lambda11     - 向量，椭圆协方差矩阵的(1,1)元素。
    %   theta        - 向量，椭圆的倾角（度）。
    %   long_axis    - 向量，椭圆的长轴长度。
    %   short_axis   - 向量，椭圆的短轴长度。
    %   hue_angle    - 向量，每个椭圆的色调角（度）。

    % 计算 C 值
    C_all = sqrt(par_all_valid(:,4).^2 + par_all_valid(:,5).^2);

    % 计算 alpha 值并处理无效值
    alpha_values = -log(par_all_valid(:,6));
    alpha_values(isinf(alpha_values) | isnan(alpha_values)) = NaN;

    % 计算协方差矩阵元素
    lambda00 = par_all_valid(:, 1) ./ alpha_values.^2;
    lambda01 = par_all_valid(:, 3) ./ alpha_values.^2 ./ 2;
    lambda10 = par_all_valid(:, 3) ./ alpha_values.^2 ./ 2;
    lambda11 = par_all_valid(:, 2) ./ alpha_values.^2;

    % 计算椭圆倾角
    theta = 0.5 * atan2d(2 * lambda01, (lambda00 - lambda11));
    theta = mod(theta, 360);

    % 计算长短轴
    A = lambda00 .* cosd(theta).^2 - lambda01 .* sind(2 * theta) + lambda11 .* sind(theta).^2;
    B = lambda00 .* sind(theta).^2 + lambda01 .* sind(2 * theta) + lambda11 .* cosd(theta).^2;
    
    % 检查并处理 A 和 B 的负值或非实数
    A(A <= 0) = NaN;
    B(B <= 0) = NaN;
    
    long_axis = sqrt(1 ./ A);
    short_axis = sqrt(1 ./ B);

    % 计算色调角
    hue_angle = atan2d(par_all_valid(:, 5), par_all_valid(:, 4));
    hue_angle = mod(hue_angle, 360);
end