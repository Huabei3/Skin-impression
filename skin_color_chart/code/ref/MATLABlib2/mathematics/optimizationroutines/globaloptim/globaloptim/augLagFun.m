function lagrangeFval = augLagFun(points,objfun,nonlcon,row,col,augLagStruct, ...
    nineqcstr,neqcstr,ncstr,tolcon,objFcnArg,conFcnArg)
%augLagFun evaluates augmented Lagrangian formulation 
%
%  points: Single or multiple points to be evaluated 
%  row, col : size of the start point
%  AugLagStruct: augmented Lagrangian data structure (used by pattern
%  search and GA)
%  nineqcstr: number of nonlinear inequality constraints
%  neqcstr: number of nonlinear equality constraints
%  ncstr: total nonlinear constraints
%  tolcon: constraint tolerance
%  objFcnArg: additional input for objective function
%  conFcnArg: additional input for constraint function

%   Copyright 2007 The MathWorks, Inc.
%   $Revision: 1.1.6.1 $  $Date: 2009/08/29 08:24:16 $


% Determine the size of points; row or column major
[m,n] = size(points);
% If the point(s) is a single point we call the special (faster) function which
% evaluates single point.
if isequal(m,row) && isequal(n,col)
    lagrangeFval = augLagScalarFun(points,objfun,nonlcon,augLagStruct, ...
        nineqcstr,neqcstr,ncstr,tolcon,objFcnArg,conFcnArg);
    return;
end

% The remaining code is executed only in the vectorized case.
% Assumption about points:
% Case 1:
% ROW major points (every row is a point); also applies to one dimensional
% problems
%
% If X0 = [5 -9 ....3]  Size: 1-by-N  then points is supposed to have the form:
%
% point = [5 -9 ....3
%          9  1 ....3
%          ...
%          ....
%          -8  2 ...10]  Size: M-by-N
% When the objective function is called with points we expect a vector 
% F of length M (row or column).
% When the constraint function is called with points we expect a matrix
% cin and ceq of size M-by-I and M-by-E respectively. 
%

% row major points: every row is a point
% equality test cover single dimension problems; we require that the
% vectorized points be a row major
row_major = col >= row && row == 1;

% Case 2
% COL major points (every col is a point)
% 
% X0 = [5 
%      -9
%       .
%       .
%       .
%       3]  Size: N-by-1
% 
% A vectorized points of M points would look like:
% 
% Points = [5  7   .  .  . 4
%       -9  1   .  .  . 3
%        .   .    .  .  .  .
%        .   .    .  .  .  .
%        3  2   .  .  .  0]  Size: N-by-M
% 
% Number of inequality constraints: I
% Number of equality constraints: E
% 
% When the objective function is called with points we expect a vector 
% F of length M (row or column vector).
% When the constraint function is called with points we expect a matrix 
% cin and ceq of size I-by-M and E-by-M respectively. 
% 

% col major points: every column is a point
col_major = row > col && col == 1;

% Evaluate nonlinear constraints at all points
[cin, ceq] = feval(nonlcon,points,conFcnArg{:});

% Since the solver calculation is always done assuming col major we convert
% cin and ceq  to col major (if it is not already)
if row_major
    cin = cin'; ceq = ceq';    % convert to col major form
    nPoints = m;
else
    nPoints = n;
end
% if cin or ceq is a vector (one constraint) we convert cin and ceq to a
% row vector (colum major convention)
if isvector(cin)
    cin = cin(:)';
end
if isvector(ceq)
    ceq = ceq(:)';
end

% Initialize
fval = nan(nPoints,1);
lagrangeFval = nan(nPoints,1);
to_evaluate = true(nPoints,1);

% We must make sure that inequality constraints satisfy the feasibility
% criteria at intermediate points. This is done by calculating the quantity
% shiftedConstr and making sure that it is greated than zero.
if nineqcstr 
    shiftedConstr = zeros(nineqcstr,nPoints);
    for i = 1:nPoints
        shiftedConstr(:,i) = augLagStruct.shift - cin(:,i) + tolcon;
        if any(shiftedConstr(:,i) <= 0)
            to_evaluate(i) = false;
        end
    end
    % Reduce the size of points by removing all points at which we do not
    % evaluate the objective (only when inequality are present)
    if col_major
        points(:,~to_evaluate) = [];
    else
        points(~to_evaluate,:) = [];
    end
    if ~any(to_evaluate)
        return;
    end
end % Done checking the constraint satisfaction criteria for inequality constraints

% Evaluate the objective in vectorized fashion
fval(to_evaluate) = feval(objfun,points,objFcnArg{:});

for i = 1:nPoints
    if to_evaluate(i)
        if nineqcstr % inequality constraints
            lagrangeFval(i) = fval(i) - sum(augLagStruct.lambda(1:nineqcstr).* ...
                augLagStruct.shift.*log(shiftedConstr(:,i)));
        else % Equality is present for sure
            lagrangeFval(i) = fval(i);
        end
        if neqcstr
            lagrangeFval(i) = lagrangeFval(i) + sum(augLagStruct.lambda(nineqcstr+1:ncstr).*ceq(:,i)) ...
                + sum(ceq(:,i).^2 )*(augLagStruct.penalty/2);
        end
    end
end

%---------------------------------------------------------------
% Augmented Lagrangian sub-problem objective function formulation
function lagrangeFval = augLagScalarFun(points,objfun,nonlcon,augLagStruct, ...
        nineqcstr,neqcstr,ncstr,tolcon,objFcnArg,conFcnArg)
ceq = zeros(neqcstr,1);
cin = zeros(nineqcstr,1);
[cin(:),ceq(:)] = feval(nonlcon,points,conFcnArg{:});

% Inequality constraint must satisfy this condition (see log term
% in the augmented lagrangian formulation)
if nineqcstr
    shiftedConstr = augLagStruct.shift - cin + tolcon; % must be > 0
    if any(shiftedConstr <= 0)
        lagrangeFval = NaN; % This is okay because PS and GA work on a population
        return;
    end
end
% Evaluate objective function
fval = feval(objfun,points,objFcnArg{:});

if nineqcstr
    % lagrangeFval = f(x) - sum(lambda_i*shift_i*log(shift_i - c(x)_i))
    % i: nonlinear inequality constraints
    lagrangeFval = fval - sum(augLagStruct.lambda(1:nineqcstr).* ...
        augLagStruct.shift.*log(shiftedConstr));
else 
    lagrangeFval = fval;
end

if neqcstr
    % lagrangeFval = lagrangeFval + sum(lambda_i*c(x)_i) +
    % (penalty/2)*sum(c(x)_i^2); i: equality constr
    lagrangeFval = lagrangeFval + sum(augLagStruct.lambda(nineqcstr+1:ncstr).*ceq) ...
        + sum(ceq.^2 )*(augLagStruct.penalty/2);
end

