clear;clc;close all;
%%

% models=["male92","male91","male48","male59","male39",...
%     "maleVIVO","male21","male46","male22","male28",...
%     "female01","female04","female06","female02","female41",...
%     "femaleVIVO","female23","female51","female25","female69"];

models{1,1}=["male92","male91","male48","female01","female04","female06"];
% models{2,1}=["male59","male39","maleVIVO","female02","female41","femaleVIVO"];
models{2,1}=["male59","male39","maleVIVO","female78","female41","femaleVIVO"];
models{3,1}=["male21","male46","female23","female51"];
models{4,1}=["male22","male28","female25","female69"];

types=["Caucasian","Oriental","South Asian","African"];

ct=["H3K","H4K","H5K","H6K","H7K","H8K","HD65",...
"L3K","L4K","L5K","L6K","L7K","L8K","LD65",...
"M3K","M4K","M5K","M6K","M7K","M8K","MD65"];

a_LC=[4.459300459802465,-47.488828958697376];

ave_folder="aveSkinByHand2";
lab_cell_all=[];picname_check_all=[];labC_HD65_all=[];
for i_type=2:2
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
    ave_lab=zeros(size(lab_cell,1),3);

    for i_model=1:length(models{i_type,1}) 

        for i_ct=1:size(lab_cell,1)

        ave_lab(i_ct,:)=ave_lab(i_ct,:)+lab_cell{i_ct,i_model}./length(models{i_type,1});
        
        end
    end

    
    for i_ct=1:size(lab_cell,1)
        figure(i_ct);
        hold on;
        for i_model=1:length(models{i_type,1}) 
            scatter(lab_cell{i_ct,i_model}(1,2),lab_cell{i_ct,i_model}(1,3),'b');
        end
        scatter(ave_lab(i_ct,2),ave_lab(i_ct,3),'r');
        title(ct(i_ct));

        max_lim=max(max(ave_lab(:,1),max(ave_lab(:,2))))+20;
        min_lim=min(min(ave_lab(:,1),min(ave_lab(:,2))))-20;
        xlim([min_lim,max_lim]);
        ylim([min_lim,max_lim]);
        axis equal;
        grid on;
    end

    % lab_cell_all{i_type,1}=lab_cell;
    picname_check_all{1,1}=picname_check;

    ave_labC=ave_lab;
    ave_labC(:,4)=sqrt(ave_lab(:,2).^2+ ...
    ave_lab(:,3).^2);
    % ave_labC_all{i_type,:}=ave_labC;

save(fullfile("aveSkinByHand2","i",strcat("aveLab_allCT_",num2str(i_type),".mat")), ...
    "ave_labC","lab_cell","picname_check");
end
% save(fullfile("aveSkinByHand2","i","aveLab_4types_D65.mat"), ...
%     "labC_HD65_all","lab_cell_all","picname_check_all","lab_data");


disp("d")