function [HMsQ,Q2,Q3,Mrg,Mbg]=xyL2cam97u(xystim,Lstim, Lstimscot,xycond,Lcond, Lcondscot,naamxls)

%op basis van paper, niet op basis van measuring colour
% CIECAM97u 
%
% SYNTAX
% ----------------------------------------------------------------------------
% HMsQ=spd2cam97u(XYZstim,XYZcond);
%calculates appearance coordinates H, M, s and Q
%
% xystim = xy van de stimulus
% xycond = xy van het conditioning field (wat je zag net voor de
% stimulus)
% Lstim = luminance stimulus
% Lcond = luminance conditioning field
% 

%read in data from input
%if data is file then read file else data is matlab matrix
if ischar(xystim) == 1  
    xy = dlmread(xystim);
else
    xy = xystim;
end
if ischar(xycond) == 1  
    xyc = dlmread(xycond);
else
    xyc = xycond;
end
if ischar(Lstim) == 1  
    L = dlmread(Lstim);
else
    L = Lstim;
end
if ischar(Lcond) == 1  
    Lc = dlmread(Lcond);
else
    Lc = Lcond;
end
if ischar(Lstimscot) == 1  
    Ls = dlmread(Lstimscot);
else
    Ls = Lstimscot;
end
if ischar(Lcondscot) == 1  
    Lcs = dlmread(Lcondscot);
else
    Lcs = Lcondscot;
end
%L=Lstim;
%Lc=Lcond;

%input data verwerking
x=xy(:,1);
y=xy(:,2);
xa=1/3*ones(max(size(x)));
ya=1/3*ones(max(size(y)));
xc=xyc(:,1);
yc=xyc(:,2);
%Ls=2.26.*L;
%Lcs=2.26.*Lc;
La=L.^(2/3)./200;
Las=2.26.*((Ls./2.26).^(2/3)./200);%eq 45 in paper
%Las=Ls.^(2/3)./200;%appendix 2 in paper

%same for conditioning field
Lc=Lc.^(2/3)./200;
Lcs=2.26.*((Lcs./2.26).^(2/3)./200);%eq 45 in paper
%Lcs=Lcs.^(2/3)./200;%appendix 2 in paper



Nc=0.5;

%step1
Xl=x.*L./y;
Yl=L;
Zl=(1-x-y).*L./y;

Xcl=xc.*Lc./yc;
Ycl=Lc;
Zcl=(1-xc-yc).*Lc./yc;

%step2
rho=0.38971.*Xl+0.68898.*Yl-0.07868.*Zl;
gamma=-0.22981.*Xl+1.18340.*Yl+0.04641.*Zl;
beta=Zl;

rhoc=0.38971.*Xcl+0.68898.*Ycl-0.07868.*Zcl;
gammac=-0.22981.*Xcl+1.18340.*Ycl+0.04641.*Zcl;
betac=Zcl;

%step3
W=((1/3)*(rho+gamma+beta)).^(1/2);

%step4
k=1./(5*La+1);
Fl=(0.2*(k.^4)).*(5*La)+0.1.*((1-(k.^4)).^2).*((5*La).^(1/3));

%step5
hrho=3*rhoc./(rhoc+gammac+betac);
hgamma=3*gammac./(rhoc+gammac+betac);
hbeta=3*betac./(rhoc+gammac+betac);
h_factors=[hrho,hgamma,hbeta];
Frho=(1+(La.^(1/3))+hrho)./(1+(La.^(1/3))+1./hrho);
Fgamma=(1+(La.^(1/3))+hgamma)./(1+(La.^(1/3))+1./hgamma);
Fbeta=(1+(La.^(1/3))+hbeta)./(1+(La.^(1/3))+1./hbeta);

%step6

c=0.2;

Brhou=10^7./(10^7+(5*La).*(3*rhoc)./(rhoc+gammac+betac));
Bgammau=10^7./(10^7+(5*La).*(3*gammac)./(rhoc+gammac+betac));
Bbetau=10^7./(10^7+(5*La).*(3*betac)./(rhoc+gammac+betac));

rhoa=Brhou.*(40*(((Fl.*Frho.*((La./Lc).^c).*rho./W).^0.73)./(((Fl.*Frho.*((La./Lc).^c).*rho./W).^0.73)+2)))+1;
gammaa=Bgammau.*(40*(((Fl.*Fgamma.*((La./Lc).^c).*gamma./W).^0.73)./(((Fl.*Fgamma.*((La./Lc).^c).*gamma./W).^0.73)+2)))+1;
betaa=Bbetau.*(40*(((Fl.*Fbeta.*((La./Lc).^c).*beta./W).^0.73)./(((Fl.*Fbeta.*((La./Lc).^c).*beta./W).^0.73)+2)))+1;

%step7
Aa=2*rhoa+gammaa+(1/20)*betaa-3.05+1;
C1=rhoa-gammaa;
C2=gammaa-betaa;
C3=betaa-rhoa;
a=C1-(C2./11);
b=1/2*(C2-C3)./4.5;

for i=1:max(size(a));
    %step8
    h(i)=180/pi*atan2(b(i),a(i));
    %step9
    %h(i)=h(i)+360*(+(h(i)<20.14));
    h(i)=h(i)+360*(+(h(i)<0));
    hR=20.14;hY=90.00;hG=164.25;hB=237.53;
    eR=0.8;eY=0.7*(L(i)./(L(i)+10))+0.3*(10./(L(i)+10));eG=1.0;eB=1.2*(L(i)./(L(i)+10))+0.2*(10./(L(i)+10));
    if hR<=h(i) && h(i)<hY    h1(i)=hR;h2(i)=hY;e1(i)=eR;e2(i)=eY;H1(i)=0;
                              HP(i)=100*((h(i)-h1(i))/e1(i))/((h(i)-h1(i))/e1(i)+(h2(i)-h(i))/e2(i));
                              H(i)=H1(i)+HP(i);HCR(i)=100-HP(i);HCY(i)=HP(i);HCG(i)=0;HCB(i)=0;
    elseif hY<=h(i) && h(i)<hG h1(i)=hY;h2(i)=hG;e1(i)=eY;e2(i)=eG;H1(i)=100;
                              HP(i)=100*((h(i)-h1(i))/e1(i))/((h(i)-h1(i))/e1(i)+(h2(i)-h(i))/e2(i));
                              H(i)=H1(i)+HP(i);HCR(i)=0;HCY(i)=100-HP(i);HCG(i)=HP(i);HCB(i)=0;
    elseif hG<=h(i) && h(i)<hB h1(i)=hG;h2(i)=hB;e1(i)=eG;e2(i)=eB;H1(i)=200;
                              HP(i)=100*((h(i)-h1(i))/e1(i))/((h(i)-h1(i))/e1(i)+(h2(i)-h(i))/e2(i));
                              H(i)=H1(i)+HP(i);HCR(i)=0;HCY(i)=0;HCG(i)=100-HP(i);HCB(i)=HP(i);
    else                      h1(i)=hB;h2(i)=hR+360;e1(i)=eB;e2(i)=eR;H1(i)=300;
                              HP(i)=100*((h(i)-h1(i))/e1(i))/((h(i)-h1(i))/e1(i)+(h2(i)-h(i))/e2(i));
                              H(i)=H1(i)+HP(i);HCR(i)=HP(i);HCY(i)=0;HCG(i)=0;HCB(i)=100-HP(i);
    end;
    
    %step11
    e(i)=e1(i)+(e2(i)-e1(i)).*(h(i)-h1(i))./(h2(i)-h1(i));
end
e=e';

%step12
Ftu=L./(L+0.1);
btu=b.*Ftu;

%step13
%s=50.*(((a.^2)+(btu.^2)).^(1/2)).*(100.*e.*(10/13)).*Nc./(rhoa+gammaa+(21/20).*betaa);
%s1=50.*(((a.^2)+(btu.^2)).^(1/2)).*(100.*e.*(10/13)).*Nc./(rhoa+gammaa+betaa);
%M=s.*(Fl.^0.15);
%M=s1.*(rhoa+gammaa+betaa)/50;
%M=s.*(rhoa+gammaa+(21/20).*betaa)/50;
M=100.*e.*(10/13).*Nc.*(((a.^2)+(btu.^2)).^(1/2));
Mrg=100.*e.*(10/13).*Nc.*a;
Mby=100.*e.*(10/13).*Nc.*btu;
s=50.*M./(rhoa+gammaa+betaa);

%step14
j=0.00001./(5.*Las./2.26+0.00001);
Fls=(3800.*(j.^2).*5).*(Las./2.26)+0.2*((1-j.^2).^4).*((5.*Las./2.26).^(1/6));

%step15
Bsu=0.5./(1+0.3.*(((5.*Las./2.26).*((Ls./2.26).^(1/2))).^0.3))+0.5./(1+5.*(5.*Las./2.26));
As=Bsu.*3.05.*(40.*(((Fls.*((Las./Lcs).^c).*((Ls./2.26).^(1/2))).^0.73)./(((Fls.*((Las./Lcs).^c).*((Ls./2.26).^(1/2))).^0.73)+2)))+0.3;

%step16
%A=Aa+As-2.31;
A=Aa+As-1-0.3+((1.09)^(1/2));

%step17 & 18
Q=((1.1)*(A+(M./100))).^0.9;



HMsQ=[H', HCR', HCY', HCG', HCB', M, s, A, Q];
if nargin ==7
if ischar(naamxls) == 1  
    xlswrite(naamxls,HMsQ,'cam97u','B3'); 
end
end
end
