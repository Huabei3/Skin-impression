function JabUCS = XYZ2CAM02UCS(XYZ,XYZw,La,Yb,surround,MCAT)
if nargin==6;
    Colorattributes = xyz2cam02(XYZ,XYZw,La,Yb,surround,MCAT);
else;
    Colorattributes = xyz2cam02(XYZ,XYZw,La,Yb,surround);
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
