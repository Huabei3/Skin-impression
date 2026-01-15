close all; 
clc;       
clear;     
addpath("utils\")
%%
% new_names = [ "m05"];
new_names = [ "f04", "f05","f06", "m04", "m05","m06"];
Dtype="summer";
iOr='i';
% new_names = ["f01", "f02", "f03", "f04", ...
%              "f05", "f06", "f07", "f08", "f09", "f10",...
%              "m01", "m02", "m03", "m04", "m05", "m06", "m07", ...
%              "m08", "m09", "m10"];
%------------i--------------
ct=["H3K","H4K","H5K","H6K","H7K","H8K","HD65",...
"L3K","L4K","L5K","L6K","L7K","L8K","LD65",...
"M3K","M4K","M5K","M6K","M7K","M8K","MD65"];
wd65_64 = [94.811, 100.00, 107.304];
CT = [3000, 4000, 5000, 6000, 7000, 8000, 6500, ...
  3000, 4000, 5000, 6000, 7000, 8000, 6500, ...
  3000, 4000, 5000, 6000, 7000, 8000, 6500]';

datai_file = 'calibResults\datai_ipv35_3.mat';
wd65=[94.813  100.000  107.262];
LUT=load(datai_file);
XYZw_LUT=LUT.XYZw;
wd65_scaled=wd65./100.*XYZw_LUT(2);

attributes = [ 1,2,3,4,5,6,7,8, 9, 10];
attribute_names = ["Preference", "Attractiveness", "Feminine", "Cooperative", ...
    "Youth", "Healthy", "Precise reproduction", "suit the environment or not", "white-skinned", "ruddyadd"]; 

target_score=0.9;
if target_score==0.9
    score_type="rela";
    target_score_str="90";
elseif target_score==0.5
    score_type="abs";
    target_score_str="50";
end
obs_type="model_group";
for i_model=4:length(new_names)
    source_folder=fullfile('mask',strcat(new_names(i_model),'i'));
    source_folder=char(source_folder);
    slashes = strfind(source_folder, '\');
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
    lab_PMCC = [62.11, 18.96, 19.76];
    labC_PMCC = [lab_PMCC, sqrt(lab_PMCC(1, 2)^2 + lab_PMCC(1, 3)^2)];
    
    save_folder=fullfile('rendered\33_i_wei\srgb\CAT16',obs_type,target_score_str,"summer",lastPart);
    if ~exist(save_folder, 'dir')
        mkdir(save_folder);
    end
    nosh_folder=fullfile(save_folder,"nosd");
    if ~exist(nosh_folder, 'dir')
        mkdir(nosh_folder);
    end
    
    num_points = readmatrix('points_added_33.xlsx'); 
    num_points=[zeros(length(num_points),1),num_points];
    
    for i = 2:numel(files)
    
        filename = fullfile(files(i).folder, files(i).name);      
        img0=imread(filename);
    %--------先跑小图看问题--------
        % img0 = imresize(img0, [size(img0,1)./6, size(img0,2)./6]);
    
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
        average(i,:)=get_average(lab1,bull,if_wei);

        % 计算labC_PMCCpre
        C_pre=6.7421*log(average(i,1))-9.9816;%亮度实验
        factor(i,:)=C_pre./labC_HD65(1,4);
        dlabs=repmat([average(i,1),labC_HD65(1,2:3)],length(num_points),1)+num_points;
        dlabs(:,2:3)=dlabs(:,2:3).*factor(i,:);
        labC_PMCCpre(i, 1) = average(i, 1);
        labC_PMCCpre(i, 2:3) = lab_PMCC(1, 2:3) ./ labC_PMCC(1, 4) .* C_pre;
        labC_PMCCpre(i, 4) = C_pre;
    %-----render attribute_serial-------------
        for attribute = attributes
            attribute_serial = strcat(sprintf("%02d", attribute), attribute_names(attribute));
            lastPart_old=gen_lastPart_old(lastPart);
            % if attribute==7
            %     obs_type_used="model_group";
            % else
                obs_type_used=obs_type;
            % end
            fit_center_data_file=fullfile('..\analyze\AnalyseResults',"summer", ...
            lastPart_old,obs_type_used,attribute_serial, ...
            'ellipPara\fitRes_level.mat');
            if exist(fit_center_data_file,'file')
                fit_center_data=load(fit_center_data_file);
                par=fit_center_data.par_all(i,:);
                target_ab=[];

                [target_ab(1,1),target_ab(1,2),target_ab(2,1),target_ab(2,2)] = ...
                    calculate_target_ab( par,target_score,"hue",score_type);
                [target_ab(3,1),target_ab(3,2),target_ab(4,1),target_ab(4,2)] = ...
                    calculate_target_ab( par,target_score,"chroma",score_type);

                nan_rows = any(isnan(target_ab), 2); 
                target_ab = target_ab(~nan_rows, :); 
                %画取点预览图
                figure(1);
                plot_target_score(par,target_ab,target_score,score_type);
                title(files(i).name(1:end-4));
                if ~exist(fullfile(save_folder,"90pre_draw"),"dir")
                    mkdir(fullfile(save_folder,"90pre_draw"));
                end                
                exportgraphics(gcf, fullfile(save_folder,"90pre_draw", ...
                    strcat(files(i).name(1:end-4),attribute_serial,".jpg")), ...
                    'Resolution', 300);
                close(gcf);
                % [CCT,i_light] = find_CCT_i( files(i).name(1:end-4));
                % %--------算中心-------   
                % if ~isempty(target_ab)
                %     dlabs_90=[repmat(average(i,1),size(target_ab,1),1),target_ab(:,1),target_ab(:,2)];
                %     for i_dlabs_90=1:size(dlabs_90,1)
                %         % dlab=CAT_lab2lab1(dlabs_90(i_dlabs_90,:),"full",CCT,"fore");
                % 
                %     datai_file = '..\renderCode\calibResults\datai_ipv35_3.mat';
                %     LUT=load(datai_file);
                %     XYZw_LUT=LUT.XYZw;
                %     backgroundGray_file=strcat("..\renderCode\backgroundGray\i\" + ...
                %         "backGroundGray",strcat(new_names(i_model),iOr),".mat");
                %     load(backgroundGray_file,"xyz_gray");
                %     LA=xyz_gray(i,2);
                %     dlab=CAT_lab2lab2(dlabs_90(i_dlabs_90,:), ...
                %         "CAT16",CCT,"fore",LA);
                % 
                %         delta_Lab=dlab-average(i,:); 
                % 
                %         dir_img_file=dir(fullfile(save_folder,files(i).name(1:end-4), ...
                %             strcat(files(i).name(1:end-4),'_',attribute_serial,sprintf("%02d",i_dlabs_90),'*.jpg')));
                %         if ~isempty(dir_img_file)
                %             continue
                %         end
                % 
                %         noFaceRGB_folder=fullfile(save_folder,"noFaceRGB");
                %         if ~exist(noFaceRGB_folder,"dir")
                %             mkdir(noFaceRGB_folder);
                %         end
                %         noFaceRGB_file=fullfile(noFaceRGB_folder, ...
                %             strcat(files(i).name(1:end-4),".mat"));
                % 
                %         disp(strcat(model,files(i).name,attribute_serial, ...
                %             sprintf("%02d",i_dlabs_90),' begin'));
                %         startTime = datetime('now'); 
                %         %---------渲染-----------
                %         [out_rendering,dest_lab,bull_nosd]=...
                %             img_AddRender_simp(img,bull,bull_nosd,'srgb',delta_Lab, ...
                %             XYZ,noFaceRGB_file,if_wei,if_2mask);        
                % 
                %         deltaE2000(dest_lab,dlab)
                %         %---------渲染-----------
                %         figure(1);
                %         imshow(out_rendering);        
                %         disp([files(i).name,' was done']);
                %         if ~exist(fullfile(save_folder,files(i).name(1:end-4)),"dir")
                %             mkdir(fullfile(save_folder,files(i).name(1:end-4)));
                %         end
                %         imwrite(out_rendering,fullfile(save_folder,files(i).name(1:end-4), ...
                %             strcat(files(i).name(1:end-4),'_',attribute_serial, ...
                %             sprintf("%02d",i_dlabs_90),'[',num2str(dest_lab(1,1)),',' ,...
                %             num2str(dest_lab(1,2)),',',num2str(dest_lab(1,3)),'].jpg')) );
                %         % figure(2);
                %         % imshow(bull_nosd);
                %         imwrite(bull_nosd,fullfile(nosh_folder,files(i).name));
                % 
                %         dlab_folder=fullfile(save_folder,files(i).name(1:end-4),'dlab',target_score_str);
                %         if ~exist(dlab_folder,"dir")
                %             mkdir(dlab_folder);
                %         end
                %         save(fullfile(dlab_folder, strcat(files(i).name(1:end-4), ...
                %             '_',attribute_serial,sprintf("%02d",i_dlabs_90),".mat")),"dlab");
                %         currentTime = datetime('now');
                %         fprintf('时间差: %s\n', currentTime - startTime);
                    % end
                % end
            end
        end
    end

end

function i_type= select_type(model)
    model = gen_lastPart_old(model);
    models{1,1}=["male92","male91","male48","female01","female04","female06","male97"];
    models{2,1}=["male59","male39","male39aftPS","maleVIVO","female78","female02","female41","femaleVIVO"];
    models{3,1}=["male21","male46","female23","female51"];
    models{4,1}=["male22","male28","female25","female69"];
    if ismember(model,models{1,1})
        i_type=1;
    elseif ismember(model,models{2,1})
        i_type=2;
    elseif ismember(model,models{3,1})
        i_type=3;
    elseif ismember(model,models{4,1})
        i_type=4;
    else
        error("model doesn't exist");
    end
end