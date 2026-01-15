function [xyY,cctt,xyYsl,Ss]=plotBBlocus(obs,cspace,lb,le,n) 
if nargin==0;obs=10;cspace='xyY';lb=1000;le=1000000;n=20;end
if nargin==1;cspace='xyY';lb=1000;le=1000000;n=20;end
if nargin==2;lb=1000;le=1000000;n=20;end
lb=10^9/lb;le=10^9/le;
for i=1:n
    cctt(i)=10^9/(lb+(i-1).*(le-lb)./(n-1));
    S = blackbodySPD(cctt(i), 360,830);%plot_2(S);hold on
    xyz(i,:)=spd2xyz(S,obs);
    if nargout==4;Ss(:,i)=S(:,2);end
end
xyY=xyz2xyY(xyz);
xyYsl=calcspectrumlocus(obs);
if cspace=='uvY';xyY=xy2uv(xyY);xyYsl=xy2uv(xyYsl);end
plot(xyYsl(:,1),xyYsl(:,2),'b');hold on;plot(xyY(:,1),xyY(:,2),'k-');
end

