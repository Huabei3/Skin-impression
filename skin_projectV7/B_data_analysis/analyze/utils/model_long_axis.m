% 长轴建模函数 (三次函数)
function [r_val, a_val,RMSE] = model_long_axis(output_folder,L_data, long_axis_data, attribute_serial, nation_color, line_style, Dtype, iOr, i_nation)
    r_val = NaN;
    a_val = NaN(1, 4);
    RMSE=NaN;

    valid_indices = ~isnan(L_data) & ~isnan(long_axis_data);
    L_valid = L_data(valid_indices);
    long_axis_valid = long_axis_data(valid_indices);

    if length(L_valid) > 4 % 三次函数需要至少 4 个点
        f = @(a, xdata)(a(1).*xdata.^3 + a(2).*xdata.^2 + a(3).*xdata + a(4));

        rmax = -inf;
        afinal = [NaN, NaN, NaN, NaN];
        RMSE=NaN;
        for t = 1:500
            a0 = rand(1, 4);
            options = optimset('MaxFunEvals', 200000, 'Display', 'off');
            try
                a = lsqcurvefit(f, a0, L_valid, long_axis_valid, [-inf,-inf,-inf,-inf], [inf,inf,inf,inf], options);
                y = f(a, L_valid);
                r = corr(y, long_axis_valid);
                if r > rmax
                    rmax = r;
                    afinal = a;
                    RMSE = sqrt(mean((long_axis_valid - y).^2))./mean(long_axis_valid); 
                end
            catch
                continue;
            end
        end

        r_val = rmax;
        a_val = afinal;

        h = figure(200 + i_nation);
        set(h, 'Name', ['Long Axis - ' char(attribute_serial) ' - ' num2str(i_nation)], 'NumberTitle', 'off');
        hold on;
        set(gcf, 'Color', 'white');

        if ~any(isnan(afinal))
            x_plot = min(L_valid):0.1:max(L_valid);
            y_plot = f(afinal, x_plot);
            plot(x_plot, y_plot, 'Color', nation_color, 'LineWidth', 1, 'LineStyle', line_style);
        end
        scatter(L_valid, long_axis_valid, 20, nation_color, 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 0.5);
        ylabel('Long Axis Length', 'FontSize', 12);
        xlabel('L^*', 'FontSize', 12, 'FontAngle', 'italic');
        title([ 'Long Axis - L^*'], 'FontSize', 14);
        grid on;


        exportgraphics(h, fullfile(output_folder, strcat(attribute_serial, '_nation_', num2str(i_nation), '.jpg')), 'Resolution', 300);
        close(h);
    end
end
