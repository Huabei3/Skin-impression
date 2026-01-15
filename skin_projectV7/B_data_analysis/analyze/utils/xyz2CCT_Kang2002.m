function CCT = xyz2CCT_Kang2002(xyz)
    xyY=[xyz(:,1)./sum(xyz,2),xyz(:,2)./sum(xyz,2),xyz(:,2)];
    CCT = xy_to_CCT_Kang2002(xyY(:,1:2));
end