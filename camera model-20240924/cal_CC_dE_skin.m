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
XYZ_mea=lab2xyz(lab_mea,'user',XYZw_LUT);


RGB_query= lut3d_xyz2rgbKDitp(XYZ_mea,LUTback_file); 

load("D:\work\CC\forPeggy_raw\Pmatrix_raw_hdrD65.mat");
XYZw_camera=[10000.2343911721	10335.0224456447	8015.70022505509];
% load("PmatrixD651227.mat");
w=Pmatrix;
%法1
V=PolynomialModel(RGB_query',Num);
XYZ1P = w*V;XYZ1P=XYZ1P';
% V0 = PolynomialModel([0;0;0],Num);
% XYZ0 = Pmatrix*V0;XYZ0 = XYZ0';
% XYZ = XYZ1P - XYZ0;
% XYZ(XYZ<0) = 0.0001;
% XYZ = cameramodel_poly1227(RGB_query);


%计算色差
%全部用h白
lab1 = xyz2lab(XYZ_mea,'user',XYZw_LUT);
lab2 = xyz2lab(XYZ1P,'user',XYZw_camera);
DE00 = deltaE2000(lab1,lab2);
DE00=DE00';
result(1,:) = [mean(DE00) std(DE00) max(DE00) min(DE00)];