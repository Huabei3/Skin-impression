function [par]= get_par(z_input,fit_center_data_file)
    load(fit_center_data_file);
    a1 = a1_interp(z_input);  % a1参数
    a2 = a2_interp(z_input);  % a2参数
    a3 = a3_interp(z_input);  % a3参数
    a4 = a4_interp(z_input);  % a4参数（x方向中心）
    a5 = a5_interp(z_input);  % a5参数（y方向中心）
    a6 = a6_interp(z_input);  % a6参数
    par=[a1,a2,a3,a4,a5,a6];


end