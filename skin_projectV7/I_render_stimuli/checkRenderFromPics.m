% close all; % 关闭所有图窗
% clc;       % 清空命令窗口
% clear;     % 清除工作区所有变量
addpath("utils\");
%% 对于
% % % %-----------i----------
% % % 
% source_folder='..\skin_projectV2\evaluation_rendering\render_code\rendered\LUT\non_model\100\drawable';
% 
% files=dir(fullfile(source_folder,"*.jpg"));
% 
% wd65=[94.813  100.000  107.262];
% 
% save_folder=fullfile("rendered\33_i_wei\LUT\summer\non_model\100");
% if ~exist(save_folder,"dir")
%     mkdir(save_folder);
% end
% 
% average_rgb_all=[];average_xyz_all=[];average_lab_all=[];average_lab1_all=[];
% de_all=[];de00_all=[];de00c_all=[];
% XYZ_all=[];XYZw_all=[];
% dlabTheo=load("rendered\33_i_wei\LUT\summer\non_model\100\theo_dlab100.mat");
% dlabTheo=dlabTheo.dlab_theo;
% i_the=1;
% rows_to_delete = [];
% % for i = 1:numel(files)
% %     if ~contains(files(i).name,"f06")
% %         rows_to_delete=[rows_to_delete;i];
% %     end
% % end
% files(rows_to_delete) = [];
% for i = 1:numel(files)
% 
% 
%     img=imread(fullfile(files(i).folder, files(i).name));
%     ind_i=find(files(i).name=='i');
%     lastPart=files(i).name(1:ind_i);
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
%             bracket=find(files(i).name=='[');
%             if strcmpi(files(i).name(1:bracket-1),strrep(name,".JPG",""))
%                 dlab_theo=dlabTheo{i_the,2};
%                 break  
%             end
%         end
%         dE_cell{i,1}=files(i).name;
%         dE_cell{i,2}=average_lab;
%         dE_cell{i,3}=dlab_theo;
% 
%         dE_cell{i,4}=deltaE2000(dlab_theo,average_lab);
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
% save(fullfile(save_folder,'checkLabFromPics_AS.mat'), ...
% "dE_cell");
% mean(cell2mat(dE_cell(:,4)))
% disp("done");
% 
% dE_cell_big=[];
% for i_dE=1:length(dE_cell)
%     if ~isempty(dE_cell{i_dE,4})
%         if ~(dE_cell{i_dE,4}<1)
%             dE_cell_big=[dE_cell_big;dE_cell(i_dE,:)];
%         end
%     end
% end
% 
% save(fullfile(save_folder,'checkLabFromPics_AS.mat'), ...
%     "dE_cell","dE_cell_big");
% disp("d")
%% 针对90和100
% %---------------------
% 

target_score="100";
source_folder=['F:\VIVOskinExpe\skin_projectV4\evaluation_rendering\render_code\rendered\LUT\non_model\100\drawable\r'];
slashes = strfind(source_folder, '\');
files = dir(strcat(source_folder,'\*.jpg'));  % 读取文件夹中的所有.jpg文件
% subfolders=dir(fullfile(source_folder,'f*'));
% subfolders=[subfolders;dir(fullfile(source_folder,'m*'))];
% files=[];
% for i_sub=1:length(subfolders)
%     sub_path=fullfile(subfolders(i_sub).folder,subfolders(i_sub).name);
%     level3_folders=dir(fullfile(sub_path,'H*'));
%     level3_folders=[level3_folders;dir(fullfile(sub_path,'L*'))];
%     level3_folders=[level3_folders;dir(fullfile(sub_path,'M*'))];
% 
%     for i_level3=1:length(level3_folders)
%         files=[files;dir(fullfile(level3_folders(i_level3).folder, ...
%             level3_folders(i_level3).name,"*.jpg"))];
%     end
% end


wd65=[94.813  100.000  107.262];

save_folder=fullfile(source_folder,'check_lab_fromPics');
if ~exist(save_folder,"dir")
    mkdir(save_folder);
end
% A=load(fullfile(save_folder,'checkLabFromPics.mat'), ...
% "delch","big_cell","big1_cell","dE_cell");
% average_rgb_all=[];average_xyz_all=[];average_lab_all=[];average_lab1_all=[];
% de_all=[];de00_all=[];de00c_all=[];
% XYZ_all=[];XYZw_all=[];

dlabTheo=load("D:\work\VIVOskinExpe\skin_projectV4\evaluation_rendering\" + ...
    "render_code\rendered\LUT\non_model\100\rtheo_dlab100.mat");
dlabTheo=dlabTheo.dlab_theo;
move_file=[];
for i = 1:numel(files) 

    lastPart=files(i).name(1:4);
    slash=find(files(i).folder=='\');
    % lastPart=files(i).folder(slash(end-1)+1:slash(end)-1);


    if ismember(strrep(lastPart,"add",""),["f04i","f05i","f06i","m04i","m06i"]) 
        if_wei=0;
    else
        if_wei=1;
    end
    img=imread(fullfile(files(i).folder, files(i).name));
    % 解析文件名中的 dlab 值
    slashes0 = find(files(i).name == '_');
    slashes1 = find(files(i).name == '[');
    slashes2 = find(files(i).name == ',');
    slashes3 = find(files(i).name == ']');
    light_name=files(i).name(1:slashes0-1);
    dlab(i,1) = str2double(files(i).name(slashes1+1:slashes2(1)-1));
    dlab(i,2) = str2double(files(i).name(slashes2(1)+1:slashes2(2)-1));
    dlab(i,3) = str2double(files(i).name(slashes2(2)+1:slashes3-1));

    dir_mask=dir(fullfile("mask",lastPart,"*.jpg"));
    % dir_mask=dir(fullfile("Shadow\mask",lastPart,"nosd\*.jpg"));
    [m, n, p] = size(img);
    flag=0;
    for i_mask=1:length(dir_mask)
        if contains(files(i).name(1:end-4),dir_mask(i_mask).name(1:end-4))
            disp([files(i).name(1:end-4),dir_mask(i_mask).name(1:end-4)]);
            bull=imread(strcat(dir_mask(i_mask).folder,'\',dir_mask(i_mask).name));
            % bull = imresize(bull, [size(bull,1)./6, size(bull,2)./6]);%先跑小图看问题
            flag=1;
            break
        end
    end
    if flag==1

        [logicalIndex,bull_weight]=read_bull(bull,if_wei);
        img=im2double(img);
        out=reshape(img, [m * n, p]);
        out = out * 255;

        datai_file = 'calibResults\datai_ipv35_3.mat';
        xyz = lut3d_rgb2xyz1(out, datai_file);     

        LUT=load(datai_file);
        XYZw_LUT=LUT.XYZw;
        wd65_scaled=wd65./100.*XYZw_LUT(2);

        [lab] = xyz2lab(xyz,'user',wd65_scaled);
        %test

        % lab_face=lab(~logicalIndex, :);
        % average_lab=mean(lab(~logicalIndex, :));
        average_lab=get_average(lab,bull,if_wei);

        dlab_theo=NaN;
        for i_theo=1:length(dlabTheo)
            if target_score=="100"
                curr_filename=files(i).name(1:slashes1-1);
                % curr_filename=strcat(lastPart,files(i).name(1:slashes1-3));
            elseif target_score=="90"
                curr_filename=files(i).name(1:slashes1-1);
                % curr_filename=strcat(lastPart,files(i).name(1:slashes1-1));
            end
            
            if strcmpi(curr_filename,dlabTheo{i_theo,1})
                dlab_theo=dlabTheo{i_theo,2};
                break  
            end
        end
        if dlab(i,1)-dlab_theo(1)>0.01
            move_file=[move_file,dir(fullfile(files(i).folder,files(i).name))];
        end
        dE_cell{i,1}=strcat(lastPart,files(i).name);
        dE_cell{i,2}=average_lab;
        dE_cell{i,3}=dlab_theo;
        dE_cell{i,4}=deltaE2000(dlab(i,:),average_lab);  
        if ~isnan(dlab_theo)
            dE_cell{i,5}=deltaE2000(dlab_theo,average_lab);
            dE_cell{i,6}=deltaE2000(dlab_theo,dlab(i,:));
            [delch1(i,1),delch1(i,2),delch1(i,3),delch1(i,4)]=...
                cielabde(dlab(i,:),average_lab);
            [delch2(i,1),delch2(i,2),delch2(i,3),delch2(i,4)]=...
                cielabde(dlab_theo,average_lab);
            [delch3(i,1),delch3(i,2),delch3(i,3),delch3(i,4)]=...
                cielabde(dlab_theo,dlab(i,:));
            dE_cell{i,7}= delch1(i,:);       
            dE_cell{i,8}=delch2(i,:);
            dE_cell{i,9}=delch3(i,:);
            dE_cell{i,10}=dlabTheo{i_theo,1};
            disp(delch2(i,:))
        end

%-----画mask区域肤色预览图-----------
        for i_out=1:length(out)
            if logicalIndex(i_out)==1
                out(i_out,:)=[0,0,0];
            end
        end

        imshow(reshape(out,[m,n,p])./255);
        output_folder=fullfile(save_folder,"cropped_area_skin");
        if ~exist(output_folder,"dir")
            mkdir(output_folder);
        end
        if mod(i,33)==0
            imwrite(reshape(out,[m,n,p])./255, ...
                fullfile(output_folder,files(i).name));
        end

    end


end
%%
% Get current timestamp
timestamp = datetime('now', 'Format', 'yyyyMMdd_HHmmss');
timestampStr = string(timestamp); % Convert datetime to string

% Construct the base filename with the timestamp
base_filename = sprintf('checkLabFromPics_90_%s.mat', timestampStr);

save(fullfile(save_folder,base_filename),"dE_cell");
disp("done");

for i_move=1:length(move_file)
    old_file=fullfile(move_file(i_move).folder,move_file(i_move).name);
    new_path=strrep(move_file(i_move).folder,"90","90_moved");
    if ~exist(new_path,"dir")
        mkdir(new_path);
    end
    new_file=fullfile(new_path,move_file(i_move).name);
    if exist(old_file,"file")
        movefile(old_file,new_file);
    end
end

dE_cell_big=[];
for i_dE=1:length(dE_cell)
    for i_col=4:6
        if isempty(dE_cell{i_dE,i_col})
            dE_cell{i_dE,i_col}=5;
        end
    end
    if ~(dE_cell{i_dE,4}<1&&dE_cell{i_dE,5}<1&&dE_cell{i_dE,6}<1)
        dE_cell_big=[dE_cell_big;dE_cell(i_dE,:)];
    end
end

dE_cell_big_calNv=[];
for i_dE=1:length(dE_cell)
    if ~(dE_cell{i_dE,5}<1)
        dE_cell_big_calNv=[dE_cell_big_calNv;dE_cell(i_dE,:)];
    end
end

% Construct the final filename with the timestamp for the second save
final_filename = sprintf('checkLabFromPics_90_%s.mat', timestampStr);
save(fullfile(save_folder,final_filename), ...
    "dE_cell","dE_cell_big","dE_cell_big_calNv");
%% 把合规的复制到另一个文件夹
% dest_folder=fullfile(source_folder,"noQst1");
% if ~exist(dest_folder,'dir')
%     mkdir(dest_folder);
% end
% for i_dE=1:length(dE_cell)
%     if dE_cell{i_dE,4}<1&&dE_cell{i_dE,5}<1&&dE_cell{i_dE,6}<1
%         old_path=fullfile(source_folder,dE_cell{i_dE,1});
%         new_path=fullfile(dest_folder,dE_cell{i_dE,1});
%         copyfile(old_path,new_path);
%     end
% end

%% 复制并重命名对的文件

% dest_folder=fullfile(source_folder,"renamed_oriMask");
% if ~exist(dest_folder,'dir')
%     mkdir(dest_folder);
% end
% 
% for i_dE=1:length(dE_cell)
%     if dE_cell{i_dE,5}<1
%         digit_str=sprintf("[%.3f,%.3f,%.3f]", ...
%             dE_cell{i_dE,3}(1,1),dE_cell{i_dE,3}(1,2),dE_cell{i_dE,3}(1,3));
%         name_dE=dE_cell{i_dE,1};
%         name_dE=char(name_dE);
%         slashes1 = find(name_dE == '[');
%         name_new=strcat(name_dE(1:slashes1-1),digit_str,".jpg");
% 
%         old_path=fullfile(source_folder,dE_cell{i_dE,1});
%         new_path=fullfile(dest_folder,name_new);
%         copyfile(old_path,new_path);
%     end
% end
%% 找漏掉的
% for i_dE=1:length(dE_cell)
%     name_dE=dE_cell{i_dE,1};
%     name_dE=char(name_dE);
%     slashes1 = find(name_dE == '[');
%     prefix=name_dE(1:slashes1-1);
%     for i_serial=1:4
%         dir_prefix=dir(fullfile(source_folder, ...
%             sprintf("%s%02d*.jpg", prefix,i_serial)));
%         if isempty(dir_prefix)
%             missing_prefixes{end+1} = missing_prefix;
%         end
%     end
% 
% end
%% 漏掉的点

% % 初始化
% prefix_map = containers.Map(); % 用于存储每个 prefix 对应的编号
% missing_prefixes = {}; % 用于存储缺失的 prefix
% 
% % 遍历每一行
% for i = 1:size(dE_cell, 1)
%     filename = dE_cell{i, 1}; % 获取文件名
%     prefix_end = strfind(filename, '[') - 3; % 找到 '[' 的位置并减去 3
%     prefix = filename(1:prefix_end); % 提取 prefix
%     number = str2double(filename(prefix_end+1:prefix_end+2)); % 提取编号
% 
%     % 将 prefix 和编号存入 map
%     if ~isKey(prefix_map, prefix)
%         prefix_map(prefix) = [];
%     end
%     prefix_map(prefix) = [prefix_map(prefix), number];
% end
% 
% % 检查每个 prefix 是否包含 1 到 4 的编号
% prefixes = keys(prefix_map);
% for i = 1:length(prefixes)
%     prefix = prefixes{i};
%     numbers = prefix_map(prefix);
%     missing_numbers = setdiff(1:4, numbers); % 找出缺失的编号
% 
%     % 如果有缺失的编号，记录到 missing_prefixes
%     if ~isempty(missing_numbers)
%         for j = 1:length(missing_numbers)
%             missing_prefix = sprintf('%s%02d', prefix, missing_numbers(j));
%             missing_prefixes{end+1} = missing_prefix;
%             % for i_dE=1:length(dE_fr_cen)
%             % 
%             %     if strcmp(missing_prefix,dE_fr_cen{i_dE,1}(1:end-4))
%             %         disp(missing_prefix,dE_fr_cen{i_dE,1}(1:end-4))
%             %         digit_str=sprintf("[%.3f,%.3f,%.3f]", ...
%             %             dE_fr_cen{i_dE,2}(1,1),dE_fr_cen{i_dE,2}(1,2), ...
%             %                 dE_fr_cen{i_dE,2}(1,3));
%             %         dE_cell_big_calNv{end+1,1}=strcat(missing_prefix,digit_str,".jpg");
%             %         dE_cell_big_calNv{end+1,3}=dE_fr_cen{i_dE,2};
%             %         break
%             %     end   
%             % end
%         end
%     end
% end
% % save(fullfile(save_folder,'checkLabFromPics1_oriMask.mat'), ...
% %     "dE_cell","dE_cell_big","dE_cell_big_calNv_miss");
%% 计算dE_big_simp
% source_folder='D:\work\VIVOskinExpe\renderCode\rendered\toVIVO\90';
% save_folder=fullfile(source_folder,'check_lab','fromPics');
% if ~exist(save_folder,"dir")
%     mkdir(save_folder);
% end
% 
% load("rendered\toVIVO\90\check_lab\fromPics\checkLabFromPics.mat");
% dE_fr_cen=load("rendered\33_i_wei\PNp\90\summer\dEFromCen\dE_fr_cen.mat");
% dE_fr_cen=dE_fr_cen.dE_fr_cen;
% dE_fr_cen_simp=load("rendered\33_i_wei\PNp\90\summer\dEFromCen\dE_fr_cen_simp1.mat");
% dE_fr_cen_simp=dE_fr_cen_simp.dE_fr_cen;
% 
% 
% for i_dE=1:length(dE_cell)
% 
%     cell_name=dE_cell{i_dE,1};
%     slashes=find(cell_name=='[');
%     cell_prefix=cell_name(1:slashes-1);
%     if_find=0;
%     for i_simp=1:length(dE_fr_cen_simp)
%         simp_name=dE_fr_cen_simp{i_simp,1};
%         simp_name=char(simp_name);
%         simp_prefix=simp_name(1:end-4);
%         dlab_theo=dE_fr_cen_simp{i_dE,3};
%         if strcmp(simp_prefix,cell_prefix)
%             dlab_theo=dE_fr_cen_simp{i_dE,2};
%             if_find=1;
%             break
%         end  
%     end
%     if if_find
%         file_name=dE_cell{i_dE,1};
%         slashes1 = find(file_name == '[');
%         slashes2 = find(file_name == ',');
%         slashes3 = find(file_name == ']');
%         dlab(1,1) = str2double(file_name(slashes1+1:slashes2(1)-1));
%         dlab(1,2) = str2double(file_name(slashes2(1)+1:slashes2(2)-1));
%         dlab(1,3) = str2double(file_name(slashes2(2)+1:slashes3-1));
% 
%         dE_cell_simp{i_dE,1}=file_name;
%         dE_cell_simp{i_dE,2}=dE_cell{i_dE,2};
%         dE_cell_simp{i_dE,3}=dlab_theo;
% 
%         dE_cell_simp{i_dE,4}=dE_cell{i_dE,4};
%         dE_cell_simp{i_dE,5}=deltaE2000(dlab_theo,dE_cell{i_dE,2});
%         dE_cell_simp{i_dE,6}=deltaE2000(dlab_theo,dlab);
% 
%         [delch2(1,1),delch2(1,2),delch2(1,3),delch2(1,4)]=...
%             cielabde(dlab_theo,dE_cell{i_dE,2});
%         [delch3(1,1),delch3(1,2),delch3(1,3),delch3(1,4)]=...
%             cielabde(dlab_theo,dlab);
%         dE_cell_simp{i_dE,7}=dE_cell{i_dE,7};
%         dE_cell_simp{i_dE,8}=delch2;
%         dE_cell_simp{i_dE,9}=delch3;
% 
%         dE_theo{i_dE,1}=deltaE2000(dE_cell{i_dE,3},dE_cell_simp{i_dE,3});
%         dE_theo{i_dE,2}=dE_cell{i_dE,3};
%         dE_theo{i_dE,3}=dE_cell_simp{i_dE,3};
%     end
% end
% 
% 
% dE_cell_big_simp=[];
% for i_dE=1:length(dE_cell_simp)
%     if ~(dE_cell_simp{i_dE,4}<1&&dE_cell_simp{i_dE,5}<1&&dE_cell_simp{i_dE,6}<1)
%         dE_cell_big_simp=[dE_cell_big_simp;dE_cell_simp(i_dE,:)];
%     end
% end
% save(fullfile(save_folder,'checkLabFromPics_simp1.mat'), ...
%     "dE_cell_simp","dE_cell_big_simp");
% mean(cell2mat(dE_theo(:,1)))
%%
% for i_dE=1:length(dE_cell)
%     dE_cell{i_dE,7}=dE_cell{i_dE,7}(end,:);
%     dE_cell{i_dE,8}=dE_cell{i_dE,8}(end,:);
%     dE_cell{i_dE,9}=dE_cell{i_dE,9}(end,:);
% end

% %% 对于实验图
% % % % %-----------i----------
% % % % 
% source_folder='I:\work\VIVOskinExpe\renderCode\rendered\i\adjust\drawable';
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
% dlabTheo=load("I:\work\VIVOskinExpe\renderCode\rendered\i\adjust\dlab_theo_i_CA_SA_AF_m0203.mat");
% dlabTheo=dlabTheo.dlab_theo;
% i_the=1;
% % for i = 2463 :-1:1
% for i = numel(files) :-1:1
%     if ~ismember(files(i).name(1:4),["m02i","m03i"])
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
%     if ismember(lastPart,["f01i","f02i","f03i"]) 
%         continue
%     end
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
% save(fullfile(save_folder,'checkLabFromPics_CA_SA_AF_m0203.mat'), ...
% "dE_cell");
% mean(cell2mat(dE_cell(:,5)))
% disp("done");
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
% save(fullfile(save_folder,'checkLabFromPics_CA_SA_AF_m0203.mat'), ...
%     "dE_cell","dE_cell_big","dE_cell_big_calNv");
%%
dE_cell_big_dNt=[];
for i_dE=1:length(dE_cell)
    if ~isempty(dE_cell{i_dE,4})
        if dE_cell{i_dE,4}<dE_cell{i_dE,6}
            dE_cell_big_dNt=[dE_cell_big_dNt;dE_cell(i_dE,:)];
        end
    end
end
%%
dE_cell_big15=[];
for i_dE=1:length(dE_cell)
    if ~isempty(dE_cell{i_dE,4})
        if ~(dE_cell{i_dE,4}<1.5&&dE_cell{i_dE,5}<1.5&&dE_cell{i_dE,6}<1.5)
            dE_cell_big15=[dE_cell_big15;dE_cell(i_dE,:)];
        end
    end
end
dE_cell_big2=[];
for i_dE=1:length(dE_cell)
    if ~isempty(dE_cell{i_dE,4})
        if ~(dE_cell{i_dE,4}<2&&dE_cell{i_dE,5}<2&&dE_cell{i_dE,6}<2)
            dE_cell_big2=[dE_cell_big2;dE_cell(i_dE,:)];
        end
    end
end
%% 单独渲染色差大的
% load(fullfile(save_folder,'checkLabFromPicsCau.mat'), ...
%     "dE_cell","dE_cell_big","dE_cell_big_calNv");


%%
% isRowEmpty = all(cellfun(@isempty, dE_cell), 2);
% dE_cell = dE_cell(~isRowEmpty, :);
%%
% figure;
% hold on;
% scatter(ave_big(34:66, 2), ave_big(34:66, 3),20,'filled', 'r');
% scatter(dlab_big(34:66,2),dlab_big(34:66,3),8, 'filled', 'b');
% % scatter(ave_big(1:33, 2), ave_big(1:33, 3),20,'filled', 'r');
% % scatter(dlab_big(1:33,2),dlab_big(1:33,3),8, 'filled', 'b');
% xlabel('dlab(1,2)');
% ylabel('dlab(1,3)');
% 
% 
% max_lim=max(max(dlab_big(:,1),max(dlab_big(:,2))))+5;
% min_lim=min(min(dlab_big(:,1),min(dlab_big(:,2))))-5;
% axis equal;
% xlim([min_lim,max_lim]);
% ylim([min_lim,max_lim]);
% axis equal;
% grid on;
%%
% load("D:\work\VIVOskinExpe\renderCode\check_lab\1227\female78r\checkLabFromPics.mat");
% datafile = 'calibResults\model3d_file_350_1deg_realP3\data_ipv40_3.mat';
% datai_file = 'calibResults\model3d_file_350_1deg_realP3\datai_ipv40_3.mat';  
% wd65=[94.813  100.000  107.262];
% LUT=load(datai_file);
% XYZw_LUT=LUT.XYZw;
% wd65_scaled=wd65./100.*XYZw_LUT(2);
% 
% 
% xyz_1=lab2xyz2(dlab,'user',wd65_scaled);
% 
% RGB_1=lut3d_xyz2rgbNoPar(xyz_1, datafile);
% xyz_2=lut3d_rgb2xyz1(RGB_1, datai_file); 
% [lab_2] = xyz2lab(xyz_2,'user',wd65_scaled);
% [delch_12(:,1),delch_12(:,2),delch_12(:,3),delch_12(:,4)] = cielabde(dlab,lab_2);
% 
% big_12=find(delch_12(:,1)>2);
