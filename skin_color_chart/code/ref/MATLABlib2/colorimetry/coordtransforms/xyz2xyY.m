function xyY = xyz2xyY(xyz)
xyY=[xyz(:,1)./sum(xyz,2),xyz(:,2)./sum(xyz,2),xyz(:,2)];
