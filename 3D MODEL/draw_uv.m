clc;clear;close all;
%%
% 定义 DCI-P3 色域的顶点坐标 (XYZ 格式)


dci_p3_xyz = [0.68,	0.32,	0.00;
0.265,	0.69,	0.045;
0.15,	0.06,	0.79;];

% 定义 sRGB 色域的顶点坐标 (XYZ 格式)

srgb_xyz=[0.64,	0.33,	0.03;
0.30,	0.60,	0.10;
0.15,	0.06,	0.79;];

% 将 XYZ 坐标转换为 xyY 坐标
dci_p3_xy = dci_p3_xyz(:, 1:2) ./ sum(dci_p3_xyz, 2);
srgb_xy = srgb_xyz(:, 1:2) ./ sum(srgb_xyz, 2);

% 绘制 DCI-P3 色域图
figure;
patch(dci_p3_xy(:, 1), dci_p3_xy(:, 2), 'r', 'FaceAlpha', 0.3, 'DisplayName', 'DCI-P3');
hold on;
plot(dci_p3_xy(:, 1), dci_p3_xy(:, 2), 'k-', 'LineWidth', 2, 'DisplayName', 'DCI-P3');

% 绘制 sRGB 色域图
patch(srgb_xy(:, 1), srgb_xy(:, 2), 'g', 'FaceAlpha', 0.3, 'DisplayName', 'sRGB');
plot(srgb_xy(:, 1), srgb_xy(:, 2), 'k--', 'LineWidth', 2, 'DisplayName', 'sRGB');

%%
%from mat
SPDname = 380:1:780;SPDname = SPDname';
% load("Z:\homes\Peggy\VIVOskinExpe\calibResults\VIVO_CS2000_96_p3_4_1deg_realP32024_11_26_10_39_11.mat");
load("Z:\homes\Peggy\VIVOskinExpe\calibResults\729_350_1deg_realP3\VIVO_CS2000_729_p3_1_1deg_realP3_2024_12_07_11_05_24.mat");
% load("Z:\homes\Peggy\VIVOskinExpe\calibResults\729_350_1deg_realP3\VIVO_CS2000_729_p3_5_1deg_2024_11_26_00_44_07.mat");
% load("Z:\homes\Peggy\VIVOskinExpe\calibResults\96_350_1deg_realP3\VIVO_CS2000_96_p3_4_1deg_2024_11_25_20_27_44.mat");
% load("D:\work\VIVOskinExpe\calibResults\729_350_1deg\VIVO_CS2000_729_p3_4_350_1deg_2024_11_08_18_53_34.mat");
% DATAs(1,:) = [];
% SPD = reshape(cell2mat(DATAs(:,4)),401,length(DATAs));
% XYZ2 = spd2xyz([SPDname SPD],2);
% xyz=XYZ2./(XYZ2(:,1)+XYZ2(:,2)+XYZ2(:,3));
% scatter(xyz(:,1),xyz(:,2));

DATAs(1,:)=[];
SPD = reshape(cell2mat(DATAs(:,4)),401,length(DATAs));
XYZ10 = spd2xyz([SPDname SPD],10);


% load("Z:\homes\Peggy\VIVOskinExpe\calibResults\96_350_1deg_realP3\VIVO_CS2000_96_p3_4_1deg_2024_11_25_17_26_26.mat");
% % load("D:\work\VIVOskinExpe\calibResults\729_350_1deg\VIVO_CS2000_729_p3_4_350_1deg_2024_11_08_18_53_34.mat");
% DATAs(1,:) = [];
% SPD = reshape(cell2mat(DATAs(:,4)),401,length(DATAs));
% XYZ2 = spd2xyz([SPDname SPD],2);
% xyz=XYZ2./(XYZ2(:,1)+XYZ2(:,2)+XYZ2(:,3));
% scatter(xyz(:,1),xyz(:,2),'red','+');
