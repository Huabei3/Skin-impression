function XYZ=ipt2xyz(IPT)
%transform from ipt to XYZ(2°)
%D65 is assumed whitepoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%IPT calculation
Mlms=[0.4002,0.7075,-0.0807;-0.2280,1.1500,0.0612;0,0,0.9184];
Mipt=[0.4000,0.4000,0.2000;4.4550,-4.8510,0.3960;0.8056,0.3572,-1.1628];

LMS=(inv(Mipt)*IPT')';
LMS=((((LMS>=0).*LMS).^(1./0.43))-(((LMS<0).*(-LMS)).^(1./0.43)));
XYZ=(inv(Mlms)*LMS')';
XYZ=XYZ.*100;
XYZ(XYZ<0)=0;
end