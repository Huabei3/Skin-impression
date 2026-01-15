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
addpath("..\..\utils\");
%%
% 模特名称列表（f=女性，m=男性，数字为编号）
new_names = [ "f04", "f05", "f06", "m04", "m05", "m06",...
"f01", "f02", "f03", "m01", "m02", "m03",...
"f07", "f08","m07", "m08",...
"f09", "f10","m09", "m10"];
% 颜色标签列表（H=高照度，M=中照度，L=低照度，D65=标准光源）

%------------i--------------

% 校准数据路径（datai_ipv35_3.mat：LUT模型 显示模型的XYZ白点数据）
datai_file = '..\..\calibration\display_model\datai_ipv35_3.mat';
wd65=[94.813  100.000  107.262];
LUT=load(datai_file);
XYZw_LUT=LUT.XYZw;
wd65_scaled=wd65./100.*XYZw_LUT(2);
attributes = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
% 评估属性列表（1-10对应不同感知属性，需与attribute_names一一对应）
attribute_names = ["Preference", "Attractiveness", "Feminine", "Cooperative", ...
    "Youth", "Healthy", "Fidelity","Harmony", "Fair", "Ruddy"];
% 目标评分配置（rela=相对评分，abs=绝对评分；1=满分）
target_score=1; % 目标评分值（0-1之间，转换为百分比）
target_score_str=num2str(target_score*100); % 字符串化评分（用于路径命名）
score_type="rela"; % 评分类型
render_type="srgb";
% iOr='i';
iOr='r';
if iOr=='i'
    pcn = ["H3K", "H4K", "H5K", "H6K", "HD65", "H7K", "H8K", ...
           "M3K", "M4K", "M5K", "M6K", "MD65", "M7K", "M8K", ...
           "L3K", "L4K", "L5K", "L6K", "LD65", "L7K", "L8K"];
else
    pcn = ["rs01","rs02","rs03","rs04","rs05","rs06","rs07", ...
                 "rs08","rs09","rs10","rs11","rs12","rs13","rs14"];
end
Dtype="efit2";
obs_type="non_model";
for i_model=1:length(new_names)
    source_folder=fullfile('mask',strcat(new_names(i_model),iOr));
    source_folder=char(source_folder);
    slashes = strfind(source_folder, '\');
    lastPart=source_folder(slashes(1,end)+1:end);
    model = lastPart(1:end-1);
    % 提取肤色时是否给边缘像素赋予透明度
    % 权重开关（判断是否为特定模型，需说明模型差异：如f04i等模型不使用权重）
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
    
    dir_mask=dir(fullfile("mask\",lastPart,"\*.jpg"));
    dir_mask_nosd=dir(fullfile("Shadow\mask",lastPart,"nosd\*.jpg"));
    dir_XYZfile=dir(fullfile("..\..\..\renderCode\XYZ",iOr,lastPart,"\*.mat"));

    % 加载标准Lab值（aveLab_D65_Asian.mat：亚洲人肤色在D65下的平均Lab值）
    load("aveLab_D65_Asian.mat","labC_HD65");
    lab_PMCC = [62.11, 18.96, 19.76];
    labC_PMCC = [lab_PMCC, sqrt(lab_PMCC(1, 2)^2 + lab_PMCC(1, 3)^2)];
    % 保存路径规则：
    % rendered/[观察者组别类]/[目标评分百分比]/[模特编号]/[光源]/[属性编号_序号]/[L*a*b*坐标].jpg
    save_folder=fullfile('rendered',render_type,obs_type,target_score_str,lastPart);
    if ~exist(save_folder, 'dir')
        mkdir(save_folder);
    end


    for i = 5:numel(files)
    
        filename = fullfile(files(i).folder, files(i).name);      
        img0=imread(filename);
    %--------先跑小图看问题--------
        % img0 = imresize(img0, [size(img0,1)./6, size(img0,2)./6]);

        for i_mask=1:length(dir_mask)
            if strcmp(files(i).name(1:end-4),dir_mask(i_mask).name(1:end-4))
                picname_check{i,1}=files(i).name(1:end-4);
                picname_check{i,2}=dir_mask(i_mask).name(1:end-4);
                bull=imread(strcat(dir_mask(i_mask).folder,'\',dir_mask(i_mask).name));
                bull_nosd=bull;
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
            slash=find(dir_XYZfile(i_xyz).name=='_');
            if isempty(slash)
                slash=0;
            end


            if strcmp(dir_XYZfile(i_xyz).name(slash+1 : end-4), files(i).name(1:end-4))                picname_check{i,4}=dir_XYZfile(i_xyz).name(1:end-4);
                XYZ=load(fullfile(dir_XYZfile(i_xyz).folder,dir_XYZfile(i_xyz).name));
                XYZ=XYZ.XYZ_cropped;
                %------先跑小图看问题---dir_XYZfile(i_xyz).name----
                % XYZ = imresize(XYZ, [size(XYZ,1)./6, size(XYZ,2)./6]);
                break
            end
        end

        img=im2double(img0);
        [m, n, p] = size(img);
        xyz1= reshape(XYZ, [m * n, p]);
        [lab1] = xyz2lab(xyz1,'user',wd65_scaled);
        average(i,:)=get_average(lab1,bull,if_wei);
        ITA = atand((average(i,1)-50)/average(i,3));

        % 公式来源：基于亮度实验的经验模型
        % C_pre = 6.7421 * ln(L) - 9.9816，其中L为输入Lab的亮度值（0-100）
        % 作用：将输入亮度转换为与标准光源（HD65）匹配的亮度因子
        C_pre=6.7421*log(average(i,1))-9.9816; % average(i,1)为当前图像的平均L值
        factor(i,:)=C_pre./labC_HD65(1,4);

        labC_PMCCpre(i, 1) = average(i, 1);
        labC_PMCCpre(i, 2:3) = lab_PMCC(1, 2:3) ./ labC_PMCC(1, 4) .* C_pre;
        labC_PMCCpre(i, 4) = C_pre;
    %-----render attribute_serial-------------
        for attribute = [1,7,8,9,10]
            attribute_serial = strcat(sprintf("%02d", attribute), attribute_names(attribute));
            [nation,i_nation,nation_serial]=find_nation(model);
            [corr_picname]= find_corr_res(files(i).name(1:end-4));

            fit_center_data_file = fullfile('D:\work\VIVOskinExpe\analyze\AnalyseResults1', ...
                Dtype,"nation", 'scale_factor_fit_results', obs_type,"i", nation);
            
            full_fit_center_file = fullfile(fit_center_data_file, ...
                                    strcat("a_scale_",attribute_serial,".mat"));
            
            if exist(full_fit_center_file,'file') == 2
                [~,i_par]=ismember(files(i).name(1:end-4),pcn);
                load(full_fit_center_file, ...
                            'a_scale', "a_CL","all_ave_curr_z","all_par");
                if iOr == 'r'
                    source_folder = fullfile('D:\work\VIVOskinExpe\analyze\AnalyseResults1', ...
                        Dtype,'50','cluster_50',obs_type, ...
                        iOr,attribute_serial,nation_serial);
                    cluster=find_cluster(pcn(i_par),i_nation);
                    full_path=fullfile(source_folder,strcat(cluster,".mat"));
                    data = load(full_path);                    
                    par = get_par_fr_SF(average(i_par,1), a_scale, a_CL, data.par); 
                else
                    par = get_par_fr_SF(average(i_par,1), a_scale, a_CL, all_par{1});
                end

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
                    warning(strcat('跳过文件：', fit_center_data_file, files(i).name,'（无有效目标ab值）'));
                    continue; % 跳过当前图像
                end
                %画取点预览图
                figure(1);
                % figure("Visible","off");
                plot_target_score(par,target_ab,target_score,score_type);
                title(files(i).name(1:end-4));
                if ~exist(fullfile(save_folder,"90pre_draw"),"dir")
                    mkdir(fullfile(save_folder,"90pre_draw"));
                end                
                exportgraphics(gcf, fullfile(save_folder,"90pre_draw", ...
                    strcat(files(i).name(1:end-4),attribute_serial,".jpg")), ...
                    'Resolution', 300);
                % close(gcf);
                [CCT,XYZw_pre] = find_CCT_combi(strcat(lastPart,files(i).name(1:end-4)));
                %--------算中心-------   
                if ~isempty(target_ab)
                    dlabs_90=[repmat(average(i,1),size(target_ab,1),1),target_ab(:,1),target_ab(:,2)];
                    for i_dlabs_90=1:size(dlabs_90,1)
                        dlab=CAT_lab2lab_combi(dlabs_90(i_dlabs_90,:),"ZJUCAT",CCT,XYZw_pre,"fore");
                        delta_Lab=dlab-average(i,:); 

                        dir_img_file=dir(fullfile(save_folder,files(i).name(1:end-4), ...
                            strcat(files(i).name(1:end-4),'_',attribute_serial,sprintf("%02d",i_dlabs_90),'*.jpg')));
                        % if ~isempty(dir_img_file)
                        %     continue
                        % end
                        % 
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
                            img_AddRender_simp(img,bull,bull_nosd,render_type,delta_Lab, ...
                            XYZ,noFaceRGB_file,if_wei,if_2mask);        
                        % 关键处理步骤：
                        % 1. 通过遮罩logicalIndex区分面部区域与背景
                        % 2. 使用LUT（查找表）进行XYZ到RGB的色域映射
                        % 3. delta_Lab为目标颜色差值，通过CAT_lab2lab1函数转换为设备相关值
                        deltaE2000(dest_lab,dlab)
                        %---------渲染-----------
                        % figure(1);
                        imshow(out_rendering);        
                        disp([files(i).name,' was done']);
                        if ~exist(fullfile(save_folder,files(i).name(1:end-4)),"dir")
                            mkdir(fullfile(save_folder,files(i).name(1:end-4)));
                        end
                        imwrite(out_rendering,fullfile(save_folder,files(i).name(1:end-4), ...
                            strcat(files(i).name(1:end-4),'_',attribute_serial, ...
                            sprintf("%02d",i_dlabs_90),'[',num2str(dlab(1,1)),',' ,...
                            num2str(dlab(1,2)),',',num2str(dlab(1,3)),'].jpg')) );

        
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

