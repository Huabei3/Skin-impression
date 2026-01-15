function XYZ=jab2xyzcamucs_(Jab,XYZw,La,Yb,surround,Did);
%calculate Jab (CAM02-UCS) back to XYZ
%inputs: Jab,XYZw,La,Yb,surround
% for use in cri engines (yellow an purple problems have been
% fixed). Default surround input as in CRI2012/CRI2014.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 6; Did = 1;end
if nargin < 5; surround=[1,1,0.69];end
if nargin < 4; Yb = 20;end
if nargin < 3; La=100; end
if isnumeric(surround);
    F = surround(1);
    Nc = surround(2);
    c = surround(3);
end

%J2=Jab(:,1);M2=Jab(:,2);h=Jab(:,3);
J2=Jab(:,1);a=Jab(:,2);b=Jab(:,3);
%calc CAM02 hue angle
h=hue_angle(a,b);
%calc CAM02 colourfulness
M2=(a.^2+b.^2).^0.5;
c1=0.007;
c2=0.0228;
M=(exp(c2*M2)-1)/c2;
%calc CAM02 lightness
J=J2./(1+(100-J2).*c1);

%calc CAM02 Chroma
Yw=XYZw(2); 
D=F*(1-(1/3.6)*exp((-La-42)/92)); %degree of adaptation
k=1/(5*La+1);
FL=0.2*k^4*5*La+0.1*(1-k^4)^2*(5*La)^(1/3);
C=M./FL^0.25;

%CIECAM02 JCh
JCh=[J,C,h];

%convert JCH to XYZ
if nargin==7;
    XYZ=jch2xyzcam02c(JCh,XYZw,La,Yb,surround,Did,MCAT);
else
    XYZ=jch2xyzcam02c(JCh,XYZw,La,Yb,surround,Did);
end
