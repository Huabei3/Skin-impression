function Yuv=xyz2Yuv(xyz)
%tranform xyz to 1976 Y, u', v' colour coordinates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
xy=xyz2xyY(xyz);
Y=xyz(:,2);
u=(4*xy(:,1))./(-2*xy(:,1)+12*xy(:,2)+3);
v=(9*xy(:,2))./(-2*xy(:,1)+12*xy(:,2)+3);
Yuv=[Y,u,v];
end