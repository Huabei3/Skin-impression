clc;clear;close all;
%%
SPDname_r = 400:10:700;SPDname_r = SPDname_r';
SPDname_m = 380:1:780;SPDname_m = SPDname_m';

white_rfl=readtable("lightbox\whiteBoard.csv");
white_rfl=table2array(white_rfl(2:end,15:45));
white_rfl=mean(white_rfl,1);
white_rfl=white_rfl';

dir_light=dir("lightbox\lightbox\*.mat");

for i_light=1:length(dir_light)
    load(fullfile(dir_light(i_light).folder,dir_light(i_light).name));   
    lightname{i_light,1}=dir_light(i_light).name(1:end-4);
    meaSPD = reshape(cell2mat(DATAs(:,4)),401,size(DATAs,1));
    meaSPD=mean(meaSPD,2);

    SPDname_m1=[];meaSPD1=[];
    for i_r=1:length(white_rfl)
        SPDname_m1=[SPDname_m1;SPDname_m(SPDname_m(:,1)==SPDname_r(i_r,1),1)];
        meaSPD1=[meaSPD1;meaSPD(SPDname_m(:,1)==SPDname_r(i_r,1),1)];
    end
    lightSPD{i_light,1}=meaSPD1./white_rfl;
end

save("lightbox\lightboxSPD.mat","lightSPD","lightname");