function [RGB, out_of_gamut_ratio] = lut3d_xyz2rgbKDitp2(XYZ, datafile)
    % 加载 LUT 数据
    LUTdata = load(datafile);

    P_labs = LUTdata.P_labs;
    XYZw1 = LUTdata.XYZw;
    rgb = LUTdata.rgb;
    cubeL = LUTdata.cubeL;

    % 将 XYZ 转换为 Lab
    Lab = xyz2lab(XYZ, 'user', XYZw1);

    % 保存数据供 Python 使用
    save('input_for_python.mat', 'Lab', 'P_labs', 'rgb', '-v7.3');
    fid = fopen('ready.flag', 'w'); fclose(fid);

    % 自动调用 Python 脚本
    system('python utils\\lut3d_interpolate_gpu.py');

    % 等待 Python 处理完成
    while ~isfile('python_done.flag')
        pause(1);
    end

    % 读取 Python 计算结果
    RGB = readNPY('result_from_python.npy');

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

    % 限制 RGB 值的范围
    RGB(RGB < 0 | isnan(RGB) | isinf(RGB)) = 0;
    RGB(RGB >= 0 & isinf(RGB)) = 255;
    RGB(RGB <= 0 & isinf(RGB)) = 0;
    RGB(RGB > 255) = 255;
end 