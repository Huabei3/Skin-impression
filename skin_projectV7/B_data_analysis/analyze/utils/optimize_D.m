function D_optimal = optimize_D(XYZ, XYZw, XYZwt, Labtarget)
    % 定义目标函数，计算 deltaE2000
    objectiveFunction = @(D) cal_deltaE2000(XYZ, XYZw, XYZwt, D, Labtarget);

    % 使用 fminbnd 或 fminsearch 搜索最优的 D 值
    % 假设 D 的合理范围是 [0, 1]
    D_optimal = fminbnd(objectiveFunction, 0, 1);

    % 输出最优 D 值
    fprintf('Optimal D value: %.6f\n', D_optimal);
end