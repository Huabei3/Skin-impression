function x = lhspoint(n,p)
%LHSPOINT Generates Latin hypercube points.
%  	X = LHSPOINT(N,P) Generates a Latin hypercube sample X containing N
%  	values on each of P variables.  For each column, the N values are
% 	 randomly distributed with one from each interval (0,1/N), (1/N,2/N),
% 	 ..., (N-1/N,1), and they are randomly permuted.

%   Copyright 2003-2005 The MathWorks, Inc.
%   $Revision: 1.1.6.1 $  $Date: 2009/08/29 08:24:59 $

x = rand(n,p);
for i=1:p
    x(:,i) = rank(x(:,i));
end
x = x - rand(size(x));
x = x / n;
x = x';
%Safeguard which should not occur in LHS
x(:,(~any(x))) = [];

%------------RANK function used by lhspoint
function r=rank(x)
[sx, rowidx] = sort(x);
r(rowidx) = 1:length(x);
r = r(:);
