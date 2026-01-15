function CAM=xyz2cam02(XYZ,XYZw,La,Yb,surround,MCAT)

% XYZ2CAM02: forward model of CIECAM02
% calculates appearance coordinates J, C, h, Q, M, ac, bc and s
%
% CAM=XYZ2CAM02(XYZ,XYZw,La,Yb,surround)
% Calculation as described in CIE Technical Report 159 'A Colour 
% Appearance Model for Colour Management Systems' (CIE, 2004).
%
% Default values for La, Yb, surround and FLL correspond to ISO 3664 P1 set-up
%
% Surround arguments can either be 'avg', 'dim' or 'dark'
% or a vector of numeric values for c, Nc and F. Such values should follow the 
% recommendations in CIE (2004).
%
% Example: CAM=xyz2cam02(XYZ) 
% The following yield the same results:
%          CAM=xyz2cam02(XYZ,d(50),63.66,20,'avg')
%          CAM=xyz2cam02(XYZ,[96.42,100,82.49],63.66,20,[0.69,1,1])
%
%   Colour Engineering Toolbox
%   author:    © Phil Green
%   version:   1.2
%   date:  	   08-12-2004
%   book:      http://www.wileyeurope.com/WileyCDA/WileyTitle/productCd-0471486884.html
%   web:       http://www.digitalcolour.org

% Get parameters

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

if length(XYZw(:,2))>1;XYZtemp=XYZ;XYZwtemp=XYZw;
    for i=1:length(XYZw(:,2));
        XYZ=XYZtemp(i,:);
        XYZw=XYZwtemp(i,:);
Yw=XYZw(2); 
D=F*(1-(1/3.6)*exp((-La-42)/92));if D>1;D=1;end;if D<0;D=0;end %degree of adaptation
k=1/(5*La+1);
FL=0.2*k^4*5*La+0.1*(1-k^4)^2*(5*La)^(1/3);
n=Yb/Yw;
Nbb=0.725*(1/n)^0.2;
Ncb=0.725*(1/n)^0.2;
z=1.48+FLL.*n^0.5;

% CAT02 forward matrix
MCAT02=[0.7328,0.4296,-0.1624;
-0.7036,1.6975,0.0061;
0.0030,0.0136,0.9834];

% Hunt-Pointer-Estevez matrix
MH=[0.38971,0.68898,-0.07868;
-.22981,1.1834,0.04641;
0,0,1];

% CAT02 inverse matrix
MCAT02i=[1.096124,-0.278869,0.182745;
0.454369,0.473533,0.072098;
-0.009628,-0.005698,1.015326];

 if nargin==6;MCAT02=MCAT;MCAT02i=inv(MCAT);end
% Pre-multiply inverse CAT02 and HPE matrices
MHM=MH*MCAT02i;

% Convert XYZ data to CAT02 LMS space
RGB=(MCAT02*XYZ')';
R=RGB(:,1);G=RGB(:,2);B=RGB(:,3);

RGBw=(MCAT02*XYZw')';
Rw=RGBw(:,1);Gw=RGBw(:,2);Bw=RGBw(:,3);

% Apply chromatic adaptation (ref ill. = equal energy ill. and ref white =
% perfect refl.diff. (Rwr=Gwr=Bwr and Ywr=100)
% 
Rc=(Yw*(D/Rw)+1-D)*R;
Gc=(Yw*(D/Gw)+1-D)*G;
Bc=(Yw*(D/Bw)+1-D)*B;
RGBc=[Rc,Gc,Bc];
XYZc=(inv(MCAT02)*RGBc')';
% Convert to Hunt-Pointer-Estevez space
RGBp=(MHM*[Rc,Gc,Bc]')';
Rp=RGBp(:,1);Gp=RGBp(:,2);Bp=RGBp(:,3);
t1=Rp<0;t2=Gp<0;t3=Bp<0;

% Apply post-adaptation non-linear compression
Rpa=0.1+((400*(FL*Rp/100).^0.42)./(27.13+(FL*Rp/100).^0.42));
Rpa(t1)=0.1-((400*(FL*abs(Rp(t1))/100).^0.42)./(27.13+(FL*abs(Rp(t1))/100).^0.42));
Gpa=0.1+((400*(FL*Gp/100).^0.42)./(27.13+(FL*Gp/100).^0.42));
Gpa(t2)=0.1-((400*(FL*abs(Gp(t2))/100).^0.42)./(27.13+(FL*abs(Gp(t2))/100).^0.42));
Bpa=0.1+((400*(FL*Bp/100).^0.42)./(27.13+(FL*Bp/100).^0.42));
Bpa(t3)=0.1-((400*(FL*abs(Bp(t3))/100).^0.42)./(27.13+(FL*abs(Bp(t3))/100).^0.42));

% Calculate temporary Cartesian coordinates
a=Rpa-Gpa*12/11+Bpa/11;
b=(Rpa+Gpa-2*Bpa)/9;

   % Calculate Aw
   RGBw=(MCAT02*XYZw')';
   Rw=RGBw(:,1);Gw=RGBw(:,2);Bw=RGBw(:,3);

   Rcw=(Yw*(D/Rw)+1-D)*Rw;
   Gcw=(Yw*(D/Gw)+1-D)*Gw;
   Bcw=(Yw*(D/Bw)+1-D)*Bw;

   RGBpw=(MHM*[Rcw,Gcw,Bcw]')';
   Rpw=RGBpw(:,1);Gpw=RGBpw(:,2);Bpw=RGBpw(:,3);

   Rpaw=0.1+((400*(FL*Rpw/100).^0.42)./(27.13+(FL*Rpw/100).^0.42));
   Gpaw=0.1+((400*(FL*Gpw/100).^0.42)./(27.13+(FL*Gpw/100).^0.42));
   Bpaw=0.1+((400*(FL*Bpw/100).^0.42)./(27.13+(FL*Bpw/100).^0.42));

   Aw=(2*Rpaw+Gpaw+0.05*Bpaw-0.305)*Nbb; % achromatic signal of white

A=(2*Rpa+Gpa+0.05*Bpa-0.305)*Nbb; % achromatic signal of stimulus
J=100*(A/Aw).^(c*z); % lightness

h=(180/pi)*atan2(b,a); % hue angle
j=(b<0);h(j)=h(j)+360;

et=(Nc*Ncb*12500/13)*(cos(h*pi/180+2)+3.8); % eccentricity factor
t=(et.*(a.^2+b.^2).^.5)./(Rpa+Gpa+(21/20)*Bpa); % temporary magnitude
Q=(4/c)*(J/100).^.5*(Aw+4)*FL.^0.25; % brightness
C=t.^.9.*(J/100).^.5*(1.64-0.29^n).^.73; % chroma
M=C*FL^0.25; % colourfulness
s=100*(M./Q).^.5; % saturation
ac=C.*cos(h*pi/180); % redness-greenness Cartesian coordinates
bc=C.*sin(h*pi/180); % blueness-yellowness Cartesian coordinates

CAM(i,:)=[J,C,h,Q,M,ac,bc,s];
    end
else
    Yw=XYZw(2); 
D=F*(1-(1/3.6)*exp((-La-42)/92));if D>1;D=1;end;if D<0;D=0;end %degree of adaptation
k=1/(5*La+1);
FL=0.2*k^4*5*La+0.1*(1-k^4)^2*(5*La)^(1/3);
n=Yb/Yw;
Nbb=0.725*(1/n)^0.2;
Ncb=0.725*(1/n)^0.2;
z=1.48+FLL.*n^0.5;

% CAT02 forward matrix
MCAT02=[0.7328,0.4296,-0.1624;
-0.7036,1.6975,0.0061;
0.0030,0.0136,0.9834];

% Hunt-Pointer-Estevez matrix
MH=[0.38971,0.68898,-0.07868;
-.22981,1.1834,0.04641;
0,0,1];

% CAT02 inverse matrix
MCAT02i=[1.096124,-0.278869,0.182745;
0.454369,0.473533,0.072098;
-0.009628,-0.005698,1.015326];

% Pre-multiply inverse CAT02 and HPE matrices
MHM=MH*MCAT02i;

% Convert XYZ data to CAT02 LMS space
RGB=(MCAT02*XYZ')';
R=RGB(:,1);G=RGB(:,2);B=RGB(:,3);

RGBw=(MCAT02*XYZw')';
Rw=RGBw(:,1);Gw=RGBw(:,2);Bw=RGBw(:,3);

% Apply chromatic adaptation (ref ill. = equal energy ill. and ref white =
% perfect refl.diff. (Rwr=Gwr=Bwr and Ywr=100)
% 
Rc=(Yw*(D/Rw)+1-D)*R;
Gc=(Yw*(D/Gw)+1-D)*G;
Bc=(Yw*(D/Bw)+1-D)*B;
RGBc=[Rc,Gc,Bc];
XYZc=(inv(MCAT02)*RGBc')';

% Convert to Hunt-Pointer-Estevez space
RGBp=(MHM*[Rc,Gc,Bc]')';
Rp=RGBp(:,1);Gp=RGBp(:,2);Bp=RGBp(:,3);
t1=Rp<0;t2=Gp<0;t3=Bp<0;

% Apply post-adaptation non-linear compression
Rpa=0.1+((400*(FL*Rp/100).^0.42)./(27.13+(FL*Rp/100).^0.42));
Rpa(t1)=0.1-((400*(FL*abs(Rp(t1))/100).^0.42)./(27.13+(FL*abs(Rp(t1))/100).^0.42));
Gpa=0.1+((400*(FL*Gp/100).^0.42)./(27.13+(FL*Gp/100).^0.42));
Gpa(t2)=0.1-((400*(FL*abs(Gp(t2))/100).^0.42)./(27.13+(FL*abs(Gp(t2))/100).^0.42));
Bpa=0.1+((400*(FL*Bp/100).^0.42)./(27.13+(FL*Bp/100).^0.42));
Bpa(t3)=0.1-((400*(FL*abs(Bp(t3))/100).^0.42)./(27.13+(FL*abs(Bp(t3))/100).^0.42));

% Calculate temporary Cartesian coordinates
a=Rpa-Gpa*12/11+Bpa/11;
b=(Rpa+Gpa-2*Bpa)/9;

   % Calculate Aw
   RGBw=(MCAT02*XYZw')';
   Rw=RGBw(:,1);Gw=RGBw(:,2);Bw=RGBw(:,3);

   Rcw=(Yw*(D/Rw)+1-D)*Rw;
   Gcw=(Yw*(D/Gw)+1-D)*Gw;
   Bcw=(Yw*(D/Bw)+1-D)*Bw;

   RGBpw=(MHM*[Rcw,Gcw,Bcw]')';
   Rpw=RGBpw(:,1);Gpw=RGBpw(:,2);Bpw=RGBpw(:,3);

   Rpaw=0.1+((400*(FL*Rpw/100).^0.42)./(27.13+(FL*Rpw/100).^0.42));
   Gpaw=0.1+((400*(FL*Gpw/100).^0.42)./(27.13+(FL*Gpw/100).^0.42));
   Bpaw=0.1+((400*(FL*Bpw/100).^0.42)./(27.13+(FL*Bpw/100).^0.42));

   Aw=(2*Rpaw+Gpaw+0.05*Bpaw-0.305)*Nbb; % achromatic signal of white

A=(2*Rpa+Gpa+0.05*Bpa-0.305)*Nbb; % achromatic signal of stimulus
J=100*(A/Aw).^(c*z); % lightness

h=(180/pi)*atan2(b,a); % hue angle
j=(b<0);h(j)=h(j)+360;

et=(Nc*Ncb*12500/13)*(cos(h*pi/180+2)+3.8); % eccentricity factor
t=(et.*(a.^2+b.^2).^.5)./(Rpa+Gpa+(21/20)*Bpa); % temporary magnitude
Q=(4/c)*(J/100).^.5*(Aw+4)*FL.^0.25; % brightness
C=t.^.9.*(J/100).^.5*(1.64-0.29^n).^.73; % chroma
M=C*FL^0.25; % colourfulness
s=100*(M./Q).^.5; % saturation
ac=C.*cos(h*pi/180); % redness-greenness Cartesian coordinates
bc=C.*sin(h*pi/180); % blueness-yellowness Cartesian coordinates

CAM=[J,C,h,Q,M,ac,bc,s,A];
end