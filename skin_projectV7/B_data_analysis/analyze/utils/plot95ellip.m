function  f=plot95ellip(center,mu,Lab,rho,output_folder,lastPart)       
%-----绘制椭球------
    lab_PMCC=[62.11,18.96,19.76];
    [a_grid, b_grid, L_grid] = meshgrid(linspace(center(2) - 10, center(2) + 10, 100), ...
                                    linspace(center(3) - 10, center(3) + 10, 100), ...
                                    linspace(center(1) - 10, center(1) + 10, 100));    
    % 定义 xdata
    xdata = [a_grid(:), b_grid(:), L_grid(:)];
    
    % 计算 y 的值
    f=mu(1).*(xdata(:,3)-center(1)).^2+...
    mu(2).*(xdata(:,3)-center(1)).*(xdata(:,1) -center(2))+...
    mu(3).*(xdata(:,3)-center(1)).*(xdata(:,2)-center(3))+...
    mu(4).*(xdata(:,1) -center(2)).^2+...
    mu(5).*(xdata(:,1) -center(2)).*(xdata(:,2)-center(3))+...
    mu(6).*(xdata(:,2)-center(3)).^2;

    % temp = sqrt(a(1)*(xdata(:,3)-a(5)).^2 + a(2)*(xdata(:,1)-a(6)).^2 + ...
    %             a(3)*(xdata(:,2)-a(7)).^2 + a(4)*(xdata(:,1)-a(6)).*(xdata(:,2)-a(7)));
    % f = (1./(1 + a(8)*exp(temp))) .* (a(1)*(xdata(:,3)-a(5)).^2 + ...
    %     (a(2)*(xdata(:,1)-a(6)).^2 + a(3)*(xdata(:,2)-a(7)).^2 + ...
    %     a(4)*(xdata(:,1)-a(6)).*(xdata(:,2)-a(7))) >= 0);
    
    % 将 y 的值重塑为与网格匹配的形状
    f = reshape(f, size(a_grid));
    
    scatter_L = Lab(:,1);
    scatter_a = Lab(:,2);
    scatter_b = Lab(:,3);
    
    % 绘制椭球等值面
    figure(4);
    % figure('Position', [100, 100, 1200, 800]); % 调整图窗尺寸
    subplot('Position', [0.1, 0.3, 0.8, 0.6]); % 调整绘制区域位置和尺寸
    p = patch(isosurface(a_grid, b_grid, L_grid, f, rho)); % 选择合适的阈值 1 绘制等值面
    isonormals(a_grid, b_grid, L_grid, f, p);
    set(p, 'FaceColor', 'cyan', 'EdgeColor', 'none', 'FaceAlpha', 0.3); % 设置透明度为0.3
    xlabel('a');
    ylabel('b');
    zlabel('L');
    % title(picname_type(i_types));
    daspect([1 1 1]); % 统一三个坐标轴的单位长度
    grid on;
    hold on;
    
    % 绘制散点图，并根据数值大小调整颜色
    scatter3(scatter_a, scatter_b, scatter_L, 10, 'filled');

    % 添加椭球中心
    plot3(center(2), center(3), center(1), 'p', 'MarkerSize', 5, 'MarkerFaceColor', 'r');
    %添加lab_PMCC
    plot3(lab_PMCC(2), lab_PMCC(3), lab_PMCC(1), 's', 'MarkerSize', 15, ...
        'MarkerFaceColor', [1, 0.4, 0.8], 'MarkerEdgeColor', [1, 0.4, 0.8]);

    % 在图下方空白区域添加椭球中心坐标和 center0_render
    annotation('textbox', [0.1, 0.1, 0.8, 0.1], 'String', ...
        sprintf('\x2605 Ellipsoid Center: [%.2f, %.2f, %.2f]\n\x25A0 PMCC: [%.2f, %.2f, %.2f]', ...
        center(1), center(2), center(3), lab_PMCC(1),lab_PMCC(2),lab_PMCC(3)), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'BackgroundColor', 'white', 'EdgeColor', 'black', 'FontSize', 8);
    
   
    % 设置视角和渲染模式
    view(3);
    camlight;
    lighting gouraud;
    
    hold off;
    saveas(gcf,fullfile(output_folder,strcat(lastPart,"ellipsoid.jpg")));
 end