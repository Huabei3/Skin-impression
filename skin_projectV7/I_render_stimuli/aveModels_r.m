%和隔壁aveModels1不同，这个函数只绘制一个model的情况
close all; 
clc;       
clear;     
%%
%maleVIVO
fav={[1,2,3,4,5,6,7,8,16,24,33];[1,2,3,4,5,6,7,8,14,15,16,23,33];[1,2,8,9,33];%rs 02 03 04
    [1,2,8,9,16,33];[1,8,33];[1,8,16,24,32];%rs 05 06 07
    [1,7,15,33];[1,2,3,4,5,8,11,16,33];[1,2,3,4,5,6,7,8,13,14,15,23,33];%rs 08 09 10
    [1,8,12,33];[1,2,3,8,12,16,33];[1,7,8,9,16,33];[1,2,7,8,16,33]};%rs 11 12 13 14
rs_name=["rs02","rs03","rs04","rs05",...
    "rs06","rs07","rs08","rs09","rs10",...
    "rs11","rs12","rs13","rs14"];

%femaleVIVO
% fav={[17,25];[5,6,7,8,13,15,16,24,33];[1,2,3,4,5,6,7,8,9,16,24,32];%rs 01 02 03
%     [1,2,3,4,8,9,11,17,24,32];[1,2,8,9,16,17,24,33];[1,2,3,9,16,17,24,32];%rs 04 05 06
%     [1,2,3,4,5,6,7,8,12,15,16,23,24,33];[1,2,3,4,7,8,16,24,33];%rs 07 08
%     [1,2,3,4,5,6,7,8,12,13,14,15,16,23,31,33]; %rs10
%     [1,2,3,8,16,33];[1,2,3,4,6,7,8,9,16,24,33];[1,2,3,4,8,16,24,33];%rs 11 12 13
%     [1,2,7,8,15,16,33]}; %14
% 
% rs_name=["rs01","rs02","rs03","rs04","rs05",...
%     "rs06","rs07","rs08","rs10",...
%     "rs11","rs12","rs13","rs14"];
%%
%------------r--------------
source_folder='Z:\homes\Peggy\VIVOskinExpe\imageCapture\Hassel\dsp\maleVIVO\r\jpg\noCard';
slashes = strfind(source_folder, '\');
model = source_folder(slashes(1,end-3)+1:slashes(1,end-2)-1);
iOr = source_folder(slashes(1,end-2)+1:slashes(1,end-1)-1);
lastPart=strcat(model,iOr);

files = dir(strcat(source_folder,'\*.jpg'));  % 读取文件夹中的所有.jpg文件

%----------------------

ct=["H3K","H4K","H5K","H6K","H7K","H8K","HD65",...
"L3K","L4K","L5K","L6K","L7K","L8K","LD65",...
"M3K","M4K","M5K","M6K","M7K","M8K","MD65"];


%-----------------------
load(fullfile("aveSkinByHand","aveLab20models.mat"),"ave_lab_mat","lab_cell");

average_file=strcat("aveSkinByHand\",lastPart,"\autoNhand_scaleoverLUT.mat");
average=load(average_file);
average=average.average_lab_all(:,1:3);

%%------------------------
num_points = readmatrix('Z:\homes\Peggy\VIVOskinExpe\points_added_33.xlsx'); 
num_points=[zeros(length(num_points),1),num_points];
%----------加载PMCC--------------
load("pmcc\under21light\PMCCunder21light.mat","lab_PMCC_pre","lab_PMCC");
%-----------准备零件--------------
for i_rs = 1:numel(files)

    filename = fullfile(files(i_rs).folder, files(i_rs).name);      
    [light_str{i_rs,1}]= select_light_r(model,files(i_rs).name(1:end-4));
    ind_ct(i_rs,1) = find(strcmp(ct,light_str{i_rs,1}));
    renCen(i_rs,:)=ave_lab_mat(ind_ct(i_rs,1),:);
    points_select{i_rs,1}=repmat(renCen(i_rs,:),length(num_points),1)+num_points;
    for i_type=1:length(lab_PMCC_pre)
        pmcc_select{i_type,1}(i_rs,:)=lab_PMCC_pre{i_type,1}(ind_ct(i_rs,1),:);
    end
end


%----------output_folder---------

output_folder=fullfile("aveSkinByHand","pic",lastPart);
if ~exist(output_folder,"dir")
    mkdir(output_folder);
end
%%
colors=[[1 0 0];[1 1 0];[0 1 0];[0 0 1]];
%-------画图 ---------
for i_rs=1:length(files)
    figure(i_rs);
    hold on;
    
    plot(points_select{i_rs,1}(:,2),points_select{i_rs,1}(:,3), ...
        'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 5);
    %粗看喜欢的
    plot(points_select{i_rs,1}(fav{i_rs,1},2), ...
        points_select{i_rs,1}(fav{i_rs,1},3), ...
        'ro', 'MarkerFaceColor', 'g', 'MarkerSize', 5);
    text(points_select{i_rs,1}(end,2),points_select{i_rs,1}(end,3), ...
        ct(i_rs), 'Color', 'r', 'FontSize', 6);
    %plot PMCC
    for i_type=1:length(lab_PMCC_pre)
        plot(lab_PMCC_pre{i_type,1}(i_rs,2),lab_PMCC_pre{i_type,1}(i_rs,3), ...
        'p', 'MarkerFaceColor', colors(i_type,:), ...
        'Color',colors(i_type,:),'MarkerSize', 15);
        plot(lab_PMCC{i_type,1}(i_rs,2),lab_PMCC{i_type,1}(i_rs,3), ...
        '^', 'MarkerFaceColor', colors(i_type,:), ...
        'Color',colors(i_type,:),'MarkerSize', 10);
    end
    %plot 

    plot(average(i_rs,2),average(i_rs,3), ...
        'ro', 'MarkerFaceColor', 'b', 'MarkerSize', 5);
    text(average(i_rs,2),average(i_rs,3), ...
        rs_name(i_rs), 'Color', 'm', 'FontSize', 6);

    title(strcat("pmcc under ",rs_name(i_rs)));
    axis equal;
    min_lim=min(min(points_select{i_rs,1}(:,2)),min(points_select{i_rs,1}(:,3)))-5;
    max_lim=max(max(points_select{i_rs,1}(:,2)),max(points_select{i_rs,1}(:,3)))+5;
    xlim([min_lim,max_lim]);
    ylim([min_lim,max_lim]);
    x=min_lim:0.1:max_lim;
    y=x;
    plot(x,y);
    axis equal;
    saveas(i_rs,fullfile(output_folder,strcat(rs_name(i_rs),".jpg")));
end


%%
function[light_str]= select_light_r(model,pic_name_r)
    %---------读取cct---------
    ct_base=[3000,4000,5000,6000,7000,8000,6500];
    ct_base_name=["3K","4K","5K","6K","7K","8K","D65"];
    lightdata_i=load("pmcc\lightbox\Caucasion.mat", ...
        "XYZ_white_unscaled");
    intensity_i=lightdata_i.XYZ_white_unscaled;
    intensity_i(22,:)=[];
    load(strcat("light_r\model_light\",model,".mat"), ...
    "XYZ_white_unscaled","ind_light");
    ind_sheet = cellfun(@(x) strcmp(x, pic_name_r), ind_light(:,1));
    cct=ind_light{ind_sheet,4};
    %--------获得ct_str---------
    [~, ind_cct] = min(abs(ct_base - cct));
    ct_str=ct_base_name(ind_cct);  
    %---------读取intensity--------------------------------
    XYZ_ind=XYZ_white_unscaled(ind_sheet,:);
    [~, closest_index] = min(abs(intensity_i(:,2) - repmat(XYZ_ind(1,2),length(intensity_i),1)));
    if closest_index<=7
        hml_str="H";
    elseif closest_index>=8&&closest_index<=14
        hml_str="L";
    elseif closest_index>=15&&closest_index<=21
        hml_str="M";
    end
    light_str=strcat(hml_str,ct_str);


end


