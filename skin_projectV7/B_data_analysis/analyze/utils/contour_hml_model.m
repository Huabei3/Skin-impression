% --- 单独的 Contour 绘制函数 ---
function plot_elliptical_contour(a_params, x_range, y_range, line_style, line_color, line_width, level_list, display_name)
% plot_elliptical_contour 绘制椭圆函数的等高线。
%   a_params: 椭圆函数参数 [a1, a2, a3, a4, a5, a6]
%   x_range: x轴的绘制范围 [xmin, xmax]
%   y_range: y轴的绘制范围 [ymin, ymax]
%   line_style: 线型 (e.g., '-', '--')
%   line_color: 颜色 (e.g., [R G B])
%   line_width: 线宽
%   level_list: 等高线水平 (e.g., [0.5, 1])
%   display_name: 图例名称

    a = a_params;
    f_handle = @(x,y) (1./(1+a(6)*exp(sqrt(a(1)*(x-a(4)).^2+a(2)*(y-a(5)).^2 + a(3)*(x-a(4)).*(y-a(5))))));
    
    % 确保只有当判别式非负时才计算平方根，否则为 NaN
    % 这将使得在椭圆外部的区域值为 NaN，fcontour 会自动忽略 NaN
    f_handle_safe = @(x,y) f_handle(x,y) .* ((a(1)*(x-a(4)).^2+a(2)*(y-a(5)).^2+a(3)*(x-a(4)).*(y-a(5))) >= 0);

    fcontour(f_handle_safe, [x_range(1) x_range(2) y_range(1) y_range(2)], ...
        'LevelList', level_list, ...
        'LineStyle', line_style, ...
        'Color', line_color, ...
        'LineWidth', line_width, ...
        'DisplayName', display_name);
end