function [result,length_kern]=diffx2(x,n,d)
if nargin<3;d=1;end
if size(x,2)>1
	lambda = x(:,1);
	x = x(:,2:end);
end
switch n
    case 1
        kern=[1 -2 1]; % d2
    case 2
        kern=[1 -2 1]; % d2
    case 3
        kern=[1 0 0 -2 0 0 1]/7; % +/- 15nm for d = 5 nm spacing (centered)
    case 4
        kern=-[-0.250 -0.433 -0.500 -0.433 -0.250 0.000 0.500 0.866 1.000 0.866 0.500 0.000 -0.250 -0.433 -0.500 -0.433 -0.250]/66;% d2 Lorne
    case 5
        kern=[1 0 0 0 0 0 -2 0 0 0 0 0 1]/35.5;
end
length_kern = length(kern);
result=conv2(x,kern');
result=result(length(kern):end-length(kern)+1,:)./d.^2;

if exist('lambda','var');
	lambda = lambda(floor((length_kern-1)/2)+1:end-ceil((length_kern-1)/2));
	result = [lambda,result];
end

%result=(x(n+1:end,:)-x(1:end-n,:))/n;