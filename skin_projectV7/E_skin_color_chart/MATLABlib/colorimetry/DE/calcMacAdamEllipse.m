function [MCellipses,xyel]= calcMacAdamEllipse(xy,plotyn,nsteps) 
% calculates Macadamellipses and plots
% xy: CIE1931 chromaticty coordinates of points 
%plotyn: 0 no plots, 1 create plot 
% nsteps: size of ellipse in plot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
x = xy(:,1);
y = xy(:,2);
if nargin<2;nsteps=1;plotyn=0;end
if nargin<3;nsteps=1;end
% gekende MA ellipsen (10 x vergroot)
a=[0.16	0.057	0.0085	0.0035	62.5
0.187	0.118	0.022	0.0055	77
0.253	0.125	0.025	0.005	55.5
0.15	0.68	0.096	0.023	105
0.131	0.521	0.047	0.02	112.5
0.212	0.55	0.058	0.023	100
0.258	0.45	0.05	0.02	92
0.152	0.365	0.038	0.019	110
0.28	0.385	0.04	0.015	75.5
0.38	0.498	0.044	0.012	70
0.16	0.2	0.021	0.0095	104
0.228	0.25	0.031	0.009	72
0.305	0.323	0.023	0.009	58
0.385	0.393	0.038	0.016	65.5
0.472	0.399	0.032	0.014	51
0.527	0.35	0.026	0.013	20
0.475	0.3	0.029	0.011	28.5
0.51	0.236	0.024	0.012	29.5
0.596	0.283	0.026	0.013	13
0.344	0.284	0.023	0.009	60
0.39	0.237	0.025	0.01	47
0.441	0.198	0.028	0.0095	34.5
0.278	0.223	0.024	0.0055	57.5
0.3	0.163	0.029	0.006	54
0.365	0.153	0.036	0.0095	40];



a(:,end)=a(:,end)*pi/180;

a(:,3:4)=a(:,3:4)./10.*nsteps;



% %rescale MacAdam ellipses in a to 1SD ellipses
% a(:,3:4)=a(:,3:4)./10;
% scale10to1=1;1.001944471887303e+002;
% if nsteps<=7;
%     conf = 2*normcdf(nsteps)-1; 
%     scale_nsteps = chi2inv(conf,2);
% else
%     if nsteps==10;
%         scale_nsteps=1;1.001944471887303e+002;
%     end
% end
% scale = (scale_nsteps./scale10to1).^(1)%scale factor for inverse covariance matrix
% 
% a=[a(:,3:4),a(:,1:2),a(:,5)];
% for i=1:25
%     a_(i,:)=cik2v(v2cik(a(i,:))./(scale));
%     %%if a_(i,2)>a_(i,1);temp=a_(i,1);a_(i,1)=a_(i,2);a_(i,2)=temp;end
% end;
% a=[a(:,3:4),a_(:,1:2),a_(:,5)];
% %a=[a(:,3:4),a(:,1:2),a(:,5)];

temp=[a(:,3:4),a(:,1:2),a(:,5)];temp=temp(1,:);figure(3);plotellipse(temp,'r');hold on
g=v2cik(temp)





at=a;
%a(:,3:4)=a(:,3:4).*cl;
for ie=1:length(x);
% ordenen van de rijen van a volgens de afstand tussen (x,y) en de ellipscentra uit a
for (k = 1:1:25)
    a(k,6) = sqrt((x(ie)-a(k,1))^2+(y(ie)-a(k,2))^2);
end
a=sortrows(a,6);
a2=[a(:,3:4),a(:,1:2),a(:,5),a(:,6)];
a2t=[at(:,3:4),at(:,1:2),at(:,5)];

if sum(a2(:,6)==0)==0
%find 3 closest ellipses that envelop chromaticity point
aext_full=ellipseXY([a(1,3:4),a(1,1:2),a(1,5)]);%use gamut spanned by full ellipses not just centers!
for i=2:25;aext_full=[aext_full;ellipseXY([a(i,3:4),a(i,1:2),a(i,5)])];end
inhull_full=inhull([x(ie),y(ie)],aext_full(:,1:2));

ae=a([1:3],:);aeext=[ae;ellipseXY([ae(1,3:4),ae(1,1:2),ae(1,5)]),ellipseXY([ae(2,3:4),ae(2,1:2),ae(2,5)]),ellipseXY([ae(3,3:4),ae(3,1:2),ae(3,5)])];
inhull_=inhull([x(ie),y(ie)],aeext(1:end,1:2));ae=a([1:3],:);
t=0;
while inhull_==0 & inhull_full & t<22;%find ellipses with a 'full' gamut envelopping chromaticity point 
    t=t+1;
        ae=a([1:2,3+t],:);
        aeext=[ae;ellipseXY([ae(1,3:4),ae(1,1:2),ae(1,5)]),ellipseXY([ae(2,3:4),ae(2,1:2),ae(2,5)]),ellipseXY([ae(3,3:4),ae(3,1:2),ae(3,5)])];
        inhull_=inhull([x(ie),y(ie)],aeext(1:end,1:2));
end

if inhull_full==0;ae=a(1:2,:);end %use two closest ellipses when outside the full gamut of all MCAdams ellipses

%calculate weights
weights=ae(:,end);
if min(weights==0);
    weights(weights==min(weights))=1;
    weights(weights~=min(weights))=0;
else;
    weights=1./weights.^1;
end
disp('average ellipse')
MCellipses(ie,:)=averageellipses([ae(:,3:4),repmat(xy(ie,:),length(ae(:,1)),1),ae(:,5)],weights)

else
    ae=a(a(:,6)==0,1:5);
    ae=[ae(:,3:4),ae(:,1:2),ae(:,5)];
    MCellipses(ie,:)=ae;
    ae=[ae(:,3:4),ae(:,1:2),ae(:,5)];
    
    
end


if plotyn==1;
figure(1)
hold on,plotBBlocus;
plotellipse(a2,'b');plotellipse(a2t,'k');plotellipse([ae(:,3:4),ae(:,1:2),ae(:,5)],'g');xyel=plotellipse(MCellipses(ie,:),'r--');
title(sprintf(['MacAdamEllipse (x',num2str(nsteps),') at xy= %0.3f, %0.3f.'],x(ie),y(ie)),'FontSize',12);
xlabel('CIE x','FontSize',12);
% xlim([0 1]);
ylabel('CIE y','FontSize',12);
% ylim([0 1]);
set(gca,'FontSize',15);
grid on
hold off
else
    xyel=0;
end
end
MCellipses(:,1:2)=MCellipses(:,1:2);%
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function xyellipse=ellipseXY(v)
[rows,cols]=size(v);

for nn=1:rows

xs=v(nn,1);
ys=v(nn,2);
xc=v(nn,3);
yc=v(nn,4);
alpha=v(nn,5);

%calculate ellipse for drawing
    N = 50;
    dx = 2*pi/N;
    theta=alpha;
    R = [ [ cos(theta) sin(theta)]', [-sin(theta) cos(theta)]'];
    for j = 1:N
         ang = j*dx;
         x = xs*cos(ang);
         y = ys*sin(ang);
         d1 = R*[x y]';
         X(j) = d1(1) + xc;
         Y(j) = d1(2) + yc;
    end
     X=[X];Y=[Y];
   
     xyellipse=[X',Y'];

            xyellipse=[X',Y'];

end
end