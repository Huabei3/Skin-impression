function br=bicor(x, y)
% function br=bicor(x, y)
% calculates the biweight midcorrelation between x and y.

br = bicov(x,y)/max((sqrt(bicov(x,x).*bicov(y,y))),1e-29);

function bv=bicov(x, y) 
% Note: the biweight mid covariance is the output bv times N, 
% N = the no. of data pairs.
mx = median(x);
my = median(y);
ux = abs((x-mx)/(9.*max(median(abs(x-mx)),1e-29)));
uy = abs((y-my)/(9.*max(median(abs(y-my)),1e-29)));
aval = ux<=1;
bval = uy<=1;
top = sum(aval.*(x-mx).*(1-ux.^2).^2.*bval.*(y-my).*(1-uy.^2).^2);
botx = sum(aval.*(1-ux.^2).*(1-5.*ux.^2));
boty = sum(bval.*(1-uy.^2).*(1-5*uy.^2));
bv = top/(botx.*boty);
