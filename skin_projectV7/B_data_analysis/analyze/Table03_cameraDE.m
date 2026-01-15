clc;clear;close all;
%%


run("..\..\A_characterization\camera_model\build\model_i\ModelCreatefromRaw.m");
result_DE{1,1}=result;
result_DE{1,2}="in-lab";
run("..\..\A_characterization\camera_model\build\model_rs\ModelCreatefromRaw.m");
result_DE{2,1}=result;
result_DE{2,2}="real-scene";