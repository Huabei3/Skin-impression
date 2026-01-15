clear;clc;close all;
%%
%CAT_PMCC
lightsource=load("lightbox\VIVO-SKIN-20240716.mat");
lightSPD_all=lightsource.DATAs(2:end,11);

XYZw_all=load("E:\Hassel\dsp\femaleVIVO\r\XYZ\XYZw_all\femaleVIVO_XYZw_all.mat");
XYZw_all=XYZw_all.XYZw_all;

PMCCrfl=readtable("E:\VIVO\reshaped_PMCCgrayScale.xlsx");
PMCCrfl=table2array(PMCCrfl);
PMCCrfl=PMCCrfl(:,1);

lab_PMCC=[62.11,18.96,19.76];
xyz_PMCC=lab2xyz2(lab_PMCC,'d65_64');

SPDname_l=250:5:1000;
SPDname_l=SPDname_l';
SPDname_r=400:10:700;
SPDname_r=SPDname_r';

for i_pic=1:length(lightSPD_all)
    lightSPD=lightSPD_all{i_pic,:};
    % XYZw=XYZw_all(i_pic,:);
    [XYZ,XYZw] = spd2xyz([SPDname_l lightSPD],10,0,[SPDname_r PMCCrfl]);
    %function [XYZ,XYZw]=spd2xyz(spddata, obs, AorR,rfldata)

end