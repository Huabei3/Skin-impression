clear;clc;close all;
%%
models{1,1}=["male92","male91","male48","female01","female04","female06"];
models{2,1}=["male59","male39","maleVIVO","female78","female41","femaleVIVO"];
models{3,1}=["male21","male46","female23","female51"];
models{4,1}=["male22","male28","female25","female69"];
%%

a_LC=[4.459300459802465,-47.488828958697376];
a_LC1=[4.222564640057191,-19.051958264342610];
figure();
hold on;
axis equal;
x = 0:0.1:30;
% y= x;
% text( 30,30,'45°', ...
%             'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right', 'FontSize', 10);
% plot(x,y);
%画拟合直线
x = 0:0.1:30;
y= a_LC(1)*x+a_LC(2);
y1= a_LC1(1)*x+a_LC1(2);

plot(x,y);
plot(x,y1);

%设置坐标
ax = gca; ax.XLim = [0 30];
ay = gca; ay.YLim = [0 90];
xlabel('C_{ab}*','FontAngle','italic');
ylabel('L*','FontAngle', 'italic');
title('L*-C_{ab}*','FontAngle', 'italic');
%%
% 检查值的计算
source_folder='D:\work\VIVOskinExpe\renderCode\rendered\33_r_L_Cnew1\femaleVIVOr';

slashes=find(source_folder=='\');
lastPart=source_folder(slashes(end)+1:end);
model=lastPart(1:end-1);
i_type= select_type(model);

files=dir(fullfile(source_folder,"*.jpg"));
dir_mask=dir(strcat("mask\",lastPart,"\*.jpg"));
a_LC=[4.459300459802465,-47.488828958697376];

wd65=[94.813  100.000  107.262];
datai_file = 'calibResults\model3d_file_350_1deg_realP3\datai_ipv40_3.mat';

LUT=load(datai_file);
XYZw_LUT=LUT.XYZw;
wd65_scaled=wd65./100.*XYZw_LUT(2);

load(fullfile("aveSkinByHand2","i",strcat("aveLab_D65_",num2str(i_type),".mat")), ...
    "labC_HD65");

average_file=strcat("aveSkinByHand2\",lastPart,"\autoNhand_scaleoverLUT.mat");
average=load(average_file);
average=average.average_lab_all(:,1:3);

num_points = readmatrix('points_added_33.xlsx'); 
num_points=[zeros(length(num_points),1),num_points];
dlabs=repmat(labC_HD65(1,1:3),length(num_points),1)+num_points;


i_check=1;
for i=1:length(files)
   imgname=files(i).name;
   slashes=find(imgname=='_');
   serial_str=imgname(slashes+1:slashes+2);
    serial=str2double(serial_str);
    slashes1=find(imgname=='[');
    slashes2=find(imgname==',');
    slashes3=find(imgname==']');
    dlab(1,1)=str2double(imgname(slashes1+1:slashes2(1)-1));
    dlab(1,2)=str2double(imgname(slashes2(1)+1:slashes2(2)-1));
    dlab(1,3)=str2double(imgname(slashes2(2)+1:slashes3-1));
    if strcmp(serial_str,"33")
        filename = fullfile(files(i).folder, files(i).name);   

        img0=imread(filename);
        img=im2double(img0);
        [m,n,p]=size(img);
        for i_mask=1:length(dir_mask)
            if strcmp(files(i).name(1:slashes-1),dir_mask(i_mask).name(1:end-4))
                picname_check{i,1}=files(i).name(1:end-4);
                picname_check{i,2}=dir_mask(i_mask).name(1:end-4);
                bull=imread(strcat(dir_mask(i_mask).folder,'\',dir_mask(i_mask).name));
                break
            end
        end
        bull_reshaped=reshape(bull, [m * n, p])./255;
        bull_reshaped = double(bull_reshaped);
        logicalIndex = all(bull_reshaped == 0, 2);
        out = reshape(img, [m * n, p]); 
        out = out * 255;
        xyz1 = lut3d_rgb2xyz1(out, datai_file);  
        [lab1] = xyz2lab(xyz1,'user',wd65_scaled);
        dest_lab(i_check,:)=mean(lab1(~logicalIndex,:));

        C_pre(i_check,1)=(dest_lab(i_check,1)-a_LC(2))./a_LC(1);
        factor=labC_HD65(1,4)./C_pre(i_check,1);
        labC_HD65_back=dest_lab(i_check,:).*factor;
        labC_HD65_back(1,1)=labC_HD65(1,1);
        labC_HD65_check{i_check,1}=files(i).name(1:end-4);
        labC_HD65_check{i_check,2}=labC_HD65_back;
        % labC_HD65_check{i_check,3}=deltaE2000(labC_HD65_back(1,1:3),labC_HD65(1,1:3));
        labC_HD65_check{i_check,3}=deltaE2000(labC_HD65_back(1,1:3),dlabs(serial,:));
        labC_HD65_check{i_check,4}=deltaE2000(dlab,dest_lab(i_check,:));
        dlabC(i_check,:)=[dlab,sqrt(dlab(1,2).^2+dlab(1,2).^3)];
        
        i_check=i_check+1;

        % if i==33
        %     disp(i);
        % end

    end
    
end

dest_labC=[dest_lab,sqrt(dest_lab(:,2).^2+dest_lab(:,2).^3)];

function i_type= select_type(model)
    models{1,1}=["male92","male91","male48","female01","female04","female06","male97"];
    models{2,1}=["male59","male39","maleVIVO","female93","female02","female41","femaleVIVO"];
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
%%

% 
% models{1,1}=["male92","male91","male48","female01","female04","female06"];
% % models{2,1}=["male59","male39","maleVIVO","female02","female41","femaleVIVO"];
% models{2,1}=["male59","maleVIVO","female41","femaleVIVO"];
% models{3,1}=["male21","male46","female23","female51"];
% models{4,1}=["male22","male28","female25","female69"];
% 
% types=["Caucasian","Oriental","South Asian","African"];
% 
% ct=["H3K","H4K","H5K","H6K","H7K","H8K","HD65",...
% "L3K","L4K","L5K","L6K","L7K","L8K","LD65",...
% "M3K","M4K","M5K","M6K","M7K","M8K","MD65"];
% 
% a_LC=[4.459300459802465,-47.488828958697376];
% 
% ave_folder="aveSkinByHand";
% ave_folder1="aveSkinByHand1";
% ave_folder2="aveSkinByHand2";
% lab_cell_all=[];picname_check_all=[];
% for i_type=2:2
%     lab_cell=[];picname_check=[];
%     for i_model=1:length(models{i_type,1})    
% 
%         file_ave=fullfile(ave_folder,strcat(models{i_type,1}(i_model),'i'),"autoNhand_scaleoverLUT.mat");
%         file_ave1=fullfile(ave_folder1,strcat(models{i_type,1}(i_model),'i'),"autoNhand_scaleoverLUT.mat");
%         file_ave2=fullfile(ave_folder2,strcat(models{i_type,1}(i_model),'i'),"autoNhand_scaleoverLUT.mat");
%         % picname_check{i_model,1}=models{i_type,1}(i_model);
%         ave_data=load(file_ave);
%         lab_data{i_model,1}=ave_data.average_lab_all;
%         ave_data=load(file_ave1);
%         lab_data1{i_model,1}=ave_data.average_lab_all;
%         ave_data=load(file_ave2);
%         lab_data2{i_model,1}=ave_data.average_lab_all;
%         dELCH1{i_model,1}=models{i_type,1}(i_model);
%         dELCH1{i_model,2}=deltaE2000(lab_data{i_model,1},lab_data1{i_model,1})';
%         [de,dl,dc,dh] = cielabde(lab_data{i_model,1},lab_data1{i_model,1});
%         dELCH1{i_model,3}=de;
%         dELCH1{i_model,4}=dl;
%         dELCH1{i_model,5}=dc;
%         dELCH1{i_model,6}=dh;
% 
%         dELCH2{i_model,1}=models{i_type,1}(i_model);
%         dELCH2{i_model,2}=deltaE2000(lab_data{i_model,1},lab_data2{i_model,1})';
%         [de,dl,dc,dh] = cielabde(lab_data{i_model,1},lab_data2{i_model,1});
%         dELCH2{i_model,3}=de;
%         dELCH2{i_model,4}=dl;
%         dELCH2{i_model,5}=dc;
%         dELCH2{i_model,6}=dh;
%     end
% end
% 
% dELCH1_mat=[];dELCH2_mat=[];
% for i_model=1:length(models{i_type,1})
%     for i_col=2:6
%         dELCH1_mat=[dELCH1_mat,dELCH1{i_model,i_col}];
%         dELCH2_mat=[dELCH2_mat,dELCH2{i_model,i_col}];
%     end
% end
%%


%%
% % 指定源文件夹和目标文件夹
% source_folder = 'Z:\homes\Peggy\VIVOskinExpe\imageCapture\20240718 哈苏相机删减整理\20240722 肤色\male39\jpg\noCard';
% % destination_folder = 'D:\work\VIVOskinExpe\renderCode\mask_findCen\female41r\新建文件夹';
% % destination_folder ='D:\work\VIVOskinExpe\renderCode\dsp\male39\r\jpg\noCard';
% destination_folder ='F:\renderCode\dsp\male39\r\jpg\noCard';
% % 确保目标文件夹存在，如果不存在则创建
% if ~exist(destination_folder, 'dir')
%     mkdir(destination_folder);
% end
% 
% % 获取源文件夹中的所有 .jpg 文件
% jpg_files = dir(fullfile(source_folder, '*.jpg'));
% 
% % 遍历每个 .jpg 文件
% for i = 1:length(jpg_files)
%     % 读取图像
%     img_path = fullfile(jpg_files(i).folder, jpg_files(i).name);
%     img = imread(img_path);
%     img=imrotate(iH3Kmg,90);
%     % 调整图像尺寸
%     resized_img = imresize(img, [2914, 2185]);
% 
%     % 构建目标文件路径
%     [~, name, ext] = fileparts(jpg_files(i).name);
%     destination_path = fullfile(destination_folder, [name, ext]);
% 
%     % 保存调整后的图像到目标文件夹
%     imwrite(resized_img, destination_path);
% 
%     % 显示进度
%     fprintf('Processed and saved %s\n', jpg_files(i).name);
% end
% 
% fprintf('All images have been processed and saved.\n');
%%
% %去【】
% % % 定义源目录和目标目录
% sourceDir = ['D:\work\VIVOskinExpe\renderCode\rendered\33_r_L_Cnew\femaleVIVOr']; 
% targetDir = ['D:\work\VIVOskinExpe\app_pics\femaleVIVOr']; 
% 
% % sourceDir = ['Z:\homes\Peggy\oppoSkinExperi\picked40\Hassel\downSampled1\' ...
% %     'cropped\renderedAdd\renderedAdd07']; 
% % targetDir = ['Z:\homes\Peggy\oppoSkinExperi\picked40\Hassel\downSampled1\' ...
% %     'cropped\renderedAdd\renderedAdd07\drawable']; 
% 
% 
% % 检查目标目录是否存在，如果不存在则创建
% if ~exist(targetDir, 'dir')
%     mkdir(targetDir);
% end
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
% 
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


%%
% % 指定文件夹路径
% folder = 'D:\work\VIVOskinExpe\app_pics\L';
% dest_folder='D:\work\VIVOskinExpe\app_pics\L\lower';
% % 获取文件夹中的所有jpg文件
% jpgFiles = dir(fullfile(folder, '*.jpg'));
% 
% % 遍历所有jpg文件
% for i = 1:length(jpgFiles)
%     % 获取旧文件名
%     oldFileName = jpgFiles(i).name;
% 
%     % 将文件名中的大写字母转换为小写字母
%     newFileName = lower(oldFileName);
% 
%     % 构造旧文件的完整路径
%     oldFilePath = fullfile(folder, oldFileName);
% 
%     % 构造新文件的完整路径
%     newFilePath = fullfile(dest_folder, newFileName);
% 
%     % 重命名文件
%     if exist(oldFilePath, 'file')
%         movefile(oldFilePath, newFilePath);
%         fprintf('Renamed: %s to %s\n', oldFileName, newFileName);
%     else
%         fprintf('File not found: %s\n', oldFileName);
%     end
% end
%%
% % % 指定源文件夹和目标文件夹路径
% sourceFolder = 'F:\drawable\maleVIVO';
% destinationFolder = 'D:\work\VIVOskinExpe\app_pics\M';
% 
% % 获取源文件夹的名字
% [~, folderName, ~] = fileparts(sourceFolder);
% 
% % 获取源文件夹中的所有jpg文件
% jpgFiles = dir(fullfile(sourceFolder, 'm*.jpg'));
% 
% % 遍历所有jpg文件
% for i = 1:length(jpgFiles)
%     % 获取旧文件名
%     oldFileName = jpgFiles(i).name;
% 
%     % 构造新文件名
%     newFileName = [lower(folderName),  oldFileName];
% 
%     % 构造旧文件的完整路径
%     oldFilePath = fullfile(sourceFolder, oldFileName);
% 
%     % 构造新文件的完整路径
%     newFilePath = fullfile(destinationFolder, newFileName);
% 
%     % 复制文件
%     if exist(oldFilePath, 'file')
%         copyfile(oldFilePath, newFilePath);
%         fprintf('Copied: %s to %s\n', oldFileName, newFileName);
%     else
%         fprintf('File not found: %s\n', oldFileName);
%     end
% end
%%
% 指定文件夹路径
% folder = 'D:\work\VIVOskinExpe\drawable\femaleVIVO\hd65';
% 
% % 获取文件夹中的所有jpg文件
% jpgFiles = dir(fullfile(folder, '*.jpg'));
% 
% % 遍历所有jpg文件
% for i = 1:length(jpgFiles)
%     % 获取旧文件名
%     oldFileName = jpgFiles(i).name;
% 
%     % 构造新文件名
%     [~, name, ext] = fileparts(oldFileName);
%     newFileName = ['female', name, ext];
% 
%     % 构造旧文件的完整路径
%     oldFilePath = fullfile(folder, oldFileName);
% 
%     % 构造新文件的完整路径
%     newFilePath = fullfile(folder, newFileName);
% 
%     % 重命名文件
%     if exist(oldFilePath, 'file')
%         movefile(oldFilePath, newFilePath);
%         fprintf('Renamed: %s to %s\n', oldFileName, newFileName);
%     else
%         fprintf('File not found: %s\n', oldFileName);
%     end
% end