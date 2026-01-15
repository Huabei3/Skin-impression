function [r_val, a_val,RMSE] = model_theta(output_folder,L_data, theta_data, attribute_serial, nation_color, line_style, Dtype, iOr, i_nation)
    r_val = NaN;
    a_val = NaN(1, 2);
    RMSE=NaN;

    valid_indices = ~isnan(L_data) & ~isnan(theta_data);
    L_valid = L_data(valid_indices);
    theta_valid = theta_data(valid_indices);

    % --- NEW CODE START ---
    % Calculate the mean of theta_valid
    mean_theta = mean(theta_valid);

    % Identify indices where theta_valid is greater than or equal to 1/7th of its mean
    filtered_indices = theta_valid >= (mean_theta / 7);

    % Apply the filter to L_valid and theta_valid
    L_valid = L_valid(filtered_indices);
    theta_valid = theta_valid(filtered_indices);
    % --- NEW CODE END ---

    if length(L_valid) > 2
        f = @(a, xdata)(a(1).*xdata + a(2));
        rmax = -inf;
        afinal = [NaN, NaN];
        RMSE=NaN;

        for t = 1:500
            a0 = rand(1, 2);
            options = optimset('MaxFunEvals', 200000, 'Display', 'off');
            try
                a = lsqcurvefit(f, a0, L_valid, theta_valid, [-inf,-inf], [inf,inf], options);
                y = f(a, L_valid);
                r = corr(y, theta_valid);
                if r > rmax
                    rmax = r;
                    afinal = a;
                    RMSE = sqrt(mean((theta_valid - y).^2))./mean(theta_valid);     
                end
            catch
                continue;
            end
        end

        r_val = rmax;
        a_val = afinal;

        h = figure(500 + i_nation);
        set(h, 'Name', ['Theta - ' char(attribute_serial) ' - ' num2str(i_nation)], 'NumberTitle', 'off');
        hold on;
        set(gcf, 'Color', 'white');

        % 绘制拟合曲线
        if ~any(isnan(afinal))
            x_plot = min(L_valid):0.1:max(L_valid);
            y_plot = f(afinal, x_plot);
            plot(x_plot, y_plot+90-360, 'Color', nation_color, 'LineWidth', 1, 'LineStyle', line_style);
        end

        % 绘制样本点
        scatter(L_valid, theta_valid+90-360, 20, nation_color, 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 0.5);
        ylim([0,180])
        ylabel('\theta', 'FontSize', 12, 'FontAngle', 'italic');
        xlabel('L^*', 'FontSize', 12, 'FontAngle', 'italic');
        title(['\theta - L^*'], 'FontSize', 14);
        grid on;

        exportgraphics(h, fullfile(output_folder, strcat(attribute_serial, '_nation_', num2str(i_nation), '.jpg')), 'Resolution', 300);
        close(h);
    end
end