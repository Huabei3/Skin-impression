clc;clear;close all;
%%
%%各人种模特原图平均肤色
% lastParts = {'f04i', 'f05i', 'f06i', 'm04i', 'm05i', 'm06i',...
% 'f01i', 'f02i', 'f03i', 'm01i', 'm02i', 'm03i',...
% 'f07i', 'f08i','m07i', 'm08i',...
% 'f09i', 'f10i','m09i', 'm10i'};n_para = 21;iOr='i';
%-------------rs----------------

lastParts = {'f04r', 'f05r', 'f06r', 'm04r', 'm05r', 'm06r',...
'f01r', 'f02r', 'f03r', 'm01r', 'm02r', 'm03r',...
'f07r', 'f08r','m07r', 'm08r',...
'f09r', 'f10r','m09r', 'm10r'};n_para = 14;iOr='r';
if iOr =='i'
    picnames_groups = ["h3k","h4k","h5k","h6k","hd65","h7k","h8k",...
                    "m3k","m4k","m5k","m6k","md65","m7k","m8k",...
                     "l3k","l4k","l5k","l6k","ld65","l7k","l8k"];
    load('optimizedD\neutral_gray\combi_XYZw_i.mat', 'XYZ_combi',"CCT_combi");
    CT = CCT_combi;
    XYZwpre=XYZ_combi;
elseif iOr=='r'
    picnames_groups = ["rs01","rs02","rs03","rs04","rs05","rs06","rs07", ...
             "rs08","rs09","rs10","rs11","rs12","rs13","rs14"];
    picnames_groups1=["1负一楼商场" ,"2负一楼vivo" ,"3下沉广场", "4学校饭堂" ,"5学校小卖部",...
    "6学校星巴克", "7草地顺光" ,"8草地侧光", "9草地逆光", "10阴天场景" ,...
    "11夕阳草地逆光", "12夕阳草地侧光", "13夜景小卖部门口", "14 极夜小卖部对面"];

end


if iOr == 'i'
    indices_target = [5,12,19];
else
    indices_target = 1:14;    
end


load(fullfile("documents",iOr,"render_data2.mat"),"render_map");
Keys = keys(render_map);
gray_folder="optimizedD\backGroundGray";
ave_CCT=nan(20,3,1);
order=[1,2,3,4,7,5,6,...
    15,16,17,18,21,19,20,...
    8,9,10,11,14,12,13];
for i_lastPart = 1:length(lastParts)
    lastPart = lastParts{i_lastPart};
    gray_file=fullfile(gray_folder,strcat(lastPart,".mat"));
    clear("xyz_gray");
    load(gray_file,"xyz_gray");
    if strcmp(iOr,"i")
        xyz_gray=xyz_gray(order,:);
    end
    ave_gray(i_lastPart,:,:)=xyz_gray;
    for i_para=indices_target

        curr_cell=render_map(strcat(lastPart,picnames_groups(i_para)));
        ave_CCT(i_lastPart,i_para,:)=curr_cell.CCT_val;
        ave(i_lastPart,i_para,:)=curr_cell.average;
        ave_scaled(i_lastPart,i_para,:)=curr_cell.ave_scaled_val;
        ave_aft(i_lastPart,i_para,:)=curr_cell.average_aft_val;
    end

end

ave_mean=squeeze(mean(ave(1:6,:,:),1,"omitnan"));
ave_scaled_mean=squeeze(mean(ave_scaled(1:6,:,:),1,"omitnan"));
ave_aft_mean=squeeze(mean(ave_aft(1:6,:,:),1,"omitnan"));
scene_results(:,1)=mean(ave_CCT,1,"omitnan")';
scene_results(:,2)=mean(ave_gray(:,:,2),1,"omitnan")';
% save(fullfile("documents",iOr,"ave_CCT_N_XYZgray.mat"),"ave_CCT","ave_gray");
disp("d")
