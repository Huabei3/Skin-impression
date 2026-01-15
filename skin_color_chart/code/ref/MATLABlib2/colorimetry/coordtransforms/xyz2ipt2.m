function IPT=xyz2ipt2(XYZ)
%transform from XYZ(2°) to IPT
%D65 is assumed whitepoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

XYZ=XYZ./100;

%IPT calculation
Mlms2d=[0.4002,0.7075,-0.0807;-0.2280,1.1500,0.0612;0,0,0.9184];%IPT fairchild
Mlms=Mlms2d;

Mipt=[0.4000,0.4000,0.2000;4.4550,-4.8510,0.3960;0.8056,0.3572,-1.1628];

LMS=((((LMS>=0).*LMS).^0.43)-(((LMS<0).*(-LMS)).^0.43));

IPT=(Mipt*LMS')';

end
