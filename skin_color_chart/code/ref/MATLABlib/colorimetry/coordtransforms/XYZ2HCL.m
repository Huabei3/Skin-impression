function HCL=xyz2HCL(XYZ)
%XYZ 2 new color space HCL (article by Sarifuddin M & Misaoui R.)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%transform XYZ to RGB
Mxyz2srgb=inv([2.76888,1.75175,1.13016;1.00000,4.59070,0.06010;0.00000,0.05651,5.59427]); %CIE RGB
%Mxyz2srgb= [3.240479, -1.537150, -0.498535;-0.969256,  1.875992,0.041556;0.055648, -0.204043,  1.057311];%sRGB
%Mxyz2srgb= [2.04148,    -0.969258,    0.0134455;-0.564977,    1.87599,    -0.118373;-0.344713,    0.0415557,   1.01527];%AdobeRGB 1998 
%Mxyz2srgb=[0.7328,0.4296,-0.1624;-0.7036,1.6975,0.0061;0.0030,0.0136,0.9834]; %MCAT02 RGB
%Mxyz2srgb=[0.8951,0.2664,-0.1614;-0.7502,1.7135,0.0367;0.0389,-0.0685,1.0296];%BFD RGB

%XYZ=XYZ./max(max(max(XYZ)));
RGB=(Mxyz2srgb*XYZ')';
RGB=255*RGB./max(max(max(RGB)))
Y0=100;
alpha=(min(RGB')'./max(RGB')')./Y0;
gamma=3;
Q=exp(alpha*gamma);
L=(Q.*max(RGB')'+(1-Q).*min(RGB')')/2;%luminance
C=Q.*(abs(RGB(:,1)-RGB(:,2))+abs(RGB(:,2)-RGB(:,3))+abs(RGB(:,3)-RGB(:,1)))/3;%Chroma
H=(180/pi)*atan((RGB(:,2)-RGB(:,3))./(RGB(:,1)-RGB(:,2)));%Hue : -90<H<90
H1=((RGB(:,1)-RGB(:,2))>=0 & (RGB(:,2)-RGB(:,3)>=0)).*((2/3)*H); % H ---> 0<H<300;
H2=((RGB(:,1)-RGB(:,2))>=0 & (RGB(:,2)-RGB(:,3)<0)).*((4/3)*H);
H3=((RGB(:,1)-RGB(:,2))<0 & (RGB(:,2)-RGB(:,3)>=0)).*((4/3)*H + 180);
H4=((RGB(:,1)-RGB(:,2))<0 & (RGB(:,2)-RGB(:,3)<0)).*((3/4)*H - 180);
H=H1+H2+H3+H4;
H=(H>=0).*H+(H<0).*(H+360);
HCL=[H,C,L];