function XYZc=xyz2xyzc(XYZ,XYZtw,Lt,Yb,surround,CATtype);
[m,n]=size(XYZtw);
if m>1
    for i=1:m
        switch CATtype
            case 'CMCCAT'
                 XYZc(i,:)=xyz2xyzcCMCCAT(XYZ(i,:),XYZtw(i,:),[100,100,100],Lt(i,:),1000);
            otherwise
                 XYZc(i,:)=xyz2xyzcCAT02(XYZ(i,:),XYZtw(i,:),Lt(i,:),Yb,surround,CATtype);

        end
    end
else
switch CATtype
    case 'CMCCAT'
                 XYZc=xyz2xyzcCMCCAT(XYZ,XYZtw,[100,100,100],Lt,1000);
    otherwise
                 XYZc=xyz2xyzcCAT02(XYZ,XYZtw,Lt,Yb,surround,CATtype);
    end
end
end
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function XYZc=xyz2xyzcCMCCAT(XYZ,XYZtw,XYZrw,Lt,Lr);
%CMCCAT
MCAT=[0.7982,	0.3389,	-0.1371;
        -0.5918,	1.5512,	0.0406;
        0.0008,	0.0239,	0.9753];
   

MCATi=inv(MCAT);

%degree of adaptation
D=0.08*log10(Lt+Lr)+0.76-0.45*(Lt-Lr)/(Lt+Lr);
if D>1;D=1;end
D=1;%take degree of adaptation=1!

Y=XYZ(:,2);

XYZ=XYZ./repmat(XYZ(:,2),1,3);
XYZtw=XYZtw./XYZtw(2);
XYZrw=XYZrw./XYZrw(2);


% Convert XYZ data to CAT02 LMS space
RGB=(MCAT*XYZ')';
R=RGB(:,1);G=RGB(:,2);B=RGB(:,3);

RGBtw=(MCAT*XYZtw')';
RGBrw=(MCAT*XYZrw')';
Rtw=RGBtw(:,1);Gtw=RGBtw(:,2);Btw=RGBtw(:,3);
Rrw=RGBrw(:,1);Grw=RGBrw(:,2);Brw=RGBrw(:,3);

% Apply chromatic adaptation (
Rc=(D.*(Rrw./Rtw)+1-D).*R;
Gc=(D.*(Grw./Gtw)+1-D).*G;
Bc=(D.*(Brw./Btw)+1-D).*B;

RGBc=[Rc,Gc,Bc];

% Calculate XYZ
XYZc=(MCATi*[Rc,Gc,Bc]')';
XYZc=XYZc.*Y;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function XYZc=xyz2xyzcCAT02(XYZ,XYZ1w,La1,Yb1,surround1,CATtype)

% xyz2xyzc: use CAT02 to calculate XYZc 
%
% Default values for La, Yb, surround and FLL correspond to ISO 3664 P1 set-up
%
% Surround arguments can either be 'avg', 'dim' or 'dark'
% or a vector of numeric values for c, Nc and F. Such values should follow the 
% recommendations in CIE (2004).

switch CATtype
    case 'CAT02'
        %CAT02 chromatic adaptation
         MCAT02=[0.7328,0.4296,-0.1624;
         -0.7036,1.6975,0.0061;
         0.0030,0.0136,0.9834];
         % CAT02 inverse matrix
         %MCAT02i=[1.096124,-0.278869,0.182745;
         %0.454369,0.473533,0.072098;
         %-0.009628,-0.005698,1.015326];
         MCAT=MCAT02;
         MCATi=inv(MCAT02);
    case 'BFD'
         %BFD chromatic adaptation
         MBFD=[0.8951,0.2664,-0.1614;
         -0.7502,1.7135,0.0367;
         0.0389,-0.0685,1.0296];
         MCAT=MBFD;
         MCATi=inv(MBFD);
    case 'SHARP'
         %SHARP chromatic adaptation
         MSHARP=[1.2694,-0.0988,-0.1706;
         -0.8364,1.8006,0.0357;
         0.0297,-0.0315,1.0018];
         MCAT=MSHARP;
         MCATi=inv(MSHARP);
    case 'KRIES'
         %von Kries chromatic adaptation
         MKRIES=[0.3897,0.6890,-0.0787;
         -0.2298,1.1834,0.0464;
         0.0000,0.0000,1.0000];
         MCAT=MKRIES;
         MCATi=inv(MKRIES);
end

%get parameters
F1=1;F2=1;
if nargin>4;    
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
 
else
   c1=0.69;Nc1=1;F1=1; % average surround
    
end 

% Calculate constants for XYZ(Ill. 1) -> XYZc(EE Ill).
Yw=XYZ1w(2);La=La1;F=F1;

D=F*(1-(1/3.6)*exp((-La-42)/92)); %degree of adaptation
%D=1; %take degree of adaptation=1!
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

% Calculate XYZ
XYZc=(MCATi*[Rc,Gc,Bc]')';
%XYZc(XYZc<0)=0;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%