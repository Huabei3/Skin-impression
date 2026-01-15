function XYZ=uvY2xyz(uvY)
%transform from CIE1976 u', v', Y to xyz
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
xy=uv2xy(uvY(:,1:2));
XYZ=xyY2xyz([xy,uvY(:,3)]);
end

