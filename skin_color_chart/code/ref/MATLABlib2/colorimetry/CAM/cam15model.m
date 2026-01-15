function [Q W M s h ] = cam15cal( SPD )
%CAM15CAL Summary of this function goes here
%   Detailed explanation goes here
load LMS15;%LMS为10度标准观察者,范围 390:830nm, 间隔1nm
kk=[666.7,782.3,1444.6];
cp=1/3;
%% 本次实验提供的光谱范围是390nm - 780nm
LMSnew=LMS15(1:391,:);
for i=1:3
    inter1(i)=kk(i)*SPD'*LMSnew(:,i);
end
inter2=inter1.^cp;


%%
interA=3.22*[2 1 1/20]*inter2';
intera=[1 -12/11 1/11]*inter2';
interb=0.117*[1 1 -2]*inter2';
M=135.52*sqrt(intera^2+interb^2);

if intera>0 && interb>0%如果在坐标轴上怎么办
    h=atan(interb/intera);
elseif intera<0 && interb>0
    h=atan(interb/intera)+pi;
elseif intera<0 && interb<0
    h=atan(interb/intera)+pi;
elseif intera>0 && interb<0
    h=atan(interb/intera)+2*pi;
end
fh=0.116*abs(sin((h-0.5*pi)/2))+0.085;
fh5 = 0.240*abs(sin((h-0.5*pi)/2))+0.238; 
%Q :brightness  s: saturation W:whiteness
Q=interA+2.559*M^0.561;%  CAM15 model
% Q=interA+(fh/0.201)*2.559*M^0.561;%  YY model
% Q=interA+(fh5/0.201)*2.441*M^0.306;% HWJ model 2017/07/23  
s=M/Q; 
W= 100/(1+2.29*s^2.68);
