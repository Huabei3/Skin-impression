function JCh=NISSCAM(XYZ,XYZw,La,Yb,surround)
%A Neurophysiology_Inspired Steady State Colour Appearance Model, Timo
%Kunkel and Erik Reinhard; JOSA, Vol. 26, No.4, april 2009.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
F=1;
if nargin>2; else La=2000/(pi*5);end % luminance of adapted white point 
if nargin>3; else Yb=20;end % luminance of background (typically 20)
if nargin>4;
   if isnumeric(surround)
      c=surround(1);Nc=surround(2);
      if length(surround)>2
         F=surround(3);
      else
         F=1;
      end
   elseif ischar(surround)
      s=0; % set flag to see if surround is set
      if strcmp(surround,'avg')||strcmp(surround,'average');c=0.69;Nc=1;F=1;s=1;FLL=1;end % average surround
      if strcmp(surround,'avg4')||strcmp(surround,'average4');c=0.69;Nc=1;F=1;s=1;FLL=0;end % average surround
      if strcmp(surround,'disp')||strcmp(surround,'display');c=0.69;Nc=1;F=0;s=1;FLL=1;end % for computer display colours
      if strcmp(surround,'dim');c=0.59;Nc=0.9;F=0.9;s=1;FLL=1;end % dim surround
      if strcmp(surround,'dark');c=0.525;Nc=0.8;F=0.8;s=1;FLL=1;end % dark surround
      if s<1; % check flag and apply defaults if not set
         c=0.69;Nc=1;F=1;
         disp('Surround not recognised; average surround condition used.')
      end 
   else
      c=0.69;Nc=1;F=1;
      disp('Surround not recognised; average surround condition used.')
   end
else
   c=0.69;Nc=1;F=1; % average surround
end 

% Calculate constants
Yw=XYZw(2); 
D=F*(1-(1/3.6)*exp((-La-42)/92));if D>1;D=1;end;if D<0;D=0;end %degree of adaptation
k=1/(5*La+1);
FL=0.2*k^4*5*La+0.1*(1-k^4)^2*(5*La)^(1/3);
n=Yb/Yw;
Nbb=0.725*(1/n)^0.2;
Ncb=0.725*(1/n)^0.2;
z=1.48+FLL.*n^0.5;

%1. chromatic adaptation and non-linear response compression
MHPE=[0.38971,0.68898,-0.07868;
-.22981,1.1834,0.04641;
0,0,1];
LMS=(MHPE*XYZ')';
LMSw=(MHPE*XYZw')';

%1.1  semi-saturation constant sigma
sigmaLMS=27.13.^(1/0.42).*(D.*(LMSw./100)+(1-D));

%1.2  non_linear response
LMSnlr=400.*((FL.*LMS./100).^0.42)./((FL.*LMS./100).^0.42+sigmaLMS.^0.42)+0.1;
LMSnlrw=400.*((FL.*LMSw./100).^0.42)./((FL.*LMSw./100).^0.42+sigmaLMS.^0.42)+0.1;


%2.  Appearance correlates
%2.1 Achromatic response
A=Nbb*(4.19.*LMSnlr(:,1)+LMSnlr(:,2)+1.17.*LMSnlr(:,3));
Aw=Nbb*(4.19.*LMSnlrw(:,1)+LMSnlrw(:,2)+1.17.*LMSnlrw(:,3));

%2.2 Lightness
J=106.5.*(A./Aw).^(c*z);

%2.3 Chroma
Mc=[-4.5132,3.9899,0.5233;-4.1562,5.2238,-1.0677;7.3984,-2.3007,-0.4156];%chroma opponent space + normalisation factor
abd=(Mc*LMSlnr')';%ab = color opponent space, d is normaisation constant

t=(Nc*Ncb.*sqrt(abd(:,1).^2+abd(:,2).^2))./abd(:,3);

C=(((10^3).*t).^0.9).*sqrt(J./100).*(1.64-0.29.^n).^0.73;% note hue is not used in the calculation of chroma!

%2.4 hue
Mh=[-15.4141,17.1339,-1.7198;-1.6010,-0.7467,2.3476];
abh=(Mh*LMSnlr')';

h=atan(abh(:,2)./abh(:,1));%intermediate hue

rp=max([0,0.6581.*(cos(9.1-h)).^0.5390]);
gp=max([0,0.9482.*(cos(167.0-h)).^2.9435]);
yp=max([0,0.9041.*(cos(90.9-h)).^2.5251]);
bp=max([0,0.7832.*(cos(268.4-h)).^0.2886]);

a2p=rp-gp;
b2p=yp-bp;

hp=atan(b2p./a2p);

JCh=[J,C,hp,a2pb2p];
end


