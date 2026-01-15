clear;clc;close all;


%%
%CAT_PMCC
lightSPD_data=load("lightbox\lightboxSPD.mat");
lightSPD_all=lightSPD_data.lightSPD;
lightname=lightSPD_data.lightname;
for i_light=1:length(lightSPD_all)
    lightSPD_all_mean(i_light,1)=mean(lightSPD_all{i_light,1});
end

PMCCrfl=readtable("PMCC_reshaped.xlsx");
PMCCrfl=table2array(PMCCrfl);
white_rfl=PMCCrfl(:,31);

types=["Caucasion","Oriental","South Asian","Africa"];

SPDname_l=400:10:700;
SPDname_l=SPDname_l';
SPDname_r=400:10:700;
SPDname_r=SPDname_r';
cmf=selectcmf(10);

wd65=[94.813  100.000  107.262];
datai_file = 'calibResults\model3d_file_350_1deg\datai_ipv40_3.mat';
LUT=load(datai_file);
XYZw_LUT=LUT.XYZw;
wd65_scaled=wd65./100.*XYZw_LUT(2);
for i_type=1:4
% for i_type=2:2
    pmcc_rfl=PMCCrfl(:,i_type);
    for i_light=1:length(lightSPD_all)
        lightSPD=lightSPD_all{i_light,:};
        lightSPD_mean(i_light,1)=mean(lightSPD);
        [XYZ(i_light,:),XYZw(i_light,:)] = spd2xyz([SPDname_l lightSPD],10,1,[SPDname_r pmcc_rfl]);
        [XYZ_white(i_light,:),~] = spd2xyz([SPDname_l lightSPD],10,1,[SPDname_r white_rfl]);
    
        %归一化
        XYZ_unscaled(i_light,:)=XYZ(i_light,:);
        XYZ_white_unscaled(i_light,:)=XYZ_white(i_light,:);
        if XYZ_white(i_light,2)>XYZw_LUT(2)
            
            XYZ(i_light,:)=XYZ(i_light,:)./XYZ_white(i_light,2).*XYZw_LUT(2);
            XYZ_white(i_light,:)=XYZw_LUT;
        end
        XYZ(i_light,:)=min(XYZ_white(i_light,2),max(0,XYZ(i_light,:)));
        
        
        lab(i_light,:)=xyz2lab(XYZ(i_light,:),'user',wd65_scaled);
        lab_rela(i_light,:)=xyz2lab(XYZ(i_light,:),'user',XYZ_white(i_light,:));
        labw(i_light,:)=xyz2lab(XYZ_white(i_light,:),'user',wd65_scaled);
        if i_light==22
            disp("22");
        end
    end
save(strcat("pmcc\lightbox\",types(i_type),".mat"),"lab", ...
    "lab_rela","labw","XYZ_unscaled","XYZ", ...
    "lightname","XYZ_white_unscaled","XYZ_white");
end

%%
%法2
% for i_light=1:length(lightSPD_all)
%     lightSPD=lightSPD_all{i_light,:};
%     SPDname_l1=[];light=[];CMF=[];
%     for i_r=1:length(SPDname_r)
%         SPDname_l1=[SPDname_l1;SPDname_l(SPDname_l(:,1)==SPDname_r(i_r,1),1)];
%         light=[light;lightSPD(SPDname_l(:,1)==SPDname_r(i_r,1),1)];
%         CMF=[CMF;cmf(cmf(:,1)==SPDname_r(i_r,1),2:4)];
%     end
%     k=100./sum(light.*CMF(:,2));
%     XYZ1(i_light,:)=k.*sum(repmat(light,[1,size(CMF,2)]).*CMF.* ...
%         repmat(oriental_rfl,[1,size(CMF,2)]));
%     XYZ_white1(i_light,:)=k.*sum(repmat(light,[1,size(CMF,2)]).*CMF.* ...
%         repmat(white_rfl,[1,size(CMF,2)]));
%     XYZ_w(i_light,:)=k.*sum(repmat(light,[1,size(CMF,2)]).*CMF);
%     lab1(i_light,:)=xyz2lab(XYZ1(i_light,:),'user',XYZ_white1(i_light,:));
% 
% end

disp("d");

A=load("lab_pmcc_cat.mat");
