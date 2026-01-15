function uvY=xyY2uvY(xyY)
%tranform CIE xyY to CIE 1976 u', v', Y  coordinates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
xy=xyY;
u=(4*xy(:,1))./(-2*xy(:,1)+12*xy(:,2)+3);
v=(9*xy(:,2))./(-2*xy(:,1)+12*xy(:,2)+3);
uvY=[u,v,xyY(:,3)];
end