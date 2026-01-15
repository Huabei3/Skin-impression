% alpha 建模函数 (线性函数)
function [r_val, a_val,RMSE] = model_alpha(output_folder,L_data, alpha_data, attribute_serial, nation_color, line_style, Dtype, iOr, i_nation)
    r_val = NaN;
    a_val = NaN(1, 2);
    RMSE=NaN;
    valid_indices = ~isnan(L_data) & ~isnan(alpha_data);
    L_valid = L_data(valid_indices);
    alpha_valid = alpha_data(valid_indices);

    if length(L_valid) > 1 % 线性函数至少需要 2 个点
        f = @(a, xdata)(a(1).*xdata + a(2));
        rmax = -inf;
        afinal = [NaN, NaN];
        RMSE=NaN;
        
        % 增加迭代次数以提高拟合成功率
        for t = 1:500 
            a0 = rand(1, 2); % 随机初始化参数
            options = optimset('MaxFunEvals', 200000, 'Display', 'off');
            try
                % 使用 lsqcurvefit 进行非线性最小二乘拟合
                a = lsqcurvefit(f, a0, L_valid, alpha_valid, [-inf,-inf], [inf,inf], options);
                y = f(a, L_valid);
                % 计算相关系数
                r = corr(y, alpha_valid);
                if r > rmax
                    rmax = r;
                    afinal = a;
                    RMSE = sqrt(mean((alpha_valid - y).^2))./mean(alpha_valid);  
                end
            catch
                % 捕获拟合失败的错误，继续下一次迭代
                continue;
            end
        end
        r_val = rmax;
        a_val = afinal;

        % 绘图
        h = figure(500 + i_nation); % 为 alpha 建模使用不同的图窗编号
        set(h, 'Name', ['Alpha - ' char(attribute_serial) ' - ' num2str(i_nation)], 'NumberTitle', 'off');
        hold on;
        set(gcf, 'Color', 'white');

        if ~any(isnan(afinal))
            x_plot = min(L_valid):0.1:max(L_valid);
            y_plot = f(afinal, x_plot);
            plot(x_plot, y_plot, 'Color', nation_color, 'LineWidth', 1, 'LineStyle', line_style);
        end
        scatter(L_valid, alpha_valid, 20, nation_color, 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 0.5);
        ylabel('\alpha', 'FontSize', 12, 'FontAngle', 'italic');
        xlabel('L^*', 'FontSize', 12, 'FontAngle', 'italic');
        ylim([0,5])
        title(['\alpha - L^*'], 'FontSize', 14);
        grid on;


        exportgraphics(h, fullfile(output_folder, strcat(attribute_serial, '_nation_', num2str(i_nation), '.jpg')), 'Resolution', 300);
        close(h);
    end
end