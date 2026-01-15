function XYZt = CAT02_D(XYZ, XYZw, XYZwt, D)
%%% XYZ is test XYZ [nx3]
%%% XYZw is test white [1x3]
%%% XYZwr is reference white [1x3]
%%% La is adaptive luminance; La should be calculated as (Lw*Yb)/Yw, 
    % where Lw is the luminance of reference white in cd/m2 unit, 
    % Yb is the luminance factor of the background and Yw is the luminance factor of
    % the reference white.
%%% F is the factor of degree of adaptation; F equals 1.0, 0.9, and 0.8 for average, 
    % dim, and dark surround viewing conditions, respectively.
%%% XYZr is the computed xyz under reference source
    M_CAT02 = [0.7328, 0.4296, -0.1624;
           -0.7036, 1.6975, 0.0061;
           0.0030, 0.0136, 0.9834];    
    Inv_M_CAT02 = M_CAT02^-1;

    % step 1
    RGB = M_CAT02*XYZ';
    RGBw = M_CAT02*XYZw';
    RGBwr = M_CAT02*XYZwt';

    % step 2
    alpha = D*XYZw(2)/XYZwt(2); 

    % step 3
    RGBc(1,:) = (alpha*(RGBwr(1)/RGBw(1)) + 1 - D)*RGB(1,:);
    RGBc(2,:) = (alpha*(RGBwr(2)/RGBw(2)) + 1 - D)*RGB(2,:);
    RGBc(3,:) = (alpha*(RGBwr(3)/RGBw(3)) + 1 - D)*RGB(3,:);
    % step 4
    
    XYZt = (Inv_M_CAT02*RGBc)';

end