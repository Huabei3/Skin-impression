function XYZ=JabCAM02UCS2XYZ(Jab,XYZw,La,Yb,surround);
%calculate Jab (CAM02-UCS) back to XYZ
%inputs: Jab,XYZw,La,Yb,surround
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if isnumeric(surround)
      c=surround(1);Nc=surround(2);
      if length(surround)>2
         F=surround(3);
      else
         F=1;
      end
   elseif ischar(surround)
      s=0; % set flag to see if surround is set
      if strcmp(surround,'avg')||strcmp(surround,'average');c=0.69;Nc=1;F=1;s=1;end % average surround
      if strcmp(surround,'disp')||strcmp(surround,'display');c=0.69;Nc=1;F=0;s=1;end % for computer display colours
      if strcmp(surround,'dim');c=0.59;Nc=0.9;F=0.9;s=1;end % dim surround
      if strcmp(surround,'dark');c=0.525;Nc=0.8;F=0.8;s=1;end % dark surround
      if s<1; % check flag and apply defaults if not set
         c=0.69;Nc=1;F=1;
         disp('Surround not recognised; average surround condition used.')
      end 
   else
      c=0.69;Nc=1;F=1;
      disp('Surround not recognised; average surround condition used.')
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
XYZ=jch2xyzcam02c(JCh,XYZw,La,Yb,surround);
