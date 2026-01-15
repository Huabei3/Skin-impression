function [XYZc,Dp]=xyz2xyzcFairchild(XYZ,XYZn,XYZn2,La1,La2,DD)
%calculates corresponding colours XYZc using the chromatic adaptation transform
% from RLAB  (M. Fairchild)
%Input:
%   XYZ = input tristimulus values
%   XYZn = adapting white point for XYZ
%   XYZn2 = adapting white point for XYZc
%   La1 = adapting luminance for XYZ
%   La2 = adapting luminance for XYZc
%   DD = degree of adaptation (regulates incomplete adaptation)
%Output:
%   XYZc = corresponding colours under XYZn2
%   Dp = adapting coefficients for the LMS channels
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin<6;DD=1;end
Mlms2xyz=[1.905378 -1.321620 0.419512;0.698648,0.333043,-0.013601;-0.024300,0.40453,2.073582];
MCAT02=[0.7328,0.4296,-0.1624; -0.7036,1.6975,0.0061;  0.0030,0.0136,0.9834];
MlmsHPE=[0.38971 0.68898 -0.07868;-0.22981 1.18340 0.04641;0 0 1];%HPE for EEW
Mlms2d=[0.4002,0.7075,-0.0807;-0.2280,1.1500,0.0612;0,0,0.9184];%IPT fairchild,HPE for D65

MlmsHPE=MCAT02;
%Yn=XYZn(:,2);Yn2=XYZn2(:,2);
Yn=La1;Yn2=La2;
XYZn=100.*XYZn./XYZn(:,2);XYZn2=100.*XYZn2./XYZn2(:,2);
%LMSn=(inv(Mlms2xyz)*XYZn')';
LMSn=((MlmsHPE)*XYZn')';%2degrees as approximation
LMSn2=((MlmsHPE)*XYZn2')';%2degrees as approximation
Ln=LMSn(:,1);Mn=LMSn(:,2);Sn=LMSn(:,3);

Ln2=LMSn2(:,1);Mn2=LMSn2(:,2);Sn2=LMSn2(:,3);
%Ln2=1;Mn2=1;Sn2=1;
lE=3.0.*(Ln./Ln2)./(Ln./Ln2+Mn./Mn2+Sn./Sn2);
mE=3.0.*(Mn./Mn2)./(Ln./Ln2+Mn./Mn2+Sn./Sn2);
sE=3.0.*(Sn./Sn2)./(Ln./Ln2+Mn./Mn2+Sn./Sn2);
%pL=(1+(Yn./Yn2).^(1/3)+lE)./(1+(Yn./Yn2).^(1/3)+1/lE);
%pM=(1+(Yn./Yn2).^(1/3)+mE)./(1+(Yn./Yn2).^(1/3)+1/mE);
%pS=(1+(Yn./Yn2).^(1/3)+sE)./(1+(Yn./Yn2).^(1/3)+1/sE);
p=1/3;
pL=(1+(Yn).^p+lE)./(1+(Yn).^p+1/lE);
pM=(1+(Yn).^p+mE)./(1+(Yn).^p+1/mE);
pS=(1+(Yn).^p+sE)./(1+(Yn).^p+1/sE);
[lE,mE,sE];
aL=(pL+DD.*(1.0-pL))./(Ln./Ln2);
aM=(pM+DD.*(1.0-pM))./(Mn./Mn2);
aS=(pS+DD.*(1.0-pS))./(Sn./Sn2);
Dp=[pL,pM,pS];
%Dp(Dp>1)=1;
Dp=[aL,aM,aS];

LMS=((MlmsHPE)*XYZ')';
LMSc=(diag(Dp)*LMS')';
XYZc=(inv(MlmsHPE)*LMSc')';

end
