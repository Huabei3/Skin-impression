clc;clear;close all;
%%

% run("..\..\A_characterization\display_model\build\model_lut3dVIVO.m");%建立模型

run("..\..\A_characterization\display_model\build\DiffLUT729pre96foreVall1.m",);
result_DE{1,1}=result_matrix;
result_DE{1,2}="foreward";
run("..\..\A_characterization\display_model\build\DiffLUT729pre96backKDVall1.m");
result_DE{2,1}=result_matrix;
result_DE{2,2}="backward";