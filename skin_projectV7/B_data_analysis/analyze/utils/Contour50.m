function Contour50(par, lab_group,MSV_group,variable,average_nations, ...
    color,line_style,plot_style,title_str)
    %准备PMCC
    nations = ["AS", "CA", "SA", "AF"];
    labCh_PMCC=[[62.11	18.96	19.76	27.39	46.18];...
            [64.15	19.56	19.63	27.71	45.10];...
            [56.01	18.25	18.72	26.14	45.72];...
            [41.06	17.37	17.94	24.97	45.93]];
    if strcmp(variable,"cluster_50")
        xyz_mean=lab2xyz2(average_nations,"d65_64");
        xyz_PMCC=lab2xyz2(labCh_PMCC(1:3),"d65_64");
        xyz_PMCC=xyz_PMCC./xyz_PMCC(2).*xyz_mean(2);
        labCh_PMCC_pre=xyz2lab(xyz_PMCC,"d65_64");
    else
        % for i_nation=1:length(nations)
        %     xyz_mean=lab2xyz2(average_nations(i_nation,:),"d65_64");
        %     % xyz_mean=lab2xyz2(average_nations(i_nation,:),"d65_64");
        %     xyz_PMCC=lab2xyz2(labCh_PMCC(i_nation,1:3),"d65_64");
        %     xyz_PMCC=xyz_PMCC./xyz_PMCC(2).*xyz_mean(2);
        %     labCh_PMCC_pre(i_nation,:)=xyz2lab(xyz_PMCC,"d65_64");
        % end
    end
    hue_values = linspace(0, 1, length(nations) + 1);hue_values = hue_values(1:end-1); 
    hsv_matrix = [hue_values', 0.8 * ones(length(nations), 1), 0.8 * ones(length(nations), 1)];
    colors = hsv2rgb(hsv_matrix);

    check_data2 = par(4) + (-30:0.2:30);
    check_data3 = par(5) + (-30:0.2:30);
    [data2, data3] = meshgrid(check_data2, check_data3);
    [row, col] = size(data2);

    % 计算等高线数据
    a = par;
    y = (1./(1+a(6)*exp(sqrt(a(1)*(data2-a(4)).^2+a(2)*(data3-a(5)).^2+ ...
        a(3)*(data2-a(4)).*(data3-a(5)))))).*((a(1)*(data2-a(4)).^2+ ...
        a(2)*(data3-a(5)).^2+a(3)*(data2-a(4)).*(data3-a(5)))>=0);
    
    % 绘制等高线
    s0 = contour(data2, data3, y, [0.5, 1], 'LineWidth', 1, ...
        'LineStyle', line_style, 'Color', color);
    hold on;
    % 绘制特殊点
    plot(par(4), par(5), plot_style, 'MarkerSize', 4, ...
        'MarkerFaceColor', color, 'Color', color);
    if strcmp(variable,"cluster_50")
        % plot(labCh_PMCC(2), labCh_PMCC(3), 's', 'MarkerSize', 5, ...
        %     'MarkerFaceColor', color, 'MarkerEdgeColor',color);
        % plot(labCh_PMCC_pre(2), labCh_PMCC_pre(3), 's', 'MarkerSize', 5, ...
        %     'MarkerFaceColor', 'none', 'MarkerEdgeColor', color);
    else
        for i_nation=1:length(nations)
            % plot(labCh_PMCC(i_nation,2), labCh_PMCC(i_nation,3), 's', 'MarkerSize', 5, ...
            %     'MarkerFaceColor', 'none', 'MarkerEdgeColor', colors(i_nation,:));
            % plot(labCh_PMCC_pre(i_nation,2), labCh_PMCC_pre(i_nation,3), 's', 'MarkerSize', 5, ...
            %     'MarkerFaceColor', 'none', 'MarkerEdgeColor', colors(i_nation,:));
        end
    end


    % 设置坐标轴标签和标题
    xlabel('\textit{a*}', 'Interpreter', 'latex', 'FontSize', 12*2);
    ylabel('\textit{b*}', 'Interpreter', 'latex', 'FontSize', 12*2);
    % 设置标题为斜体
    title(title_str,  'FontSize', 12*2);
    % 设置坐标轴范围和参考线
    % lim_max = max(max(lab_group(:,2)), max(lab_group(:,3))) + 15;
    % lim_min = min(min(lab_group(:,2)), min(lab_group(:,3))) - 15;

    if strcmp(variable,"nation1")
        lim_max=40;
        lim_min=-5;
    else
        lim_max = max(par(4), par(5)) + 35;
        lim_min = min(par(4), par(5)) - 35;
    end
    



    % 设置图形属性
    hold on;
    axis equal;
    xlim([lim_min, lim_max]);
    ylim([lim_min, lim_max]);

end