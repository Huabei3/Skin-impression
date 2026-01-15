% C_L 建模函数
function [r_val, a_val,RMSE] = model_C_L(output_folder,L_data, C_data, attribute_serial, nation_color, line_style, Dtype, iOr, i_nation)
    r_val = NaN;
    a_val = NaN(1, 2);
    RMSE=NaN;

    % 检查并移除包含NaN的行
    valid_indices = ~isnan(L_data) & ~isnan(C_data) & L_data > 0;
    L_valid = L_data(valid_indices);
    C_valid = C_data(valid_indices);

    % 如果有足够的数据点进行拟合
    if length(L_valid) > 3
        % 定义拟合模型
        f = @(a, xdata)(a(1).*log(xdata) + a(2));

        % 多次随机初始化以找到最佳拟合
        rmax = -inf;
        afinal = [NaN, NaN]; % 初始化为 NaN
        RMSE=NaN;
        for t = 1:500
            a0 = [rand, rand];
            options = optimset('MaxFunEvals', 200000, 'Display', 'off'); % 关闭显示以避免过多输出
            try
                a = lsqcurvefit(f, a0, L_valid, C_valid, [-inf, -inf], [inf, inf], options);
                y = f(a, L_valid);
                r = corr(y, C_valid);
                if r > rmax
                    rmax = r;
                    afinal = a;
                    RMSE = sqrt(mean((C_valid - y).^2))./mean(C_valid);  
                end
            catch
                % 捕获 lsqcurvefit 可能的错误，继续下一次迭代
                continue;
            end
        end

        r_val = rmax;
        a_val = afinal;

        % 创建新的图形窗口或使用现有图形窗口
        h = figure(100 + i_nation); % 使用一个唯一的 ID 确保每个 nation 有一个 C-L 图
        set(h, 'Name', ['C_L - ' char(attribute_serial) ' - ' num2str(i_nation)], 'NumberTitle', 'off');
        hold on;
        set(gcf, 'Color', 'white');

        % 绘制拟合曲线
        if ~any(isnan(afinal))
            x_plot = min(L_valid):0.1:max(L_valid);
            y_plot = f(afinal, x_plot);
            plot(y_plot, x_plot, 'Color', nation_color, 'LineWidth', 1, 'LineStyle', line_style);
        end

        % 亮度实验曲线 (假设 nation == 1 时绘制，可根据需要调整)
        % if i_nation == 1
        %     x2 = 10:0.1:70;
        %     y2 = 6.7421 * log(x2) - 9.9816;
        %     plot(y2, x2, 'Color', 'k', 'LineWidth', 1, 'LineStyle', ':');
        % end
        scatter(C_valid,L_valid, 20, nation_color, 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 0.5);

        % 设置图表属性
        ylabel('L_{ab}^*', 'FontSize', 12, 'FontAngle', 'italic');
        xlabel('C^*', 'FontSize', 12, 'FontAngle', 'italic');
        title(['C^* - L^*'], 'FontSize', 14);
        grid on;
        axis equal
        interval = 10;
        xticks(0:interval:35);
        yticks(0:interval:80);
        ylim([0, 80]);
        xlim([0, 35]);


        exportgraphics(h, fullfile(output_folder, strcat(attribute_serial, '_nation_', num2str(i_nation), '.jpg')), 'Resolution', 300);
        close(h); % 关闭图形窗口，避免内存占用过高
    end
end

