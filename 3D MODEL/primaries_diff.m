
clc; clear; close all;

%%
n_phones=6;
% for i_device=14
for i_device=1:n_phones
    SPDname = 380:1:780;SPDname = SPDname';
    if i_device<=5
    dir_729data=dir(fullfile("D:\work\VIVOskinExpe\renderCode\calibResults\x200\5", ...
        strcat("VIVO_CS2000_5_x200_", ...
        num2str(i_device),"_1deg_P3*.mat")));
    else
        dir_729data=dir(fullfile("D:\work\VIVOskinExpe\renderCode\calibResults\x200\5", ...
            strcat("VIVO_CS2000_5_x200_4_fof1_1deg_P3*.mat")));
    end
    if isempty(dir_729data)
        warning("No matching file found for i_device=%d, skipping.", i_device);
        continue;
    end
    load(fullfile(dir_729data(1).folder,dir_729data(1).name));
    
    DATAs(1,:) = [];
    SPD = reshape(cell2mat(DATAs(:,4)),401,length(DATAs));
    XYZ10 = spd2xyz([SPDname SPD],10);
    XYZ10_cell{i_device,1}=XYZ10;
    [val, ind]=max(XYZ10);
    XYZw(i_device,:)=XYZ10(ind(2),:);

end

[val1, ind1]=max(XYZw(1:5,:));
for i_device=1:n_phones

    [lab_r{i_device}] = xyz2lab(XYZ10_cell{i_device,1},'user',XYZw(i_device,:));
    [lab_abs{i_device}] = xyz2lab(XYZ10_cell{i_device,1},'user',XYZw(ind1(2),:));

end

% 计算两两之间的平均色差值
for i = 1:n_phones
    for j=1:n_phones
        [de00_r,de00c] = deltaE2000(lab_r{j},lab_r{i});
        [de00_abs,de00c] = deltaE2000(lab_abs{j},lab_abs{i});
        for i_row=1:size(XYZ10,1)
                
            result_matrix_r(i,j,i_row)=de00_r(i_row);
            result_matrix_ave_r(i,j) = mean(de00_r);

            result_matrix_abs(i,j,i_row)=de00_abs(i_row);
            result_matrix_ave_abs(i,j) = mean(de00_abs);

        end
    end        
end
for i_row=1:size(XYZ10,1)
    result_cell_r{i_row}=result_matrix_r(:,:,i_row);
    result_cell_abs{i_row}=result_matrix_abs(:,:,i_row);
end
disp("d")
