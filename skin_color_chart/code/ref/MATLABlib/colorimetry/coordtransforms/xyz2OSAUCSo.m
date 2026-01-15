function LJG=xyz2OSAUCSo(xyz)
%calc OSAUCS using equations derived by Oleari
%input xyz are assumed to be the corresponding colours under D65
%xyz(2)=100 for perfect diffuser
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
xyY=xyz2xyY(xyz);
Y0=xyY(:,2).*(4.493*xyY(:,1).^2+4.3034.*xyY(:,2).^2-4.276.*xyY(:,1).*xyY(:,2)-1.3744.*xyY(:,1)-2.5643.*xyY(:,2)+1.8103);

Lc=5.9*(Y0.^(1/3)-2/3+(Y0>30).*0.042.*abs(Y0-30).^(1/3)-(Y0<=30).*0.042.*abs(Y0-30).^(1/3));
L=(Lc-14.4)./sqrt(2);

%calc main chromatic opponency functions
T_10_D65=[0.6597 0.4492 -0.1089;-0.3053 1.2126 0.0927;-0.0374 0.4795 0.5579];%transformation matrix T: paper by Oleari, CRA 2004: Hypotheses for chromatic opponency functions and their performance on classical psychophysical data
ABC=(T_10_D65*xyz')';

%calculate  J & G
SJ=2*(0.5735*L+7.0892);SG=-2*(0.7640*L+9.2521);
alpha=-10.31*pi/180;
beta=71.46*pi/180;
AndivBn=0.93655;BndivCn=0.98074; %ratios of the main tristimulus values related to the D65 white point

JG=([SJ 0;0 SG]*[-sin(alpha) cos(alpha);sin(beta) -cos(beta)]*[log((ABC(:,1)./ABC(:,2))./AndivBn)';log((ABC(:,2)./ABC(:,3))./BndivCn)'])';

LJG=[L,JG];
end