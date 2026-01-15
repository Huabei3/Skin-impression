function z = simpson(x,y)
%simpson integration
%%%%%%%%%%%%%%%%%%%%

h= x(2)-x(1);
y1 = y(1);
yn = y(length(y));
%summation
%z = h*sum(y);

%lagrange : even though simpson is more accurate, use Lagrange to get
%results in agreement with CIE results
%ylag = y(2:(end-1));
%z = y1/2 + sum(h*ylag) + yn/2;

%simpson
yeven =  y(2:2:(end-1));
yodd = y(3:2:(end-2));
sumeven = sum(yeven);
sumodd = sum(yodd);
z = (h/3)*(y1+4*sumodd+2*sumeven+yn);

