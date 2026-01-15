function M = color3mixer(xyY1,xyY2,xyY3,xyYm)
%Calculates the weights M for sources with xy coordinates: xyY1,xyY2,xyY3
%to obtain xyYm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
x1 = xyY1(1);
y1 = xyY1(2);
x2 = xyY2(1);
y2 = xyY2(2);
x3 = xyY3(1);
y3 = xyY3(2);
xm = xyYm(1);
ym = xyYm(2);
m1 = y1*((xm-x3)*y2-(ym-y3)*x2+x3*ym-xm*y3)/(ym*((x3-x2)*y1+(x2-x1)*y3+(x1-x3)*y2));
m2 = -y2*((xm-x3)*y1-(ym-y3)*x1+x3*ym-xm*y3)/(ym*((x3-x2)*y1+(x2-x1)*y3+(x1-x3)*y2));
m3 = y3*((x2-x1)*ym-(y2-y1)*xm+x1*y2-x2*y1)/(ym*((x2-x1)*y3-(y2-y1)*x3+x1*y2-x2*y1));
M = [m1,m2,m3];
if sum(M<0)>1;disp('out of gamut');end
end