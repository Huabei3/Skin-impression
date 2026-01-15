function SPDLED = RGBYSPDmodel(n,lRled,hlR,lGled,hlG,lBled,hlB,lYled,hlY,Yprocent,xyYm,cieobs)
%Calculate a SPD for a RGBY LED engine that has Colour Coordinates xyYm
%n = number of model
%l0= start lambda of spectrum
%ln = end lambda of spectrum
%lB = peak wavelength of Blue LED
%hlB = FWHM Blue LED 
%lG = peak wavelength of Green LED
%hlG = FWHM Green LED 
%lY = peak wavelength of Yellow LED
%hlY = FWHM Yellow LED
%lR = peak wavelength of Red LED
%hlR = FWHM Red LED 
%Yprocent = power of Y to R+Y (<0); lumen of Y to R+Y (>=0)
%xyYm = [xyYx, xyYy] of colour to match
%_______________________________________________________________________
if nargin<12;cieobs=2;else;cieobs=10;end

[CMF,K]=selectcmf(cieobs);
lb=CMF(1,1);
le=CMF(end,1);
stepsize=CMF(2,1)-CMF(1,1);
wavrange=[lb,le,stepsize];

%calculate individual dye spectra
B = LEDgaussmodel1(lBled,hlB,wavrange);
G = LEDgaussmodel1(lGled,hlG,wavrange);
Y = LEDgaussmodel1(lYled,hlY,wavrange);
R = LEDgaussmodel1(lRled,hlR,wavrange);
lamb = linspace(lb,le,((le-lb)+1))';
%calculate individual dye color coordinates
TSVB=spd2xyz([lamb,B],cieobs,0);
TSVG=spd2xyz([lamb,G],cieobs,0);
TSVY=spd2xyz([lamb,Y],cieobs,0);
TSVR=spd2xyz([lamb,R],cieobs,0);
xyYB = xyz2xyY(TSVB);
xyYG = xyz2xyY(TSVG);
xyYY = xyz2xyY(TSVY);
xyYR = xyz2xyY(TSVR);


%Calculate required lumen output for each dye
CMFylum = CMF(:,3);
Blumens =  sum(B.*CMFylum.*stepsize);
Glumens =  sum(G.*CMFylum.*stepsize);
Ylumens =  sum(Y.*CMFylum.*stepsize);
Rlumens =  sum(R.*CMFylum.*stepsize);

if Yprocent <0
   %calculate ratio of lumenoutput for 1 Watt to convert powerratio to lumenratio
    RYlumenratio = Rlumens/Ylumens;
else 
    %input is directly in lumen, so RYlumenratio = 1
    RYlumenratio=1;
end
Yprocent=abs(Yprocent);
%calculate the lumenratio given a certain Yprocent 
RYratio=((1-Yprocent/100)/(Yprocent/100))*RYlumenratio;

%Calculate dye-weights to create xyYm color, RYratio = lumenratio of R to Y (NOT powerratio!)
M = color4mixer(xyYR,xyYG,xyYB,xyYY,RYratio,xyYm);
wR = M(1)/Rlumens;
wG = M(2)/Glumens;
wB = M(3)/Blumens;
wY = M(4)/Ylumens;
RGBY=[CMF(:,1),wR.*R,wG.*G,wB.*B,wY.*Y];
SPDLED = RGBY(:,2)+RGBY(:,3)+RGBY(:,4)+RGBY(:,5);
SPDLED=(xyYm(3)./K).*SPDLED./sum(SPDLED.*CMFylum.*stepsize);%total luminous power = 1
SPDLED = [RGBY(:,1),SPDLED];
if n>0;filename = ['LEDSPDmodel' num2str(n) '.txt'];dlmwrite(filename,SPDLED,'delimiter',',');end
plot(RGBY(:,1),RGBY(:,end:-1:2),SPDLED(:,1),SPDLED(:,2),'k');
end