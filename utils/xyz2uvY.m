function uvY=xyz2uvY(XYZ)
% convert CIE 1976 u',v' Y coordinates from tristimulus XYZ

X=XYZ(:,1);Y=XYZ(:,2);Z=XYZ(:,3);
up=4*X./(X+15*Y+3*Z);
vp=9*Y./(X+15*Y+3*Z);
uvY=[up, vp, Y];
end