function xyY=xyYold2xyYnew(xyz,xyzold,xyznew)
%convert from one set of XYZ 2 another set of XYZ
%xyzold are 4 colourpoints in the old system
%xyznew are the same 4 colourpoints in the new system
%xyz is colour to be transformed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
xyYold(:,1)=xyzold(:,1)./sum(xyzold')';
xyYold(:,2)=xyzold(:,2)./sum(xyzold')';
xyYnew(:,1)=xyznew(:,1)./sum(xyznew')';
xyYnew(:,2)=xyznew(:,2)./sum(xyznew')';
xyY(:,1)=xyz(:,1)./sum(xyz')';
xyY(:,2)=xyz(:,2)./sum(xyz')';
xo=xyYold(:,1);
yo=xyYold(:,2);
xn=xyYnew(:,1);
yn=xyYnew(:,1);
x=xyY(:,1);
y=xyY(:,2);
M=[xo(1),y0(1),1,-xn(1)*xo(1),-xn(1)*y0(1),0,0,0;0,0,0,-yn(1)*x0(1),-yn(1)*y0(1),x0(1),y0(1),1;
   xo(2),y0(2),1,-xn(2)*xo(2),-xn(2)*y0(2),0,0,0;0,0,0,-yn(2)*x0(2),-yn(2)*y0(2),x0(2),y0(2),1;
   xo(3),y0(3),1,-xn(3)*xo(3),-xn(3)*y0(3),0,0,0;0,0,0,-yn(3)*x0(3),-yn(3)*y0(3),x0(3),y0(3),1;
   xo(4),y0(4),1,-xn(4)*xo(4),-xn(4)*y0(4),0,0,0;0,0,0,-yn(4)*x0(4),-yn(4)*y0(4),x0(4),y0(4),1];
V=[xn(1),yn(1),xn(2),yn(2),xn(3),yn(3),xn(4),yn(4)]';
Minv=inv(M);
U=Minv*V;
xt=(U(1)*x+u(2)*y+U(3))/(U(4)*x+U(5)*y+1);
yt=(U(6)*x+u(7)*y+U(8))/(U(4)*x+U(5)*y+1);
Y=sum(xyz')';%1-op_& tranformatie van luminance
Y=100*(Y./(3*255));%voor xyzold=RGB
xyY=[xt;,yt,Y];