function [xyYsl,xyw,xyvw,xyYBL]=plotwhite(obs,cspace,lb,le,n);
global cmf2 cmf10 cmflms
if nargin==0;obs=10;cspace='xyY';lb=1000;le=100000;n=20;end
if nargin==1;cspace='xyY';lb=1000;le=100000;n=20;end
if nargin==2;lb=1000;le=100000;n=20;end
[xyYBL,cctt,xyYsl]=plotBBlocus(obs,cspace,lb,le,n) ;
[xyYDL]=plotDaylocus(obs,cspace,4000+(1e-9),le,n) ;
[xyw,xyvw]=ICAOwhite(obs,cspace);
axis square
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [xyw,xyvw]=ICAOwhite(obs,cspace)
acc=0.5;nint=50;
tt=0;
%x,y lines for white icao area
picao1w=[0.285];
picao2w=[0,0.440];
picao3w=[0.640,0.150];
picao4w=[0.750,0.050];
picao5w=[0,0.382];
picao6w=[0.5];

%x,y lines for variable white icao area
picao1vw=[0.285];
picao2vw=[0,0.440];
picao3vw=[0.640,0.150];
picao4vw=[0.750,0.050];
picao5vw=[0,0.382];
picao6vw=[1/0.750,-0.255/0.750];
picao7vw=[-1/1.500,1.185/1.500];

%white
xy1w=datapointsline1(obs,picao1w,picao3w,picao4w,acc,nint);if cspace=='uvY';xy1w=xy2uv(xy1w);end;plot(xy1w(:,1),xy1w(:,2),'b');
xy2w=datapointsline1(obs,picao2w,picao3w,picao6w,acc,nint);if cspace=='uvY';xy2w=xy2uv(xy2w);end;plot(xy2w(:,1),xy2w(:,2),'b');
xy3w=datapointsline1(obs,picao3w,picao1w,picao2w,acc,nint);if cspace=='uvY';xy3w=xy2uv(xy3w);end;plot(xy3w(:,1),xy3w(:,2),'b');
xy4w=datapointsline1(obs,picao4w,picao1w,picao5w,acc,nint);if cspace=='uvY';xy4w=xy2uv(xy4w);end;plot(xy4w(:,1),xy4w(:,2),'b');
xy5w=datapointsline1(obs,picao5w,picao4w,picao6w,acc,nint);if cspace=='uvY';xy5w=xy2uv(xy5w);end;plot(xy5w(:,1),xy5w(:,2),'b');
xy6w=datapointsline1(obs,picao6w,picao2w,picao5w,acc,nint);if cspace=='uvY';xy6w=xy2uv(xy6w);end;plot(xy6w(:,1),xy6w(:,2),'b');
xyw=[xy1w;xy2w;xy3w;xy4w;xy5w;xy6w];
%uvw=xy2uv(xyw);

%variable white
xy1vw=xy1w;plot(xy1w(:,1),xy1w(:,2),'b');
xy3vw=xy3w;plot(xy2w(:,1),xy2w(:,2),'b');
xy4vw=xy4w;plot(xy3w(:,1),xy3w(:,2),'b');
xy2vw=datapointsline1(obs,picao2vw,picao3vw,picao7vw,acc,nint);if cspace=='uvY';xy2vw=xy2uv(xy2vw);end;plot(xy2vw(:,1),xy2vw(:,2),'b');
xy5vw=datapointsline1(obs,picao5vw,picao4vw,picao6vw,acc,nint);if cspace=='uvY';xy5vw=xy2uv(xy5vw);end;plot(xy5vw(:,1),xy5vw(:,2),'b');
xy6vw=datapointsline1(obs,picao6vw,picao5vw,picao7vw,acc,nint);if cspace=='uvY';xy6vw=xy2uv(xy6vw);end;plot(xy6vw(:,1),xy6vw(:,2),'b');
xy7vw=datapointsline1(obs,picao7vw,picao2vw,picao6vw,acc,nint);if cspace=='uvY';xy7vw=xy2uv(xy7vw);end;plot(xy7vw(:,1),xy7vw(:,2),'b');
xyvw=[xy1vw;xy2vw;xy3vw;xy4vw;xy5vw;xy6vw;xy7vw];
%uvvw=xy2uv(xyvw);
end

function xy1=datapointsline1(obs,picao1,picao2,picao3,acc,nint) 
%calculate datapoints for picao1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%1. find endpoints of line picao1 
if ischar(picao3) 
    crossL1=findintersection2llines(picao1,picao2);
    crossL2=intersectionwithspectrumlocus(obs,picao1,acc,picao3);
else

    crossL1=findintersection2llines(picao1,picao2);
    crossL2=findintersection2llines(picao1,picao3);
end

%switch order of crossL1 and crossL2 so that crossL1(x) <= crossL2(x)
if crossL1(1)> crossL2(1)
   temp=crossL1;crossL1=crossL2;crossL2=temp;
end
%2. create ICAO dataset for line picao1
dr=sqrt((crossL1(1)-crossL2(1))^2+(crossL1(2)-crossL2(2))^2)/nint;%=length of line picao1
r1=dr.*(0:nint)';

if (crossL1(1)-crossL2(1)) ==0 alpha1=-pi/2; else alpha1=atan(picao1(1));end %special case for x=k lines
x1=crossL1(1)+cos(alpha1).*r1;y1=crossL1(2)+sin(alpha1).*r1;
xy1=[x1,y1];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function X=findintersection2llines(line1,line2)
%find intersection of 2 straight lines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

X=[];
if length(line1)==1 & length(line2)==1; disp('No intersection found!');end
if length(line1)==1; x = line1;X=[x,line2(1)*x+line2(2)];end
if length(line2)==1; x = line2;X=[x,line1(1)*x+line1(2)];end

if length(X)~=2;   
    x=-(line1(2)-line2(2))./(line1(1)-line2(1)); 
    y=line1(1)*x+line1(2);
    X=[x,y];
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function [crosssl,teller]=intersectionwithspectrumlocus(obs,picao,acc,picao3)
%find intersection of line picao with spectrumlocus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[xyYsl,lambda]=calcspectrumlocus([obs,'d'],acc);
offset=50/acc;xyYsl=xyYsl(offset:end,:);%not all of spectrumlocus is needed.
%offset=0;
teller=0;
j=1;   
for i=1:length(xyYsl(:,1))-2
    psl=[(xyYsl(i+1,2)-xyYsl(i,2))/(xyYsl(i+1,1)-xyYsl(i,1)),(xyYsl(i,2)-xyYsl(i,1)*((xyYsl(i+1,2)-xyYsl(i,2))/(xyYsl(i+1,1)-xyYsl(i,1))))];
    crosssltemp=findintersection2llines(picao,psl);
    %check if point lies between the two xyYsl points
    ux=mean([xyYsl(i,1),xyYsl(i+1,1)]);
    uy=mean([xyYsl(i,2),xyYsl(i+1,2)]);
    r1=sqrt((xyYsl(i,1)-ux)^2+(xyYsl(i,2)-uy)^2);
    r2=sqrt((xyYsl(i+1,1)-ux)^2+(xyYsl(i+1,2)-uy)^2);
    rt=sqrt((crosssltemp(1)-ux)^2+(crosssltemp(2)-uy)^2);
    maxr=max([r1,r2]);
    if rt<maxr; crosssl(j,:)=crosssltemp;teller=i;j=j+1;end
end 
teller=teller+offset;
picao3=char(picao3);
crosssl=crosssl(str2double(picao3(3)),:); %select 1° or 2° intersection
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

