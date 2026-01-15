function XYZc=xyz2xyzcCMCCAT(XYZ,XYZtw,XYZrw,Lt,Lr);
%calculates corresponding colours XYZc using the CMCCAT chromatic adaptation transform
%Input:
%   XYZ = input tristimulus values
%   XYZtw = adapting white point under test source
%   XYZrw = adapting white point under reference source
%   Lt = adapting luminance of test source
%   Lr = adapting luminance of reference source
%Output:
%   XYZc = corresponding colours under reference source
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%CMCCAT
MCAT02=[0.7982,	0.3389,	-0.1371;
        -0.5918,	1.5512,	0.0406;
        0.0008,	0.0239,	0.9753];
MCAT=MCAT02;
   

MCATi=inv(MCAT);

%degree of adaptation
D=0.08*log10(Lt+Lr)+0.76-0.45*(Lt-Lr)/(Lt+Lr);
if D>1;D=1;end

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