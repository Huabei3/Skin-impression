function jab=xyz2camucs(xyz,xyzw,LA,Yb,surround,Did);
% xyz2camucs for use in cri engines (yellow an purple problems have been
% fixed). Default surround input as in CRI2012/CRI2014.
if nargin < 6; Did = 1;end
if nargin < 5; surround=[1,1,0.69];end
if nargin < 4; Yb = 20;end
if nargin < 3; LA=100; end
if isnumeric(surround);
    F = surround(1);
    Nc = surround(2);
    c = surround(3);
else
      if strcmp(surround,'avg')||strcmp(surround,'average');c=0.69;Nc=1;F=1;s=1;FLL=1;end % average surround
      if strcmp(surround,'avg4')||strcmp(surround,'average4');c=0.69;Nc=1;F=1;s=1;FLL=0;end % average surround
      if strcmp(surround,'disp')||strcmp(surround,'display');c=0.69;Nc=1;F=0;s=1;FLL=1;end % for computer display colours
      if strcmp(surround,'dim');c=0.59;Nc=0.9;F=0.9;s=1;FLL=1;end % dim surround
      if strcmp(surround,'dark');c=0.525;Nc=0.8;F=0.8;s=1;FLL=1;end % dark surround
end

[J,C,H,M,s,Q,h,Hc,D,A,td,InfSucFail]=CIECAM02ForwardM(xyz,xyzw,Yb,Did,F,Nc,c,LA);

Jc=(1+100*0.007)*J./(1+0.007*J);
Mc=(1/0.0228)*log(1+0.0228*M);
aMc=Mc.*cos(h*pi/180);
bMc=Mc.*sin(h*pi/180);
jab=[Jc',aMc',bMc'];
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%  ciecam02 ,  matrix form
%  input:  
%   XYZ, 3 by n matrix
%   XYZW, 3 by 1 vector, the trisstimulus values of the light source
%  Did  =  1,   D=1
%          otherwise,  D is computed using formula
% output
% J, C, H, M,s,Q,h : all are 1 by n 
% Hc: Hue composition
%      Hc.percentage, gives the percentage (integers) of Red, Geen, Yellow or Blue
%      Hc.Colour, gives the corresponding colours
%      30B 70G
%      Hc.percentage, gives 30   70
%      Hc.Colour,    B   G
%   InfSucFail: 1 by n vectors
%               1    means sucessfully predicted the pereptual attributes
%               0    fails to predict the perceptual attributes
function [J,C,H,M,s,Q,h,Hc,D,A,td,InfSucFail]=CIECAM02ForwardM(XYZ,XYZW,Yb,Did,F,Nc,c,LA)
% % setup the CAT02 matrix
% MCAT02=[ 0.7328, 0.4296, -0.1624;
%         -0.7036, 1.6975, 0.0061;
%         0.0030,  0.0136, 0.9834];
% %  set up the inverse of MCAT02
% INVMCAT02=[ 1.096124    -0.278869    0.182745;
%             0.454369     0.473533    0.072098;
%            -0.009628    -0.005698    1.015326];
       
%use adjusted CAT02 (3rd line)to solve yellow-blue gamut problem      
MCAT02=[ 0.7328, 0.4296, -0.1624;        -0.7036, 1.6975, 0.0061;        0,  0, 1];
INVMCAT02=  inv(MCAT02);

%setup the HPE matrix
MHPE=[ 0.38971,  0.68898,  -0.07868;
      -0.22981,  1.18340,   0.04641;
      0.00000,  0.0000,     1.00000];
  
%  step 1
RGBW=MCAT02*XYZW';
RGB=MCAT02*XYZ';

% step 2
if Did==1
    D=1;
else
    if isempty(Did);Did=1;end
    if Did <=1;D=abs(Did);else;D=F*(1-exp(-(LA+42)/92)/3.6);end
    
end
temp=ones(3,1);
DRGB=inv( diag(RGBW) )*temp*(D*XYZW(2))  +  (1-D)*temp  ;

%Step 3
RGBC=diag(DRGB)*RGB;
RGBWC=diag(DRGB)*RGBW;

% step 4
k=1/(5*LA+1);
FL=0.2*(k^4)*(5*LA) + 0.1*( (1-k^4)^2 )*(5*LA)^(1/3);
n=Yb/XYZW(2);
z=1.48+n^0.5;
Nbb=0.725*(1/n)^0.2;
Ncb=Nbb;

%Step 5
RGB1=MHPE*INVMCAT02*RGBC;
RGBW1=MHPE*INVMCAT02*RGBWC;

%solve purple problem! with CAT02 based CAT transform
RGB1=MHPE*INVMCAT02*RGBC;RGB1(RGB1<0)=0;
RGBW1=MHPE*INVMCAT02*RGBWC;RGBW1(RGBW1<0)=0;

%step 6
RGBA1=CAM02RGBA1M(RGB1,FL);
RGBAW1=CAM02RGBA1M(RGBW1,FL);

%step 7, a and b are row vectors
a=RGBA1(1,:)-12*RGBA1(2,:)/11+RGBA1(3,:)/11;
b=(RGBA1(1,:)+RGBA1(2,:)-2*RGBA1(3,:))/9;

%  h is a row vector 
h=HueAngle(a,b);

% step 8
ColourName=[' Red  ';'Yellow';'Green ';' Blue ';' Red  '];
HueTable=[1       2        3       4       5;
          20.14   90.0    164.25  237.53   380.14;
          0.8    0.7      1.0      1.2      0.8;
          0.     100.0    200.0   300.0    400.0];
%
s1=h<20.14;
s2=h>=20.14;
h1=s1.*(h+360)+s2.*h;
%
s1=h1<HueTable(2,2);
s2=(h1>=HueTable(2,2))&(h1<HueTable(2,3));
s3=(h1>=HueTable(2,3))&(h1<HueTable(2,4));
s4=(h1>=HueTable(2,4))&(h1<=HueTable(2,5));
%
et=0.25*( cos(h1*pi/180+2) +3.8 );
e=et*(50000/13)*Nc*Ncb;
%
i=1;
H1=HueTable(4,i)+100*( (h1-HueTable(2,i))/HueTable(3,i) )./( (h1-HueTable(2,i))/HueTable(3,i) + (HueTable(2,i+1)-h1)/HueTable(3,i+1) );
i=2;
H2=HueTable(4,i)+100*( (h1-HueTable(2,i))/HueTable(3,i) )./( (h1-HueTable(2,i))/HueTable(3,i) + (HueTable(2,i+1)-h1)/HueTable(3,i+1) );
i=3;
H3=HueTable(4,i)+100*( (h1-HueTable(2,i))/HueTable(3,i) )./( (h1-HueTable(2,i))/HueTable(3,i) + (HueTable(2,i+1)-h1)/HueTable(3,i+1) );
i=4;
H4=HueTable(4,i)+100*( (h1-HueTable(2,i))/HueTable(3,i) )./( (h1-HueTable(2,i))/HueTable(3,i) + (HueTable(2,i+1)-h1)/HueTable(3,i+1) );
H=s1.*H1+s2.*H2+s3.*H3+s4.*H4;
%
kk=floor(H/100);
Hp=round( 100*((H/100)-kk ) );
i=kk+1;
%Hc = struct( 'percentage',{Hp 100-Hp},'Colour',{ColourName(i+1,1:6), ColourName(i,1:6) } );
Hc={'disabled'};

% Step 9
ca=[2 1 1/20];
aaa=sum(ca)*0.1;
A=Nbb*( ca*RGBA1- aaa );
AW=Nbb*( ca*RGBAW1 - aaa );

% step 10
s1=A<0;
s2=A>=0;
J = 100*((s2.*A)./AW).^(c*z)+999*s1;

%step 11
Q=s2.*( (4/c)*( (J/100).^0.5 ).*(AW+4)*FL^0.25 ) + 999*s1;

%step 12
td=RGBA1(1,:)+RGBA1(2,:)+RGBA1(3,:)*(21/20);
s3=td<=0;
s4=td>0;
InfSucFail=(s1+s3)<0.5;
t=s4.* ( ( e.*( a.^2+b.^2 ).^0.5 )./(s4.*td +s3)  )+s3*999;
C=s4.* ( (t.^0.9).*( (J/100).^0.5)*(1.64-0.29^n)^0.73 ) + s3*999;
M=s4.* ( C*FL^0.25 ) + s3*999;
s1=Q==0;
s2=Q>0;
s=s2.* (100*(M./(Q+s1)).^0.5) + 0*s1;

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compute RGBa' named RGBA1 for the forward model in step 6
function RGBA1=CAM02RGBA1M(RGB,FL)
temp=FL*RGB/100;
temp2=(abs(temp)).^0.42;
temp3=27.13+temp2;
temp4=(400*temp2)./temp3;
s1=temp>=0;
s2=temp<0;
RGBA1=(s1.*temp4)-s2.*temp4 +0.1;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% hue angle calculation for given a and b:  a  horizontal axis, and b the vertical axis
% a and b can be vector. In this case, h is also a vector.
% if a and b are row vector, then h is row vector, and a and b are column
% vectors, then h is column vector too.
%
function h=HueAngle(a,b)
h=atan2(b,a)*180/pi;
s1=h<0;
s2=h>=0;
h1=(h+360).*s1;
h2=h.*s2;
h=h1+h2;
end
