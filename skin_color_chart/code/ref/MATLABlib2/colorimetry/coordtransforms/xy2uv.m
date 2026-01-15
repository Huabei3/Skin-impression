function uv=xy2uv(xy)
%tranform CIE xy to CIE 1976 u', v' colour coordinates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
u=(4*xy(:,1))./(-2*xy(:,1)+12*xy(:,2)+3);
v=(9*xy(:,2))./(-2*xy(:,1)+12*xy(:,2)+3);
uv=[u,v];
end