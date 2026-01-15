function [actualwhite,rgbnew,ccT,duv,bull,bull1,ratio,lab,outxyz,center0,center1]=AWBrendering1_fcsq(img,i,spq,w,dlab,option,square_lab)
% center0是原图的肤色中心，center1为渲染后的中心
% 用于改变目标中心，实现渲染功能
% white65=[95.04,100,108.89];
white65=[94.813  100.000  107.262];
rgbnew=zeros(size(img));
[m,n,~]=size(img);
% dir_pointsfiles=dir("Z:\homes\Peggy\oppoSkinExperi\picked40\iphone\cropped\setPoints\setPoints\*.mat");
% load(strcat(dir_pointsfiles(i).folder,"\",dir_pointsfiles(i).name));
% ellipse=[center0(1),center0(2),center0(3),0.021918043,0.114852178,0.047455333,-0.057891224,2.083585086];
mode=3;
switch mode
    case 1
        string='caucasian';
        ellipse=[64.8,19.5,19.5,0.020667578,0.127532583,0.047573365,-0.055680769,2.396801573];
    case 2
        string='brown';
        ellipse=[57,18,18.7,0.018735974,0.120533937,0.043763641,-0.064045284,1.917478005];
    case 3
        string='chinese';
        ellipse=[62.6,18.8,19.50,0.021918043,0.114852178,0.047455333,-0.057891224,2.083585086];
    case 4
        string='sky';
        ellipse=[54.5,-1.3,-37,0.02,0.12,0.05,-0.064045284,2.4];
    case 5
        string='grass';
        ellipse=[47.5,-25.7,27.6,0.018735974,0.120533937,0.043763641,-0.064045284,2]; 
    case 6
        string='black';
        ellipse=[41.4,17.3,17.2,0.013829993,0.094652341,0.046905515,-0.057624519,1.288093013];
    case 7
        string='newpmcc';
        ellipse=[54.61,16.42,18.12,0.021918043,0.114852178,0.047455333,-0.057891224,2.083585086];
end
%caucasian=[64.8,19.5,19.5,0.020667578,0.127532583,0.047573365,-0.055680769,2.396801573];%PMCC肤色中心
%black=[41.4,17.3,17.2,0.013829993,0.094652341,0.046905515,-0.057624519,1.288093013];
%brown=[57,18,18.7,0.018735974,0.120533937,0.043763641,-0.064045284,1.917478005];
%chinese=[62.6,18.8,19.50,0.021918043,0.114852178,0.047455333,-0.057891224,2.083585086];
%sky=[54.5,-1.3,-37,0.018735974,0.120533937,0.043763641,-0.064045284,2];
%grass=[47.5,-25.7,27.6,0.018735974,0.120533937,0.043763641,-0.064045284,2];%没有ellipse数据，暂用肤色椭球更换中心代替

%% 脸部区域肤色降采样采集，预测白点

%skinSquare的lab代替椭圆中心
ellipse(1,1:3)=square_lab;
downsize=1;
input=imresize(img,downsize);
[lab,xyz,center0,bull,count,~]=mask(input,ellipse,white65,w,option);%用于其他像素占据较大比重，同时与肤色差异很大时，初始椭球采用肤色椭球
% [lab,xyz,center0,bull,round]=maskv2(input,ellipse,white65,w);%用于其他像素与肤色接近时，采用图片平均中心作为初始椭球的中心，提高肤色获取率
ratio=count/(m*n*downsize*downsize);
if count==0
%    disp([string,' not founded in memory ellipse, average center was used']);
   [lab,xyz,center0,bull,count1,~]=maskv2(input,ellipse,white65,w,option);
end


% % 对bull进行去噪以及形态学处理
% noise=5;
% bull(:,:,1) = bwareaopen(bull(:,:,1), noise); % 根据实际情况调整噪点大小阈值
% % 进行形态学操作
% region_size=2;
% se = strel('disk', region_size); % 根据实际情况调整结构元素大小
% bull(:,:,1) = imopen(bull(:,:,1), se);
% 
% bull(:,:,2) = bull(:,:,1);
% bull(:,:,3) = bull(:,:,1);

% dv,dd不能同时改变
ellipse1=ellipse;%中国人椭球

% 渲染目标差值
ellipse1(1)=dlab(1);%[30 5 5]
ellipse1(2)=dlab(2);
ellipse1(3)=dlab(3);

% ellipse1(1)=ellipse1(1)+dlab(1);
% ellipse1(2)=ellipse1(2)+dlab(2);
% ellipse1(3)=ellipse1(3)+dlab(3);


[actualwhite,ccT,duv,e1,center1]=findwhitev2(center0,ellipse1,white65,spq);

%% CAT16 变换到D65光源
[rgbnew,outxyz,kL,rgbnew2]=imgcat(img,actualwhite,white65,white65,w,option);
rgbnew(rgbnew<0)=0;
rgbnew(rgbnew>255)=255;
%% 图片文件处理
bull1=imresize(bull,[m,n]);
% out=rgbnew.*bull1+img.*(1-bull1);
% imshow([img rgbnew])

end
