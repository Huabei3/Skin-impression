clear;clc;close all;
%%
models{1,1}=["m01","m02","m03","f01","f02","f03"];
models{2,1}=["m04","m05","m06","f04","f05","f06"];
models{3,1}=["m07","m08","f07","f08"];
models{4,1}=["m09","m10","f09","f10"];

% models{1,1}=["male92","male91","male48","female01","female04","female06"];
% models{2,1}=["male59","male39","maleVIVO","female78","female41","femaleVIVO"];
% models{3,1}=["male21","male46","female23","female51"];
% models{4,1}=["male22","male28","female25","female69"];

types=["Caucasian","Oriental","South Asian","African"];

ct=["H3K","H4K","H5K","H6K","H7K","H8K","HD65",...
"L3K","L4K","L5K","L6K","L7K","L8K","LD65",...
"M3K","M4K","M5K","M6K","M7K","M8K","MD65"];

a_LC=[4.459300459802465,-47.488828958697376];

num_points = readmatrix('points_added_33.xlsx'); 
num_points=[zeros(length(num_points),1),num_points];

ave_folder="aveSkinByHand2";
lab_cell_all=[];picname_check_all=[];labC_HD65_all=[];
for i_type=[1,3,4]
% for i_type=1:length(models)
    lab_cell=[];picname_check=[];
    for i_model=1:length(models{i_type,1})    
        file_ave=fullfile(ave_folder,strcat(models{i_type,1}(i_model),'i'),"autoNhand_scaleoverLUT.mat");
        picname_check{i_model,1}=models{i_type,1}(i_model);
        ave_data=load(file_ave);
        for i_ct=1:length(ave_data.average_lab_all)
            if sum(ave_data.average_lab_all(i_ct,:))~=0
                lab_cell{i_ct,i_model}=ave_data.average_lab_all(i_ct,:);
            end
        end
        lab_data{i_type,i_model}=ave_data.average_lab_all;
    end
    % ave_temp=zeros(1,3);
    labC_ind_D65=[];
    figure();
    hold on;

    for i_model=1:length(models{i_type,1}) 
        labC_ind_D65=[labC_ind_D65;lab_cell{7,i_model}];
        % ave_temp=ave_temp+lab_cell{7,i_model}./length(models{i_type,1});
        plot(lab_cell{7,i_model}(1,2),lab_cell{7,i_model}(1,3), ...
            'p', 'MarkerSize', 10, 'MarkerFaceColor', ...
            'b', 'MarkerEdgeColor', 'b');
        hold on;
    end
    labC_ind_D65(:,4)=sqrt(labC_ind_D65(:,2).^2+labC_ind_D65(:,3).^2);
    % labC_HD65(1,1:3)=ave_temp;
    labC_HD65(1,1:3)=mean(labC_ind_D65(1:3));
    plot(labC_HD65(1,2),labC_HD65(1,3), 'p', 'MarkerSize', 10, 'MarkerFaceColor', 'red', 'MarkerEdgeColor', 'red');
    dlabs=repmat([0,labC_HD65(1,2:3)],length(num_points),1)+num_points;
    scatter(dlabs(:,2),dlabs(:,3));
    disp("d")
    max_lim=max(max(dlabs(:,2),max(dlabs(:,3))))+5;
    min_lim=min(min(dlabs(:,2),min(dlabs(:,3))))-5;
    axis equal;
    xlim([min_lim,max_lim]);
    ylim([min_lim,max_lim]);
    exportgraphics(gcf,fullfile("aveSkinByHand2","i", ...
        strcat("aveLab_D65_",num2str(i_type),".jpg")),'Resolution',150);
    lab_cell_all{i_type,1}=lab_cell;
    picname_check_all{1,1}=picname_check;

    labC_HD65(1,4)=sqrt(labC_HD65(1,2).^2+ ...
        labC_HD65(1,3).^2);
    labC_HD65_all(i_type,:)=labC_HD65;
    disp("d")
    
% save(fullfile("aveSkinByHand2","i",strcat("aveLab_D65_",num2str(i_type),".mat")), ...
%     "labC_HD65","lab_cell","picname_check");
end
% save(fullfile("aveSkinByHand2","i","aveLab_4types_D65.mat"), ...
%     "labC_HD65_all","lab_cell_all","picname_check_all","lab_data");


disp("d")