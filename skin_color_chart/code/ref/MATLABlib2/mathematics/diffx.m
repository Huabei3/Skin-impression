function [result,length_kern]=diffx(x,n,d)
if nargin<3;d=1;end
if size(x,2)>1
	lambda = x(:,1);
	x = x(:,2:end);
end
switch n
    case 1
        kern=[1 -1]; % d (non-centered)
    case 2
        kern=[0.5 0 -0.5]; % 2*d +/- 5nm for 5nm spacing (centered)
    case 3
        kern=[1 0 0 0 0 0 -1]/6; % d, +/- 15nm for 5 nm spacing (centered)
    case 4
        kern=-[-.5 -.87 -1 -.87 -.5 0 .5 .87 1 .87 .5]/21.6; % d1 Lorne
end
length_kern = length(kern);
result=conv2(x,kern');
result=result(length(kern):end-length(kern)+1,:)./abs(d);

if exist('lambda','var');
	lambda = lambda(floor((length_kern-1)/2)+1:end-ceil((length_kern-1)/2));
	result = [lambda,result];
end
%result=(x(n+1:end,:)-x(1:end-n,:))/n;