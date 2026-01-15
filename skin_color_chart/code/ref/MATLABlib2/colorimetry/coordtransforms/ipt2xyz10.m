function XYZ=ipt2xyz10(IPT)
%transform from ipt to XYZ(10°)
%D65 is assumed whitepoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%IPT calculation
Mlms=[ 0.400070	0.707270	-0.080674;-0.228111	1.150561	0.061230;0.000000	0.000000	0.931757];
Mipt=[0.4000,0.4000,0.2000;4.4550,-4.8510,0.3960;0.8056,0.3572,-1.1628];

LMS=(inv(Mipt)*IPT')';
LMS=((((LMS>=0).*LMS).^(1./0.43))-(((LMS<0).*(-LMS)).^(1./0.43)));
XYZ=(inv(Mlms)*LMS')';
XYZ=XYZ.*100;
XYZ(XYZ<0)=0;
end