
function [XYZc,D12]=xyz2xyzcCAT02(XYZ,XYZ1w,XYZ2w,La1,La2,Yb1,Yb2,surround1,surround2,D1,D2)
%calculates corresponding colours XYZc using the CAT02 chromatic adaptation transform
%Input:
%   XYZ = input tristimulus values
%   XYZ1w = adapting white point under test source
%   XYZ2w = adapting white point under reference source
%   La1 = adapting luminance of test source 
%   La2 = adapting luminance of reference source 
%   Yb1 = background luminance under test source in percent of white luminance 
%   Yb2 = background luminance under reference source in percent of white luminance
%   surround1 =  surround conditions under test source ('average', 'dark', 'dim' or 'disp')
%   surround2 =  surround conditions under reference source ('average', 'dark', 'dim' or 'disp')
%       Note :
%           Default values for La, Yb, surround and FLL correspond to ISO 3664 P1 set-up
%           Surround arguments can either be 'avg', 'dim' or 'dark' or a vector of numeric 
%           values for c, Nc and F. Such values should follow the recommendations in CIE (2004).
%   D1,D2: optional 'degrees of adaptation' that override the inputted La1 &  La2
%Output:
%   XYZc = corresponding colours under reference source
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
CATtype='CAT02';
MCAT02=[0.7328,0.4296,-0.1624;
         -0.7036,1.6975,0.0061;
         0.0030,0.0136,0.9834];
         % CAT02 inverse matrix
MCAT=MCAT02;
MCATi=inv(MCAT02);

%get parameters
F1=1;F2=1;
if nargin>3; else La1=XYZ1w(2)/5; La2=XYZ2w(2)/5;end % La = 20% of luminance of adapted white point 
if nargin>5; else Yb1=20; Yb2= 20;  end % luminance of background (typically 20)
if nargin>7;
    
   %surround1________________________________
   if isnumeric(surround1)
      c1=surround1(1);Nc1=surround1(2);
      if length(surround1)>2
         F1=surround1(3);
      else
         F1=1;
      end
   elseif ischar(surround1)
      s1=0; % set flag to see if surround is set
      if strcmp(surround1,'avg')||strcmp(surround1,'average');c1=0.69;Nc1=1;F1=1;s1=1;end % average surround
      if strcmp(surround1,'disp')||strcmp(surround1,'display');c1=0.69;Nc1=1;F1=0;s1=1;end % for computer display colours
      if strcmp(surround1,'dim');c1=0.59;Nc1=0.9;F1=0.9;s1=1;end % dim surround
      if strcmp(surround1,'dark');c1=0.525;Nc1=0.8;F1=0.8;s1=1;end % dark surround
      if s1<1; % check flag and apply defaults if not set
         c1=0.69;Nc1=1;F1=1;
         disp('Surround not recognised; average surround condition used.')
      end 
   else
      c1=0.69;Nc1=1;F1=1;
      disp('Surround not recognised; average surround condition used.')
   end
   %end surround1_________________________________
   
   %surround2_____________________________________
      if isnumeric(surround2)
      c2=surround2(1);Nc2=surround2(2);
      if length(surround2)>2
         F2=surround2(3);
      else
         F2=1;
      end
   elseif ischar(surround2)
      s2=0; % set flag to see if surround is set
      if strcmp(surround2,'avg')||strcmp(surround2,'average');c2=0.69;Nc2=1;F2=1;s2=1;end % average surround
      if strcmp(surround2,'disp')||strcmp(surround2,'display');c2=0.69;Nc2=1;F2=0;s2=1;end % for computer display colours
      if strcmp(surround2,'dim');c2=0.59;Nc2=0.9;F2=0.9;s2=1;end % dim surround
      if strcmp(surround2,'dark');c2=0.525;Nc2=0.8;F2=0.8;s2=1;end % dark surround
      if s2<1; % check flag and apply defaults if not set
         c2=0.69;Nc2=1;F2=1;
         disp('Surround not recognised; average surround condition used.')
      end 
   else
      c2=0.69;Nc2=1;F2=1;
      disp('Surround not recognised; average surround condition used.')
    end
   %end surround2________________________________________________
else
   c1=0.69;Nc1=1;F1=1; % average surround
    c2=0.69;Nc2=1;F2=1;
end 

% Calculate constants for XYZ(Ill. 1) -> XYZc(EE Ill).
Yw=XYZ1w(2);La=La1;F=F1;

D=F*(1-(1/3.6)*exp((-La-42)/92)); %degree of adaptation
if nargin>9;if ~isempty(D1);D=D1;end;end
D12(1)=D;
%_________________________________

% Convert XYZ data to CAT02 LMS space

RGB=(MCAT*XYZ')';
R=RGB(:,1);G=RGB(:,2);B=RGB(:,3);

RGBw=(MCAT*XYZ1w')';
Rw=RGBw(:,1);Gw=RGBw(:,2);Bw=RGBw(:,3);

% Apply chromatic adaptation (Ill. 1 --> Ill. EE)
Rc=(Yw*(D/Rw)+1-D)*R;
Gc=(Yw*(D/Gw)+1-D)*G;
Bc=(Yw*(D/Bw)+1-D)*B;

RGBc=[Rc,Gc,Bc];
%XYZctemp=(inv(MCAT02)*RGBc')';

% Calculate constants for XYZc(EE Ill.) -> XYZc(Ill. 2).
Yw=XYZ2w(2);
La=La2;F=F2;
D=F*(1-(1/3.6)*exp((-La-42)/92));%degree of adaptation
if nargin>10;if ~isempty(D2);D=D2;end;end
D12(2)=D;
%RGBc=(MCAT02*XYZc')';
%Rc=RGBc(:,1);Gc=RGBc(:,2);Bc=RGBc(:,3);

RGBw=(MCAT*XYZ2w')';
Rw=RGBw(:,1);Gw=RGBw(:,2);Bw=RGBw(:,3);

%apply inverse chromatic adaptation from Ill. EE to Ill. 2
R=Rc/(Yw*(D/Rw)+1-D);
G=Gc/(Yw*(D/Gw)+1-D);
B=Bc/(Yw*(D/Bw)+1-D);

% Calculate XYZ
XYZc=(MCATi*[R,G,B]')';
XYZc(XYZc<0)=0;
