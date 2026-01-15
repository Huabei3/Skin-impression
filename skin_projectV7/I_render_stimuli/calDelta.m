close all; % 关闭所有图窗
clc;       % 清空命令窗口
clear;     % 清除工作区所有变量

filename = 'F:\研一\oppoSkinExperi\points48.xlsx';                               %文件名
num_points = readmatrix(filename); 
num_center = num_points(53,:); 
num_points(50:53,:)=[];
delta_points=zeros(49,3);
for i_points=1:length(num_points)
    delta_points(i_points,:)=num_points(i_points,:)-num_center;
end