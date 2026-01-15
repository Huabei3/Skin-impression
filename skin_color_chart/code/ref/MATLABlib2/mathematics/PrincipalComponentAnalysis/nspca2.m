function U = nspca2 (A, k, alpha, beta, breakPercent, U0)
% U = nspca2 (A, k, alpha[, beta[, breakPercent[, U0]]])
%
% Perform Nonnegative Sparse PCA.
%
% A - Correlation matrix of data-points that are centered on zero. (d by d matrix)
% k - The desired dimension. (scalar)
% alpha - Weight of orthonormality term. The higher alpha is, the more orthonormal and disjoint the result is. (non-negative scalar)
% beta [Optional, default = 0] - Weight of the Lasso term. The higher beta is, the sparser the result is.
% breakPercent [Optional, default = 0.001] - Break when the improvement to the objective is less than breakPercent percents. (scalar between 0 and 1)
% U0 [Optional, default is random] - An initial guess. (d by k matrix)
%
% U [Output] - The new k axes as columns. (d by k matrix)
%
% See also: nspca.m
%
% Author: Ron Zass, zass@cs.huji.ac.il, www.cs.huji.ac.il/~zass

% Prepare input:
    d = size(A,1);

    if (max(max(abs(A - A'))) > 1e-4)
        error 'A must be symmetric';
    end
    if (alpha <= 0)
        error 'alpha has to be positive (and non-zero)';
    end

    if (nargin < 4)
        beta = 0;
    end

    if (nargin < 5)
        breakPercent = 0.001;
    end

% Initial guess for U:
    if (nargin < 6)
        U = rand(d,k);
    else
        U = U0;
    end

% Preprocessing:
    UU = U .* U;
    alphaQuarter = alpha / 4;
    Error = -Inf;

% Iterate till convergence:
    for l = 1 : 500
        maxDelta = -1;
        minU = 0;

        % Update U elements in a row major raster-scan sequence:
        for i = 1 : d 
            for j = 1 : k
                % Find roots:
                U(i,j) = 0;
                UU(i,j) = 0;
                a2 = alpha * (sum(UU(i,:)) + sum(UU(:,j)) - 1) - A(i,i);
                a1 = beta + alpha * U(i,:)*U'*U(:,j) - sum(U(:,j) .* A(:,i));
                r = roots ([alpha, 0, a2, a1]);

                % Choose the non-negative root / zero that minimize the (minus of the) objective:
                minU = 0;
                minObj = 0;
                r2 = r .* r;
                r4 = r2 .* r2;
                for n = 1 : length(r)
                    if (isreal(r(n)) && r(n) > 0)
                        obj = alpha*r4(n) + 2*a2*r2(n) + 4*a1*r(n);
                        if (obj < minObj)
                            minObj = obj;
                            minU = r(n);
                        end
                    end
                end

                % Update U:
                U(i,j) = minU;
                UU(i,j) = minU * minU;

%test code
%e0 = objective(A,U,alphaQuarter,beta);
%Ut = U;
%Ut(i,j) = U(i,j) + 1e-4;
%e1 = objective(A,Ut,alphaQuarter,beta);
%if (e1 > e0)
%    for p = 0 : 1 : 10
%        Ut(i,j) = Ut(i,j) + (1e-2 * p);
%        e1 = objective(A,Ut,alphaQuarter,beta);
%        disp (sprintf ('p=%d, e=%d', p, e1));
%    end
%    l, i, j
%    r
%    error ('not a maximum!');
%end
%if (minU > 1e-4)
%    Ut(i,j) = U(i,j) - 1e-4;
%    e1 = objective(A,Ut,alphaQuarter,beta);
%    if (e1 > e0)
%        l, i, j
%        r
%        error ('not a maximum (minus)!');
%    end
%end
%end of test code
            end
        end

        % Break condition:
        LastError = Error;
        Error = objective(A,U,alphaQuarter,beta);
        if ((Error - LastError) / abs(Error) <= breakPercent)
            return;
        end
        
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function o = objective (A, U, alphaQuarter, beta)
% The objective to be maximized
    % t1 = trace (U'*A*U);
    t1 = 0;
    for i = 1 : size(U,2)
        t1 = t1 + ( U(:,i)' * A * U(:,i) );
    end

    t2 = eye(size(U,2)) - U'*U;

    o = (t1/2) - alphaQuarter * sum(sum(t2 .* t2)) - beta * sum(sum(U));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

