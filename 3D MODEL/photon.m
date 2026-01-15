clear;
%%
% 定义函数
function y = gain_function(hv, x)
    y = 1.32e5 * ((hv - 1.4).^(1/2) ./ (hv.^2)) .* ...
        (1 ./ (exp((0.877 * (hv - 1.4) - 5.22e-18 * x.^(2/3)) / 0.026) + 1) - ...
         1 ./ (exp(-(0.123 * (hv - 1.4) - 7.3e-19 * x.^(2/3)) / 0.026) + 1));
end

% 参数定义
hv_range = linspace(1.4, 2.4, 100); % 光子能量范围 (eV)
x_range = linspace(1e18, 2e18, 100); % 注入载流子浓度范围 (cm^-3)

% 初始化矩阵
y_matrix = zeros(length(hv_range), length(x_range));

% 计算函数
for i = 1:length(hv_range)
    for j = 1:length(x_range)
        y_matrix(i, j) = gain_function(hv_range(i), x_range(j));
    end
end

% 绘制函数
figure;
surf(x_range, hv_range, y_matrix);
xlabel('注入载流子浓度 x (cm^{-3})');
ylabel('光子能量 hv (eV)');
zlabel('增益系数 y');
title('增益系数随光子能量和注入载流子浓度的变化关系');
colorbar;
grid on;
%%
% 参数定义
E_g = 1.40; % 带隙能量 (eV)
m_e = 0.07 * 9.10938356e-31; % 电子有效质量 (kg)
m_h = 0.5 * 9.10938356e-31; % 空穴有效质量 (kg)
n = 3.6; % 折射率
p_o = 1.2e18; % 掺杂浓度 (cm^-3)
tau_r = 2e-9; % 辐射复合寿命 (s)
k_B = 8.617333262e-5; % 玻尔兹曼常数 (eV/K)
T_0K = 0; % 0 K
T_300K = 300; % 300 K

% 光子能量范围 (eV)
hv_range = linspace(E_g, E_g + 1, 100);

% 注入载流子浓度范围 (cm^-3)
Delta_n_range = linspace(0, 2e18, 100);

% 计算增益系数峰值
gamma_peak_0K = zeros(size(Delta_n_range));
gamma_peak_300K = zeros(size(Delta_n_range));

for i = 1:length(Delta_n_range)
    Delta_n = Delta_n_range(i);
    
    % T = 0 K 下的增益系数
    f_c_0K = ones(size(hv_range));
    f_v_0K = zeros(size(hv_range));
    gamma_0K = calculate_gain(hv_range, f_c_0K, f_v_0K, m_e, m_h, E_g);
    gamma_peak_0K(i) = max(gamma_0K);
    
    % T = 300 K 下的增益系数
    E_F = E_g / 2; % 假设费米能级在带隙中间
    f_c_300K = 1 ./ (1 + exp((hv_range - E_F) / (k_B * T_300K)));
    f_v_300K = 1 ./ (1 + exp((E_F - hv_range) / (k_B * T_300K)));
    gamma_300K = calculate_gain(hv_range, f_c_300K, f_v_300K, m_e, m_h, E_g);
    gamma_peak_300K(i) = max(gamma_300K);
end

% 绘制增益系数峰值随 Delta_n 的变化关系
figure;
plot(Delta_n_range, gamma_peak_0K, 'r', 'LineWidth', 2);
hold on;
plot(Delta_n_range, gamma_peak_300K, 'b', 'LineWidth', 2);
xlabel('注入载流子浓度 \Delta n (cm^{-3})');
ylabel('增益系数峰值 \gamma_o(v) (cm^{-1})');
title('增益系数峰值随 \Delta n 的变化关系');
legend('T = 0 K', 'T = 300 K');
grid on;

% (d) 使用线性近似模型，计算损耗系数 α 和透明载流子浓度 Δn_T
% 假设线性近似模型为 γ_p = α (Δn - Δn_T)
% 通过实验数据或理论计算，确定 α 和 Δn_T 的值
% 这里假设 α = 600 cm^-1 和 Δn_T = 1.25e18 cm^-3
alpha = 600; % 损耗系数 (cm^-1)
Delta_n_T = 1.25e18; % 透明载流子浓度 (cm^-3)

% (e) 绘制放大器的总带宽随 Δn 的变化关系
% 总带宽（单位：Hz, nm 和 eV）
% 计算不同 Δn 下的增益带宽
bandwidth_Hz = zeros(size(Delta_n_range));
bandwidth_nm = zeros(size(Delta_n_range));
bandwidth_eV = zeros(size(Delta_n_range));

for i = 1:length(Delta_n_range)
    Delta_n = Delta_n_range(i);
    gamma_p = alpha * (Delta_n - Delta_n_T);
    bandwidth_Hz(i) = calculate_bandwidth(gamma_p);
    bandwidth_nm(i) = convert_Hz_to_nm(bandwidth_Hz(i));
    bandwidth_eV(i) = convert_Hz_to_eV(bandwidth_Hz(i));
end

% 绘制带宽随 Δn 的变化关系
figure;
subplot(3,1,1);
plot(Delta_n_range, bandwidth_Hz, 'g', 'LineWidth', 2);
xlabel('注入载流子浓度 \Delta n (cm^{-3})');
ylabel('带宽 (Hz)');
title('带宽随 \Delta n 的变化关系 (Hz)');
grid on;

subplot(3,1,2);
plot(Delta_n_range, bandwidth_nm, 'm', 'LineWidth', 2);
xlabel('注入载流子浓度 \Delta n (cm^{-3})');
ylabel('带宽 (nm)');
title('带宽随 \Delta n 的变化关系 (nm)');
grid on;

subplot(3,1,3);
plot(Delta_n_range, bandwidth_eV, 'c', 'LineWidth', 2);
xlabel('注入载流子浓度 \Delta n (cm^{-3})');
ylabel('带宽 (eV)');
title('带宽随 \Delta n 的变化关系 (eV)');
grid on;

% 计算增益系数的函数
function gamma = calculate_gain(hv, f_c, f_v, m_e, m_h, E_g)
    e = 1.602176634e-19; % 电子电荷 (C)
    hbar = 1.054571817e-34; % 约化普朗克常数 (Js)
    c = 2.99792458e8; % 光速 (m/s)
    epsilon_0 = 8.8541878128e-12; % 真空介电常数 (F/m)
    
    gamma = (e^2 * hbar^2 / (4 * pi^2 * c * epsilon_0 * m_e * m_h)) * (f_c .* f_v ./ hv);
end

% 计算带宽的函数
function bandwidth = calculate_bandwidth(gamma_p)
    % 这里假设带宽与增益系数成正比
    bandwidth = gamma_p * 1e12; % 假设比例系数为 1e12
end

% 将带宽从 Hz 转换为 nm
function bandwidth_nm = convert_Hz_to_nm(bandwidth_Hz)
    c = 2.99792458e8; % 光速 (m/s)
    bandwidth_nm = c ./ (bandwidth_Hz * 1e9); % 转换为 nm
end

% 将带宽从 Hz 转换为 eV
function bandwidth_eV = convert_Hz_to_eV(bandwidth_Hz)
    h = 6.62607015e-34; % 普朗克常数 (Js)
    e = 1.602176634e-19; % 电子电荷 (C)
    bandwidth_eV = h * bandwidth_Hz / e; % 转换为 eV
end