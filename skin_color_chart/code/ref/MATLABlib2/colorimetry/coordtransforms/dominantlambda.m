function output=dominantlambda(xyY,obs)
%calculates dominant wavelength and excitation purity from xyY
%output=[dominant wavelength, excitation purity]
%if dom. wavelength < 0 --> extraspectral hue!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin==1;obs=2;end

spectrumlocus=calcspectrumlocus(obs);
spectrumlocus=spectrumlocus(1:end-1,:);
extraspectral=0;
lambda=linspace(380,700,(700-380)/1 +1)';
spectrumlocus=[lambda,spectrumlocus];
x=spectrumlocus(:,2);
y=spectrumlocus(:,3);
xc=xyY(1);
yc=xyY(2);

%find polar angles
alpha=pi/180*hue_angle((x-1/3),(y-1/3));
alphac=pi/180*hue_angle((xc-1/3),(yc-1/3));


%check if extraspectral hue
if alphac<alpha(end) & alphac>alpha(1)
    alphac=alphac-pi;
    extraspectral=1;
end


%zet alpha(end)=0° en maak alpha monotoon dalend
alphaend=alpha(end);
alpha=alpha-alphaend;
alpha=alpha*180/pi;
alpha=alpha+360.*(alpha<=0);
alphac=alphac-alphaend;
alphac=alphac*180/pi;
alphac=alphac+360.*(alphac<=0);
alpha_g=(alpha<=alphac);
alpha_s=(alpha>alphac);
lgs=[lambda,alpha,alpha_g,alpha_s];%for testing
index_g=find(alpha<=alphac);
index_g=index_g(1);
index_s=find(alpha>alphac);
index_s=index_s(end);

for j=1:length(alpha)-1
    if (alphac<=alpha(j)&alphac>=alpha(j+1))
        index_dom=j;
    end
end
index_g=index_dom;
index_s=index_dom+1;
%lambda(index_dom)

domlambda=-(alphac-alpha(index_s))./(alpha(index_g)-alpha(index_s))+lambda(index_s);


if extraspectral==0;
    %bepaal xy voor snijlijn met spectrumlocus
    domxy=findintersection2llines([xc,yc;1/3,1/3],[x(index_s),y(index_s);x(index_g),y(index_g)]);
else
    %bepaal xy voor snijlijn met purpleline
    domxy=findintersection2llines([xc,yc;1/3,1/3],[x(end),y(end);x(1),y(1)]);
end 



figure(10);
plotwhite(obs,'xyY');
plot_2([xc,yc],'b.');
hold on;plot_2(domxy','b*');
plot([1/3;domxy(1)],[1/3;domxy(2)],'k')
%plot([x,y],'r');
%bepaal afstand xyc, domxy tot (1/3,1/3)
dc=sqrt((xc-1/3).^2+(yc-1/3).^2);
domd=sqrt((domxy(1)-1/3).^2+(domxy(2)-1/3).^2);
if extraspectral==1
    domlambda=-domlambda;
end
dominantwavelength=domlambda;
excitationpurity=dc./domd;
output=[dominantwavelength,excitationpurity];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function X=findintersection2llines(xy1,xy2)

%first straight line
line1=polyfit(xy1(:,1),xy1(:,2),1);

%second straight line
line2=polyfit(xy2(:,1),xy2(:,2),1);

%solve A*X=B by X=A\B
A= [line1(1),-1;line2(1),-1];
B=[-line1(2),-line2(2)]';

X=A\B;

%check solution
if norm(A*X-B)<10^(-5)*norm(B);
    X=X;
else
    X=[];
    disp('No solution using X=A\B');
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

