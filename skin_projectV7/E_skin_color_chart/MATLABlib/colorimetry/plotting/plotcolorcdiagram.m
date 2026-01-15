function plotcolorcdiagram(obs,cspace,xyt,colorsym,lb,le,n)
%plots colored chromaticitydiagram
%obs = degree of observer, 2 (default) or 10
%cspace : 'xyY' (CIE xy, default) or 'uvY' (1976 uprime vprime)
%xyt: optional test point (in whatever cspace selected) to be plotted
%colorsym: color + marker symbol to plot testpoints, e.g. 'bx' or 'ro',...
%lb: begin cct for blackbody locus (default = 1500)
%le: end cct for blackbody locus (default = 16000)
%n: number of ccts between lb and le (default = 100)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin==0;obs=2;cspace='xyY';lb=1500;le=16000;n=100;end
if nargin==1;cspace='xyY';lb=1500;le=16000;n=100;end
if nargin<=4;lb=1500;le=16000;n=100;end

[cmf,K]=selectcmf(obs);
%cmf=cmf(cmf>360 & cmf<740,:);
switch obs
    case 10
        cmf=cmf(cmf>360 & cmf<740,:);
end

[xyYbb,cctt]=calcBBlocus(obs,le,lb,n) ;

X=cmf(:,2);Y=cmf(:,3);Z=cmf(:,4);x=X./(X+Y+Z);y=Y./(X+Y+Z);z=(1-x-y);
xyYsl=[x,y,repmat(100,numel(x),1)];
xyYsl=xyYsl(~isnan(sum(xyYsl,2)),:);

% plot_2(xyz2uvY(xyY2xyz(xyYsl)),'ro');hold on;

xy0=[1/3,1/3];%whitepoint for plotting

if cspace=='uvY';xyYbb=xy2uv(xyYbb);xyYsl=xy2uv(xyYsl);x=xyYsl(:,1);y=xyYsl(:,2);xy0=xy2uv(xy0);end

x=xyYsl(:,1);y=xyYsl(:,2);

wav=cmf(:,1);
n = length(xyYsl(:,1));

% blue blue cyan green yellow orange red red
wav0 = [cmf(1,1) 470 492 520 575 600 630 cmf(end,1)]'; 
rgb0 = [0 0 1;0 0 1;0 1 1;0 1 0;1 1 0;1 0.5 0;1 0 0;1 0 0];
rgb = [pchip(wav0,rgb0(:,1),wav), pchip(wav0,rgb0(:,2),wav),...
    pchip(wav0,rgb0(:,3),wav)];
 
% for k = 1:n-1
%     rgb2 = permute([1 1 1;rgb(k,:);rgb(k+1,:)],[1 3 2]);
%     patch([xy0(1);x(k:k+1)],[xy0(2);y(k:k+1)],rgb2,'edgecolor','none');
% end
% rgb2 = permute([1 1 1;rgb(end,:);rgb(1,:)],[1 3 2]);
% patch([xy0(1);x([end 1])],[xy0(2);y([end 1])],rgb2,'edgecolor','none');
 
patch(x,y,'-k','facecolor','none','edgecolor','k', 'LineWidth', 1.5)

hold on;
% plot(xyYbb(:,1),xyYbb(:,2),'k.-');
if nargin>2;if nargin<=3;colorsym='ko';end;plot(xyt(:,1),xyt(:,2),colorsym);end 
hold off
grid on
axis equal
switch obs;
    case 10;
        if cspace =='xyY';axis([0 .8 0 .9]);else;axis([0 .6 0 .6]);end
    case 2
        if cspace =='xyY';axis([0 .8 0 .9]);else;axis([0 .65 0 .6]);end
    otherwise
        if cspace =='xyY';axis([0 .8 0 .9]);else;axis([0 .6 0 .6]);end

end
end


function [xyY,cctt]=calcBBlocus(obs,le,lb,n) 
if nargin==0;obs=10;lb=1500;le=16000;n=100;end
if nargin==1;lb=1500;le=16000;n=100;end
for i=1:n
    cctt(i)=lb+(i-1).*(le-lb)./(n-1);
    S = blackbodySPD(cctt(i), 380,780);
    xyY(i,:)=xyz2xyY(spd2xyz(S,obs,0));
end
end

