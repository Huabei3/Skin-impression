clear;clc;close all;
addpath("utils\");
%%

%%
datai_file = 'calibResults\model\datai_ipv40_3.mat';
wd65=[94.813  100.000  107.262];
LUT=load(datai_file);
XYZw_LUT=LUT.XYZw;
wd65_scaled=wd65./100.*XYZw_LUT(2);


gridSize = 17; % LUT 的网格大小
[R, G, B] = ndgrid(linspace(0, 255, gridSize), ...
    linspace(0, 255, gridSize), ...
    linspace(0, 255, gridSize));
sz=size(R);
RGBout=[reshape(R,[sz(1)*sz(2)*sz(3),1]),...
    reshape(G,[sz(1)*sz(2)*sz(3),1]),...
    reshape(B,[sz(1)*sz(2)*sz(3),1])];
XYZin=lut3d_rgb2xyz1(RGBout,datai_file);

% 创建 scatteredInterpolant 对象
F_R = scatteredInterpolant(XYZin(:,1), XYZin(:,2), XYZin(:,3), RGBout(:,1), 'linear');
F_G = scatteredInterpolant(XYZin(:,1), XYZin(:,2), XYZin(:,3), RGBout(:,2), 'linear');
F_B = scatteredInterpolant(XYZin(:,1), XYZin(:,2), XYZin(:,3), RGBout(:,3), 'linear');
% 示例查询点：需要插值的 XYZ 值
XYZ_query = [50, 60, 70; % 第一个点
             80, 90, 100]; % 第二个点

% 使用插值函数计算对应的 RGB 值
RGB_query = zeros(size(XYZ_query));
RGB_query(:,1) = F_R(XYZ_query(:,1), XYZ_query(:,2), XYZ_query(:,3)); % 插值 R
RGB_query(:,2) = F_G(XYZ_query(:,1), XYZ_query(:,2), XYZ_query(:,3)); % 插值 G
RGB_query(:,3) = F_B(XYZ_query(:,1), XYZ_query(:,2), XYZ_query(:,3)); % 插值 B

XYZ_r=lut3d_rgb2xyz1(RGB_query,datai_file);
lab_q=xyz2lab(XYZ_query,'d65_64');
lab_r=xyz2lab(XYZ_r,'d65_64');
dE=deltaE2000(lab_q,lab_r);
%%
SPDname = 380:1:780;SPDname = SPDname';
load("D:\work\VIVOskinExpe\renderCode\calibResults\96\" + ...
    "VIVO_CS2000_96_p3_3_1deg_realP32024_11_25_20_27_44.mat");
DATAs(1,:) = [];
SPD = reshape(cell2mat(DATAs(:,4)),401,96);
XYZ10 = spd2xyz([SPDname SPD],10);
XYZ_mea=XYZ10;
RGB_pre = zeros(size(XYZ_mea));
RGB_pre(:,1) = F_R(XYZ_mea(:,1), XYZ_mea(:,2), XYZ_mea(:,3)); % 插值 R
RGB_pre(:,2) = F_G(XYZ_mea(:,1), XYZ_mea(:,2), XYZ_mea(:,3)); % 插值 G
RGB_pre(:,3) = F_B(XYZ_mea(:,1), XYZ_mea(:,2), XYZ_mea(:,3)); % 插值 B
RGB_pre=max(min(RGB_pre,255),0);
XYZ_r=lut3d_rgb2xyz1(RGB_pre,datai_file);


[val, ind]=max(XYZ_mea);
XYZw=XYZ_mea(ind(2),:);
[lab_r] = xyz2lab(XYZ_r,'user',XYZw);
[lab_mea] = xyz2lab(XYZ_mea,'user',XYZw);
[de00,de00c] = deltaE2000(lab_mea,lab_r);
save("D:\work\VIVOskinExpe\renderCode\calibResults\interp_3.mat", ...
    "F_R","F_B","F_G");
%%

% 生成示例 3D LUT 数据
% 假设输入 RGB 范围为 [0, 1]，输出 RGB 也是 [0, 1]
gridSize = 17; % LUT 的网格大小
[X, Y, Z] = ndgrid(linspace(0, XYZw_LUT(2), gridSize), ...
    linspace(0, XYZw_LUT(2), gridSize), ...
    linspace(0, XYZw_LUT(2), gridSize));
sz=size(X);
XYZin=[reshape(X,[sz(1)*sz(2)*sz(3),1]), ...
    reshape(Y,[sz(1)*sz(2)*sz(3),1]),...
    reshape(Z,[sz(1)*sz(2)*sz(3),1])];
% 示例映射函数：将输入 RGB 转换为输出 RGB
% 这里使用一个简单的颜色增强函数
datafile = 'calibResults\model\data_ipv40_3.mat';
RGBout=lut3d_xyz2rgbKD(XYZin, datafile);


% 将 3D LUT 数据存储为网格
LUT_R = RGBout(:,1);
LUT_G = RGBout(:,2);
LUT_B = RGBout(:,3);

% 创建插值函数
F_R = griddedInterpolant(X, Y, Z, LUT_R, 'linear');
F_G = griddedInterpolant(X, Y, Z, LUT_G, 'linear');
F_B = griddedInterpolant(X, Y, Z, LUT_B, 'linear');

% 测试插值函数
% 定义一组查询点（输入 RGB 值）
testXYZ = [0.2, 0.5, 0.8; % 第一个颜色
           0.7, 0.3, 0.1]; % 第二个颜色

% 使用插值函数计算输出 RGB 值
outputRGB = zeros(size(testXYZ));
for i = 1:size(testXYZ, 1)
    x = testXYZ(i, 1);
    y = testXYZ(i, 2);
    z = testXYZ(i, 3);
    outputRGB(i, 1) = F_R(x, y, z); % 插值 R
    outputRGB(i, 2) = F_G(x, y, z); % 插值 G
    outputRGB(i, 3) = F_B(x, y, z); % 插值 B
end

% 显示结果
disp('输入 RGB 值：');
disp(testXYZ);
disp('输出 RGB 值：');
disp(outputRGB);

% lut3d_rgb2xyz1