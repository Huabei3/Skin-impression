clear;clc;close all;
%%

%读取光源信息
%-----------
% % %20240718
% filename = 'light_r\20240718_rspd.xlsx';
% n_model=4;
% model_name=["male07","male22","male28","maleVIVO"];
% pmcc_serial=[1,4,4,2];

%-----------
% % 20240719
% filename = 'light_r\20240719_rspd.xlsx';
% n_model=4;
% model_name=["female06","male21","female25","female23"];
% pmcc_serial=[1,3,4,3];
%-----------
% % % 20240722
filename = 'light_r\20240722_rspd.xlsx';
n_model=4;
model_name=["male39","male59","female36","femaleVIVO"];
pmcc_serial=[2,1,2,2];
%-----------
%20240723
% filename = 'light_r\20240723_rspd.xlsx';
% n_model=5;
% model_name=["female04","female01","female41","female51","male46"];
% pmcc_serial=[1,1,2,3,3];

% %-----------
% % % %20240724
% filename = 'light_r\20240724_rspd.xlsx';
% n_model=2;
% model_name=["male59","female69"];
% pmcc_serial=[2,4];
%-----------


date_str=filename(end-17:end-10);
SPDname_l=360:1:780;SPDname_l=SPDname_l';
SPDname_r=400:10:700;
SPDname_r=SPDname_r';
cmf=selectcmf(10);

[~,sheets] = xlsfinfo(filename) ;
sheets=sheets';
% 循环遍历所有工作表
for i_sheet = 1:length(sheets)
    % 读取每个工作表
    [numstr, ~] = regexp(sheets{i_sheet,1}, '^\d+', 'match');
    numstr=str2double(numstr);
    picname{i_sheet,1}=sprintf("rs%02d",numstr);
    lightdata = readtable(filename, 'Sheet', i_sheet);

    if strcmp(lightdata{1,1}{1,1},'日期时间')
        row_start=28;
        row_end=448;
        row_cct=2;
    elseif strcmp(lightdata{1,1}{1,1},'数据编号')
        row_start=29;
        row_end=449;
        row_cct=3;
    end
    % lightsource{i_sheet,1}=lightdata;
    unit_col=floor(size(lightdata,2)/n_model);
    for i_model=1:n_model
        col_used=(i_model-1)*unit_col+2;
        inds_light{i_model,i_sheet}=lightdata(row_start:row_end,col_used);
        inds_cct{i_model,i_sheet}=lightdata(row_cct,col_used);
    end
end

%%
%对光源进行插值匹配fdQst
for i_model=1:size(inds_light,1)
    for i_sheet=1:size(inds_light,2)
        light_temp=inds_light{i_model,i_sheet};
        %插值匹配
        SPDname_l1=[];ind_light1=[];CMF=[];
        for i_r=1:length(SPDname_r)
            SPDname_l1=[SPDname_l1;SPDname_l(SPDname_l(:,1)==SPDname_r(i_r,1),1)];
            ind_light1=[ind_light1;light_temp(SPDname_l(:,1)==SPDname_r(i_r,1),1)];
            CMF=[CMF;cmf(cmf(:,1)==SPDname_r(i_r,1),2:4)];
        end
        ind_light1=table2array(ind_light1);
        inds_light1{i_model,i_sheet}=ind_light1;
        inds_light1_mean(i_model,i_sheet)=mean(ind_light1);
    end
end
%%
source_folder=strcat("Z:\homes\Peggy\VIVOskinExpe\imageCapture\20240718 哈苏相机删减整理\",date_str," 肤色");

%计算PMCC
PMCCrfl=readtable("Z:\homes\Peggy\reference\PMCC_reshaped.xlsx");
PMCCrfl=table2array(PMCCrfl);
PMCCrfl=PMCCrfl./100;
white_rfl=PMCCrfl(:,31);

wd65=[94.813  100.000  107.262];
datai_file = 'Z:\homes\Peggy\VIVOskinExpe\calibResults\model3d_file_350_1deg\datai_ipv40_3.mat';
LUT=load(datai_file);
XYZw_LUT=LUT.XYZw;
wd65_scaled=wd65./100.*XYZw_LUT(2);

model_name_check=[];
for i_model=1:n_model

    dir_pic=dir(strcat(source_folder,"\",model_name(i_model),"\jpg\card\*.jpg"));
    model_name_check{i_model,1}=model_name(i_model);
    pmcc_rfl=PMCCrfl(:,pmcc_serial(i_model));

    lab_pmcc=[];lab_pmcc_scaled=[];lab_pmcc_w=[];
    XYZ=[];XYZ_unscaled=[];XYZ_white=[];XYZ_white_unscaled=[];
    ind_light=[];
    for i_pic=1:length(dir_pic)
        for i_light=1:size(inds_light,2)
            if isequal(picname{i_light,1},dir_pic(i_pic).name(1:end-4))
                disp([model_name(i_model),i_light,picname{i_light,1}, ...
                    dir_pic(i_pic).name(1:end-4)]);
                ind_pic_light=table2array(inds_light{i_model,i_light});

                break
            end
        end
        ind_light{i_pic,1}=picname{i_light,1};
        ind_light{i_pic,2}=ind_pic_light;
        ind_light{i_pic,3}=mean(ind_pic_light);
        ind_light{i_pic,4}=table2array(inds_cct{i_model,i_light});

        [XYZ(i_pic,:),XYZw(i_pic,:)] = spd2xyz([SPDname_l ind_pic_light],10,1,[SPDname_r pmcc_rfl]);
        [XYZ_white(i_pic,:),~] = spd2xyz([SPDname_l ind_pic_light],10,1,[SPDname_r white_rfl]); 

        %归一化
        XYZ_unscaled(i_pic,:)=XYZ(i_pic,:);
        XYZ_white_unscaled(i_pic,:)=XYZ_white(i_pic,:);
        if XYZ_white(i_pic,2)>XYZw_LUT(2)
            
            XYZ(i_pic,:)=XYZ(i_pic,:)./XYZ_white(i_pic,2).*XYZw_LUT(2);
            XYZ_white(i_pic,:)=XYZw_LUT;
        end
        XYZ(i_pic,:)=min(XYZ_white(i_pic,2),max(0,XYZ(i_pic,:)));

        lab_pmcc_scaled(i_pic,:)=xyz2lab(XYZ(i_pic,:),'user',XYZ_white(i_pic,:));
        lab_pmcc(i_pic,:)=xyz2lab(XYZ(i_pic,:),'user',wd65_scaled);
        lab_pmcc_w(i_pic,:)=xyz2lab(XYZ_white(i_pic,:),'user',wd65_scaled);
    end
    save(strcat("light_r\model_light\",model_name(i_model),".mat"), ...
            "SPDname_l","XYZ","XYZ_white","XYZ_white_unscaled", ...
            "lab_pmcc","lab_pmcc_w","lab_pmcc_scaled","ind_light");
end

%%




