clc;clear;close all;
%% 生成dlabsNpicname
source_folder='D:\work\VIVOskinExpe\renderCode\rendered\rs\adjust_ch_bg\m10r';
slashes=find(source_folder=='\');
lastPart=source_folder(slashes(end)+1:end);
lastPart=gen_lastPart_new(lastPart);
lastPart=lower(lastPart);
files = dir(fullfile(source_folder,'*.jpg'));
save_folder=fullfile('dlabsNpicname');
if ~exist(save_folder, 'dir')
    mkdir(save_folder);
end

for i = 1:numel(files)


    [~, fileName, fileExt] = fileparts(files(i).name);
    slashes1=find(fileName=='[');
    slashes2=find(fileName==',');
    slashes3=find(fileName==']');
    dlab(1,1)=str2double(fileName(slashes1+1:slashes2(1)-1));
    dlab(1,2)=str2double(fileName(slashes2(1)+1:slashes2(2)-1));
    dlab(1,3)=str2double(fileName(slashes2(2)+1:slashes3-1));
    
    fileName_short=fileName(1:slashes1-1);    
    fileName_short=strcat(lastPart,fileName_short);
    fileName_short=lower(fileName_short);

    dlabsNpicname{i,1}=dlab;
    dlabsNpicname{i,2}=fileName_short;
    
end
if contains(source_folder(slashes(end-1)+1:slashes(end)-1),"add")
    lastPart1=strcat(lastPart,"add");
else
    lastPart1=lastPart;
end
save(fullfile(save_folder,strcat(lastPart1,".mat")),"dlabsNpicname");

disp("d")