function XYZc=xyz2xyzcCAT02_2Ds(XYZ,XYZ1w,XYZ2w,La,surround)%from paper by sung-hak lee: factors of incomplete adaptation ...
%Chromatic Adaptation taking into account the purity of the light sources
%cfr. paper by Sung-Hak Lee (but problem: CAT based on figures and equations in papers
%don't give the same result!!) Figure based data seems more in accord with
%CAT02 degree of adaptation, but authors claim equation data should be
%used.
%PART1 & PART2 (Ds factor) of paper are taken into account.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%CAT02 chromatic adaptation
MCAT02=[0.7328,0.4296,-0.1624;
-0.7036,1.6975,0.0061;
0.0030,0.0136,0.9834];
MCAT=MCAT02;

% CAT02 inverse matrix
MCATi=inv(MCAT02);
    
%get parameters
if nargin>4;    
switch surround
    case 'avg' 
        F=1;
    case 'average'
        F=1;
    case 'disp'
        F=0;
    case 'dim'
        F=0.9;
    case 'dark'
        F=0.8;
    otherwise
        F=1;
end
end

% Calculate constants for XYZ(Ill. 1) -> XYZc(Ill. 2).
xy=xyz2xyY(XYZ1w);xyn=[0.319,0.319];Pxy=sqrt((xy(1)-xyn(1)).^2+(xy(2)-xyn(2)).^2);%Purity
Dc=1-exp(-5.30*Pxy);
Dm=0.96*(1-exp(-5.30*Pxy))*((1-exp(-4.28*log10(La))).^(406.5)-1)+1;%paper eq 4
%Dm=0.96*(1-exp(-7.02*Pxy))*((1-exp(-2.14*log10(La))).^(34)-1)+1;%paper fig 4


alpha=XYZ1w(2)./XYZ2w(2);
%_________________________________

% Convert XYZ data to CAT02 LMS space
RGB=(MCAT*XYZ')';
R=RGB(:,1);G=RGB(:,2);B=RGB(:,3);
RGBw=(MCAT*XYZ1w')';
Rw=RGBw(:,1);Gw=RGBw(:,2);Bw=RGBw(:,3);

RGBw2=(MCAT*XYZ2w')';
Rw2=RGBw2(:,1);Gw2=RGBw2(:,2);Bw2=RGBw2(:,3);


% Apply chromatic adaptation (Ill. 1 --> Ill.2)
Rc=(alpha.*D*(Rw2./Rw)+1-D).*R;
Gc=(alpha.*D*(Gw2./Gw)+1-D).*G;
Bc=(alpha.*D*(Bw2./Bw)+1-D).*B;

RGBc=[Rc,Gc,Bc];

%saturation adjustement
Dss = 0.61+0.52*(1-exp(-0.82*log10(La))).^6.7;
Lar=1000/pi/5;Dsr = 0.61+0.52*(1-exp(-0.82*log10(Lar))).^6.7;%ref
Ds=Dss/Dsr;Ds(Ds>1)=1;
Rcp=Ds.*Rc+(1-Ds).*(XYZ1w(2)./100).*Rw2;
Gcp=Ds.*Gc+(1-Ds).*(XYZ1w(2)./100).*Gw2;
Bcp=Ds.*Bc+(1-Ds).*(XYZ1w(2)./100).*Bw2;

RGBcp=[Rcp,Gcp,Bcp];

RGBc=RGBcp;

% Calculate XYZ
XYZc=(MCATi*RGBc')';
XYZc(XYZc<0)=0;
end