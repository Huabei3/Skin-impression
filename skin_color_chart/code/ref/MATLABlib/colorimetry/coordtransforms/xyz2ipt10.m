function IPT=xyz2ipt10(XYZ)
%transform from XYZ(10°) to IPT
%D65 is assumed whitepoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%calculate relative tristimulus values
XYZ=XYZ./100;

%convert XYZ to LMS space
Mlms10d=[ 0.400070	0.707270	-0.080674;-0.228111	1.150561	0.061230;0.000000	0.000000	0.931757];
LMS=(Mlms10d*XYZ')';

%response compression: LMS to LMSprime
LMS=((((LMS>=0).*LMS).^0.43)-(((LMS<0).*(-LMS)).^0.43));

%convert LMSprime to IPT coordinates
Mipt=[0.4000,0.4000,0.2000;4.4550,-4.8510,0.3960;0.8056,0.3572,-1.1628];
IPT=(Mipt*LMS')';
end