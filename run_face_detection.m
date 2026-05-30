%% RUN_FACE_DETECTION
% 运行人脸检测脚本
clear; close all; clc;

% 添加当前目录到路径
addpath(fileparts(mfilename('fullpath')));

% 运行批量处理
batch_face_detection;

fprintf('\n处理完成！\n');
