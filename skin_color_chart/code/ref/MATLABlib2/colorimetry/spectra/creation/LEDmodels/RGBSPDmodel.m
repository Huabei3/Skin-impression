function SPDLED = RGBSPDmodel(n,lBled,hlB,lGled,hlG,lRled,hlR,xyYm,cieobs)
%Calculate a SPD for a RGB LED engine that has Colour Coordinates xyYm
%n = number of model
%l0= start lambda of spectrum
%ln = end lambda of spectrum
%lB = peak wavelength of Blue LED
%hlB = FWHM Blue LED 
%lG = peak wavelength of Green LED
%hlG = FWHM Green LED 
%lR = peak wavelength of Red LED
%hlR = FWHM Red LED 
%xyYm = [xyYx, xyYy] of colour to match
%_______________________________________________________________________
if nargin<9;cieobs=2;else;cieobs=10;end

[CMF,K]=selectcmf(cieobs);
lb=CMF(1,1);
le=CMF(end,1);
stepsize=CMF(2,1)-CMF(1,1);
wavrange=[lb,le,stepsize];

%calculate individual dye spectra
lamb = linspace(lb,le,((le-lb)+1))';
B = LEDgaussmodel1(lBled,hlB,wavrange);%figure(11);hold on;plot(lamb,B,'b');
G = LEDgaussmodel1(lGled,hlG,wavrange);%plot(lamb,G,'g');
R = LEDgaussmodel1(lRled,hlR,wavrange);%plot(lamb,R,'r');

%calculate individual dye color coordinates
TSVB=spd2xyz([lamb,B],cieobs,1);
TSVG=spd2xyz([lamb,G],cieobs,1);
TSVR=spd2xyz([lamb,R],cieobs,1);
xyYB = xyz2xyY(TSVB);
xyYG = xyz2xyY(TSVG);
xyYR = xyz2xyY(TSVR);
figure(22);hold on;plotwhite(cieobs,'xyY');
plot_2(xyYB,'b.');plot_2(xyYG,'g.');plot_2(xyYR,'r.');
%Calculate dye-weights to create xyYm color
M = color3mixer(xyYB,xyYG,xyYR,xyYm);
%Calculate required lumen output for each dye
CMFylum = CMF(:,3);
Blumens =  sum(B.*CMFylum.*stepsize);
Glumens =  sum(G.*CMFylum.*stepsize);
Rlumens =  sum(R.*CMFylum.*stepsize);
wB = M(1)/(Blumens);
wG = M(2)/(Glumens);
wR = M(3)/(Rlumens);

RGB=[CMF(:,1),wR.*R,wG.*G,wB.*B];
SPDLED = RGB(:,2)+RGB(:,3)+RGB(:,4);
SPDLED=(xyYm(3)./K).*SPDLED./sum(SPDLED.*CMFylum.*stepsize);%total luminous power = 1
SPDLED = [RGB(:,1),SPDLED];
if n>0;figure(1);filename = ['LEDSPDmodel' num2str(n) '.txt'];dlmwrite(filename,SPDLED,'delimiter',',');plot(RGB(:,1),RGB(:,end:-1:2),SPDLED(:,1),SPDLED(:,2),'k');end
xyY=xyz2xyY(spd2xyz_(cieobs,SPDLED));figure(22);plot(xyY(1),xyY(2),'ro');
end

function spd=spd2xyz_(obs,spd,Aor,rfldata);
spd=spd2xyz(spd,obs,1);
end