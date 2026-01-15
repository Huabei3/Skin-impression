function XYZc=xyz2xyzcCAT02_(XYZ,XYZ1w,XYZ2w,La,surround)
%calculates corresponding colours XYZc using the CAT02 chromatic adaptation transform
%Input:
%   XYZ = input tristimulus values
%   XYZ1w = adapting white point under test source
%   XYZ2w = adapting white point under reference source
%   La = adapting luminance of test source (if La<=1, then La = degree of adaptation)
%   surround =  surround conditions ('average', 'dark', 'dim' or 'disp')
%Output:
%   XYZc = corresponding colours under reference source
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%CAT02 chromatic adaptation
MCAT02=[0.7328,0.4296,-0.1624;
-0.7036,1.6975,0.0061;
0.0030,0.0136,0.9834];
MCAT=MCAT02;

% CAT02 inverse matrix
MCATi=inv(MCAT02);
    
%get parameters
if nargin>4;    
switch surround
    case 'avg' 
        F=1;
    case 'average'
        F=1;
    case 'disp'
        F=0;
    case 'dim'
        F=0.9;
    case 'dark'
        F=0.8;
    otherwise
        F=1;
end
else;
    F=1;
end

% Calculate constants for XYZ(Ill. 1) -> XYZc(Ill. 2).
D=F*(1-(1/3.6)*exp((-La-42)/92)); %degree of adaptation
if La<=1;D=abs(La);end
alpha=XYZ1w(2)./XYZ2w(2);
%_________________________________

% Convert XYZ data to CAT02 LMS space
RGB=(MCAT*XYZ')';
R=RGB(:,1);G=RGB(:,2);B=RGB(:,3);
RGBw=(MCAT*XYZ1w')';
Rw=RGBw(:,1);Gw=RGBw(:,2);Bw=RGBw(:,3);

RGBw2=(MCAT*XYZ2w')';
Rw2=RGBw2(:,1);Gw2=RGBw2(:,2);Bw2=RGBw2(:,3);


% Apply chromatic adaptation (Ill. 1 --> Ill.2)
Rc=(alpha.*D*(Rw2./Rw)+1-D).*R;
Gc=(alpha.*D*(Gw2./Gw)+1-D).*G;
Bc=(alpha.*D*(Bw2./Bw)+1-D).*B;

RGBc=[Rc,Gc,Bc];

% Calculate XYZ
XYZc=(MCATi*[Rc,Gc,Bc]')';
XYZc(XYZc<0)=0;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%