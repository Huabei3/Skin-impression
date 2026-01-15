function lab99d=xyz2DIN99d(xyz,xyzw)
%convert from xyz to lab99DIN space
%input: xyz and xyzw of white point
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
xyz(:,1)=1.12.*xyz(:,1)-0.12.*xyz(:,3);
xyzw(:,1)=1.12.*xyzw(:,1)-0.12.*xyzw(:,3);

lab=xyz2lab(xyz,xyzw);

L99d=325.22.*log(1+0.0036.*lab(:,1));
e=lab(:,2).*cos(50*pi/180)+lab(:,3).*sin(50*pi/180);
f=1.14.*(-lab(:,2).*sin(50*pi/180)+lab(:,3).*cos(50*pi/180));
G=sqrt(e.^2+f.^2);

C99d=22.5.*log(1+0.06.*G);

h99d=(180/pi)*atan2(f,e);j=(f<0);h99d(j)=h99d(j)+360;
h99d=h99d+50;

a99d=C99d.*cos(h99d.*pi/180);
b99d=C99d.*sin(h99d.*pi/180);

lab99d=[L99d,a99d,b99d,C99d,h99d];
end
