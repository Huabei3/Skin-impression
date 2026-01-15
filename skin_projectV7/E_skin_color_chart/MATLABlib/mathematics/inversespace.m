function y = inversespace(d1, d2, n)
%INVERSESPACE Inverse power spaced vector.

if nargin == 2
    n = 50;
end
n = double(n);
y = 1./[d1+(0:n-2)*(d2-d1)/(floor(n)-1), d2];
