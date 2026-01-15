close all; 
clc;       
clear;     
%% rs
num_points = readmatrix('points_added_33.xlsx'); 
num_points=[zeros(length(num_points),1),num_points];
datai_file = 'calibResults\model3d_file_350_1deg_realP3\datai_ipv40_3.mat';
wd65=[94.813  100.000  107.262];
LUT=load(datai_file);
XYZw_LUT=LUT.XYZw;
wd65_scaled=wd65./100.*XYZw_LUT(2);
%------------r--------------
new_names = [ "f01", "f02", "f03","m01","m02","m03"];
% new_names = [ "f04", "f05", "f06","m04","m05","m06"];
% new_names = ["f07","f08","m07","m08"];
% new_names = ["f09","f10","m09","m10"];

Dtype="full";
for i_model=1:length(new_names)
    source_folder=fullfile('mask',strcat(new_names(i_model),'r'));   
    lastPart=strcat(new_names(i_model),'r');
    model = new_names(i_model);    
    i_type=select_type(model);    
    files = dir(strcat(source_folder,'\*.jpg'));     
    dir_mask=dir(strcat("mask\",lastPart,"\*.jpg"));
    nosh_folder=fullfile("Shadow\mask",lastPart);
    if ~exist(nosh_folder, 'dir')
        mkdir(nosh_folder);
    end
    dir_XYZfile=dir(fullfile("XYZ\1227_r_chgW",lastPart,"*.mat"));    
    
    %----------------------
    if ismember(lastPart,["f04i","f05i","f06i","m04i","m06i"]) 
        if_wei=0;
    else
        if_wei=1;
    end
    if ismember(lastPart,["m02i","m03i"]) 
        if_2mask=1;
    else
        if_2mask=0;
    end
    load(fullfile("aveSkinByHand2","i",strcat("aveLab_D65_",num2str(i_type),".mat")), ...
        "labC_HD65");
   
    
    save_folder=fullfile('rendered\33_r_lateCAT1_clf',lastPart);
    if ~exist(save_folder, 'dir')
        mkdir(save_folder);
    end
    
    load(fullfile("light_r\model_tcp",strcat(model,".mat")));
    
    % for i = [1,6,7,8]
    for i = 1:length(files)
    
        filename = fullfile(files(i).folder, files(i).name);      
        img0=imread(filename);
    %--------先跑小图看问题--------
        % img0 = imresize(img0, [size(img0,1)./6, size(img0,2)./6]);
    
        img=im2double(img0);
        [m,n,p]=size(img);
    
        startCenter=1;
        endCenter=length(num_points);
    
        for i_mask=1:length(dir_mask)
            if strcmp(files(i).name(1:end-4),dir_mask(i_mask).name(1:end-4))
            bull=imread(strcat(dir_mask(i_mask).folder,'\',dir_mask(i_mask).name));
            % bull = imresize(bull, [size(bull,1)./6, size(bull,2)./6]);%先跑小图看问题
                break
            end
        end

        for i_xyz=1:length(dir_XYZfile)
            if strcmp(dir_XYZfile(i_xyz).name(end-7:end-4),files(i).name(1:end-4))
                XYZ=load(fullfile(dir_XYZfile(i_xyz).folder,dir_XYZfile(i_xyz).name));
                XYZ=XYZ.XYZ_cropped;
                %------先跑小图看问题-------
                 % XYZ = imresize(XYZ, [size(XYZ,1)./6, size(XYZ,2)./6]);       
                break
            end
        end
        img=im2double(img0);
        [m, n, p] = size(img);
        xyz1= reshape(XYZ, [m * n, p]);
        [lab1] = xyz2lab(xyz1,'user',wd65_scaled);
        if if_2mask
            average(i,:)=get_average(lab1,bull_nosd,if_wei);
        else
            average(i,:)=get_average(lab1,bull,if_wei);
        end

        if ismember(i_type,[2])
            C_pre=6.7421*log(average(i,1))-9.9816;%亮度实验
        elseif ismember(i_type,[1,3,4])
            load(fullfile("aveSkinByHand2\i\C_Lpara",...
            strcat(num2str(i_type),"C_L_para.mat")),"a_CL");
            C_pre=a_CL(1)*log(average(i,1))+a_CL(2);
        end

        factor(i,:)=C_pre./labC_HD65(1,4);
        dlabs=repmat([average(i,1),labC_HD65(1,2:3)],length(num_points),1)+num_points;
        dlabs(:,2:3)=dlabs(:,2:3).*factor(i,:);
        %-----------后CAT-----------        
        CCT=model_tcp_mean(i,1);
        for i_points=startCenter:1:endCenter
            dlabs(i_points,:)=CAT_lab2lab1(dlabs(i_points,:),Dtype,CCT,"fore");            
        end   

        delta_Lab=dlabs(1,:)-average(i,:);
        delta_Lab0=dlabs(33,:)-average(i,:);

        %---------渲染-----------
        [dest_lab,bull_nosd]=...
        img_AddRender_gen_nosh(img,bull,'LUT',delta_Lab, ...
        XYZ,delta_Lab0,if_wei);
%         ---------渲染-----------
        imshow(bull_nosd);
        imwrite(bull_nosd,fullfile(nosh_folder,files(i).name));

    end
end

%% i
% % new_names = [ "f01", "f02", "f03","m01","m02","m03"];
% % new_names = [ "f04", "f05", "f06","m04","m05","m06"];
% % new_names = [ "f07", "f08", "m07","m08"];
% new_names = [ "f09", "f10", "m09","m10"];
% Dtype="summer";
% % new_names = ["f01", "f02", "f03", "f04", ...
% %              "f05", "f06", "f07", "f08", "f09", "f10",...
% %              "m01", "m02", "m03", "m04", "m05", "m06", "m07", ...
% %              "m08", "m09", "m10"];
% 
% ct=["H3K","H4K","H5K","H6K","H7K","H8K","HD65",...
% "L3K","L4K","L5K","L6K","L7K","L8K","LD65",...
% "M3K","M4K","M5K","M6K","M7K","M8K","MD65"];
% wd65_64 = [94.811, 100.00, 107.304];
% CT = [3000, 4000, 5000, 6000, 7000, 8000, 6500, ...
%   3000, 4000, 5000, 6000, 7000, 8000, 6500, ...
%   3000, 4000, 5000, 6000, 7000, 8000, 6500]';
% 
% 
% attribute_names = ["Preference", "Attractiveness", "Feminine", "Cooperative", ...
%         "Youth", "Healthy", "Precise reproduction", "suit the environment or not", "white-skinned", "ruddy"];
% for i_model=[3]
% % for i_model=1:length(new_names)
%     source_folder=fullfile('mask',strcat(new_names(i_model),'i'));
%     source_folder=char(source_folder);
%     slashes = strfind(source_folder, '\');
%     lastPart=source_folder(slashes(1,end)+1:end);
%     if strcmp(lastPart,"m05i")
%         if_wei=1;
%     else
%         if_wei=0;
%     end
%     model = lastPart(1:end-1);
% 
%     i_type=select_type(model);
% 
%     files = dir(strcat(source_folder,'\*.jpg'));  % 读取文件夹中的所有.jpg文件
% 
%     dir_mask=dir(strcat("mask\",lastPart,"\*.jpg"));
%     dir_XYZfile=dir(strcat("XYZ\maxw_i\",lastPart,"\*.mat"));
%     %----------------------
% 
% 
% 
%     load(fullfile("aveSkinByHand2","i",strcat("aveLab_D65_",num2str(i_type),".mat")), ...
%         "labC_HD65");
%     lab_PMCC = [62.11, 18.96, 19.76];
%     labC_PMCC = [lab_PMCC, sqrt(lab_PMCC(1, 2)^2 + lab_PMCC(1, 3)^2)];
% 
%     average_file=strcat("aveSkinByHand2\",lastPart,"\autoNhand_scaleoverLUT.mat");
%     average=load(average_file);
%     average=average.average_lab_all(:,1:3);
% 
%     target_score=0.5;
%     save_folder=fullfile('Shadow\mask',lastPart);
%     % save_folder=fullfile('rendered\33_i_wei\PNp\nosd_mask',lastPart);
%     if ~exist(save_folder, 'dir')
%         mkdir(save_folder);
%     end
%     nosh_folder=fullfile(save_folder,"nosd");
%     if ~exist(nosh_folder, 'dir')
%         mkdir(nosh_folder);
%     end
% 
%     num_points = readmatrix('points_added_33.xlsx'); 
%     num_points=[zeros(length(num_points),1),num_points];
%         % 计算labC_PMCCpre
%     for i = 1:numel(files)
% 
%         C_pre=6.7421*log(average(i,1))-9.9816;%亮度实验
%         factor(i,:)=C_pre./labC_HD65(1,4);
%         dlabs=repmat([average(i,1),labC_HD65(1,2:3)],length(num_points),1)+num_points;
%         dlabs(:,2:3)=dlabs(:,2:3).*factor(i,:);
%         labC_PMCCpre(i, 1) = average(i, 1);
%         labC_PMCCpre(i, 2:3) = lab_PMCC(1, 2:3) ./ labC_PMCC(1, 4) .* C_pre;
%         labC_PMCCpre(i, 4) = C_pre;
%     end
%     %% 
%     attributes=1:10;
%     for i = 1:numel(files)
% 
%         filename = fullfile(files(i).folder, files(i).name);    
% 
%         img0=imread(filename);
%     %--------先跑小图看问题--------
%         % img0 = imresize(img0, [size(img0,1)./6, size(img0,2)./6]);
% 
%         img=im2double(img0);
%         [m,n,p]=size(img);
% 
%         startCenter=1;
%         endCenter=length(num_points);
%         % load mask和XYZ
%         for i_mask=1:length(dir_mask)
%             if strcmp(files(i).name(1:end-4),dir_mask(i_mask).name(1:end-4))
%                 picname_check{i,1}=files(i).name(1:end-4);
%                 picname_check{i,2}=dir_mask(i_mask).name(1:end-4);
%                 bull=imread(strcat(dir_mask(i_mask).folder,'\',dir_mask(i_mask).name));
%                  % bull = imresize(bull, [size(bull,1)./6, size(bull,2)./6]);%先跑小图看问题
%                 break
%             end
%         end
%         for i_xyz=1:length(dir_XYZfile)
%             if strcmp(dir_XYZfile(i_xyz).name(1:end-4),files(i).name(1:end-4))
%                 picname_check{i,4}=dir_XYZfile(i_xyz).name(1:end-4);
%                 XYZ=load(fullfile(dir_XYZfile(i_xyz).folder,dir_XYZfile(i_xyz).name));
%                 XYZ=XYZ.XYZ_cropped;
%                 break
%             end
%         end
%             % 
%             % % %------先跑小图看问题-------
%             % XYZ = imresize(XYZ, [size(XYZ,1)./6, size(XYZ,2)./6]);
% 
%             %-----render PMCC-------------
%             CCT=CT(i);
%             dlab=CAT_lab2lab(labC_PMCCpre(i,1:3),Dtype,CCT);
%             delta_Lab=dlab-average(i,:); 
%             delta_Lab0=dlabs(33,:)-average(i,:); 
%             %决定要不要render 
%             % if ~exist(fullfile(save_folder,files(i).name(1:end-4)),"dir")
%             %     mkdir(fullfile(save_folder,files(i).name(1:end-4)));
%             % end
%             dir_img_file=dir(fullfile(save_folder,files(i).name(1:end-4), ...
%                         strcat(files(i).name(1:end-4),'_','PMCC[',num2str(dlab(1,1)),',' ,...
%                         num2str(dlab(1,2)),',',num2str(dlab(1,3)),'].jpg')) );
%             if_render=1;
%             % if ~isempty(dir_img_file)
%             %     if_render=0;
%             % end
%             % if_render=0;
% 
%             noFaceRGB_folder=fullfile(save_folder,"noFaceRGB");
%             % if ~exist(noFaceRGB_folder,"dir")
%             %     mkdir(noFaceRGB_folder);
%             % end
%             noFaceRGB_file=fullfile(noFaceRGB_folder, ...
%                 strcat(files(i).name(1:end-4),".mat"));
% 
%             if if_render
%                     disp([files(i).name,'PMCC begin']);
%                     startTime = datetime('now'); 
%                     %渲染
% 
%                     [dest_lab,bull_nosd]=...
%                     img_AddRender_gen_nosh(img,bull,'LUT',delta_Lab, ...
%                     XYZ,noFaceRGB_file,delta_Lab0,if_wei,i,lastPart);
% 
% 
%                     deltaE2000(dest_lab,dlab)
% 
%                     figure(2);
%                     imshow(bull_nosd);
%                     imwrite(bull_nosd,fullfile(nosh_folder,files(i).name));
%                     currentTime = datetime('now');
%                     fprintf('时间差: %s\n', currentTime - startTime);
%             end
% 
%     end
% 
% end

