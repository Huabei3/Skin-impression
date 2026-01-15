
%%
% close all; 
% clc;       
% clear;     
addpath("utils\")
%%
% clear("dlab_theo");
% for i_the=1:length(dE_cell)
%     if ~isempty(dE_cell{i_the,1})
%         slash=find(dE_cell{i_the,1}=='[');
%         dlab_theo{i_the,1}=dE_cell{i_the,1}(1:slash-1);
%         dlab_theo{i_the,2}=dE_cell{i_the,3};
%     end
% end
% save(fullfile(strrep(save_folder,lastPart,""),"dlab_theo_i_CA_SA_AF.mat"),"dlab_theo");
% A=load(fullfile(strrep(save_folder,lastPart,""),"dlab_theo_i_CA_SA_AF.mat"),"dlab_theo");
%% % main_i  
%----------------------
ct=["H3K","H4K","H5K","H6K","H7K","H8K","HD65",...
"L3K","L4K","L5K","L6K","L7K","L8K","LD65",...
"M3K","M4K","M5K","M6K","M7K","M8K","MD65"];
CT = [3000, 4000, 5000, 6000, 7000, 8000, 6500, ...
  3000, 4000, 5000, 6000, 7000, 8000, 6500, ...
  3000, 4000, 5000, 6000, 7000, 8000, 6500]';
datai_file = 'calibResults\datai_ipv18_3.mat';
wd65=[94.813  100.000  107.262];
LUT=load(datai_file);
XYZw_LUT=LUT.XYZw;
wd65_scaled=wd65./100.*XYZw_LUT(2);
% load("render_range.mat","shift_range","db_range");
%------------i--------------
% new_names = [ "m01","m02","m03",...
%     "f07","f08","m07","m08",...
%     "f09","f10","m09","m10"];
new_names = [ "f04", "f05", "f06","m04","m05","m06"];
Dtype="full";i_file=1;
for i_model=1:length(new_names)
    source_folder=fullfile('mask',strcat(new_names(i_model),'i'));
    source_folder=char(source_folder);
    slashes = find(source_folder== '\');
    lastPart=source_folder(slashes(1,end)+1:end);    

    model = lastPart(1:end-1);

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
    i_type=select_type(model);
    
    files = dir(strcat(source_folder,'\*.jpg'));  % 读取文件夹中的所有.jpg文件
    
    dir_mask=dir(strcat("mask\",lastPart,"\*.jpg"));
    dir_mask_nosd=dir(fullfile("Shadow\mask",lastPart,"nosd\*.jpg"));
    dir_XYZfile=dir(strcat("XYZ\i\",lastPart,"\*.mat"));
    
    
    load(fullfile("aveSkinByHand2","i",strcat("aveLab_D65_",num2str(i_type),".mat")), ...
        "labC_HD65");  
    
    save_folder=fullfile('rendered\i\adjust',lastPart);

    if ~exist(save_folder, 'dir')
        mkdir(save_folder);
    end
    % load(fullfile(strrep(save_folder,lastPart,""),"dlab_theo_i_CA_SA_AF.mat"),"dlab_theo");
    
    num_points = readmatrix('points_added_33.xlsx'); 
    num_points=[zeros(length(num_points),1),num_points];
    % for i =[1,7,8,14,15,21]
    for i =1: numel(files)
    
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
                picname_check{i,1}=files(i).name(1:end-4);
                picname_check{i,2}=dir_mask(i_mask).name(1:end-4);
                bull=imread(strcat(dir_mask(i_mask).folder,'\',dir_mask(i_mask).name));
                % bull = imresize(bull, [size(bull,1)./6, size(bull,2)./6]);%先跑小图看问题
                break
            end
        end
        for i_mask=1:length(dir_mask_nosd)
            if strcmp(files(i).name(1:end-4),dir_mask_nosd(i_mask).name(1:end-4))
                bull_nosd=imread(strcat(dir_mask_nosd(i_mask).folder,'\',dir_mask_nosd(i_mask).name));
                % bull_nosd = imresize(bull_nosd, [size(bull_nosd,1)./6, size(bull_nosd,2)./6]);%先跑小图看问题
                break
            end
        end
        for i_xyz=1:length(dir_XYZfile)
            if strcmp(dir_XYZfile(i_xyz).name(1:end-4),files(i).name(1:end-4))
                picname_check{i,4}=dir_XYZfile(i_xyz).name(1:end-4);
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

        a_CL=[];
        if ismember(i_type,[1,2])
            a_CL=[6.7421,-9.9816];
        elseif ismember(i_type,[3,4])
            load(fullfile("aveSkinByHand2\i\C_Lpara",...
            strcat(num2str(i_type),"C_L_para.mat")),"a_CL");
        end

        if average(i,1)>60
            C_pre=a_CL(1)*log(60)+a_CL(2);%亮度实验
        else
            C_pre=a_CL(1)*log(average(i,1))+a_CL(2);%亮度实验
        end

        factor=C_pre./labC_HD65(1,4);
        dlabs=repmat([average(i,1),labC_HD65(1,2:3)],length(num_points),1)+num_points;
        dlabs(:,2:3)=dlabs(:,2:3).*factor;

        %计算delta_Lab
        CCT=CT(i);
        for i_points=startCenter:1:endCenter
            dlab_CATed(i_points,:)=CAT_lab2lab1(dlabs(i_points,:),Dtype,CCT,"fore");            
        end
        dlab_CATed=adjust_dlabs_shape1(dlab_CATed);
        if i_type==4
            if ismember(model,["f09","m09"])
                adj=0.55;
            elseif ismember(model,["f10"])
                adj=0.54;
            elseif ismember(model,["m10"])
                adj=0.5;
            end
            dlab_CATed=adjust_dlabs(dlab_CATed,adj);
        end

        % figure(1)
        % plot_render_points(dlab_CATed)
        % draw_folder=fullfile(save_folder,"draw");
        % if ~exist(draw_folder,"dir")
        %     mkdir(draw_folder);
        % end
        % exportgraphics(gcf,fullfile(draw_folder,strcat(lastPart,files(i).name)),'Resolution',150);
        % clf;
        
        % adjust
        delta_Lab=dlab_CATed-repmat(average(i,:),length(dlabs),1);
        for i_points=startCenter:1:endCenter  
        % for i_points=startCenter:1:endCenter  
            % dlab=dlabs(i_points,:);
            % delta_Lab(i_points,:)=dlab-average(i,:);
            dlab=delta_Lab(i_points,:)+average(i,:);

%             %---------渲染-----------

            [dest_lab] = img_AddRender_gendlab(img, bull,bull_nosd, 'LUT', ...
            delta_Lab(i_points,:),XYZ,if_wei,if_2mask);

            dlab_theo{i_file,1}=strcat(lastPart,files(i).name(1:end-4),'_',sprintf('%02d', i_points));  
            dlab_theo{i_file,2}=dest_lab;
            % dlab_theo{i_file,3}=dE_points;
            i_file=i_file+1;
        end

    end
end
save(fullfile(strrep(save_folder,lastPart,""), ...
    "dlab_theo_i_AS.mat"),"dlab_theo");
disp("d")
% save(fullfile(strrep(save_folder,lastPart,""),"dlab_theo_i_CA_SA_AF_m0203.mat"),"dlab_theo");

%% main_rs 3.12版本
% % 
% num_points = readmatrix('points_added_33.xlsx'); 
% num_points=[zeros(length(num_points),1),num_points];
% datai_file = 'calibResults\data_ipv18_3.mat';
% wd65=[94.813  100.000  107.262];
% LUT=load(datai_file);
% XYZw_LUT=LUT.XYZw;
% wd65_scaled=wd65./100.*XYZw_LUT(2);
% 
% %%
% %------------r--------------
% new_names = [ "f01", "f02", "f03","m01","m02","m03",...
%     "f07","f08","m07","m08",...
%     "f09","f10","m09","m10"];
% Dtype="full";i_file=1;
% for i_model=1:length(new_names)
%     source_folder=fullfile('mask',strcat(new_names(i_model),'r'));   
%     lastPart=strcat(new_names(i_model),'r');
%     model = new_names(i_model);    
%     i_type=select_type(model);    
%     files = dir(strcat(source_folder,'\*.jpg'));     
%     dir_mask=dir(strcat("mask\",lastPart,"\*.jpg"));
%     dir_XYZfile=dir(fullfile("XYZ\rs",lastPart,"*.mat"));    
% 
%     %----------------------
%     if ismember(lastPart,["f04i","f05i","f06i","m04i","m06i"]) 
%         if_wei=0;
%     else
%         if_wei=1;
%     end
% 
%     load(fullfile("aveSkinByHand2","i",strcat("aveLab_D65_",num2str(i_type),".mat")), ...
%         "labC_HD65");   
% 
%     save_folder=fullfile('rendered\rs\adjust',lastPart);
%     if ~exist(save_folder, 'dir')
%         mkdir(save_folder);
%     end
% 
% 
%     load(fullfile("light_r\model_tcp",strcat(model,".mat")));
%     % for i = [8]
%     for i = 1:length(files)
% 
%         filename = fullfile(files(i).folder, files(i).name);      
%         img0=imread(filename);
%     %--------先跑小图看问题--------
%         % img0 = imresize(img0, [size(img0,1)./6, size(img0,2)./6]);
% 
%         img=im2double(img0);
%         [m,n,p]=size(img);
% 
%         startCenter=1;
%         endCenter=length(num_points);
% 
%         for i_mask=1:length(dir_mask)
%             if strcmp(files(i).name(1:end-4),dir_mask(i_mask).name(1:end-4))
%             bull=imread(strcat(dir_mask(i_mask).folder,'\',dir_mask(i_mask).name));
%             % bull = imresize(bull, [size(bull,1)./6, size(bull,2)./6]);%先跑小图看问题
%                 break
%             end
%         end
% 
%         for i_xyz=1:length(dir_XYZfile)
%             if strcmp(dir_XYZfile(i_xyz).name(end-7:end-4),files(i).name(1:end-4))
%                 XYZ=load(fullfile(dir_XYZfile(i_xyz).folder,dir_XYZfile(i_xyz).name));
%                 XYZ=XYZ.XYZ_cropped;
%                 %------先跑小图看问题-------
%                  % XYZ = imresize(XYZ, [size(XYZ,1)./6, size(XYZ,2)./6]);       
%                 break
%             end
%         end
%         img=im2double(img0);
%         [m, n, p] = size(img);
%         xyz1= reshape(XYZ, [m * n, p]);
%         [lab1] = xyz2lab(xyz1,'user',wd65_scaled);
% 
%         average(i,:)=get_average(lab1,bull,if_wei);
% 
%         a_CL=[];
%         lastPart=char(lastPart);
%         if ismember(i_type,[1,2])
%             a_CL=[6.7421,-9.9816];
%         elseif ismember(i_type,[3,4])
%             load(fullfile("aveSkinByHand2\i\C_Lpara",...
%             strcat(num2str(i_type),"C_L_para.mat")),"a_CL");
%         end
% 
%         if average(i,1)>60
%             C_pre=a_CL(1)*log(60)+a_CL(2);%亮度实验
%         else
%             C_pre=a_CL(1)*log(average(i,1))+a_CL(2);%亮度实验
%         end
% 
% 
%         if i_type==4
%             load(fullfile("aveSkinByHand2",strcat(model,"i"), ...
%                 "autoNhand_scaleoverLUT.mat"),"average_lab_all");
%             C_HD65_ind=sqrt(average_lab_all(7,2).^2+average_lab_all(7,3).^2);
%             labC_HD65(1,2:4)=labC_HD65(1,2:4)./labC_HD65(1,4).*C_HD65_ind;
%         end
%         factor=C_pre./labC_HD65(1,4);
%         dlabs=repmat([average(i,1),labC_HD65(1,2:3)],length(num_points),1)+num_points;
%         dlabs(:,2:3)=dlabs(:,2:3).*factor;
% 
%         %-----------后CAT-----------        
%         CCT=model_tcp_mean(i,1);
%         for i_points=endCenter:-1:startCenter
%             dlabs(i_points,:)=CAT_lab2lab1(dlabs(i_points,:),Dtype,CCT,"fore",wd65,wd65);            
%         end   
%         dlabs=adjust_dlabs_shape1(dlabs);
%         if i_type==4
%             dlabs=adjust_dlabs(dlabs,0.5);
%         end
% 
%     %     %render
%         for i_points=startCenter:endCenter
% 
%     %         %--------算中心-------
% 
%             dlab=dlabs(i_points,:);
%             delta_Lab=dlab-average(i,:);
% 
%             if_2mask=0;
%             [dest_lab] = img_AddRender_gendlab(img, bull,bull, 'LUT', ...
%             delta_Lab,XYZ,if_wei,if_2mask);
% 
%             dlab_theo{i_file,1}=strcat(lastPart,files(i).name(1:end-4),'_',sprintf('%02d', i_points));  
%             dlab_theo{i_file,2}=dest_lab;
%             % dlab_theo{i_file,3}=dE_points;
%             i_file=i_file+1;
%         end
% 
%     end
% end
% 
% save(fullfile(strrep(save_folder,lastPart,""),"dlab_theo_r_CA_SA.mat"),"dlab_theo");
%% %  main_i 
%----------------------
% ct=["H3K","H4K","H5K","H6K","H7K","H8K","HD65",...
% "L3K","L4K","L5K","L6K","L7K","L8K","LD65",...
% "M3K","M4K","M5K","M6K","M7K","M8K","MD65"];
% CT = [3000, 4000, 5000, 6000, 7000, 8000, 6500, ...
%   3000, 4000, 5000, 6000, 7000, 8000, 6500, ...
%   3000, 4000, 5000, 6000, 7000, 8000, 6500]';
% datai_file = 'calibResults\datai_ipv18_3.mat';
% wd65=[94.813  100.000  107.262];
% LUT=load(datai_file);
% XYZw_LUT=LUT.XYZw;
% wd65_scaled=wd65./100.*XYZw_LUT(2);
% % load("render_range.mat","shift_range","db_range");
% %------------i--------------
% new_names = [ "f01", "f02", "f03","m01","m02","m03",...
%     "f04", "f05", "f06","m04","m05","m06",...
%     "f07","f08","m07","m08"];
% Dtype="full";i_file=1;
% for i_model=1:length(new_names)
%     source_folder=fullfile('mask',strcat(new_names(i_model),'i'));
%     source_folder=char(source_folder);
%     slashes = find(source_folder== '\');
%     lastPart=source_folder(slashes(1,end)+1:end);    
% 
%     model = lastPart(1:end-1);
% 
%     if ismember(lastPart,["f04i","f05i","f06i","m04i","m06i"]) 
%         if_wei=0;
%     else
%         if_wei=1;
%     end
%     if ismember(lastPart,["m02i","m03i"]) 
%         if_2mask=1;
%     else
%         if_2mask=0;
%     end
%     i_type=select_type(model);
% 
%     files = dir(strcat(source_folder,'\*.jpg'));  % 读取文件夹中的所有.jpg文件
% 
%     dir_mask=dir(strcat("mask\",lastPart,"\*.jpg"));
%     dir_mask_nosd=dir(fullfile("Shadow\mask",lastPart,"nosd\*.jpg"));
%     dir_XYZfile=dir(strcat("XYZ\i\",lastPart,"\*.mat"));
% 
% 
%     load(fullfile("aveSkinByHand2","i",strcat("aveLab_D65_",num2str(i_type),".mat")), ...
%         "labC_HD65");  
% 
%     save_folder=fullfile('rendered\i\adjust',lastPart);
% 
%     if ~exist(save_folder, 'dir')
%         mkdir(save_folder);
%     end
% 
%     num_points = readmatrix('points_added_33.xlsx'); 
%     num_points=[zeros(length(num_points),1),num_points];
%     % for i =[1,7,8,14,15,21]
%     for i =1: numel(files)
% 
%         filename = fullfile(files(i).folder, files(i).name);      
%         img0=imread(filename);
%     %--------先跑小图看问题--------
%         % img0 = imresize(img0, [size(img0,1)./6, size(img0,2)./6]);
% 
%         img=im2double(img0);
%         [m,n,p]=size(img);
% 
%         startCenter=1;
%         endCenter=length(num_points);
% 
%         for i_mask=1:length(dir_mask)
%             if strcmp(files(i).name(1:end-4),dir_mask(i_mask).name(1:end-4))
%                 picname_check{i,1}=files(i).name(1:end-4);
%                 picname_check{i,2}=dir_mask(i_mask).name(1:end-4);
%                 bull=imread(strcat(dir_mask(i_mask).folder,'\',dir_mask(i_mask).name));
%                 % bull = imresize(bull, [size(bull,1)./6, size(bull,2)./6]);%先跑小图看问题
%                 break
%             end
%         end
%         for i_mask=1:length(dir_mask_nosd)
%             if strcmp(files(i).name(1:end-4),dir_mask_nosd(i_mask).name(1:end-4))
%                 bull_nosd=imread(strcat(dir_mask_nosd(i_mask).folder,'\',dir_mask_nosd(i_mask).name));
%                 % bull_nosd = imresize(bull_nosd, [size(bull_nosd,1)./6, size(bull_nosd,2)./6]);%先跑小图看问题
%                 break
%             end
%         end
%         for i_xyz=1:length(dir_XYZfile)
%             if strcmp(dir_XYZfile(i_xyz).name(1:end-4),files(i).name(1:end-4))
%                 picname_check{i,4}=dir_XYZfile(i_xyz).name(1:end-4);
%                 XYZ=load(fullfile(dir_XYZfile(i_xyz).folder,dir_XYZfile(i_xyz).name));
%                 XYZ=XYZ.XYZ_cropped;
%                 %------先跑小图看问题-------
%                 % XYZ = imresize(XYZ, [size(XYZ,1)./6, size(XYZ,2)./6]);      
%                 break
%             end
%         end
% 
%         img=im2double(img0);
%         [m, n, p] = size(img);
%         xyz1= reshape(XYZ, [m * n, p]);
%         [lab1] = xyz2lab(xyz1,'user',wd65_scaled);
%         if if_2mask
%             average(i,:)=get_average(lab1,bull_nosd,if_wei);
%         else
%             average(i,:)=get_average(lab1,bull,if_wei);
%         end
% 
%         a_CL=[];
%         if ismember(i_type,[1,2])
%             a_CL=[6.7421,-9.9816];
%         elseif ismember(i_type,[3,4])
%             load(fullfile("aveSkinByHand2\i\C_Lpara",...
%             strcat(num2str(i_type),"C_L_para.mat")),"a_CL");
%         end
% 
%         if average(i,1)>60
%             C_pre=a_CL(1)*log(60)+a_CL(2);%亮度实验
%         else
%             C_pre=a_CL(1)*log(average(i,1))+a_CL(2);%亮度实验
%         end
% 
%         factor=C_pre./labC_HD65(1,4);
%         dlabs=repmat([average(i,1),labC_HD65(1,2:3)],length(num_points),1)+num_points;
%         dlabs(:,2:3)=dlabs(:,2:3).*factor;
% 
%         %计算delta_Lab
%         CCT=CT(i);
%         for i_points=startCenter:1:endCenter
%             dlab_CATed(i_points,:)=CAT_lab2lab1(dlabs(i_points,:),Dtype,CCT,"fore",wd65,wd65);            
%         end
%         dlab_CATed=adjust_dlabs_shape1(dlab_CATed);
%         if i_type==4
%             dlab_CATed=adjust_dlabs(dlab_CATed,0.47);
%         end
% 
%         % for i_points=1:length(dlab_CATed)
%         %     for j_points=1:length(dlab_CATed)
%         %         dE_points(i_points,j_points)=deltaE2000(dlab_CATed(i_points,:), ...
%         %             dlab_CATed(j_points,:));
%         %     end
%         % end
% 
%         % figure(1)
%         % plot_render_points(dlab_CATed)
%         % draw_folder=fullfile(save_folder,"draw");
%         % if ~exist(draw_folder,"dir")
%         %     mkdir(draw_folder);
%         % end
%         % exportgraphics(gcf,fullfile(draw_folder,strcat(lastPart,files(i).name)),'Resolution',150);
%         % clf;
% 
%         % adjust
%         delta_Lab=dlab_CATed-repmat(average(i,:),length(dlabs),1);
%         for i_points=startCenter:1:endCenter  
% 
%             dlab=delta_Lab(i_points,:)+average(i,:);
% 
%             %---------渲染-----------
% 
%             [dest_lab] = img_AddRender_gendlab(img, bull,bull, 'LUT', ...
%             delta_Lab(i_points,:),XYZ,if_wei,if_2mask);
% 
%             dlab_theo{i_file,1}=strcat(lastPart,files(i).name(1:end-4),'_',sprintf('%02d', i_points));  
%             dlab_theo{i_file,2}=dest_lab;
%             % dlab_theo{i_file,3}=dE_points;
%             i_file=i_file+1;
% 
% 
%         end
% 
% 
%     end
% end
% 
% 
% save(fullfile(strrep(save_folder,lastPart,""),"dlab_theo_i_CA_SA.mat"),"dlab_theo");
