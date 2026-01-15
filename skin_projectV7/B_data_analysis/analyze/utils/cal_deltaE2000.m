function deltaE = cal_deltaE2000(XYZ, XYZw, XYZwt, D, Labtarget)
    % 调用 CAT16_D 函数计算 XYZt
    XYZt = CAT16_D(XYZ, XYZw, XYZwt, D);

    % 将 XYZt 和 XYZtarget 转换为 Lab
    [Labt] = xyz2lab(XYZt, 'd65_64');

    % 计算 deltaE2000
    deltaE = deltaE2000(Labt, Labtarget);
end