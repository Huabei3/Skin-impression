function contour95ellip(center, mu, lab_group, rho, color,line_style,plot_style, ...
    variable,ori_lab_mean,h,average_nations,title_str)
    nations = ["AS", "CA", "SA", "AF"];
    labCh_PMCC=[[62.11	18.96	19.76	27.39	46.18];...
            [64.15	19.56	19.63	27.71	45.10];...
            [56.01	18.25	18.72	26.14	45.72];...
            [41.06	17.37	17.94	24.97	45.93]];
    for i_nation=1:length(nations)
        xyz_mean=lab2xyz2(average_nations(i_nation,:),"d65_64");
        xyz_PMCC=lab2xyz2(labCh_PMCC(i_nation,1:3),"d65_64");
        xyz_PMCC=xyz_PMCC./xyz_PMCC(2).*xyz_mean(2);
        labCh_PMCC_pre(i_nation,:)=xyz2lab(xyz_PMCC,"d65_64");
    end
    hue_values = linspace(0, 1, length(nations) + 1);hue_values = hue_values(1:end-1); 
    hsv_matrix = [hue_values', 0.8 * ones(length(nations), 1), 0.8 * ones(length(nations), 1)];
    colors = hsv2rgb(hsv_matrix);
    scatter_L = lab_group(:, 1);
    scatter_a = lab_group(:, 2);
    scatter_b = lab_group(:, 3);
    scatter_C = sqrt(lab_group(:, 2).^2+lab_group(:, 3).^2);
    scatter_h = atan2d(lab_group(:, 2),lab_group(:, 3));
    center(4)=sqrt(center(2).^2+center(3).^2);
    ori_lab_mean(4)=sqrt(ori_lab_mean(2).^2+ori_lab_mean(3).^2);



    % a-b
    grid on;box on;hold on;
    
    check_data2 = center(2) + (-20:0.2:20);
    check_data3 = center(3) + (-20:0.2:20);
    [data2, data3] = meshgrid(check_data2, check_data3);

    % 计算 f 的值
    f = mu(1) .* (data2 - center(2)).^2 + ...
        mu(2) .* (data2 - center(2)) .* (data3 - center(3)) + ...
        mu(3) .* (data3 - center(3)).^2;
    if ~strcmp(variable,"models")
        contour(data2, data3, f, [0, rho], 'Linewidth', 1, 'Color', color,'LineStyle', line_style);
    end
    

    % scatter
    scatter(ori_lab_mean(2), ori_lab_mean(3), 20, '+', 'LineWidth', 1, ...
        'MarkerEdgeColor',color);


    % 标注中心
    plot(center(2), center(3), plot_style, 'MarkerSize', 4, 'MarkerFaceColor', color, 'Color', color);
    for i_nation=1:length(nations)
        plot(labCh_PMCC(i_nation,2), labCh_PMCC(i_nation,3), 's', 'MarkerSize', 5, ...
            'MarkerFaceColor', colors(i_nation,:), 'MarkerEdgeColor', colors(i_nation,:));
        % plot(labCh_PMCC_pre(i_nation,2), labCh_PMCC_pre(i_nation,3), 's', 'MarkerSize', 5, ...
        %     'MarkerFaceColor', 'none', 'MarkerEdgeColor', colors(i_nation,:));
    end

    % 设置 xlabel 和 ylabel 为斜体
    xlabel('\textit{a*}', 'Interpreter', 'latex', 'FontSize', 12*2);
    ylabel('\textit{b*}', 'Interpreter', 'latex', 'FontSize', 12*2);

    % 设置标题为斜体
    title(title_str,  'FontSize', 12*2);

    % 设置坐标轴范围
    axis equal;
    % if strcmp(variable,"gender")
        max_lim = 30;
        min_lim = 0;
    % elseif strcmp(variable,"scene")
    %     max_lim = 35;
    %     min_lim = 0;
    % end
    x = linspace(min_lim, max_lim, 1000);
    y = x;
    plot(x, y);
    
    hAx1 = findobj(h, 'Type', 'axes'); 
    interval=5;
    xticks(min_lim:interval:max_lim)
    yticks(min_lim:interval:max_lim)
    xlim([min_lim, max_lim]);
    ylim([min_lim, max_lim]);
    
    hold on;
    

  
end