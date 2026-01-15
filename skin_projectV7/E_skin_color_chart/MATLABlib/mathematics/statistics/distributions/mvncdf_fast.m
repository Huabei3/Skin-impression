function [p, err, N] = mvncdf_fast(x, mu, Sigma, errMax, ci, Nmax)
%MVNCDF Multivariate normal cumulative distribution function (cdf).
%   P = MVNCDF(X,MU,SIGMA) computes the multivariate normal cdf 
%   with mean vector MU and variance matrix SIGMA at the values in 
%   vector X.
%
%   P = MVNCDF(X,MU,SIGMA,ERRMAX,CI,NMAX) uses additional control 
%   parameters. The difference between P and the true value of the
%   cdf is less than ERRMAX CI percent of the time. NMAX is the 
%   maximum number of iterations that the algorithm makes. By 
%   default, ERRMAX is 0.01, CI is 99, and NMAX is 300.
%
%   [P,ERR,N] = MVNCDF(...) also returns the estimated error and the
%   number of iterations made.
%
%   See also NORMCDF.

%   Algorithm from Alan Genz (1992) Numerical Computation of 
%   Multivariate Normal Probabilities, Journal of Computational and 
%   Graphical Statistics, pp. 141-149.

%   Copyright 2005 Alex Strashny (alex@strashny.org)
%   version 1, April 29, 2005

%     This program is free software; you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation; either version 2 of the License, or
%     (at your option) any later version.
% 
%     This program is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with this program; if not, write to the Free Software
%     Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

m1 = size(x,2);
n=size(x,1);
m2 = size(mu,2);
[m3,m4] = size(Sigma);

if m1 ~= m2 | m1 ~= m3 | m1 ~= m4
    error('Dimentions of X, MU, and SIGMA must agree.');
end;
m = m1;
x = x - repmat(mu,size(x,1),1);

if nargin < 6
    Nmax = 300;
end;
if nargin < 5
    alph = 2.3;
else
    alph = norminv(ci/100);
end;
if nargin < 4
    errMax = 0.01;
end;

C = chol(Sigma)';

p = zeros(n,1); N = zeros(n,1); varSum = zeros(n,1); 

% d is always zero
f = zeros(n,m);
f(:,1) = normcdf(x(:,1) ./ C(1,1));

y = zeros(n,m);
err = repmat(2 * errMax,n,1);
k=1:n;
k=(err(k)> errMax) & (N(k) < Nmax);
    while sum(k)>0
        w = unifrnd(0,1,m-1,1);
        for i = 2:m
            y(k,i-1) = norminv(w(i-1).*f(k,i-1));
            q = 0;
            for j = 1:i-1
                q = q + C(j,i).*y(k,j);
            end;
            f(k,i) = normcdf((x(k,i) - q)./ C(i,i)).* f(k,i-1);
        end;
        N(k) = N(k) + 1;
        del = (f(k,m) - p(k))./ N(k);
        p(k) = p(k) + del;
        varSum(k) = (N(k)-2) .* varSum(k)./ N(k) + del.^2;
        err(k) = alph.* sqrt(varSum(k));
        k=(err(k)> errMax) & (N(k) < Nmax);
    end;