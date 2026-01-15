function XYZ2 = SimpleTwostepCAT (XYZ1,XYZ1w,XYZ2w,XYZ0w,Mtype,D1,D2)

% step 0 ------choose a M------------------------
switch Mtype
    case 'CAT02'
        M=[0.7328, 0.4296, -0.1624;
             -0.7036, 1.6975,  0.0061;
              0.0030, 0.0136,  0.9834];
    case 'CAT16'
        M=[0.401288   0.650173  -0.051461
             -0.250268   1.204414   0.045854
             -0.002079   0.048952   0.953127];
    case 'VonKries'
        M=[0.40024, 0.70760, -0.08081;
             -0.22630, 1.16532,  0.04570;
              0,       0,        0.91822];
    case 'CMC'
        M=[0.7982,  0.3389,	-0.1371;
             -0.5918,  1.5512,	 0.0406;
              0.0008,  0.0239,	 0.9753];
    case 'HPE'
        M=[0.38971, 0.68898, -0.07868;
             -0.22981, 1.18340,  0.04641;
              0,       0,        1     ];
    case 'IPT'
        M=[0.4002,  0.7075, -0.0807;
             -0.2280,  1.1500,  0.0612;
              0,       0,       0.9184];
    case 'LMS'      
        M=[0.2070,   0.8655,  -0.0362;
             -0.4307,   1.1780,   0.0949;
              0.0865,  -0.2197,   0.4633];
end

% step 1 -------XYZ1 to BRG1--------
RGB1=(M*XYZ1');
RGBw1=(M*XYZ1w');
RGBw2=(M*XYZ2w');
RGBw0=(M*XYZ0w');

D11=(XYZ1w(2)/XYZ0w(2))*D1*(RGBw0./RGBw1)+1-D1;
D22=(XYZ2w(2)/XYZ0w(2))*D2*(RGBw0./RGBw2)+1-D2;

% step 2 ---------calculate the transform factor Dt-----------
Dt =D11./D22;

% step 3 ------RGB1 to RGB2-----------
RGB2=RGB1.*Dt;

% step 4 ------RGB2 to XYZ2-----------
XYZ2=(M\RGB2)';
XYZ2(XYZ2<0)=0;


% m=41;n=41;
% cells_XYZ1 = cell(1, 3);
% cells_XYZ1{1} = reshape(XYZ1(:, 1), [m, n]);
% cells_XYZ1{2} = reshape(XYZ1(:, 2), [m, n]);
% cells_XYZ1{3} = reshape(XYZ1(:, 3), [m, n]);
% 
% cells_RGB1 = cell(1, 3);
% RGB1=RGB1';
% cells_RGB1{1} = reshape(RGB1(:, 1), [m, n]);
% cells_RGB1{2} = reshape(RGB1(:, 2), [m, n]);
% cells_RGB1{3} = reshape(RGB1(:, 3), [m, n]);
% 
% cells_RGB2 = cell(1, 3);
% RGB2=RGB2';
% cells_RGB2{1} = reshape(RGB2(:, 1), [m, n]);
% cells_RGB2{2} = reshape(RGB2(:, 2), [m, n]);
% cells_RGB2{3} = reshape(RGB2(:, 3), [m, n]);
% 
% cells_XYZ2 = cell(1, 3);
% cells_XYZ2{1} = reshape(XYZ2(:, 1), [m, n]);
% cells_XYZ2{2} = reshape(XYZ2(:, 2), [m, n]);
% cells_XYZ2{3} = reshape(XYZ2(:, 3), [m, n]);

% save("Z:\homes\Peggy\oppoSkinExperi\picked40\iphone\cropped\findRdQst\rgb_cells.mat", ...
%     "cells_XYZ2","cells_RGB2","cells_RGB1","cells_XYZ1");
