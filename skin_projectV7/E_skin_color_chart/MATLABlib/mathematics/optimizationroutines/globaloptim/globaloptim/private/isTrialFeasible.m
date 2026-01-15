function feasible = isTrialFeasible(X,Aineq,bineq,Aeq,beq,lb,ub,tol)
%isTrialFeasible Checks if X is feasible w.r.t. linear constraints. 
% 	

%   Copyright 2003-2010 The MathWorks, Inc.
%   $Revision: 1.1.6.2 $  $Date: 2010/11/08 02:22:24 $

feasibleIneq = true;
feasibleEq = true;

% Inequality constraints
if ~isempty(Aineq)
    feasibleIneq = max(Aineq*X-bineq) <= tol;
end
% Upper bounds
argub = ~eq(ub,inf);
if feasibleIneq && any(argub) && ~isempty(argub)
    feasibleIneq = all(X(argub) <= ub(argub));
end
% Lower bounds
arglb = ~eq(lb,-inf);
if feasibleIneq && any(arglb) && ~isempty(arglb)
    feasibleIneq = all(X(arglb) >= lb(arglb));
end
% Equality constraints
if feasibleIneq && ~isempty(Aeq) 
    constrViolation = (Aeq*X-beq);
    feasibleEq   = all(abs(constrViolation(~isinf(constrViolation))) <= tol);
end
feasible = feasibleIneq && feasibleEq;
