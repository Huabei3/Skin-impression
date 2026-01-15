function luv=xyz2luv(XYZ,XYZw)
% XYZ2luv: calculates CIELUV coordinates from tristimulus XYZ,XYZw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

X=XYZ(:,1);Y=XYZ(:,2);Z=XYZ(:,3);
up=4.*X./(X+15.*Y+3.*Z);
vp=9.*Y./(X+15.*Y+3.*Z);
uvp=[up,vp];

Xw=XYZw(1);Yw=XYZw(2);Zw=XYZw(3);
upw=4*Xw./(Xw+15*Yw+3*Zw);
vpw=9*Yw./(Xw+15*Yw+3*Zw);
uvpw=[upw,vpw];

%uv1976 to CIELUV
YYW=Y./Yw;
L(find(YYW>(6/29)^3)) = 116*(YYW(find(YYW>(6/29)^3))).^(1/3)-16;
L(find(YYW<=(6/29)^3)) = ((29/3)^3).*(YYW(find(YYW<=(6/29)^3)));
L=L';
u=13*L.*(up-repmat(upw,length(up),1));
v=13*L.*(vp-repmat(vpw,length(vp),1));

luv=[L,u,v];
end

