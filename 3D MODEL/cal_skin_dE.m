clear;clc;close all;
%%

LUTback_file="D:\work\VIVOskinExpe\renderCode\" + ...
    "calibResults\data_ipv18_3.mat";

LUTfore_file="D:\work\VIVOskinExpe\renderCode\" + ...
    "calibResults\datai_ipv18_3.mat";
wd65=[94.813  100.000  107.262];
LUT=load(LUTfore_file);
XYZw_LUT=LUT.XYZw;
wd65_scaled=wd65./100.*XYZw_LUT(2);

lab_mea = readtable("..\skintone_Grace.xlsx");
lab_mea = table2array(lab_mea);
XYZ_mea=lab2xyz(lab_mea,'user',wd65_scaled);


RGB_r= lut3d_xyz2rgbKDitp1(XYZ_mea,LUTback_file); 
XYZ_r=lut3d_rgb2xyz1(RGB_r,LUTfore_file);

% [lab_r] = xyz2lab(XYZ_r,'user',XYZw_LUT);
% [lab_mea] = xyz2lab(XYZ_mea,'user',XYZw_LUT);
[lab_r] = xyz2lab(XYZ_r,'user',wd65_scaled);
[lab_mea] = xyz2lab(XYZ_mea,'user',wd65_scaled);

[de00] = deltaE2000(lab_mea,lab_r)';
result_de00=[mean(de00),max(de00),min(de00),std(de00)];