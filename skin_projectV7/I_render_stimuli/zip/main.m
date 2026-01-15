% NIKON Z6 相机参数
% 光圈： f/5.6
% 快门速度： 1/60s
% ISO： 200
% 曝光补偿： 0.7
% 色温： 6500K

% 多项式相机模型 3*20矩阵
% 模型拟合误差： DE2000 
% Mean / SD / MAX / MIN
% [0.7006	0.5845	4.5278	0.1115]

clear;close all;
load w.mat

% load image - read RGB
RGB = imread();

% RGB2XYZ
V = Signal2V2(RGB');
XYZ = w*V;
XYZ(XYZ<0)=0;