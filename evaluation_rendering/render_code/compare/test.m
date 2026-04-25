clc;clear;close all;
addpath("..\utils\")
%% 把同一张原图的拼接到一起
source_folder="D:\work\VIVOskinExpe\skin_model\evaluation_rendering\render_code\compare\res\pic\on_Peggy_OPPO";

% 定义需要拼接的文件夹名称列表
target_folders = {'cen_david', 'cen_cherry', 'cen_summer', 'cen_peggy','cen_peggy_OPPO','ori_img'};

% 创建保存结果的文件夹
save_folder = fullfile(source_folder, 'concatenated1');
if ~exist(save_folder, 'dir')
    mkdir(save_folder); % 如果文件夹不存在则创建
end
% 
% % 获取cen_david文件夹下的所有jpg图片
% david_folder = fullfile(source_folder, target_folders{1});
% image_list = dir(fullfile(david_folder, '*.jpg'));
% 
% % 遍历每张图片进行处理
% for i = 1:length(image_list)
%     % 获取当前图片的文件名（不含路径）
%     img_name = image_list(i).name;
% 
%     % 初始化存储图片路径的数组
%     image_files=dir(fullfile(source_folder, target_folders{1}, img_name));
% 
%     % 遍历所有目标文件夹，收集同名图片路径
%     for j = 2:length(target_folders)
%         % 拼接当前文件夹的图片完整路径
%         image_files = [image_files;dir(fullfile(source_folder, target_folders{j}, img_name))];
% 
% 
%     end
% 
%     % 调用拼接函数（n_col设置为4列，你可根据需要修改）
%     n_col = length(target_folders); % 4张图片排成4列，也可设为2列（2行2列）等
%     concatenate_images_dir(image_files, save_folder, n_col);
% 
%     fprintf('已处理并保存: %s\n', img_name);
% end
% 
% fprintf('所有图片处理完成！结果保存在: %s\n', save_folder);
%% 每个场景各选一张做例子

sampled_img=["female2makeup","indoor02","night07","outdoor03","sunset07"];
dir_con=[];
for i_sample=1:length(sampled_img)
    
    for i_folder=1:length(target_folders)
        dir_con=[dir_con;dir(fullfile(source_folder, target_folders{i_folder}, ...
            strcat(sampled_img(i_sample),".jpg")))];
    end
    
end
concatenate_dir_same_width(dir_con,save_folder,6)
%% 测试david_table有没有错位

% david_table_file=fullfile("D:\work\ZJU_entire_skin\David\Naturalness model\Jason's final project\data analysis\res\separate_skin_methods\resTable\quality\David_table.mat");
% david_table_data=load(david_table_file);
% david_table=david_table_data.fit_table;
% 
% ethnicities=["asian_skin","caucasian_skin"];
% 
% David_fitRes_folder=fullfile("D:\work\ZJU_entire_skin\David\Naturalness model\Jason's final project\data analysis\res\separate_skin_methods\quality\fitRes\ellipsoidfit4");
% 
% 
% i_count=1;
% 
% for i_eth=1:2
% 
%     David_fitRes_file=fullfile(David_fitRes_folder,strcat(ethnicities(i_eth),".mat"));
%     David_fitRes_data=load(David_fitRes_file);
%     labNscore=David_fitRes_data.labNscore;
% for i_row=1:size(labNscore,1)
%     for i_match=1:size(david_table,1)
%         source_char=david_table.source{i_match};
%         source_char=char(source_char);
%         if strcmp(labNscore{i_row,4},source_char(7:end))
%             table_points=david_table.lab_values{i_match};
%             file_points=labNscore{i_row,1};
%             diff_points=table_points-file_points;
%             diff_points_mean{i_count,1}=mean(mean(diff_points));
%             diff_points_mean{i_count,2}=labNscore{i_row,4};
%             i_count=i_count+1;
%         end
%     end
% end
% 
% end
% 
