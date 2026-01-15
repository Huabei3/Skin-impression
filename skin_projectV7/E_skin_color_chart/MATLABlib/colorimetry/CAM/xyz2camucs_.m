function JabUCS = xyz2cam02ucs(XYZ,XYZw,La,Yb,surround,Did,MCAT)
% xyz2camucs for use in cri engines (yellow an purple problems have been
% fixed). Default surround input as in CRI2012/CRI2014.
if nargin < 6; Did = 1;end
if nargin < 5; surround=[1,1,0.69];end
if nargin < 4; Yb = 20;end
if nargin < 3; La=100; end
if isnumeric(surround);
    F = surround(1);
    Nc = surround(2);
    c = surround(3);
end

if nargin==7;
    Colorattributes = xyz2cam02c(XYZ,XYZw,La,Yb,surround,Did,MCAT);
else;
    Colorattributes = xyz2cam02c(XYZ,XYZw,La,Yb,surround,Did);
end

J = Colorattributes(:,1);
M = Colorattributes(:,5);
h = Colorattributes(:,3);
c1=0.007; %= CAM02_UCS value
J2 = ((1+100*c1).*J)./(1+c1.*J);
c2=0.0228; %= CAM02_UCS value
M2=(1/c2).*log(1+c2.*M);
a = M2.*cos(h*pi/180);
b= M2.*sin(h*pi/180);
JabUCS = [J2,a,b];
end

