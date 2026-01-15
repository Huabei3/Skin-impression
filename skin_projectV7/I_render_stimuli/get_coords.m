function coords=get_coords(par, target_score,score_type)
    % 绘制等高线
    check_data2 = par(4) + (-30:0.1:30);
    check_data3 = par(5) + (-30:0.1:30);
    [data2, data3] = meshgrid(check_data2, check_data3);

    a = par;
    y = (1./(1 + a(6) * exp(sqrt(a(1) * (data2 - a(4)).^2 + a(2) * (data3 - a(5)).^2 + ...
        a(3) * (data2 - a(4)) .* (data3 - a(5)))))) .* ((a(1) * (data2 - a(4)).^2 + ...
        a(2) * (data3 - a(5)).^2 + a(3) * (data2 - a(4)) .* (data3 - a(5))) >= 0);

    % 绘制等高线
    if strcmp(score_type,"abs")
        target_y=target_score;
    elseif strcmp(score_type,"rela")
        y_center=calculate_y(par(4), par(5), par);
        target_y=target_score*y_center;
    end

    coords = contourc(check_data2, check_data3, y, [target_y,target_y]);
    coords=coords';
end