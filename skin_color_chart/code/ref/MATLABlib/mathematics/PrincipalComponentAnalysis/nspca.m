function U = nspca (X, k, alpha, beta, breakPercent, U0)
% U = nspca (X, k, alpha[, beta[, breakPercent[, U0]]])
%
% Perform Nonnegative Sparse PCA.
%
% X - Contains m data points as columns. (d by m matrix)
% k - The desired dimension. (scalar)
% alpha - Weight of orthonormality term. The higher alpha is, the more orthonormal and disjoint the result is. (non-negative scalar)
% beta [Optional, default = 0] - Weight of the Lasso term. The higher beta is, the sparser the result is.
% breakPercent [Optional, default = 0.001] - Break when the improvement to the objective is less than breakPercent percents. (scalar between 0 and 1)
% U0 [Optional, default is random] - An initial guess. (d by k matrix)
%
% U [Output] - The new k axes as columns. (d by k matrix)
%
% See also: nspca2.m
%
% Author: Ron Zass, zass@cs.huji.ac.il, www.cs.huji.ac.il/~zass

% Prepare input: (Center the data points on zero and calculate the correlation matrix.)
    F = X * X' - (1/size(X,2)) * X * ones(size(X,2)) * X';

% Run nscpa2:
    switch nargin
        case 3
            U = nspca2 (F, k, alpha);
        case 4
            U = nspca2 (F, k, alpha, beta);
        case 5
            U = nspca2 (F, k, alpha, beta, breakPercent);
        case 6
            U = nspca2 (F, k, alpha, beta, breakPercent, U0);
        otherwise
            error 'Wrong number of arguments';
    end
