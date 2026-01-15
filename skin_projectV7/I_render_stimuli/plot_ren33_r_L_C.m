close all; 
clc;       
clear;     

%%
%------------r--------------
source_folder='Z:\homes\Peggy\VIVOskinExpe\imageCapture\Hassel\dsp\maleVIVO\r\jpg\noCard';
i_type=2;
% source_folder='Z:\homes\Peggy\VIVOskinExpe\imageCapture\Hassel\dsp\femaleVIVO\r\jpg\noCard';
slashes = strfind(source_folder, '\');
model = source_folder(slashes(1,end-3)+1:slashes(1,end-2)-1);
iOr = source_folder(slashes(1,end-2)+1:slashes(1,end-1)-1);
lastPart=strcat(model,iOr);

files = dir(strcat(source_folder,'\*.jpg'));  % 读取文件夹中的所有.jpg文件




%----------------------
ct=["H3K","H4K","H5K","H6K","H7K","H8K","HD65",...
"L3K","L4K","L5K","L6K","L7K","L8K","LD65",...
"M3K","M4K","M5K","M6K","M7K","M8K","MD65"];


load(fullfile("aveSkinByHand","i","aveLab_4types_D65.mat"), ...
    "labC_HD65","lab_cell_all","picname_check_all");
a_LC=[4.459300459802465,-47.488828958697376];

average_file=strcat("aveSkinByHand\",lastPart,"\autoNhand_scaleoverLUT.mat");
average=load(average_file);
average=average.average_lab_all(:,1:3);

load("pmcc\under21light\PMCCunder21light.mat","lab_PMCC_pre","lab_PMCC","a_LC_pmcc");


save_folder=fullfile('Z:\homes\Peggy\VIVOskinExpe\imageCapture\Hassel\rendered\33_r_L_C\pic',lastPart);
if ~exist(save_folder, 'dir')
    mkdir(save_folder);
end

num_points = readmatrix('D:\work\VIVOskinExpe\points_added_33.xlsx'); 
% num_points = readmatrix('Z:\homes\Peggy\VIVOskinExpe\points_added_33.xlsx'); 
num_points=[zeros(length(num_points),1),num_points];



for i = 1:numel(files)

    startCenter=1;
    endCenter=length(num_points);

    C_pre=(average(i,1)-a_LC(2))./a_LC(1);
    factor(i,:)=C_pre./labC_HD65(i_type,4);
    dlabs=repmat(labC_HD65(i_type,1:3),length(num_points),1)+num_points;
    dlabs(:,2:3)=dlabs(:,2:3).*factor(i,:);
    dlabs_all{i,1}=dlabs;
    dlabs_all{i,2}=files(i).name(1:end-4);

    figure();
    hold on;
    scatter(dlabs(:,2),dlabs(:,3));


    plot(lab_PMCC_pre{i_type,1}(i,2),lab_PMCC_pre{i_type,1}(i,3), ...
    'p', 'MarkerFaceColor', "r", ...
    'Color',"r",'MarkerSize', 15);
    plot(lab_PMCC{i_type,1}(i,2),lab_PMCC{i_type,1}(i,3), ...
    '^', 'MarkerFaceColor', "b", ...
    'Color',"b",'MarkerSize', 10);

    plot(average(i,2),average(i,3), ...
    'd', 'MarkerSize', 10);

    axis equal;
    min_lim=-15;
    max_lim=60;
    xlim([min_lim,max_lim]);
    ylim([min_lim,max_lim]);
    x=min_lim:0.1:max_lim;
    y=x;
    plot(x,y);
    
    title(strcat(model,iOr,files(i).name));
    
    saveas(gcf,fullfile(save_folder,strcat(files(i).name(1:end-4),".jpg")));
end


