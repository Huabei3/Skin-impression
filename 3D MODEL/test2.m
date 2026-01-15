clear;
%5
% XYZ_table=readtable("Z:\homes\Peggy\" + ...
%     "test-color-patch-indoor1Ncalib-2024-06-27-10-32.csv");
XYZ_table=readtable("Z:\homes\Peggy\" + ...
    "test-color-patch-indoor1Ncalib-3.csv");
XYZ_spd=table2array(XYZ_table(:,4:end));
SPDname = 400:2:700;
SPDname = SPDname';
XYZ_mea1 = spd2xyz([SPDname XYZ_spd'],10);

% XYZ_table=readtable("Z:\homes\Peggy\" + ...
%     "test-color-patch-indoor1Ncalib2-2024-06-27-10-34.csv");
XYZ_table=readtable("Z:\homes\Peggy\" + ...
    "test-color-patch-indoor1Ncalib2-3.csv");
XYZ_spd=table2array(XYZ_table(:,4:end));
SPDname = 400:2:700;
SPDname = SPDname';
XYZ_mea2 = spd2xyz([SPDname XYZ_spd'],10);

[val, ind]=max(XYZ_mea1);
XYZw=XYZ_mea1(ind(2),:);

[lab1] = xyz2lab(XYZ_mea1,'user',XYZw);
[lab2] = xyz2lab(XYZ_mea2,'user',XYZw);

[de,~,~,~] = cielabde(lab1,lab2);
[de00,de00c] = deltaE2000(lab1,lab2);
average_deltaE = mean(de00);
