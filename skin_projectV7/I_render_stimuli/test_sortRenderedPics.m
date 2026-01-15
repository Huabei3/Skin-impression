clear;clc;close all;
addpath("utils\")
%%

baseDir = 'F:\VIVOskinExpe\skin_projectV4\evaluation_rendering\render_code\rendered\LUT'; % 根目录

% 定义一级子文件夹
firstLevelFolders = {'non_model', 'model_group'};

% 定义二级子文件夹
secondLevelFolder = '100'; 

% 定义三级子文件夹的前缀和范围
thirdLevelPrefixes = {'f', 'm'};
thirdLevelSuffixes = {'i', 'r'};

% 初始化结果 cell 数组
% 列：三级子文件夹名称、所在二级子文件夹名称、所在一级子文件夹名称、四级子文件夹数目、是否符合条件
resultCell = {'三级文件夹名称', '二级文件夹名称', '一级文件夹名称', '四级文件夹数目', '是否符合条件'};

% 定义符合条件的四级子文件夹前缀
allowedFourthLevelPrefixes = {'H', 'M', 'L', 'rs'};

% 遍历一级子文件夹
for i = 1:length(firstLevelFolders)
    currentFirstLevelFolder = firstLevelFolders{i};
    firstLevelPath = fullfile(baseDir, currentFirstLevelFolder);
    
    % 检查一级文件夹是否存在
    if ~isfolder(firstLevelPath)
        warning('Folder not found: %s', firstLevelPath);
        continue;
    end
    
    % 构建二级文件夹路径
    secondLevelPath = fullfile(firstLevelPath, secondLevelFolder);
    
    % 检查二级文件夹是否存在
    if ~isfolder(secondLevelPath)
        warning('Folder not found: %s', secondLevelPath);
        continue;
    end
    
    % 遍历三级子文件夹
    for p = 1:length(thirdLevelPrefixes)
        prefix = thirdLevelPrefixes{p};
        for s = 1:length(thirdLevelSuffixes)
            suffix = thirdLevelSuffixes{s};
            for d = 1:10
                thirdLevelFolderName = sprintf('%s%02d%s', prefix, d, suffix);
                thirdLevelPath = fullfile(secondLevelPath, thirdLevelFolderName);
                
                % 检查三级文件夹是否存在
                if ~isfolder(thirdLevelPath)
                    % warning('Folder not found: %s', thirdLevelPath);
                    continue; % 如果不存在，跳过
                end
                
                % 获取四级子文件夹
                dirInfo = dir(thirdLevelPath);
                subFolders = dirInfo([dirInfo.isdir]); % 筛选出目录
                
                % 移除 '.' 和 '..'
                subFolders = subFolders(~ismember({subFolders.name}, {'.', '..'}));
                
                % 统计符合条件的四级子文件夹数目
                count = 0;
                for k = 1:length(subFolders)
                    currentSubFolderName = subFolders(k).name;
                    % 检查四级子文件夹名称是否以H, M, L或rs开头
                    if startsWith(currentSubFolderName, allowedFourthLevelPrefixes, 'IgnoreCase', true)
                        count = count + 1;
                    end
                end
                
                % 判断是否符合条件
                isCompliant = '否';
                if strcmp(suffix, 'i') % 以i结尾的文件夹
                    if count == 21
                        isCompliant = '是';
                    end
                elseif strcmp(suffix, 'r') % 以r结尾的文件夹
                    if count == 14
                        isCompliant = '是';
                    end
                end
                
                % 添加到结果 cell 数组
                resultCell = [resultCell; {thirdLevelFolderName, secondLevelFolder, currentFirstLevelFolder, count, isCompliant}]; %#ok<AGROW>
            end
        end
    end
end

%% 换背景 
% %
% num_points = readmatrix('points_added_33.xlsx'); 
% num_points=[zeros(length(num_points),1),num_points];
% datai_file = 'calibResults\data_ipv18_3.mat';
% wd65=[94.813  100.000  107.262];
% LUT=load(datai_file);
% XYZw_LUT=LUT.XYZw;
% wd65_scaled=wd65./100.*XYZw_LUT(2);
% 
% 
% %------------i--------------
% new_names = ["f01","f02","f03","m01","m02","m03",...
%     "f07","f08","m07","m08",...
%     "f09","f10","m09","m10"];
% Dtype="full";
% % for i_model=[8]
% for i_model=length(new_names)-2:-1:1 
%     source_folder=fullfile("rendered\i\adjust", ...
%     strcat(new_names(i_model),"i"));  
%     files = dir(strcat(source_folder,'\*.jpg'));  
%     lastPart=strcat(new_names(i_model),'i');
%     model = new_names(i_model);    
%     i_type=select_type(model);    
%     dir_mask=dir(strcat("mask\",lastPart,"\*.jpg"));
%     %----------------------
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
%     save_folder=fullfile('rendered\i\adjust_ch_bg',lastPart);
%     if ~exist(save_folder, 'dir')
%         mkdir(save_folder);
%     end  
% 
%     for i=1:length(files)
%         slash=find(files(i).name=='_');
%         nofaceRGB_file=fullfile(strrep(source_folder,"adjust","adjust_add"),"noFaceRGB", ...
%             strcat(files(i).name(1:slash-1),".mat"));
%         clear("noFaceRGB");
% 
%         if ~exist(nofaceRGB_file,"file")
%             continue
%         end
%         load(nofaceRGB_file,"noFaceRGB");
% 
%         img0=imread(fullfile(files(i).folder, files(i).name));
%         %--------先跑小图看问题--------
%         % img0 = imresize(img0, [size(img0,1)./6, size(img0,2)./6]);
% 
%         img=im2double(img0);
%         [m,n,p]=size(img);
% 
%         startCenter=1;
%         endCenter=length(num_points);
% 
%         for i_mask=1:length(dir_mask)
%             slash=find(files(i).name=='_');
%             if strcmpi(files(i).name(1:slash-1),dir_mask(i_mask).name(1:end-4))
%                 bull=imread(strcat(dir_mask(i_mask).folder,'\',dir_mask(i_mask).name));
%                 % bull = imresize(bull, [size(bull,1)./6, size(bull,2)./6]);%先跑小图看问题
%                 break
%             end
%         end
% 
% 
%         img=im2double(img0);
%         [m, n, p] = size(img);
%         out = reshape(img, [m * n, p]); % 灞曞紑
%         [logicalIndex,bull_weight]=read_bull(bull,if_wei);
%         % [logicalIndex_nosd,bull_weight_nosd]=read_bull(bull_nosd,if_wei);
%         out(logicalIndex,:)=noFaceRGB./255;
%         outnew = reshape(out, [m, n, p]);
% 
%         imwrite(outnew,fullfile(save_folder,files(i).name));
% 
%     end
% 
% 
% end
% disp("d")
%% 换背景 
% 2025 3 1版本 没有2mask 使用get_average 使用chgW（13 15 分别拉亮5、50）
% num_points = readmatrix('points_added_33.xlsx'); 
% num_points=[zeros(length(num_points),1),num_points];
% datai_file = 'calibResults\data_ipv18_3.mat';
% wd65=[94.813  100.000  107.262];
% LUT=load(datai_file);
% XYZw_LUT=LUT.XYZw;
% wd65_scaled=wd65./100.*XYZw_LUT(2);
% 
% 
% %------------r--------------
% new_names = ["f01","f02","f03","m01","m02","m03",...
%     "f07","f08","m07","m08",...
%     "f09","f10","m09","m10"];
% Dtype="full";i_file=1;if_2mask=0;
% % for i_model=[8]
% for i_model=length(new_names):-1:1
%     source_folder=fullfile("rendered\rs\adjust", ...
%         strcat(new_names(i_model),"r"));   
% 
%     files = dir(strcat(source_folder,'\*.jpg'));  
%     lastPart=strcat(new_names(i_model),'r');
%     model = new_names(i_model);    
%     i_type=select_type(model);    
%     dir_mask=dir(strcat("mask\",lastPart,"\*.jpg"));
%     %----------------------
%     if ismember(lastPart,["f04i","f05i","f06i","m04i","m06i"]) 
%         if_wei=0;
%     else
%         if_wei=1;
%     end
%     save_folder=fullfile('rendered\rs\adjust_ch_bg',lastPart);
%     if ~exist(save_folder, 'dir')
%         mkdir(save_folder);
%     end  
% 
%     for i=1:length(files)
% 
%         nofaceRGB_file=fullfile(strrep(source_folder,"adjust","adjust_add"),"noFaceRGB", ...
%             strcat(files(i).name(1:4),".mat"));
%         clear("noFaceRGB");
% 
%         if ~exist(nofaceRGB_file,"file")
%             continue
%         end
%         load(nofaceRGB_file,"noFaceRGB");
% 
%         img0=imread(fullfile(files(i).folder, files(i).name));
%         %--------先跑小图看问题--------
%         % img0 = imresize(img0, [size(img0,1)./6, size(img0,2)./6]);
% 
%         img=im2double(img0);
%         [m,n,p]=size(img);
% 
%         startCenter=1;
%         endCenter=length(num_points);
% 
%         for i_mask=1:length(dir_mask)
%             slash=find(files(i).name=='_');
%             if strcmpi(files(i).name(1:slash-1),dir_mask(i_mask).name(1:end-4))
%                 bull=imread(strcat(dir_mask(i_mask).folder,'\',dir_mask(i_mask).name));
%                 % bull = imresize(bull, [size(bull,1)./6, size(bull,2)./6]);%先跑小图看问题
%                 break
%             end
%         end
% 
% 
%         img=im2double(img0);
%         [m, n, p] = size(img);
%         out = reshape(img, [m * n, p]); % 灞曞紑
%         [logicalIndex,bull_weight]=read_bull(bull,if_wei);
%         % [logicalIndex_nosd,bull_weight_nosd]=read_bull(bull_nosd,if_wei);
%         out(logicalIndex,:)=noFaceRGB./255;
%         outnew = reshape(out, [m, n, p]);
% 
%         imwrite(outnew,fullfile(save_folder,files(i).name));
% 
%     end
% 
% 
% end
% disp("d")


%% 对于实验图
% % % %-----------rs----------
% % % 
% source_folder='I:\work\VIVOskinExpe\renderCode\rendered\rs\adjust\drawable';
% 
% files=dir(fullfile(source_folder,"*.jpg"));
% 
% wd65=[94.813  100.000  107.262];
% 
% save_folder=fullfile(source_folder,"checkLabRes");
% if ~exist(save_folder,"dir")
%     mkdir(save_folder);
% end
% % A=load(fullfile(save_folder,'checkLabFromPicsCau1.mat'),"dE_cell_big");
% % files=[];
% % for i_file=1:length(A.dE_cell_big)
% %     files=[files;dir(fullfile(source_folder,A.dE_cell_big{i_file,1}))];
% % end
% average_rgb_all=[];average_xyz_all=[];average_lab_all=[];average_lab1_all=[];
% de_all=[];de00_all=[];de00c_all=[];
% XYZ_all=[];XYZw_all=[];
% dlabTheo=load("I:\work\VIVOskinExpe\renderCode\rendered\rs\adjust\dlab_theo_r_CA_SA_AF_f123.mat");
% dlabTheo=dlabTheo.dlab_theo;
% i_the=1;
% 
% for i =1: numel(files) 
%     if ~ismember(files(i).name(1:3),["f01","f02","f03"])
%         continue
%     end
% 
%     img=imread(fullfile(files(i).folder, files(i).name));
%     % 解析文件名中的 dlab 值
%     slashes1 = find(files(i).name == '[');
%     slashes2 = find(files(i).name == ',');
%     slashes3 = find(files(i).name == ']');
% 
%     dlab(1,1) = str2double(files(i).name(slashes1+1:slashes2(1)-1));
%     dlab(1,2) = str2double(files(i).name(slashes2(1)+1:slashes2(2)-1));
%     dlab(1,3) = str2double(files(i).name(slashes2(2)+1:slashes3-1));
% 
%     lastPart=files(i).name(1:4);
%     lastPart=gen_lastPart_new(lastPart);
% 
%     if ismember(lastPart,["m02i","m03i"]) 
%         if_2mask=1;
%     else
%         if_2mask=0;
%     end
%     dir_mask=dir(fullfile("mask",lastPart,"*.jpg"));
%     dir_mask_nosd=dir(fullfile("Shadow\mask",lastPart,"nosd\*.jpg"));
% 
% 
%     [m, n, p] = size(img); 
%     flag=0;
%     if if_2mask
%         dir_mask_used=dir_mask_nosd;
%     else
%         dir_mask_used=dir_mask;
%     end
%     for i_mask=1:length(dir_mask_used)
%         if contains(lower(files(i).name(1:end-4)),lower(dir_mask_used(i_mask).name(1:end-4)))
%             disp([files(i).name(1:end-4),dir_mask_used(i_mask).name(1:end-4)]);
%             bull=imread(strcat(dir_mask_used(i_mask).folder,'\',dir_mask_used(i_mask).name));
%             % bull = imresize(bull, [size(bull,1)./6, size(bull,2)./6]);%先跑小图看问题
%             flag=1;
%             break
%         end
%     end
%     if flag==1
%         if ismember(lastPart,["f04i","f05i","f06i","m04i","m06i"]) 
%             if_wei=0;
%         else
%             if_wei=1;
%         end
%         [logicalIndex,bull_weight]=read_bull(bull,if_wei);
%         img=im2double(img);
%         out=reshape(img, [m * n, p]);
%         out = out * 255;
% 
%         datai_file = 'calibResults\datai_ipv18_3.mat';
%         xyz = lut3d_rgb2xyz1(out, datai_file);     
% 
%         LUT=load(datai_file);
%         XYZw_LUT=LUT.XYZw;
%         wd65_scaled=wd65./100.*XYZw_LUT(2);
% 
%         [lab] = xyz2lab(xyz,'user',wd65_scaled);
% 
%         [average_lab]=get_average(lab,bull,if_wei);
%         for i_the=1:length(dlabTheo)
%             name=dlabTheo{i_the,1};
%             name=char(name);            
%             if strcmpi(files(i).name(1:slashes1-1),strrep(name,".JPG",""))
%                 dlab_theo=dlabTheo{i_the,2};
%                 break  
%             end
%         end
%         dE_cell{i,1}=files(i).name;
%         dE_cell{i,2}=average_lab;
%         dE_cell{i,3}=dlab_theo;
% 
%         dE_cell{i,4}=deltaE2000(dlab,average_lab);
%         dE_cell{i,5}=deltaE2000(dlab_theo,average_lab);
%         dE_cell{i,6}=deltaE2000(dlab_theo,dlab);
%         i_the=i_the+1;
% 
%         [delch(i,1),delch(i,2),delch(i,3),delch(i,4)] = cielabde(dlab_theo,average_lab);
%         disp(delch(i,:));
% 
% % -----画mask区域肤色预览图-----------
%         if if_wei
%             out=out.*bull_weight;
%         else
%             for i_out=1:length(out)
%                 if logicalIndex(i_out)==1
%                     out(i_out,:)=[0,0,0];
%                 end
%             end        
%         end
% 
%         imshow(reshape(out,[m,n,p])./255);
%         output_folder=fullfile(save_folder,"cropped_area_skin");
%         if ~exist(output_folder,"dir")
%             mkdir(output_folder);
%         end
%         if mod(i,33)==0
%             % imwrite(reshape(out,[m,n,p])./255, ...
%             %     fullfile(output_folder,files(i).name));
%         end
% 
% 
%     else
% 
%         average_xyz=[0 0 0];
%         average_lab=[0 0 0];
%     end
% 
%     average_lab_all=[average_lab_all;average_lab];
% 
% end
% 
% save(fullfile(save_folder,'checkLabFromPics_CA_SA_AF_f123_1.mat'), ...
% "dE_cell");
% disp("done");
% 
% empty_idx=[];
% for i_dE=1:length(dE_cell)
%     if isempty(dE_cell{i_dE,4})
%         empty_idx=[empty_idx;i_dE];
%     end
% end
% dE_cell(empty_idx,:)=[];
% 
% 
% 
% 
% dE_cell_big=[];
% for i_dE=1:length(dE_cell)
%     if ~isempty(dE_cell{i_dE,4})
%         if ~(dE_cell{i_dE,4}<1&&dE_cell{i_dE,5}<1&&dE_cell{i_dE,6}<1)
%             dE_cell_big=[dE_cell_big;dE_cell(i_dE,:)];
%         end
%     end
% end
% dE_cell_big_calNv=[];
% for i_dE=1:length(dE_cell)
%     if ~isempty(dE_cell{i_dE,4})
%         if ~(dE_cell{i_dE,5}<1)
%             dE_cell_big_calNv=[dE_cell_big_calNv;dE_cell(i_dE,:)];
%         end
%     end
% end
% save(fullfile(save_folder,'checkLabFromPics_CA_SA_AF_f123.mat'), ...
%     "dE_cell","dE_cell_big","dE_cell_big_calNv");
% disp("d")
% %%
% empty_idx=[];
% for i_dE=1:length(dE_cell)
%     if isempty(dE_cell{i_dE,4})
%         empty_idx=[empty_idx;i_dE];
%     end
% end
% dE_cell(empty_idx,:)=[];
% 
% delete_idx=[];
% for i_dE=1:length(dE_cell)
%     if ismember(dE_cell{i_dE,1}(1:4),["m02i","m03i"])
%     % if ismember(dE_cell{i_dE,1}(1:4),["f01r","f02r","f03r"])
%         delete_idx=[delete_idx;i_dE];
%     end
% end
% dE_cell(delete_idx,:)=[];
% 
% 
% 
% dE_cell_big=[];
% for i_dE=1:length(dE_cell)
%     if ~isempty(dE_cell{i_dE,4})
%         if ~(dE_cell{i_dE,4}<1&&dE_cell{i_dE,5}<1&&dE_cell{i_dE,6}<1)
%             dE_cell_big=[dE_cell_big;dE_cell(i_dE,:)];
%         end
%     end
% end
% dE_cell_big_calNv=[];
% for i_dE=1:length(dE_cell)
%     if ~isempty(dE_cell{i_dE,4})
%         if ~(dE_cell{i_dE,5}<1)
%             dE_cell_big_calNv=[dE_cell_big_calNv;dE_cell(i_dE,:)];
%         end
%     end
% end
% save(fullfile(save_folder,'checkLabFromPics_CA_SA_AF.mat'), ...
%     "dE_cell","dE_cell_big","dE_cell_big_calNv");
%%
% % 定义主文件夹路径
% mainFolderPath = 'your_main_folder_path'; % 替换为你的主文件夹路径
% 
% % 获取主文件夹中的所有子文件夹
% subFolders = dir(mainFolderPath);
% subFolders = subFolders([subFolders.isdir]); % 只保留文件夹
% subFolders = subFolders(~ismember({subFolders.name}, {'.', '..'})); % 排除 . 和 ..
% 
% % 遍历每个子文件夹
% for i = 1:length(subFolders)
%     subFolder = subFolders(i);
%     subFolderPath = fullfile(mainFolderPath, subFolder.name);
% 
%     % 获取子文件夹中的所有 .jpg 文件
%     jpgFiles = dir(fullfile(subFolderPath, '*.jpg'));
% 
%     % 遍历所有文件，检查是否有文件名前部分相同的文件
%     for i_file = 1:length(jpgFiles)
%         slash=find(jpgFiles(i).name=='[');
%         dir_prefix=dir(fullfile(jpgFiles(i).folder, ...
%             strcat(jpgFiles(i).name(1:slash-1),"*.jpg")));
% 
%         % 检查文件名前部分是否相同
%         if strcmp(prefix1, prefix2)
%             % 找到时间戳较早的文件
%             if file1.datenum < file2.datenum
%                 earlyFile = file1;
%             else
%                 earlyFile = file2;
%             end
% 
%             % 创建 'early' 文件夹（如果不存在）
%             earlyFolderPath = fullfile(subFolderPath, 'early');
%             if ~exist(earlyFolderPath, 'dir')
%                 mkdir(earlyFolderPath);
%             end
% 
%             % 移动时间戳较早的文件到 'early' 文件夹
%             movefile(fullfile(subFolderPath, earlyFile.name), fullfile(earlyFolderPath, earlyFile.name));
%             fprintf('Moved: %s\n', earlyFile.name);
%         end
% 
%     end
% end
% 
% disp('文件移动完成！');

%%
% folderPath = 'rendered\i\adjust\f09i\';
% dest_folder="rendered\i\adjust\f09i\discarded";
% files=dir(fullfile(folderPath,"*.jpg"));
% for i=1:length(files)
%     if strcmp(files(i).name(5:6),"33")
%         movefile(fullfile(folderPath,files(i).name),fullfile(dest_folder,files(i).name));
%     end
% end

%%
% 定义文件夹路径
% folderPath = 'D:\work\VIVOskinExpe\renderCode\rendered\i\adjust\m10i'; % 替换为你的文件夹路径
% discardedFolder = fullfile(folderPath, 'discarded');
% 
% % 创建 'discarded' 文件夹（如果不存在）
% if ~exist(discardedFolder, 'dir')
%     mkdir(discardedFolder);
% end
% 
% % 获取文件夹中的所有 .jpg 文件
% files = dir(fullfile(folderPath, '*.jpg'));
% 
% % 定义截止日期（2025年3月9日）
% cutoffDate = datenum('2025-03-09');
% 
% % 遍历所有文件
% for i = 1:length(files)
%     file = files(i);
%     filePath = fullfile(folderPath, file.name);
% 
%     % 检查文件的时间戳是否在截止日期之前
%     if file.datenum < cutoffDate
%         % 移动文件到 'discarded' 文件夹
%         movefile(filePath, fullfile(discardedFolder, file.name));
%         fprintf('Moved: %s\n', file.name);
%     end
% end
% 
% disp('文件移动完成！');

%% 色差大的挪走
% source_folder="D:\work\VIVOskinExpe\renderCode\rendered\i\adjust";
% dest_folder=fullfile(source_folder,"big_dE");
% 
% load('rendered\i\adjust\drawable\checkLabRes\checkLabFromPics.mat');
% for i_row=1:length(dE_cell_big)
%     foldername=dE_cell_big{i_row,1}(1:4);
%     img_name=dE_cell_big{i_row,1}(5:end);
%     img_name=upper(img_name);
%     old_path=fullfile(source_folder,foldername,img_name);
%     if ~exist(fullfile(dest_folder,foldername),"dir")
%         mkdir(fullfile(dest_folder,foldername));
%     end
%     new_path=fullfile(dest_folder,foldername,img_name);
%     movefile(old_path,new_path);
% end
% disp("d")
%% 单独检验新跑的



% source_folder='D:\work\VIVOskinExpe\renderCode\rendered\rs\adjust\drawable';
% 
% files=dir(fullfile(source_folder,"*.jpg"));
% 
% wd65=[94.813  100.000  107.262];
% 
% save_folder=fullfile(source_folder,"checkLabRes");
% if ~exist(save_folder,"dir")
%     mkdir(save_folder);
% end
% % A=load('rendered\i\adjust\drawable\checkLabRes\checkLabFromPics.mat',"dE_cell_big");
% % files=[];
% % for i_file=1:length(A.dE_cell_big)
% %     files=[files;dir(fullfile(source_folder,A.dE_cell_big{i_file,1}))];
% % end
% average_rgb_all=[];average_xyz_all=[];average_lab_all=[];average_lab1_all=[];
% de_all=[];de00_all=[];de00c_all=[];
% XYZ_all=[];XYZw_all=[];
% dlabTheo=load("D:\work\VIVOskinExpe\renderCode\rendered\rs\adjust\dlab_theo_r_CA_SA.mat");
% dlabTheo=dlabTheo.dlab_theo;
% i_the=1;
% 
% for i = 1:numel(files) 
% 
% 
%     img=imread(fullfile(files(i).folder, files(i).name));
%     % 解析文件名中的 dlab 值
%     slashes1 = find(files(i).name == '[');
%     slashes2 = find(files(i).name == ',');
%     slashes3 = find(files(i).name == ']');
% 
%     dlab(1,1) = str2double(files(i).name(slashes1+1:slashes2(1)-1));
%     dlab(1,2) = str2double(files(i).name(slashes2(1)+1:slashes2(2)-1));
%     dlab(1,3) = str2double(files(i).name(slashes2(2)+1:slashes3-1));
% 
%     lastPart=files(i).name(1:4);
%     lastPart=gen_lastPart_new(lastPart);
%     if ismember(lastPart,["m02i","m03i"]) 
%         if_2mask=1;
%     else
%         if_2mask=0;
%     end
%     dir_mask=dir(fullfile("mask",lastPart,"*.jpg"));
%     dir_mask_nosd=dir(fullfile("Shadow\mask",lastPart,"nosd\*.jpg"));
% 
% 
%     [m, n, p] = size(img); 
%     flag=0;
%     if if_2mask
%         dir_mask_used=dir_mask_nosd;
%     else
%         dir_mask_used=dir_mask;
%     end
%     for i_mask=1:length(dir_mask_used)
%         if contains(lower(files(i).name(1:end-4)),lower(dir_mask_used(i_mask).name(1:end-4)))
%             disp([files(i).name(1:end-4),dir_mask_used(i_mask).name(1:end-4)]);
%             bull=imread(strcat(dir_mask_used(i_mask).folder,'\',dir_mask_used(i_mask).name));
%             % bull = imresize(bull, [size(bull,1)./6, size(bull,2)./6]);%先跑小图看问题
%             flag=1;
%             break
%         end
%     end
%     if flag==1
%         if ismember(lastPart,["f04i","f05i","f06i","m04i","m06i"]) 
%             if_wei=0;
%         else
%             if_wei=1;
%         end
%         [logicalIndex,bull_weight]=read_bull(bull,if_wei);
%         img=im2double(img);
%         out=reshape(img, [m * n, p]);
%         out = out * 255;
% 
%         datai_file = 'calibResults\datai_ipv18_3.mat';
%         xyz = lut3d_rgb2xyz1(out, datai_file);     
% 
%         LUT=load(datai_file);
%         XYZw_LUT=LUT.XYZw;
%         wd65_scaled=wd65./100.*XYZw_LUT(2);
% 
%         [lab] = xyz2lab(xyz,'user',wd65_scaled);
% 
%         [average_lab]=get_average(lab,bull,if_wei);
%         for i_the=1:length(dlabTheo)
%             name=dlabTheo{i_the,1};
%             name=char(name);            
%             if strcmpi(files(i).name(1:slashes1-1),strrep(name,".JPG",""))
%                 dlab_theo=dlabTheo{i_the,2};
%                 break  
%             end
%         end
%         dE_cell{i,1}=files(i).name;
%         dE_cell{i,2}=average_lab;
%         dE_cell{i,3}=dlab_theo;
% 
%         dE_cell{i,4}=deltaE2000(dlab,average_lab);
%         dE_cell{i,5}=deltaE2000(dlab_theo,average_lab);
%         dE_cell{i,6}=deltaE2000(dlab_theo,dlab);
%         i_the=i_the+1;
% 
%         [delch(i,1),delch(i,2),delch(i,3),delch(i,4)] = cielabde(dlab_theo,average_lab);
%         disp(delch(i,:));
% 
% % -----画mask区域肤色预览图-----------
%         if if_wei
%             out=out.*bull_weight;
%         else
%             for i_out=1:length(out)
%                 if logicalIndex(i_out)==1
%                     out(i_out,:)=[0,0,0];
%                 end
%             end        
%         end
% 
%         imshow(reshape(out,[m,n,p])./255);
%         output_folder=fullfile(save_folder,"cropped_area_skin");
%         if ~exist(output_folder,"dir")
%             mkdir(output_folder);
%         end
%         if mod(i,33)==0
%             % imwrite(reshape(out,[m,n,p])./255, ...
%             %     fullfile(output_folder,files(i).name));
%         end
% 
% 
%     else
% 
%         average_xyz=[0 0 0];
%         average_lab=[0 0 0];
%     end
% 
%     average_lab_all=[average_lab_all;average_lab];
% 
% end
% 
% save(fullfile(save_folder,'checkLabFromPics_CA_SA.mat'), ...
% "dE_cell");

% disp("done");
% 
% dE_cell_big=[];
% for i_dE=1:length(dE_cell)
%     if ~(dE_cell{i_dE,4}<1&&dE_cell{i_dE,5}<1&&dE_cell{i_dE,6}<1)
%         dE_cell_big=[dE_cell_big;dE_cell(i_dE,:)];
%     end
% end
% dE_cell_big_calNv=[];
% for i_dE=1:length(dE_cell)
%     if ~(dE_cell{i_dE,5}<1)
%         dE_cell_big_calNv=[dE_cell_big_calNv;dE_cell(i_dE,:)];
%     end
% end
% save(fullfile(save_folder,'checkLabFromPics_CA_SA.mat'), ...
%     "dE_cell","dE_cell_big","dE_cell_big_calNv");
%% 把源文件夹下及其子文件夹下面所有名为10ruddy的文件夹改为10ruddy_ori
% % 目标文件夹路径
% targetFolder = "D:\work\VIVOskinExpe\analyze\AnalyseResults";
% 
% % 检查目标文件夹是否存在
% if ~isfolder(targetFolder)
%     error('指定的文件夹不存在：%s', targetFolder);
% end
% 
% % 定义要重命名的文件夹名称
% folderToRename = '10ruddy';
% newFolderName = '10ruddy_ori';
% 
% % 递归重命名指定文件夹
% rename_folders_recursively(targetFolder, folderToRename, newFolderName);
% 
% disp('指定的文件夹已成功重命名。');
% 
% function rename_folders_recursively(folderPath, folderToRename, newFolderName)
%     % 获取当前文件夹中的所有条目
%     entries = dir(fullfile(folderPath, '*'));
%     subFolders = entries([entries.isdir]); % 只保留文件夹
%     subFolders = {subFolders.name};
%     subFolders = subFolders(~ismember(subFolders, {'.', '..'})); % 去掉 . 和 ..
% 
%     % 遍历所有子文件夹
%     for i = 1:length(subFolders)
%         currentFolder = subFolders{i};
%         fullPath = fullfile(folderPath, currentFolder);
% 
%         % 如果当前文件夹是需要重命名的文件夹
%         if strcmp(currentFolder, folderToRename)
%             newFullPath = fullfile(folderPath, newFolderName);
%             movefile(fullPath, newFullPath); % 重命名文件夹
%             fprintf('文件夹已重命名：%s -> %s\n', fullPath, newFullPath);
%         else
%             % 递归处理子文件夹
%             rename_folders_recursively(fullfile(folderPath, currentFolder), folderToRename, newFolderName);
%         end
%     end
% end
%%
% %matlab一键删除一个文件夹及其子文件夹里面所有名为10ruddy、10ruddyadd_mixed、
% % % delete_log、ellipPara95、list、的文件夹
% % % 目标文件夹路径
% targetFolder = "F:\toVIVO_AS\renderTargetScore\AnalyseResults\summer";
% 
% % 检查目标文件夹是否存在
% if ~isfolder(targetFolder)
%     error('指定的文件夹不存在：%s', targetFolder);
% end
% 
% % 定义要删除的文件夹名称
% foldersToDelete = {'10ruddy', '10ruddyadd_mixed', 'delete_log', 'ellipPara95', 'list', 'pre_draw'};
% 
% % 定义要删除的文件名称
% filesToDelete = {'STRESS.mat'};
% 
% % 递归删除指定文件夹和文件
% delete_folders_and_files_recursively(targetFolder, foldersToDelete, filesToDelete);
% 
% disp('指定的文件夹和文件已成功删除。');
% 
% function delete_folders_and_files_recursively(folderPath, foldersToDelete, filesToDelete)
%     % 获取当前文件夹中的所有条目
%     entries = dir(fullfile(folderPath, '*'));
%     subFolders = entries([entries.isdir]); % 只保留文件夹
%     subFiles = entries(~[entries.isdir]); % 只保留文件
% 
%     % 提取文件夹名称和文件名称
%     subFolders = {subFolders.name};
%     subFolders = subFolders(~ismember(subFolders, {'.', '..'})); % 去掉 . 和 ..
%     subFiles = {subFiles.name};
% 
%     % 删除匹配的文件夹
%     for i = 1:length(subFolders)
%         currentFolder = subFolders{i};
%         if ismember(currentFolder, foldersToDelete)
%             fullPath = fullfile(folderPath, currentFolder);
%             rmdir(fullPath, 's'); % 删除文件夹及其内容
%             fprintf('已删除文件夹：%s\n', fullPath);
%         else
%             % 递归处理子文件夹
%             delete_folders_and_files_recursively(fullfile(folderPath, currentFolder), foldersToDelete, filesToDelete);
%         end
%     end
% 
%     % 删除匹配的文件
%     for i = 1:length(subFiles)
%         currentFile = subFiles{i};
%         if ismember(currentFile, filesToDelete)
%             fullPath = fullfile(folderPath, currentFile);
%             delete(fullPath); % 删除文件
%             fprintf('已删除文件：%s\n', fullPath);
%         end
%     end
% end

%% i CardMask

% source_folder="D:\work\VIVOskinExpe\renderCode\rendered\i\ASadd";
% dest_foler=fullfile(source_folder,"CardMasked");
% if ~exist(dest_foler, 'dir')
%     mkdir(dest_foler);
% end
% % % 获取源文件夹中的所有子文件夹
% % SubFolders = dir(fullfile(source_folder, 'm*'));
% SubFolders = dir(fullfile(source_folder, 'f*')); % 获取以 "f" 开头的子文件夹
% SubFolders = [SubFolders; dir(fullfile(source_folder, 'm*'))]; % 添加以 "m" 开头的子文件夹
% % for i_sub=[length(SubFolders)]
% for i_sub=1:length(SubFolders)
%     sub_folder=fullfile(SubFolders(i_sub).folder,SubFolders(i_sub).name);
%     files=dir(fullfile(sub_folder,"*.jpg"));
% 
% 
%     for i=1:length(files)
%         slashes = find(files(i).name == '_');
%         slashes1=find(files(i).name == '[');
% 
%         file_CardMask=fullfile("CardMask",strrep(SubFolders(i_sub).name,"i",""), ...
%             strcat(files(i).name(1:slashes-1),".jpg"));
%         if exist(file_CardMask,"file")
% 
%             bull=imread(file_CardMask);
%             [logicalIndex,~]=read_bull(bull,0);
% 
%             img0=imread(fullfile(files(i).folder, files(i).name));
%             img=im2double(img0);
%             [m, n, p] = size(img);
%             out = reshape(img, [m * n, p]);
% 
% 
%             if any(~logicalIndex)
%                 out(~logicalIndex, :)=repmat([0,0,0], sum(~logicalIndex), 1);
%             end
%             outnew = reshape(out, [m, n, p]);
%         else
%             outnew=imread(fullfile(files(i).folder, files(i).name));
%         end
%         %     imshow(outnew);
% 
% 
%         fikename_new=lower(strcat(SubFolders(i_sub).name, files(i).name(1:slashes1-1),".jpg"));
% 
%         targetFile=fullfile(dest_foler,fikename_new);
%         imwrite(outnew,targetFile);
%     end
%     disp(SubFolders(i_sub).name);
% end
%% rs CardMask

% source_folder="I:\work\VIVOskinExpe\renderCode\rendered\rs\adjust_ch_bg";
% dest_foler=fullfile(source_folder,"CardMasked");
% if ~exist(dest_foler, 'dir')
%     mkdir(dest_foler);
% end
% % % 获取源文件夹中的所有子文件夹
% SubFolders = dir(fullfile(source_folder, 'f*')); % 获取以 "f" 开头的子文件夹
% SubFolders = [SubFolders; dir(fullfile(source_folder, 'm*'))]; % 添加以 "m" 开头的子文件夹
% for i_sub=[length(SubFolders)]
% % for i_sub=length(SubFolders):-1:1
%     sub_folder=fullfile(SubFolders(i_sub).folder,SubFolders(i_sub).name);
%     files=dir(fullfile(sub_folder,"*.jpg"));
% 
% 
%     for i=1:length(files)
%         slashes = find(files(i).name == '_');
%         slashes1=find(files(i).name == '[');
% 
%         file_CardMask=fullfile("CardMask",SubFolders(i_sub).name, ...
%             strcat(files(i).name(1:slashes-1),".jpg"));
%         if exist(file_CardMask,"file")
% 
%             bull=imread(file_CardMask);
%             [logicalIndex,~]=read_bull(bull,0);
% 
%             img0=imread(fullfile(files(i).folder, files(i).name));
%             img=im2double(img0);
%             [m, n, p] = size(img);
%             out = reshape(img, [m * n, p]);
% 
% 
%             if any(~logicalIndex)
%                 out(~logicalIndex, :)=repmat([0,0,0], sum(~logicalIndex), 1);
%             end
%             outnew = reshape(out, [m, n, p]);
%         else
%             outnew=imread(fullfile(files(i).folder, files(i).name));
%         end
%         %     imshow(outnew);
% 
% 
%         fikename_new=lower(strcat(SubFolders(i_sub).name, files(i).name(1:slashes1-1),".jpg"));
% 
%         targetFile=fullfile(dest_foler,fikename_new);
%         imwrite(outnew,targetFile);
%     end
% end
%% 全部CardMask

% source_folder="D:\work\VIVOskinExpe\renderCode\rendered\33_i_lL_C_CATedN2mask\drawable";
% files=dir(fullfile(source_folder,"*.jpg"));
% dest_foler=fullfile(source_folder,"CardMasked");
% if ~exist(dest_foler, 'dir')
%     mkdir(dest_foler);
% end
% for i=1:length(files)
%     slashes = find(files(i).name == '_');
%     slashes1=find(files(i).name == '[');
%     fikename_new=strcat(files(i).name(1:slashes1-1),".jpg");
% 
%     prefix=files(i).name(1:slashes-1);
%     lastPart=files(i).name(1:4);
%     light_str=strrep(prefix,lastPart,"");
%     model=lastPart(1:end-1);
%     % model_old=gen_lastPart_old(model);
%     dir_cardMask=dir(fullfile("CardMask",model,"*.jpg"));
%     for i_mask=1:length(dir_cardMask)
%         if strcmpi(light_str,dir_cardMask(i_mask).name(1:end-4))
%             bull=imread(fullfile(dir_cardMask(i_mask).folder,dir_cardMask(i_mask).name));
%             [logicalIndex,~]=read_bull(bull,0);
%             break
%         end
% 
%     end
% 
%     img0=imread(fullfile(files(i).folder, files(i).name));
%     img=im2double(img0);
%     [m, n, p] = size(img);
%     out = reshape(img, [m * n, p]);
% 
% 
%     if any(~logicalIndex)
%         out(~logicalIndex, :)=repmat([0,0,0], sum(~logicalIndex), 1);
%     end
%     outnew = reshape(out, [m, n, p]);
%     %     imshow(outnew);
%     targetFile=fullfile(dest_foler,fikename_new);
%     imwrite(outnew,targetFile);
% end
%%
% % 定义源文件夹和目标文件夹路径
% sourceFolder = 'D:\work\VIVOskinExpe\renderCode\rendered\33_i_lL_C_CATed\cau'; % 源文件夹路径
% destFolder = 'D:\work\VIVOskinExpe\renderCode\rendered\33_i_lL_C_CATed\cau\2mask'; % 目标文件夹路径
% 
% % 获取源文件夹中的所有子文件夹
% sourceSubFolders = dir(fullfile(sourceFolder, 'f*')); % 获取以 "f" 开头的子文件夹
% sourceSubFolders = [sourceSubFolders; dir(fullfile(sourceFolder, 'm*'))]; % 添加以 "m" 开头的子文件夹
% 
% % 遍历每个子文件夹
% for i = 1:length(sourceSubFolders)
%     subFolder = sourceSubFolders(i).name;
%     subFolderPath = fullfile(sourceFolder, subFolder);
% 
%     % 获取子文件夹中的所有 jpg 文件
%     jpgFiles = dir(fullfile(subFolderPath, '*.jpg'));
% 
%     % 遍历每个 jpg 文件
%     for j = 1:length(jpgFiles)
%         jpgFile = jpgFiles(j).name;
%         jpgFilePath = fullfile(subFolderPath, jpgFile);
% 
%         % 获取文件的时间戳
%         fileAttributes = dir(jpgFilePath);
%         fileDate = fileAttributes.date;
% 
%         % 将时间戳转换为日期格式
%         fileDateNum = datenum(fileDate);
%         targetDateNum = datenum('2025-02-10');
% 
%         % 检查文件的时间戳是否在 2025 年 2 月 10 日之前
%         if fileDateNum < targetDateNum
%             % 创建目标文件夹（如果不存在）
%             destSubFolderPath = fullfile(destFolder, subFolder);
%             if ~exist(destSubFolderPath, 'dir')
%                 mkdir(destSubFolderPath);
%             end
% 
%             % 移动文件到目标文件夹
%             destFilePath = fullfile(destSubFolderPath, jpgFile);
%             movefile(jpgFilePath, destFilePath);
%             fprintf('Moved: %s to %s\n', jpgFilePath, destFilePath);
%         end
%     end
% end
% 
% disp('Operation completed.');
%% 遇见多余的取色差最小的其余移动 实验图版
% folderPath = 'D:\work\VIVOskinExpe\renderCode\rendered\33_i_lL_C_CATed\drawable';
% 
% dest_foldr = fullfile(folderPath, "discarded");
% if ~exist(dest_foldr, 'dir')
%     mkdir(dest_foldr);
% end
% 
% % 获取所有jpg文件
% jpgFiles = dir(fullfile(folderPath, '*.JPG'));
% 
% % 初始化一个空的容器
% fileGroups = containers.Map('KeyType', 'char', 'ValueType', 'any');
% 
% % 加载数据
% dlabTheo=load("D:\work\VIVOskinExpe\renderCode\rendered\33_i_lL_C_CATed\theo_dlab\theo_dlab_iCATAsian.mat");
% dlabTheo=dlabTheo.dlab_theo;
% % 遍历每个文件
% for i = 1:length(jpgFiles)
%     % 获取文件名
%     [~, fileName, ~] = fileparts(jpgFiles(i).name);
%     slashes = find(fileName == '_');
%     serial(i, 1) = str2double(fileName(slashes + 1:slashes + 2));
%     slashes1 = find(fileName == '[');
%     slashes2 = find(fileName == ',');
%     slashes3 = find(fileName == ']');
%     dlab(1, 1) = str2double(fileName(slashes1 + 1:slashes2(1) - 1));
%     dlab(1, 2) = str2double(fileName(slashes2(1) + 1:slashes2(2) - 1));
%     dlab(1, 3) = str2double(fileName(slashes2(2) + 1:slashes3 - 1));
% 
%     % 查找对应的 dlab_theo
%     for i_dE = 1:length(dlabTheo)
%         name_theo = dlabTheo{i_dE, 1};
%         name_theo = char(name_theo);
%         if strcmpi(jpgFiles(i).name(1:slashes1 - 1), name_theo(1:end))
%             dlab_theo = dlabTheo{i_dE, 2};
%             break;
%         end
% 
%     end
% 
%     % 计算 dE_viNcal
%     dE_viNcal = deltaE2000(dlab, dlab_theo);
% 
%     % 使用正则表达式提取第二个下划线前的内容
%     tokens{i} = fileName(1:slashes1 - 1);
% 
%     if ~isempty(tokens{i})
%         key = tokens{i};
%         fileInfo = struct();
%         fileInfo.filePath = fullfile(folderPath, jpgFiles(i).name);
%         fileInfo.filename = jpgFiles(i).name;
%         fileInfo.dlab = dlab;
%         fileInfo.dlab_theo = dlab_theo;
%         fileInfo.dE_viNcal = dE_viNcal;
% 
%         % 将文件信息添加到对应的组
%         if isKey(fileGroups, key)
%             fileGroups(key) = [struct(fileGroups(key)); fileInfo];
%         else
%             fileGroups(key) = fileInfo;
%         end
%     end
% end
% destPath=fullfile(folderPath,"bigger_dE");
% if ~exist(destPath,"dir")
%     mkdir(destPath);
% end
% for i_token=1:length(tokens)
%     cell_data=[];
%     key = tokens{i_token}; % 替换为实际的 key
%     if isKey(fileGroups, key)
%         filesInfo = fileGroups(key);
%         for i_ing = 1:length(filesInfo)
%              cell_data{i_ing,1}=filesInfo(i_ing).filename;
%              cell_data{i_ing,2}=filesInfo(i_ing).dlab;
%              cell_data{i_ing,3}=filesInfo(i_ing).dlab_theo;
%              cell_data{i_ing,4}=filesInfo(i_ing).dE_viNcal;
%         end
%     else
%         fprintf('Key %s not found.\n', key);
%     end
%     cell_data_all{i_token,1}=cell_data;
% end
% % 保存 fileGroups 到文件以便后续调用
% if ~exist(fullfile(folderPath,"fileGroups"), 'dir')
%     mkdir(fullfile(folderPath,"fileGroups"));
% end
% 
% save(fullfile(folderPath,"fileGroups",'fileGroups.mat'),'tokens', 'fileGroups');
% %
% for i_token=1:size(cell_data_all,1)
%     cell_data=cell_data_all{i_token,1};
%     for i_ing=1:size(cell_data,1)
%         [min_val,min_idx]=min(cell2mat(cell_data(:,4)));
%     end
%     for i_ing=1:size(cell_data,1)
%         if i_ing~=min_idx
%             old_path=fullfile(folderPath,cell_data{i_ing,1});
%             new_path=fullfile(destPath,cell_data{i_ing,1});
%             if exist(old_path,"file")
%                 movefile(old_path,new_path);
%             end
%         end
%     end
% end
% 
% disp("done");

%% 遇见多余的取色差最小的其余移动
% folderPath = 'D:\work\VIVOskinExpe\renderCode\rendered\33_i_wei\PNp\50\summer\oriMask\toVIVO';
% % load(fullfile(folderPath,"fileGroups",'fileGroups.mat'), 'fileGroups');
% 
% target_score = "50";
% dest_foldr = fullfile(folderPath, "discarded");
% if ~exist(dest_foldr, 'dir')
%     mkdir(dest_foldr);
% end
% 
% % 获取所有jpg文件
% jpgFiles = dir(fullfile(folderPath, '*.JPG'));
% 
% % 初始化一个空的容器
% fileGroups = containers.Map('KeyType', 'char', 'ValueType', 'any');
% 
% % 加载数据
% load("rendered\33_i_wei\PNp\50\summer\dEFromCen\dE_fr_cen_simp.mat");
% 
% % 遍历每个文件
% for i = 1:length(jpgFiles)
%     % 获取文件名
%     [~, fileName, ~] = fileparts(jpgFiles(i).name);
%     slashes = find(fileName == '_');
%     serial(i, 1) = str2double(fileName(slashes + 1:slashes + 2));
%     slashes1 = find(fileName == '[');
%     slashes2 = find(fileName == ',');
%     slashes3 = find(fileName == ']');
%     dlab(1, 1) = str2double(fileName(slashes1 + 1:slashes2(1) - 1));
%     dlab(1, 2) = str2double(fileName(slashes2(1) + 1:slashes2(2) - 1));
%     dlab(1, 3) = str2double(fileName(slashes2(2) + 1:slashes3 - 1));
% 
%     % 查找对应的 dlab_theo
%     for i_dE = 1:length(dE_fr_cen)
%         name_fr_dE = dE_fr_cen{i_dE, 1};
%         name_fr_dE = char(name_fr_dE);
%         if target_score == "90" || target_score == "50"
%             if strcmp(jpgFiles(i).name(1:slashes1 - 1), name_fr_dE(1:end - 4))
%                 dlab_theo = dE_fr_cen{i_dE, 2};
%                 break;
%             end
%         elseif target_score == "100"
%             if strcmp(jpgFiles(i).name(1:slashes1 - 1), name_fr_dE(1:end - 6))
%                 dlab_theo = dE_fr_cen{i_dE, 3};
%                 break;
%             end
%         end
%     end
% 
%     % 计算 dE_viNcal
%     dE_viNcal = deltaE2000(dlab, dlab_theo);
% 
%     % 使用正则表达式提取第二个下划线前的内容
%     tokens{i} = fileName(1:slashes1 - 1);
% 
%     if ~isempty(tokens{i})
%         key = tokens{i};
%         fileInfo = struct();
%         fileInfo.filePath = fullfile(folderPath, jpgFiles(i).name);
%         fileInfo.filename = jpgFiles(i).name;
%         fileInfo.dlab = dlab;
%         fileInfo.dlab_theo = dlab_theo;
%         fileInfo.dE_viNcal = dE_viNcal;
% 
%         % 将文件信息添加到对应的组
%         if isKey(fileGroups, key)
%             fileGroups(key) = [struct(fileGroups(key)); fileInfo];
%         else
%             fileGroups(key) = fileInfo;
%         end
%     end
% end
%%
% % folderPath = 'D:\work\VIVOskinExpe\renderCode\rendered\33_i_wei\PNp\50\summer\oriMask\toVIVO';
% % load(fullfile(folderPath,"fileGroups",'fileGroups.mat'), 'fileGroups');
% destPath=fullfile(folderPath,"bigger_dE");
% if ~exist(destPath,"dir")
%     mkdir(destPath);
% end
% for i_token=1:length(tokens)
%     cell_data=[];
%     key = tokens{i_token}; % 替换为实际的 key
%     if isKey(fileGroups, key)
%         filesInfo = fileGroups(key);
%         for i_ing = 1:length(filesInfo)
%              cell_data{i_ing,1}=filesInfo(i_ing).filename;
%              cell_data{i_ing,2}=filesInfo(i_ing).dlab;
%              cell_data{i_ing,3}=filesInfo(i_ing).dlab_theo;
%              cell_data{i_ing,4}=filesInfo(i_ing).dE_viNcal;
%         end
%     else
%         fprintf('Key %s not found.\n', key);
%     end
%     cell_data_all{i_token,1}=cell_data;
% end
% % 保存 fileGroups 到文件以便后续调用
% if ~exist(fullfile(folderPath,"fileGroups"), 'dir')
%     mkdir(fullfile(folderPath,"fileGroups"));
% end
% 
% save(fullfile(folderPath,"fileGroups",'fileGroups.mat'),'tokens', 'fileGroups');
%%
% for i_token=1:size(cell_data_all,1)
%     cell_data=cell_data_all{i_token,1};
%     for i_ing=1:size(cell_data,1)
%         [min_val,min_idx]=min(cell2mat(cell_data(:,4)));
%     end
%     for i_ing=1:size(cell_data,1)
%         if i_ing~=min_idx
%             old_path=fullfile(folderPath,cell_data{i_ing,1});
%             new_path=fullfile(destPath,cell_data{i_ing,1});
%             if exist(old_path,"file")
%                 movefile(old_path,new_path);
%             end
%         end
%     end
% end

% disp("done");

%% ---------------------------------










%% 复制ruddy
% folderPath="D:\work\VIVOskinExpe\renderCode\rendered\33_i_wei\PNp\summer\m04i";
% destFolder=fullfile(folderPath,"ruddy");
% if ~exist(destFolder,"dir")
%     mkdir(destFolder);
% end
%     % 获取二级子文件夹（以 "H"、"M" 或 "L" 开头）
% subfolders = dir(fullfile(folderPath, 'H*'));
% subfolders = [subfolders; dir(fullfile(folderPath, 'M*'))];
% subfolders = [subfolders; dir(fullfile(folderPath, 'L*'))];
% subfolders = subfolders([subfolders.isdir]); % 只保留文件夹
% 
% % 遍历每个二级子文件夹
% for j = 1:length(subfolders)
%     subfolderName = subfolders(j).name;
%     subfolderPath = fullfile(folderPath, subfolderName);
% 
%     % 获取二级子文件夹中的所有 .jpg 文件
%     jpgFiles = dir(fullfile(subfolderPath, '*.jpg'));
% 
%     % 遍历每个 .jpg 文件
%     for k = 1:length(jpgFiles)
%         fileName = jpgFiles(k).name;
% 
%         % 检查文件名是否包含 "PMCC" 或 "ruddy"
%         if contains(fileName, 'ruddy')
%             % 构造新的文件名（在原文件名前加上一级子文件夹的名字）
%             newFileName = strcat(subfolderName, fileName);
% 
%             % 构造源文件路径和目标文件路径
%             sourceFilePath = fullfile(subfolderPath, fileName);
%             destFilePath = fullfile(destFolder, newFileName);
% 
%             % 复制文件
%             copyfile(sourceFilePath, destFilePath);
%         end
%     end
% end
%%
%matlab，对于一个文件夹下面所有一级子文件夹（除掉.和..）若其下有名为add的二级子文件夹，
% 则对于add内每一个jpg文件，假设文件名中[前内容（提取时别用正则表达式）为前缀，
% 将该一级子文件夹中相同前缀的jpg文件移入该一级子文件夹下面的“discarded"文件夹内，
% % 并把add中的jpg文件复制如该一级子文件夹
% clc;
% clear;
% 
% % 指定主文件夹路径
% mainFolder = 'D:\work\VIVOskinExpe\renderCode\rendered\i\interp'; % 替换为你的文件夹路径
% 
% % 获取所有一级子文件夹
% subFolders = dir(mainFolder);
% subFolders = subFolders([subFolders.isdir]); % 只保留文件夹
% subFolders = subFolders(~ismember({subFolders.name}, {'.', '..'})); % 忽略 . 和 ..
% 
% % 遍历一级子文件夹
% for k = 1:length(subFolders)
%     currentFolder = fullfile(mainFolder, subFolders(k).name);
% 
%     % 检查是否存在 'add' 文件夹
%     addFolder = fullfile(currentFolder, 'add');
%     if ~isfolder(addFolder)
%         continue; % 不存在 'add' 文件夹，跳过
%     end
% 
%     % 创建 'discarded' 文件夹（如果不存在）
%     discardedFolder = fullfile(currentFolder, 'discarded');
%     if ~isfolder(discardedFolder)
%         mkdir(discardedFolder);
%     end
% 
%     % 获取 'add' 文件夹中的所有 .jpg 文件
%     jpgFiles = dir(fullfile(addFolder, '*.jpg'));
% 
%     % 遍历 'add' 中的 .jpg 文件
%     for j = 1:length(jpgFiles)
%         jpgFile = jpgFiles(j).name;
% 
%         % 提取文件名前缀（不包含下划线和扩展名）
%         prefix = extractBefore(jpgFile, '['); % 使用下划线作为分隔符
% 
% 
%         % 查找一级子文件夹中具有相同前缀的 .jpg 文件
%         matchingFiles = dir(fullfile(currentFolder, strcat(prefix, '*.jpg')));
% 
%         % 将匹配的 .jpg 文件移动到 'discarded' 文件夹
%         for m = 1:length(matchingFiles)
%             sourceFile = fullfile(currentFolder, matchingFiles(m).name);
%             destinationFile = fullfile(discardedFolder, matchingFiles(m).name);
%             movefile(sourceFile, destinationFile);
%         end
% 
%         % 复制 'add' 中的 .jpg 文件到一级子文件夹
%         sourceFile = fullfile(addFolder, jpgFile);
%         destinationFile = fullfile(currentFolder, jpgFile);
%         copyfile(sourceFile, destinationFile);
%     end
% end
% 
% disp('处理完成！');

%% 替换旧的
% sourceFolder = 'D:\work\VIVOskinExpe\renderCode\rendered\33_i_wei\PNp\summer\oriMask\toVIVO';
% destFolder='D:\work\VIVOskinExpe\renderCode\rendered\toVIVO\100';
% discardFolder=fullfile(destFolder,"discarded");
% if ~exist(discardFolder,"dir")
%     mkdir(discardFolder);
% end
% dir_source=dir(fullfile(sourceFolder,"*.jpg"));
% % 创建日志文件
% logFileName = sprintf('log_%s.txt', datestr(now, 'yyyy-mm-dd_HH-MM-SS')); % 生成带时间戳的日志文件名
% logFilePath = fullfile(destFolder, logFileName); % 日志文件路径
% logFile = fopen(logFilePath, 'w'); % 打开日志文件
% 
% for i_source=1:length(dir_source)
%     slashes1 = find(dir_source(i_source).name == '[');
%     prefix=dir_source(i_source).name(1:slashes1-1);
%     dir_prefix=dir(fullfile(destFolder,strcat(prefix,"*.jpg")));
%     for i_pref=1:length(dir_prefix)
%         old_path=fullfile(destFolder,dir_prefix(i_pref).name);
%         new_path=fullfile(discardFolder,dir_prefix(i_pref).name);
%         movefile(old_path,new_path);
%         % 记录日志
%         fprintf(logFile, '[%s] Moved file: %s -> %s\n', ...
%             datestr(now, 'yyyy-mm-dd HH:MM:SS'), old_path, new_path);
%     end
%     old_path=fullfile(sourceFolder,dir_source(i_source).name);
%     new_path=fullfile(destFolder,dir_source(i_source).name);
%     copyfile(old_path,new_path);
%     % 记录日志
%     fprintf(logFile, '[%s] Copied file: %s -> %s\n', ...
%         datestr(now, 'yyyy-mm-dd HH:MM:SS'), old_path, new_path);
% end
% % 关闭日志文件
% fclose(logFile);
% disp("Operation completed. Log file created: " + logFilePath);

%% 复制到drawable 100/90
% Define source and destination folder paths
sourceFolder = 'F:\VIVOskinExpe\skin_projectV4\evaluation_rendering\render_code\rendered\LUT\non_model\100'; % Replace with your actual source folder path
destFolder = 'F:\VIVOskinExpe\skin_projectV4\evaluation_rendering\render_code\rendered\LUT\non_model\100\drawable\r'; % Replace with your actual destination folder path

% Ensure the destination folder exists
if ~exist(destFolder, 'dir')
    mkdir(destFolder);
end

% Get first-level subfolders (starting with "f" or "m" and ending with "r")
subfolders = dir(fullfile(sourceFolder, 'f*r'));
subfolders = [subfolders; dir(fullfile(sourceFolder, 'm*r'))];
subfolders = subfolders([subfolders.isdir]); % Keep only directories

% Iterate through each first-level subfolder
for i = 1:length(subfolders)
    subfolderName = subfolders(i).name;
    subfolderPath = fullfile(sourceFolder, subfolderName);

    % Get third-level subfolders (starting with "rs")
    third_level_folders = dir(fullfile(subfolderPath, 'rs*'));
    third_level_folders = third_level_folders([third_level_folders.isdir]);

    for i_third = 1:length(third_level_folders)
        third_level_Path = fullfile(third_level_folders(i_third).folder, ...
            third_level_folders(i_third).name);

        % Get all .jpg files in the third-level subfolder
        jpgFiles = dir(fullfile(third_level_Path, '*.jpg'));

        % Iterate through each .jpg file
        for j = 1:length(jpgFiles)
            fileName = jpgFiles(j).name;
            
            % Construct the new file name (prefixing with the first-level subfolder name)
            % The original code had a commented-out section for removing bracketed text.
            % If you need that functionality, uncomment and adjust accordingly.
            newFileName = strcat(strrep(subfolderName,"add",""),  lower(fileName));
            
            % Construct source and destination file paths
            sourceFilePath = fullfile(third_level_Path, fileName);
            destFilePath = fullfile(destFolder, newFileName);
            
            % Check if the destination file already exists
            if exist(destFilePath, 'file') == 2
                disp(['Skipping: ', newFileName, ' (file already exists in destination)']);
            else
                % Copy the file
                copyfile(sourceFilePath, destFilePath);
                disp(['Copied: ', newFileName]);
            end
        end
    end
end
disp('File copying process complete!');
%% 复制到drawable
% % % % % 定义源文件夹和目标文件夹路径
% sourceFolder = 'D:\work\VIVOskinExpe\skin_projectV2\evaluation_rendering\render_code\rendered\LUT\non_model\100'; % 替换为实际的源文件夹路径
% destFolder = 'D:\work\VIVOskinExpe\skin_projectV2\evaluation_rendering\render_code\rendered\LUT\non_model\100\drawable'; % 替换为实际的目标文件夹路径
% 
% % 确保目标文件夹存在
% if ~exist(destFolder, 'dir')
%     mkdir(destFolder);
% end
% 
% % 获取一级子文件夹（以 "f" 或 "m" 开头）
% % subfolders = dir(fullfile(sourceFolder,'m*'));
% subfolders = dir(fullfile(sourceFolder, 'f*'));
% subfolders = [subfolders; dir(fullfile(sourceFolder, 'm*'))];
% subfolders = subfolders([subfolders.isdir]); % 只保留文件夹
% 
% % 遍历每个一级子文件夹
% for i = 1:length(subfolders)
%     subfolderName = subfolders(i).name;
%     subfolderPath = fullfile(sourceFolder, subfolderName);
% 
%     % 获取一级子文件夹中的所有 .jpg 文件
%     jpgFiles = dir(fullfile(subfolderPath, '*.jpg'));
% 
%     % 遍历每个 .jpg 文件
%     for j = 1:length(jpgFiles)
%         fileName = jpgFiles(j).name;
% 
%         % 构造新的文件名（在原文件名前加上一级子文件夹的名字）
%         newFileName = strcat(subfolderName, lower(fileName));
%         % slashes1=find(newFileName1=='[');
%         % slashes2=find(newFileName1==']');
%         % newFileName=strrep(newFileName1,newFileName1(slashes1:slashes2),"");
% 
%         % 构造源文件路径和目标文件路径
%         sourceFilePath = fullfile(subfolderPath, fileName);
%         destFilePath = fullfile(destFolder, newFileName);
% 
%         % 复制文件
%         copyfile(sourceFilePath, destFilePath);
%     end
% end
% 
% disp('文件复制完成！');
%% 把07Fidelity移动进去
% % % 定义源文件夹和目标文件夹
% source_folder = 'D:\work\VIVOskinExpe\renderCode\rendered\33_i_wei\non_model\90\summer\09_07'; % 源文件夹路径
% dest_folder = 'D:\work\VIVOskinExpe\renderCode\rendered\33_i_wei\non_model\90\summer'; % 目标文件夹路径
% 
% % 获取源文件夹下的所有一级子文件夹
% top_level_folders = dir(fullfile(source_folder, 'f*'));
% top_level_folders = [top_level_folders;dir(fullfile(source_folder, 'm*'))];% 匹配以 f 或 m 开头的文件夹
% 
% % 遍历每个一级子文件夹
% for i = 1:length(top_level_folders)
%     top_level_folder = fullfile(source_folder, top_level_folders(i).name);
% 
%     % 获取二级子文件夹（07Fidelity）
%     second_level_folder = fullfile(top_level_folder, '07Fidelity');
% 
%     if isfolder(second_level_folder) % 确保二级子文件夹存在
%         % 获取三级子文件夹（以 H, M, L 开头）
%         third_level_folders = dir(fullfile(second_level_folder, 'H*'));
%         third_level_folders = [third_level_folders;dir(fullfile(second_level_folder, 'L*'))];
%         third_level_folders = [third_level_folders;dir(fullfile(second_level_folder, 'M*'))];
% 
%         % 遍历每个三级子文件夹
%         for j = 1:length(third_level_folders)
%             third_level_folder = fullfile(second_level_folder, third_level_folders(j).name);
% 
%             % 获取三级子文件夹下的所有文件
%             files_to_copy = dir(fullfile(third_level_folder, '*.jpg'));
% 
%             % 创建目标文件夹路径
%             dest_path = fullfile(dest_folder, ...
%                 top_level_folders(i).name, ...
%                 third_level_folders(j).name); % 三级子文件夹名称
% 
%             % 如果目标文件夹不存在，则创建
%             if ~isfolder(dest_path)
%                 mkdir(dest_path);
%             end
% 
%             % 复制文件到目标文件夹
%             for k = 1:length(files_to_copy)
%                 source_file = fullfile(third_level_folder, files_to_copy(k).name);
%                 destination_file = fullfile(dest_path, files_to_copy(k).name);
%                 copyfile(source_file, destination_file);
%             end
%         end
%     end
% end
% 
% disp('文件复制完成！');
%%
% %% 把07移动出来
% sourceFolder = 'D:\work\VIVOskinExpe\renderCode\rendered\33_i_wei\non_model\100\summer'; % 替换为实际的源文件夹路径
% destFolder = 'D:\work\VIVOskinExpe\renderCode\rendered\33_i_wei\non_model\100\summer\07_old'; % 替换为实际的目标文件夹路径
% 
% % 确保目标文件夹存在
% if ~exist(destFolder, 'dir')
%     mkdir(destFolder);
% end
% 
% % 获取一级子文件夹（以 "f" 或 "m" 开头）
% subfolders = dir(fullfile(sourceFolder, 'f*'));
% subfolders = [subfolders; dir(fullfile(sourceFolder, 'm*'))];
% subfolders = subfolders([subfolders.isdir]); % 只保留文件夹
% 
% % 遍历每个一级子文件夹
% for i = 1:length(subfolders)
%     subfolderName = subfolders(i).name;
%     subfolderPath = fullfile(sourceFolder, subfolderName);
% 
%     % 获取二级子文件夹（以 "H"、"M" 或 "L" 开头）
%     subsubfolders = dir(fullfile(subfolderPath, 'H*'));
%     subsubfolders = [subsubfolders; dir(fullfile(subfolderPath, 'M*'))];
%     subsubfolders = [subsubfolders; dir(fullfile(subfolderPath, 'L*'))];
%     subsubfolders = subsubfolders([subsubfolders.isdir]); % 只保留文件夹
% 
%     % 遍历每个二级子文件夹
%     for j = 1:length(subsubfolders)
%         subsubfolderName = subsubfolders(j).name;
%         subsubfolderPath = fullfile(subfolderPath, subsubfolderName);
% 
%         % 获取二级子文件夹中的所有 .jpg 文件
%         jpgFiles = dir(fullfile(subsubfolderPath, '*.jpg'));
% 
%         % 遍历每个 .jpg 文件
%         for k = 1:length(jpgFiles)
%             fileName = jpgFiles(k).name;
% 
%             % 检查文件名是否包含 "PMCC" 或 "ruddy"
%             if contains(fileName, '07Precise reproduction') 
%                 % 构造新的文件名（在原文件名前加上一级子文件夹的名字）
%                 newFileName = strcat(subfolderName, fileName);
% 
%                 % 构造源文件路径和目标文件路径
%                 sourceFilePath = fullfile(subsubfolderPath, fileName);
%                 destFilePath = fullfile(destFolder, newFileName);
% 
%                 % 复制文件
%                 movefile(sourceFilePath, destFilePath);
%             end
%         end
%     end
% end
% 
% disp('文件复制完成！');

%% 复制到toVIVO
% % % % % % % % % 定义源文件夹和目标文件夹路径
% sourceFolder = 'D:\work\VIVOskinExpe\skin_projectV4\evaluation_rendering\render_code\rendered\LUT\non_model\100'; % 替换为实际的源文件夹路径
% destFolder = 'D:\work\VIVOskinExpe\skin_projectV4\evaluation_rendering\render_code\rendered\LUT\non_model\100\toVIVO1'; % 替换为实际的目标文件夹路径
% 
% % 确保目标文件夹存在
% if ~exist(destFolder, 'dir')
%     mkdir(destFolder);
% end
% 
% % 获取一级子文件夹（以 "f" 或 "m" 开头）
% subfolders = dir(fullfile(sourceFolder, 'f*'));
% subfolders = [subfolders; dir(fullfile(sourceFolder, 'm*'))];
% subfolders = subfolders([subfolders.isdir]); % 只保留文件夹
% 
% % 遍历每个一级子文件夹
% for i = 1:length(subfolders)
%     subfolderName = subfolders(i).name;
%     subfolderPath = fullfile(sourceFolder, subfolderName);
% 
%     % 获取二级子文件夹（以 "H"、"M" 或 "L" 开头）
%     subsubfolders = dir(fullfile(subfolderPath, 'H*'));
%     subsubfolders = [subsubfolders; dir(fullfile(subfolderPath, 'M*'))];
%     subsubfolders = [subsubfolders; dir(fullfile(subfolderPath, 'L*'))];
%     subsubfolders = subsubfolders([subsubfolders.isdir]); % 只保留文件夹
% 
%     % 遍历每个二级子文件夹
%     for j = 1:length(subsubfolders)
%         subsubfolderName = subsubfolders(j).name;
%         subsubfolderPath = fullfile(subfolderPath, subsubfolderName);
% 
%         % 获取二级子文件夹中的所有 .jpg 文件
%         jpgFiles = dir(fullfile(subsubfolderPath, '*.jpg'));
% 
%         % 遍历每个 .jpg 文件
%         for k = 1:length(jpgFiles)
%             fileName = jpgFiles(k).name;
% 
%             % 检查文件名是否包含 "PMCC" 或 "ruddy"
%             % if ~contains(fileName, 'PMCC') && ~contains(fileName, 'ruddy')
%                 % 构造新的文件名（在原文件名前加上一级子文件夹的名字）
%                 newFileName = strcat(subfolderName, fileName);
% 
%                 % 构造源文件路径和目标文件路径
%                 sourceFilePath = fullfile(subsubfolderPath, fileName);
%                 destFilePath = fullfile(destFolder, newFileName);
% 
%                 % 复制文件
%                 copyfile(sourceFilePath, destFilePath);
%             % end
%         end
%     end
% end
% 
% disp('文件复制完成！');
%% %移除多余的
% source_folder='D:\work\VIVOskinExpe\renderCode\rendered\33_i_lL_C_CATed\m06i';
% dest_folder=fullfile(files(i).folder,"extra");
% if ~exist(dest_folder,"dir")
%     mkdir(dest_folder);
% end
% files = dir(fullfile(source_folder,'*.jpg'));
% for i_file=1:size(files,1)
% 
%     if contains(files(i_file).name,"(1)")
%         old_path=fullfile(files(i_file).folder,files(i_file).name);
%         new_path=fullfile(dest_folder,files(i_file).name);
%         movefile(old_path,new_path);
%         disp(strcat(files(i_file).name,"moved"));
%     end
% end
%% 生成CardMask
% % % % % % % % 设置源文件夹路径
% % source_folder = 'E:\Hasselblad-lab-23model-22light\dsp\female01\i';
% source_folder='dsp\f10\i';
% slashes=find(source_folder=='\');
% lastPart=source_folder(slashes(end-1)+1:slashes(end)-1);
% % 创建目标文件夹路径
% destination_folder = fullfile('Cardmask',lastPart);
% 
% % 如果目标文件夹不存在，则创建它
% if ~exist(destination_folder, 'dir')
%     mkdir(destination_folder);
% end
% 
% % 获取源文件夹中的所有jpg文件
% jpg_files = dir(fullfile(source_folder, '*.jpg'));
% 
% % 检查是否存在JPG文件
% if isempty(jpg_files)
%     disp('没有找到JPG文件，请检查源文件夹路径。');
%     return;
% end
% 
% % 遍历每个jpg文件
% for i = 1:length(jpg_files)
%     % 读取文件
%     source_file = fullfile(source_folder, jpg_files(i).name);
%     img = imread(source_file);
% 
%     % 获取图像尺寸
%     [height, width, ~] = size(img);
% 
%     % 初始化temp_mask为黑色
%     temp_mask = zeros(height, width, 'uint8'); % 黑色为0，白色为255
% 
%     % 查找符合条件的像素
%     for y = 1:height
%         for x = 1:width
%             % 条件：第二坐标(y) > 1000 且 RGB 均小于 30
%             if y > 1000 && all(img(y, x, :) < 30)
%                 temp_mask(y, x) = 255; % 设置为白色
%             end
%         end
%     end
% 
%     % 将被白色区域包围的区域也变成白色
%     % 使用MATLAB的内置函数进行图像填充
%     filled_mask = imfill(temp_mask, 'holes');
% 
%     % 保存生成的掩码图像到目标文件夹
%     destination_file = fullfile(destination_folder, jpg_files(i).name);
%     imwrite(filled_mask, destination_file);
% 
%     disp(['已生成并保存掩码：', jpg_files(i).name]);
% end
% 
% disp('所有掩码图片已生成并保存至Cardmask文件夹M。');
%
%% CardMask
% 
% source_folder='D:\work\VIVOskinExpe\renderCode\rendered\i\adjust\drawable';
% slashes=find(source_folder=='\');
% lastPart=source_folder(slashes(end)+1:end);
% lastPart=gen_lastPart_old(lastPart);
% lastPart=char(lastPart);
% % lastPart=lower(lastPart);
% files = dir(fullfile(source_folder,'m10*.jpg'));
% % dir_mask=dir("CardMask\maleVIVO\*.jpg");
% 
% 
% save_folder=fullfile('D:\work\VIVOskinExpe\renderCode\rendered\i\adjust\drawable\drawable');
% if ~exist(save_folder, 'dir')
%     mkdir(save_folder);
% end
% 
% 
% for i = 1:numel(files)
% 
%     dir_mask=dir(fullfile("CardMask",files(i).name(1:3),"*.jpg"));
%     [~, fileName, fileExt] = fileparts(files(i).name);
%     slashes0=find(fileName=='_');
%     slashes1=find(fileName=='[');
%     slashes2=find(fileName==',');
%     slashes3=find(fileName==']');
%     % dlab(1,1)=str2double(fileName(slashes1+1:slashes2(1)-1));
%     % dlab(1,2)=str2double(fileName(slashes2(1)+1:slashes2(2)-1));
%     % dlab(1,3)=str2double(fileName(slashes2(2)+1:slashes3-1));
%     % save_dlabs{i,1}=fileName;
%     % save_dlabs{i,2}=dlab;
%     % 删除文件名中从[开始到后缀名之前的内容（包括[）
%     idx = find(fileName=='[');
%     if ~isempty(idx)
%         fileName = fileName(1:idx-1);
%     end
%     fileName=lower(fileName);
%     % 生成新的文件名
%     newFileName = [fileName, fileExt];
%     % 生成目标文件的完整路径
%     targetFile = fullfile(save_folder, newFileName);
% 
%     % if exist(targetFile, 'file') == 2
%     %     continue
%     % end
%     filename = fullfile(files(i).folder, files(i).name);
%     img0=imread(filename);
%     img=im2double(img0);
%     [m, n, p] = size(img);
%     out = reshape(img, [m * n, p]);
%     i_mask=1;
%     while (~strcmpi(files(i).name(5:slashes0-1),dir_mask(i_mask).name(1:end-4)))
%         i_mask=i_mask+1;
%     end
% 
%     bull=imread(strcat(dir_mask(i_mask).folder,'\',dir_mask(i_mask).name));
%     if ~isequal(size(bull), size(img))
%         if size(bull,1)/size(bull,2)==size(img,1)/size(img,2)
%             bull_temp=bull;
%             bull(:,:,1)=bull_temp;
%             bull(:,:,2)=bull_temp;
%             bull(:,:,3)=bull_temp;
% %             bull=imresize(bull,[size(img, 1), size(img, 2)]);
%         end
%     end
%     bull_reshaped=reshape(bull, [m * n, p])./255;
%     bull_reshaped = double(bull_reshaped);
%     logicalIndex = all(bull_reshaped == 0, 2);
% 
% 
% 
%     if any(~logicalIndex)
%         out(~logicalIndex, :)=repmat([0,0,0], sum(~logicalIndex), 1);
%     end
%     outnew = reshape(out, [m, n, p]);
%     %     imshow(outnew);
%     imwrite(outnew,targetFile);
%     % imwrite(outnew,strcat(save_folder,'\',files(i).name(1:end-4),'.jpg') );
%     currentTime = datetime('now');
%     formattedTime = datestr(currentTime, 'yyyy-mm-dd HH:MM:SS');
%     disp([files(i).name(1:end-4),'finished: ',formattedTime]);
% end
% disp("d")
% % save(fullfile(save_folder,"render_dlabs.mat"),"save_dlabs");
% % disp("done");


%%
% % % **********去[]************
% % % % % % % % % % % 定义源目录和目标目录
% sourceDir='D:\work\VIVOskinExpe\renderCode\rendered\rs\adjust\drawable';
% slashes=find(sourceDir=='\');
% lastPart=sourceDir(slashes(end)+1:end);
% lastPart=lower(lastPart);
% files = dir(fullfile(sourceDir,'*.jpg'));
% 
% % targetDir=fullfile("drawable",lastPart);
% targetDir=fullfile(sourceDir,"drawable");
% if ~exist(targetDir, 'dir')
%     mkdir(targetDir);
% end
% 
% 
% % 获取源目录下所有jpg文件的信息
% jpgFiles = dir(fullfile(sourceDir, '*.jpg'));
% 
% % 遍历每个jpg文件
% for k = 1:length(jpgFiles)
%     % % pattern = 'female5';
%     % pattern = 'indoor05';
%     % if ~contains(jpgFiles(k).name, pattern)
%     %     continue
%     % end
%     % 获取当前文件的完整路径
%     currentFile = fullfile(sourceDir, jpgFiles(k).name);
% 
%     % 获取当前文件名
%     [~, fileName, fileExt] = fileparts(jpgFiles(k).name);
% 
%     % 删除文件名打头的cropped_
%     if startsWith(fileName, 'cropped_')
%         fileName = erase(fileName, 'cropped_');
%     end
% 
%     % 删除文件名中从[开始到后缀名之前的内容（包括[）
%     idx = strfind(fileName, '[');
%     if ~isempty(idx)
%         fileName = fileName(1:idx-1);
%     end
%     % fileName=strcat(lower(lastPart),fileName);
%     % 生成新的文件名
%     newFileName = [fileName, fileExt];
% 
%     % 生成目标文件的完整路径
%     targetFile = fullfile(targetDir, newFileName);
% 
%     % 复制文件到目标目录
%     copyfile(currentFile, targetFile);
% 
%     % 打印处理信息
%     fprintf('File %s renamed and copied to %s\n', jpgFiles(k).name, newFileName);
% end
% 
% fprintf('All files have been processed.\n');