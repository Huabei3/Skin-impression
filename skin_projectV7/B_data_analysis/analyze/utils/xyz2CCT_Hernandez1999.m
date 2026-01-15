function CCT = xyz2CCT_Hernandez1999(xyz)
    xyY=[xyz(:,1)./sum(xyz,2),xyz(:,2)./sum(xyz,2),xyz(:,2)];
    CCT = xy_to_CCT_Hernandez1999(xyY(:,1:2));
end