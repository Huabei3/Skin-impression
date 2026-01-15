close all; 
clc;       
clear;     
%%

%------------i--------------
source_folder='Z:\homes\Peggy\VIVOskinExpe\imageCapture\Hassel\dsp\femaleVIVO\i\CardMasked';
% source_folder='F:\Hassel\dsp\femaleVIVO\i\CardMasked';
i_type=2;
slashes = strfind(source_folder, '\');
model = source_folder(slashes(1,end-2)+1:slashes(1,end-1)-1);
iOr = source_folder(slashes(1,end-1)+1:slashes(1,end)-1);
lastPart=strcat(model,iOr);

files = dir(strcat(source_folder,'\*.jpg'));  % 读取文件夹中的所有.jpg文件

save_folder=fullfile('Z:\homes\Peggy\VIVOskinExpe\imageCapture\Hassel\rendered\fdQst',lastPart);
if ~exist(save_folder, 'dir')
    mkdir(save_folder);
end
%%
load("fdQst.mat","fdQst");

for i=1:length(fdQst)
        figure();
    hold on;
    % scatter(dlabs(:,2),dlabs(:,3));



    plot(fdQst{i,1}(:,5),fdQst{i,1}(:,6), ...
    '^', 'MarkerFaceColor', "g", ...
    'Color',"g",'MarkerSize', 5);

    plot(fdQst{i,1}(:,9),fdQst{i,1}(:,10),'^', 'MarkerFaceColor', "b", ...
    'Color',"b", 'MarkerSize', 5);
    
        plot(fdQst{i,1}(:,2),fdQst{i,1}(:,3), ...
    'p', 'MarkerFaceColor', "r", ...
    'Color',"r",'MarkerSize', 5);

    axis equal;

    min_lim=-10;
    max_lim=50;
    x=min_lim:0.1:max_lim;
    y=x;
    plot(x,y);
    
    xlim([min_lim,max_lim]);
    ylim([min_lim,max_lim]);


    title(strcat(model,iOr,files(i).name));

    saveas(gcf,fullfile(save_folder,files(i).name));

end