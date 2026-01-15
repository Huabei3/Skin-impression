% ======================================
% 代码功能：基于颜色渲染的属性评分模拟系统
% 适用场景：图像处理、颜色科学、属性评分预测
% 依赖工具：MATLAB R2020+、Image Processing Toolbox、自定义工具包
% 作者：XXX
% 版本：V1.0（2025-05-19）
% ======================================
% 依赖工具说明：
% 1. Godel计算工具：用于数值计算（若有计算步骤）
% 2. 自定义工具包：
%    - utils文件夹需包含：
%      - xyz2lab.m, lab2xyz2.m       （颜色空间转换）
%      - read_bull.m                 （读取遮罩）
%      - calculate_target_ab.m       （计算目标ab值）
%      - deltaE2000.m                （色差计算）
% 3. 外部数据：
%    - calibration文件夹：显示模型校准数据（.mat文件）
%    - mask/Shadow文件夹：遮罩图像（.jpg格式）
%    - data/ellipse_para：椭圆拟合参数（用于属性评分模型）



close all; 
clc;       
clear;     
addpath("utils\");
%%
% 模特名称列表（f=女性，m=男性，数字为编号）
new_names = [ "f04", "f05","f06", "m04", "m05","m06"];
% 颜色标签列表（H=高照度，M=中照度，L=低照度，D65=标准光源）
ct = ["H3K", "H4K", "H5K", "H6K", "HD65", "H7K", "H8K", ...
           "M3K", "M4K", "M5K", "M6K", "MD65", "M7K", "M8K", ...
           "L3K", "L4K", "L5K", "L6K", "LD65", "L7K", "L8K"];
Dtype="summer";
iOr='i';
%------------i--------------

% 校准数据路径（datai_ipv35_3.mat：LUT模型 显示模型的XYZ白点数据）
datai_file = 'calibResults\datai_ipv35_3.mat';
wd65=[94.813  100.000  107.262];
LUT=load(datai_file);
XYZw_LUT=LUT.XYZw;
wd65_scaled=wd65./100.*XYZw_LUT(2);

attributes = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
% 评估属性列表（1-10对应不同感知属性，需与attribute_names一一对应）
attribute_names = ["Preference", "Attractiveness", "Feminine", "Cooperative", ...
    "Youth", "Healthy", "Fidelity","Harmony", "Fair", "Ruddy"];
% 目标评分配置（rela=相对评分，abs=绝对评分；100=满分）
target_score=1; % 目标评分值（0-1之间，转换为百分比）
if target_score==0.5
    score_type="abs";
else
    score_type="rela"; 
end
target_score_str=num2str(target_score*100); % 字符串化评分（用于路径命名）

obs_type="non_model";
for i_model=1:length(new_names)
    source_folder=fullfile('mask',strcat(new_names(i_model),'i'));
    source_folder=char(source_folder);
    slashes = strfind(source_folder, '\');
    lastPart=strcat(new_names(i_model),iOr,'add');
    model =strrep(lastPart,"iadd","");
    % 提取肤色时是否给边缘像素赋予透明度
    % 权重开关（判断是否为特定模型，需说明模型差异：如f04i等模型不使用权重）
    if ismember(strrep(lastPart,"add",""),["f04i","f05i","f06i","m04i","m06i"]) 
        if_wei=0;
    else
        if_wei=1;
    end
    if ismember(strrep(lastPart,"add",""),["m02i","m03i"]) 
        if_2mask=1;
    else
        if_2mask=0;
    end
    
    i_type=select_type(strrep(model,"add",""));
    
    files = dir(strcat(source_folder,'\*.jpg'));  % 读取文件夹中的所有.jpg文件
    
    dir_mask=dir(strcat("mask\",strrep(lastPart,"add",""),"\*.jpg"));
    dir_mask_nosd=dir(fullfile("Shadow\mask",strrep(lastPart,"add",""),"nosd\*.jpg"));
    dir_XYZfile=dir(strcat("XYZ\i\",strrep(lastPart,"add",""),"\*.mat"));

    load(fullfile("aveSkinByHand2","i",strcat("aveLab_D65_",num2str(i_type),".mat")), ...
        "labC_HD65");
    lab_PMCC = [62.11, 18.96, 19.76];
    labC_PMCC = [lab_PMCC, sqrt(lab_PMCC(1, 2)^2 + lab_PMCC(1, 3)^2)];
    % 保存路径规则：
    % rendered/[观察者组别类]/[目标评分百分比]/[模特编号]/[光源]/[属性编号_序号]/[L*a*b*坐标].jpg
    save_folder=fullfile('rendered\33_i_wei\LUT',Dtype,obs_type,target_score_str,lastPart);
    if ~exist(save_folder, 'dir')
        mkdir(save_folder);
    end


    
    for i = 1:numel(files)
    
        filename = fullfile(files(i).folder, files(i).name);      
        img0=imread(filename);
    %--------先跑小图看问题--------
        % img0 = imresize(img0, [size(img0,1)./6, size(img0,2)./6]);

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

        % 公式来源：基于亮度实验的经验模型
        % C_pre = 6.7421 * ln(L) - 9.9816，其中L为输入Lab的亮度值（0-100）
        % 作用：将输入亮度转换为与标准光源（HD65）匹配的亮度因子
        C_pre=6.7421*log(average(i,1))-9.9816; % average(i,1)为当前图像的平均L值
        factor(i,:)=C_pre./labC_HD65(1,4);

        labC_PMCCpre(i, 1) = average(i, 1);
        labC_PMCCpre(i, 2:3) = lab_PMCC(1, 2:3) ./ labC_PMCC(1, 4) .* C_pre;
        labC_PMCCpre(i, 4) = C_pre;
    %-----render attribute_serial-------------
        for attribute = attributes
            attribute_serial = strcat(sprintf("%02d", attribute), attribute_names(attribute));
            if attribute==7
                obs_type_used="model_group";
            else
                obs_type_used=obs_type;
            end
            fit_center_data_file=fullfile('..\analyze\AnalyseResults1',"summer", ...
            lastPart,obs_type_used,attribute_serial, ...
            'ellipPara\fitRes_level.mat');
            if exist(fit_center_data_file,'file')
                [~,i_par]=ismember(files(i).name(1:end-4),ct);
                % 加载椭圆拟合参数（用于属性评分模型）
                fit_center_data=load(fit_center_data_file);
                par=fit_center_data.par_all(i_par,:);

                target_ab=[];
                 % 计算目标ab值（基于色相和饱和度）
                [target_ab(1,1),target_ab(1,2),target_ab(2,1),target_ab(2,2)] = ...
                    calculate_target_ab( par,target_score,"hue",score_type);
                [target_ab(3,1),target_ab(3,2),target_ab(4,1),target_ab(4,2)] = ...
                    calculate_target_ab( par,target_score,"chroma",score_type);
                % 过滤无效值（NaN行，可能因拟合失败、或者椭圆过于接近原点导致）
                nan_rows = any(isnan(target_ab), 2); 
                target_ab = target_ab(~nan_rows, :); 
                [target_ab, ~, ~] = unique(target_ab, 'rows');
                if isempty(target_ab)
                    warning(['跳过文件：', files(i).name, '（无有效目标ab值）']);
                    continue; % 跳过当前图像
                end
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
                % close(gcf);
                [CCT,i_light] = find_CCT_i( files(i).name(1:end-4));
                %--------算中心-------   
                if ~isempty(target_ab)
                    dlabs_90=[repmat(average(i,1),size(target_ab,1),1),target_ab(:,1),target_ab(:,2)];
                    for i_dlabs_90=1:size(dlabs_90,1)
                        dlab=CAT_lab2lab1(dlabs_90(i_dlabs_90,:),Dtype,CCT,"fore");
                        delta_Lab=dlab-average(i,:); 
                        if target_score==1
                            pic_serial="";
                        else
                            pic_serial=sprintf("%02d",i_dlabs_90);
                        end
                        dir_img_file=dir(fullfile(save_folder,files(i).name(1:end-4), ...
                            strcat(files(i).name(1:end-4),'_',attribute_serial,pic_serial,'*.jpg')));
                        if ~isempty(dir_img_file)
                            continue
                        end
                
                        noFaceRGB_folder=fullfile(save_folder,"noFaceRGB");
                        if ~exist(noFaceRGB_folder,"dir")
                            mkdir(noFaceRGB_folder);
                        end
                        noFaceRGB_file=fullfile(noFaceRGB_folder, ...
                            strcat(files(i).name(1:end-4),".mat"));
                
                        disp(strcat(model,files(i).name,attribute_serial, ...
                            sprintf("%02d",i_dlabs_90),' begin'));
                        startTime = datetime('now'); 
                        %---------渲染-----------
                        % 渲染主函数（输入：原图、遮罩、无阴影遮罩、LUT参数、目标Lab差值）
                        [out_rendering,dest_lab,bull_nosd]=...
                            img_AddRender_simp(img,bull,bull_nosd,'LUT',delta_Lab, ...
                            XYZ,noFaceRGB_file,if_wei,if_2mask);        
                        % 关键处理步骤：
                        % 1. 通过遮罩logicalIndex区分面部区域与背景
                        % 2. 使用LUT（查找表）进行XYZ到RGB的色域映射
                        % 3. delta_Lab为目标颜色差值，通过CAT_lab2lab1函数转换为设备相关值
                        deltaE2000(dest_lab,dlab)
                        %---------渲染-----------
                        figure(1);
                        imshow(out_rendering);        
                        disp([files(i).name,' was done']);
                        if ~exist(fullfile(save_folder,files(i).name(1:end-4)),"dir")
                            mkdir(fullfile(save_folder,files(i).name(1:end-4)));
                        end
                        imwrite(out_rendering,fullfile(save_folder,files(i).name(1:end-4), ...
                            strcat(files(i).name(1:end-4),'_',attribute_serial, ...
                            sprintf("%02d",i_dlabs_90),'[',num2str(dest_lab(1,1)),',' ,...
                            num2str(dest_lab(1,2)),',',num2str(dest_lab(1,3)),'].jpg')) );

        
                        dlab_folder=fullfile(save_folder,files(i).name(1:end-4),'dlab',target_score_str);
                        if ~exist(dlab_folder,"dir")
                            mkdir(dlab_folder);
                        end
                        save(fullfile(dlab_folder, strcat(files(i).name(1:end-4), ...
                            '_',attribute_serial,sprintf("%02d",i_dlabs_90),".mat")),"dlab");
                        currentTime = datetime('now');
                        fprintf('时间差: %s\n', currentTime - startTime);
                    end
                end
            else
                warning(strcat('文件缺失：', fit_center_data_file, '（跳过属性', attribute_serial, '）'));
            end
        end
    end

end

