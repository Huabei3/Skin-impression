function [M, DE00, DEab] = getCCMlight(SSF, CMF, spddata, refl, range)

SSF = find_spd(SSF, range);
SSF(:, 1) = [];
CMF = find_spd(CMF, range);
CMF(:, 1) = [];
spddata = find_spd(spddata, range);
spddata(:, 1) = [];
refl = find_spd(refl, range);
refl(:, 1) = [];

SPD = spddata .* refl;

RGBw = spddata' * SSF;
RGB = SPD' * SSF;
RGB = RGB ./ max(RGBw);

XYZw = spddata' * CMF;
XYZ = SPD' * CMF;
k = 100 / XYZw(2);
XYZw = XYZw .* k;
XYZ = XYZ .* k;

M = RGB \ XYZ;
XYZc = RGB * M;

labc = xyz2lab(XYZc, 'user', XYZw);
lab = xyz2lab(XYZ, 'user', XYZw);
DE00 = mean(deltaE2000(lab, labc));
DEab = mean(deltaE(lab, labc));

end

