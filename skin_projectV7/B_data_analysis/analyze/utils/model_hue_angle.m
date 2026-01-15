% 色调角建模函数 (线性函数)
function [r_val, a_val,RMSE] = model_hue_angle(output_folder,L_data, hue_angle_data, attribute_serial, nation_color, line_style, Dtype, iOr, i_nation)
    r_val = NaN;
    a_val = NaN(1, 2);
    RMSE=NaN;

    valid_indices = ~isnan(L_data) & ~isnan(hue_angle_data);
    L_valid = L_data(valid_indices);
    hue_angle_valid = hue_angle_data(valid_indices);

    if length(L_valid) > 2 % 线性函数需要至少 2 个点
        f = @(a, xdata)(a(1).*xdata + a(2));

        rmax = -inf;
        afinal = [NaN, NaN];
        RMSE=NaN;
        for t = 1:500
            a0 = rand(1, 2);
            options = optimset('MaxFunEvals', 200000, 'Display', 'off');
            try
                a = lsqcurvefit(f, a0, L_valid, hue_angle_valid, [-inf,-inf], [inf,inf], options);
                y = f(a, L_valid);
                r = corr(y, hue_angle_valid);
                % 均方误差（MSE）
                if r > rmax
                    rmax = r;
                    afinal = a;
                    RMSE = sqrt(mean((hue_angle_valid - y).^2))./mean(hue_angle_valid);   
                end
            catch
                continue;
            end
        end

        r_val = rmax;
        a_val = afinal;

        h = figure(400 + i_nation);
        set(h, 'Name', ['Hue Angle - ' char(attribute_serial) ' - ' num2str(i_nation)], 'NumberTitle', 'off');
        hold on;
        set(gcf, 'Color', 'white');

        if ~any(isnan(afinal))
            x_plot = min(L_valid):0.1:max(L_valid);
            y_plot = f(afinal, x_plot);
            plot(x_plot, y_plot, 'Color', nation_color, 'LineWidth', 1, 'LineStyle', line_style);
        end
        scatter(L_valid, hue_angle_valid, 20, nation_color, 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 0.5);
        ylabel('h', 'FontSize', 12, 'FontAngle', 'italic');
        xlabel('L^*', 'FontSize', 12, 'FontAngle', 'italic');
        ylim([0,max(hue_angle_valid)+10])
        title([ 'h - L^*'], 'FontSize', 14);
        grid on;


        exportgraphics(h, fullfile(output_folder, strcat(attribute_serial, '_nation_', num2str(i_nation), '.jpg')), 'Resolution', 300);
        close(h);
    end
end
