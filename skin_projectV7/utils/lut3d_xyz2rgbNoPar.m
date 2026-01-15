function [RGB, out_of_gamut_ratio] = lut3d_xyz2rgbNoPar(XYZ, datafile)
    LUTdata = load(datafile);

    P_labs = LUTdata.P_labs;
    XYZw1 = LUTdata.XYZw;
    rgb = LUTdata.rgb;
    cubeL = LUTdata.cubeL;

    Lab = xyz2lab(XYZ, 'user', XYZw1);

    % 初始化RGB
    RGB = zeros(size(XYZ, 1), 3);

    % 创建KD树
    kdtree = KDTreeSearcher(P_labs);


        % 并行计算
    for i_row = 1:size(Lab, 1)
        % 找到最近邻候选点
        [indices, ~] = knnsearch(kdtree, Lab(i_row, :), 'K', 5);
        
        % 计算色差
        delta_E = zeros(length(indices), 1);
        for j = 1:length(indices)
            delta_E(j) = cielabde(Lab(i_row, :), P_labs(indices(j), :));
        end
        
        % 找到最小色差的索引
        [~, min_idx] = min(delta_E);
        RGB(i_row, :) = rgb(indices(min_idx), :);

        % 显示进度
        if mod(i_row, 10000) == 0
            disp([num2str(i_row) '/' num2str(size(Lab, 1))]);
            disp(['Current time: ' datestr(now, 'yyyy-mm-dd HH:MM:SS')]);
        end
    end 
%     parfor i_row = 1:length(Lab)
%         % 最近邻搜索
%         [mindeidx, minde] = knnsearch(kdtree, Lab(i_row, :), 'K', 1);
%         RGB(i_row, :) = rgb(mindeidx, :);
% 
%         % 显示进度
%         if mod(i_row, 10000) == 0
%             disp([num2str(i_row) '/' num2str(length(Lab))]);
%             disp(['Current time: ' datestr(now, 'yyyy-mm-dd HH:MM:SS')]);
%         end
%     end

    % 计算超色域值的比例
    out_of_gamut = sum(any(RGB < 0 | RGB > 255, 2));
    out_of_gamut_ratio = out_of_gamut / size(RGB, 1);

    % 使用邻近的有效值插值处理 NaN 和 Inf
    for c = 1:size(RGB, 2)
        invalid_mask = isnan(RGB(:, c)) | isinf(RGB(:, c));
        if any(invalid_mask)
            RGB(:, c) = fillmissing(RGB(:, c), 'nearest');
        end
    end

    % 限制RGB值的范围
    RGB(RGB < 0 | isnan(RGB) | isinf(RGB)) = 0;
    RGB(RGB >= 0 & isinf(RGB)) = 255;
    RGB(RGB <= 0 & isinf(RGB)) = 0;
    RGB(RGB > 255) = 255;
end
