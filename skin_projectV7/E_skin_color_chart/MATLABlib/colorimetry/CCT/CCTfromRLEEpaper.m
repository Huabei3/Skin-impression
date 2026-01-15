function CCT = CCTfromRLEEpaper(xyY)
%Calculates CCT based on paper from R.Lee using CIE1931 xy coordinates
%for CCTs from 3000K to 50 000K
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
xe = 0.3366;
ye = 0.1735;
A0 = -949.86315;
a1 = 6253.80338;
t1 = 0.92159;
a2 = 28.70599;
t2 = 0.20039;
A3 = 0.00004;
t3 = 0.07125;
n = (xyY(1) - xe) / (xyY(2) - ye);
CCT = A0 + a1 * exp(-n / t1) + a2 * exp(-n / t2) + A3 * exp(-n / t3);
end