clc;clear;close all;
addpath("..\..\utils\");
%%
skin_type='f05';
average_rgb=[54.4026   47.7699   38.3991];
attribute=1;
CCT=6500;
obs_type_used="non_model";
[y_scaled,y]=predict_score(skin_type,average_rgb,"RGB",attribute,CCT,obs_type_used);

disp("d")