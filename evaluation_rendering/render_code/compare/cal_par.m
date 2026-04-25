function [par, hue_angle, chroma, long_axis, short_axis, theta, alpha] = cal_par(obs_type, attribute_serial, i_nation, lab_extracted)
%CAL_PAR Load full-parameter curves and compute ellipse params + par.
version="new";
model_fupara_file=fullfile("D:\work\VIVOskinExpe\analyze\AnalyseResults_p\" , ...
    "efit_p\unscaled\model_fullpara\d65",version,"i", obs_type);
fullpara_data = load(fullfile(model_fupara_file, ...
    strcat(attribute_serial, '_all_curve_params.mat')));

% Extract coefficients for the given nation index

a_alpha = fullpara_data.a_alpha_all(i_nation, :);
a_CL = fullpara_data.a_CL_all(i_nation, :);
a_hue_angle = fullpara_data.a_hue_angle_all(i_nation, :);
a_long_axis = fullpara_data.a_long_axis_all(i_nation, :);
a_short_axis = fullpara_data.a_short_axis_all(i_nation, :);
a_theta = fullpara_data.a_theta_all(i_nation, :);

x = lab_extracted(1, 1);

if strcmp(version,"new")
    hue_angle=a_hue_angle(1);
    chroma=a_CL(1).*(average(i_par,1)) + a_CL(2);
    long_axis=a_long_axis(1).*average(i_par,1).^3 + a_long_axis(2).*average(i_par,1).^2 +...
        a_long_axis(3).*average(i_par,1) + a_long_axis(4);
    short_axis=a_short_axis(1).*average(i_par,1).^3 + a_short_axis(2).*average(i_par,1).^2 +...
        a_short_axis(3).*average(i_par,1) + a_short_axis(4);
    theta=a_theta(1);
    alpha=a_alpha(1);

else
    hue_angle=a_hue_angle(1).*average(i_par,1) + a_hue_angle(2);
    chroma=a_CL(1).*log(average(i_par,1)) + a_CL(2);
    long_axis=a_long_axis(1).*average(i_par,1).^3 + a_long_axis(2).*average(i_par,1).^2 +...
        a_long_axis(3).*average(i_par,1) + a_long_axis(4);
    short_axis=a_short_axis(1).*average(i_par,1).^3 + a_short_axis(2).*average(i_par,1).^2 +...
        a_short_axis(3).*average(i_par,1) + a_short_axis(4);
    theta=a_theta(1).*average(i_par,1) + a_theta(2);
    alpha=a_alpha(1).*average(i_par,1) + a_alpha(2);

end

[par] = calculate_par_from_ellipse(hue_angle, chroma, ...
    long_axis, short_axis, theta, alpha);

end
