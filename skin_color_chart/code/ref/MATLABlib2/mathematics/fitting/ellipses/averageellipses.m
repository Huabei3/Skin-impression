function [vellipseavg,cikavg,cikstd]=averageellipses(vellipses,weights)
%take (weighted) average of ellipses in vellipse
%vellipses = matrix of ellipses: each row is an ellipse;
%ellipse format --> Rmax,Rmin,xc,yc,theta
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[m,n]=size(vellipses);
for i=1:m
    cik(:,:,i)=v2cik(vellipses(i,:));
end
xyc=vellipses(:,3:4);


if nargin==1; 
    weights=ones(m,1);
else 
    if weights(:,1)<0 %calculate weights from data
        weights=ones(m,1);%initialize
        xc=(xyc(:,1)-mean(xyc(:,1)));
        yc=(xyc(:,2)-mean(xyc(:,2)));
        R=sqrt(xc.^2+yc.^2);
        RM=sqrt((vellipses(:,1)-mean(vellipses(:,1))).^2);
        Rm=sqrt((vellipses(:,2)-mean(vellipses(:,2))).^2);
        theta=sqrt((vellipses(:,5)-mean(vellipses(:,5))).^2);
        delta=[R./min(R),RM./min(RM),Rm./min(Rm),theta./min(theta)];
        sumdelta=sum(delta')';
        w=[R,RM,Rm,theta,sumdelta./4];
        wm=abs(1-w(:,5));
        weights=exp(-sqrt(wm));
        weights=weights./max(weights);
    end
end

suminvcik=zeros(2,2);
xycavg(1)=0;xycavg(2)=0;
for i=1:m
    suminvcik=suminvcik+pinv(cik(:,:,i)).*weights(i);
    xycavg(1)=xycavg(1)+weights(i).*(xyc(i,1));
    xycavg(2)=xycavg(2)+weights(i).*(xyc(i,2));
end
avginvcik=suminvcik./sum(weights);
cikavg=pinv(avginvcik);

%calculate std on cikavg
suminvcik=zeros(2,2);
for i=1:m;
    suminvcik=suminvcik+((pinv(cik(:,:,i))-avginvcik).^2).*weights(i);
end
if sum(weights)>1;stdinvcik=sqrt(suminvcik./(sum(weights)-1));else;stdinvcik=[0,0;0,0];end%SD
%stdinvcik=stdinvcik./sqrt(sum(weights));%SE
cikstd=pinv(stdinvcik);

xycavg(1)=xycavg(1)./sum(weights);
xycavg(2)=xycavg(2)./sum(weights);
center=[xycavg(1),xycavg(2)];
[Q,D]=eig(cikavg);
l=1./sqrt(diag(D));l_(1)=max(l);l_(2)=min(l);l=l_';
vellipseavg=[l',xycavg,atan2(-2*cikavg(1,2),cikavg(2,2)-cikavg(1,1))/2];

end