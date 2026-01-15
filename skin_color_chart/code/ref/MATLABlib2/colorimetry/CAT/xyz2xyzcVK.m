function XYZi2 = xyz2xyzcVK(XYZi1,XYZw1,XYZw2,XYZ0,D1,D2,MCAT)
% Calculate corresponding colors: 
%   transform XYZi under XYZw1 to XYZi2 under XYZw2
%   D1: degree of adaptation under XYZw1 compared to baseline adaptation state XYZ0
%   D2: degree of adaptation under XYZw1 compared to baseline adaptation state XYZ0

%--------------------------------------------------------------------------
% Take care of missing input
if nargin < 7;MCAT = [];end
if nargin < 6;D2 = [];end
if nargin < 5;D1 = [];end
if nargin < 4;XYZ0 = [];end

%--------------------------------------------------------------------------
% Set defaults
if isempty(D1);D1 = 1;end
if isempty(D2);D2 = 1;end
if isempty(XYZ0);XYZ0 = [100 100 100];end

%--------------------------------------------------------------------------
% Enter CAT-details in single vector (for optimization purposes)
MCATs={'CAT02','BFD', 'SHARP', 'KRIES'};
if size(XYZ0,2)==5+9;
    MCAT = [XYZ0(5+(1:3));XYZ0(5+3+(1:3));XYZ0(5+6+(1:3))];
end
if size(XYZ0,2) == 6;
    MCAT=MCATs{XYZ0(6)};
end
if size(XYZ0,2) >= 5;
    D2 = XYZ0(5);
end
if size(XYZ0,2)>=4;
    D1 = XYZ0(4);
    XYZ0=XYZ0(1:3);
end
    

%--------------------------------------------------------------------------
% Select predefined CAT-matrix or enter your own
if ~isempty(MCAT)
    if ischar(MCAT)
        switch MCAT
            case 'CAT02'
                %CAT02 chromatic adaptation
                 MCAT = [0.7328,0.4296,-0.1624;-0.7036,1.6975,0.0061;0.0030,0.0136,0.9834];
            case 'BFD'
                 %BFD chromatic adaptation
                 MCAT = [0.8951,0.2664,-0.1614;-0.7502,1.7135,0.0367;0.0389,-0.0685,1.0296];
            case 'SHARP'
                 %SHARP chromatic adaptation
                 MCAT = [1.2694,-0.0988,-0.1706;-0.8364,1.8006,0.0357;0.0297,-0.0315,1.0018];
            case 'KRIES'
                 %von Kries chromatic adaptation (HPE-matrix)
                 MCAT = [0.38971,0.68898,-0.07868;-0.22981,1.1834,0.04641;0.0000,0.0000,1.0000];
            otherwise
                error('Unknown specified CAT.')
        end
    else
        if sum(size(MCAT)==[3,3])~=2;error('CAT-matrix not 3 x 3.');end
    end
else
    MCAT = [0.7328,0.4296,-0.1624;-0.7036,1.6975,0.0061;0.0030,0.0136,0.9834];%CAT02 = default
end

%--------------------------------------------------------------------------
% Transform XYZ to selected sensor space
    LMSi1 = (MCAT*XYZi1')';
    LMSw1 = (MCAT*XYZw1')';
    LMSw2 = (MCAT*XYZw2')';
    LMS0 = (MCAT*XYZ0')';
    
%--------------------------------------------------------------------------
% Calculate sensor-gains
     g10 = LMS0./LMSw1;
     g02 = LMSw2./LMS0;
%--------------------------------------------------------------------------
% Apply von Kries type chromatic adaptation transform
    % Illuminant 1 to baseline
    LMSi0 = ((diag(g10.*D1)+diag((1-D1.*ones(1,3))))*LMSi1')';
    
    % Bbaseline to illuminant 2
    LMSi2 = ((diag(g02.*D2)+diag((1-D2.*ones(1,3))))*LMSi0')';
    
%--------------------------------------------------------------------------
% Transform LMS from sensor space to XYZ
    XYZi2 = (inv(MCAT)*LMSi2')';
    
end



