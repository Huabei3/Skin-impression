function Population = gacreationlinearfeasible(GenomeLength,unused1,options)
%GACREATIONLINEARFEASIBLE Creates the initial population for GA.
%   POP = GACREATIONLINEARFEASIBLE(NVARS,FITNESSFCN,OPTIONS) Creates the
%   initial population that GA will then evolve into a solution.
%
%   Example:
%     options = gaoptimset('CreationFcn',@gacreationlinearfeasible);

%   Copyright 2007-2010 The MathWorks, Inc.
%   $Revision: 1.1.6.5 $  $Date: 2010/11/01 19:36:45 $


if strcmpi(options.PopulationType,'custom')
    error(message('globaloptim:gacreationlinearfeasible:unknownPopulationType', options.PopulationType));
end

totalPopulation = sum(options.PopulationSize);
initPopProvided = size(options.InitialPopulation,1);
individualsToCreate = totalPopulation - initPopProvided;

if strcmpi(options.PopulationType,'doubleVector')
    % Initialize Population to be created
    Population = zeros(totalPopulation,GenomeLength);
    % Use initial population provided already
    if initPopProvided > 0
        Population(1:initPopProvided,:) = options.InitialPopulation;
    end
    % Create remaining population
    % problemtype is either 'unconstrained', 'boundconstraints', or
    % 'linearconstraints'. Nonlinear constrained algorithm 'ALGA' does not
    % create or use initial population of its own. It calls sub-problem
    % solvers (galincon/gaunc)
    problemtype = options.LinearConstr.type;
    %
    if ~strcmp(problemtype,'linearconstraints')
        range = options.PopInitRange;
        lowerBound = range(1,:);
        span = range(2,:) - lowerBound;
        Population(initPopProvided+1:end,:) = repmat(lowerBound,individualsToCreate,1) + ...
            repmat(span,individualsToCreate,1) .* rand(individualsToCreate,GenomeLength);
    else
        feasiblePop = feasibleLHS(individualsToCreate,GenomeLength,options);
        m = min(individualsToCreate,size(feasiblePop,1));
        if m > 0
            Population(initPopProvided+1:m+initPopProvided,:) = feasiblePop(1:m,:);
        end
        % Make sure that we remove infeasible individuals
        Population(initPopProvided+m+1:end,:) = [];
    end
elseif strcmpi(options.PopulationType,'bitString')
    % Call gacreationuniform in this case
    Population = gacreationuniform(GenomeLength,unused1,options);
end

if all(isnan(Population))
    error(message('globaloptim:gacreationlinearfeasible:populationIsNaN'));
elseif all(isinf(Population))
    error(message('globaloptim:gacreationlinearfeasible:populationIsInf'));
end
%------------------------------------------------------------------------
function initialPopulation = feasibleLHS(npop,nvar,options)
% Extract information about constraints
linCon = options.LinearConstr;
tol = max(sqrt(eps),options.TolCon);
errnorm = 100*nvar*eps; % Tolerance to detect singular directions
maxStep = 1; % Maximum step along a direction
% Allocate at least double space for initial population
popSize = 2*npop;
initialPopulation = nan(popSize+1,nvar);
indiv = 1;
x = linCon.feasibleX;
maxDirections = 2*popSize;
directionCounter = 1;
% Combine inequalities and bounds
A = linCon.Aineq;
B = linCon.bineq;
lb = linCon.lb;
arglb = ~eq(lb,-inf);
lenlb=length(lb);
if nnz(arglb) > 0
    lbmatrix = -eye(lenlb,nvar);
    A=[A; lbmatrix(arglb,1:nvar)]; % select non-Inf bounds
    B=[B;-lb(arglb)];
end
ub = linCon.ub;
argub = ~eq(ub,inf);
lenub=length(ub);
if nnz(argub) > 0
    ubmatrix = eye(lenub,nvar);
    A=[A; ubmatrix(argub,1:nvar)];
    B=[B; ub(argub)];
end

% Create individuals on the feasible boundary and then generate some points
% inside the boundary by a convex combination (in LHS sense) of boundary
% points.
while indiv <= popSize
    if directionCounter > maxDirections
        break;
    end
    directionCounter = directionCounter + 1;
    if indiv > 2 % Generate directions from a new point
        % Coefficient for linear combination of directions
        alpha = randperm(indiv-1)./((indiv-1)*(indiv/2)); 
        x = (alpha.*ones(1,(indiv-1))*initialPopulation(1:indiv-1,:))';
    end
    % Get random directons that spans the feasible region
    try
        [Basis, NormalCone] = lcondirections(true,1,x,linCon.Aineq,linCon.bineq,linCon.Aeq,linCon.lb,linCon.ub,tol);
        DirVector = [Basis NormalCone];
    catch % lcondirections will error for degenerate active constraints
        if  directionCounter < maxDirections
            continue;
        else
            break;
        end
    end
    % Total number of search directions
    nDirTotal = size(DirVector,2);
    % Make the index vector to be used to access directions
    indexVec = [1:nDirTotal 1:nDirTotal];
    % Vector to take care of sign of directions
    dirSign = [ones(1,nDirTotal) -ones(1,nDirTotal)];
    OrderVec = 1:length(indexVec);
    % Total number of trial points
    numberOfDirections = length(OrderVec);

    % Inequality constraints at x
    if ~isempty(A)
        constr = A*x-B;
    else
        constr = 0;
    end
    for k = 1:numberOfDirections
        direction = dirSign(k).*DirVector(:,indexVec(OrderVec(k)));
        if ~isempty(A)
            proj_direction = A*direction;
            % Select directions that are not singular
            indf = proj_direction > errnorm*norm(direction);
            if ~any(indf) % No constraints to hit
                maxStep = max(maxStep,1);
            else % Find distance to the nearest constraint
                dist = abs(constr(indf)./proj_direction(indf));
                maxStep =  min(dist);
            end
        else
            maxStep = max(maxStep,1);
        end
        % Reject very close points
        if maxStep <= eps
            continue;
        end
        step = x + direction*maxStep;
        if isTrialFeasible(step,A,B,linCon.Aeq,linCon.beq,[],[],tol)
            initialPopulation(indiv,:) = step';
            indiv = indiv + 1;
        end
        if indiv > popSize + 1
            break;
        end
    end
end % Points on the boundary are generated

% Generate points inside the feasible boundary
if indiv > 1
    initialPopulation(indiv:end,:) = [];
    popSize = size(initialPopulation,1);
    if popSize > 2
        % Get half the population on the boundary and other half inside
        interior_points = ceil(min(npop,popSize)/2);
        boundary_points = min(npop,popSize) - interior_points;
        % Chose individuals with higher distance measure (on the boundary)
        crowdingDistance = distancecrowding(initialPopulation(1:indiv-1,:),[],[],'genotype');
        [unused,index] = sort(crowdingDistance,'descend');
        % Select half points on the boundary; do not overwrite
        % initialPopulation yet (they will be used for interior points)
        tempPopulation = initialPopulation(index(1:boundary_points),:);
        % Generate a convex LHS-type convex combination for the interior points
        if interior_points > 0
            initialPopulation(boundary_points+1:interior_points+boundary_points,:) = ...
                lhsLambda(interior_points,size(tempPopulation,1))*tempPopulation;
            initialPopulation(interior_points+boundary_points+1 :end,:) = [];
        end
        initialPopulation(1:boundary_points,:) = tempPopulation;
        % Make sure the population is feasible (bounds may not be satisfied
        % by 'active-set' algorithm and that may result in infeasible
        % population.
        pop = size(initialPopulation,1);
        feasible = false(pop,1);
        for i = 1:pop
            feasible(i) = isTrialFeasible(initialPopulation(i,:)',linCon.Aineq,linCon.bineq, ...
                linCon.Aeq,linCon.beq,linCon.lb,linCon.ub,options.TolCon);
        end
        initialPopulation(~feasible,:) = [];
    end
else % Could not generate feasible population
    initialPopulation = [];
end

%-------------Generate LHS coefficients-----------------
function lambda = lhsLambda(n,p)
lambda = lhspoint(n,p)';
% Form constraints on lambda
Aeq = ones(1,p); beq = 1;
% 'active-set' may violate the bounds so instead of zero we set it to eps
lb = eps*ones(1,p); 
ub = []; % ones(1,p); implied with the equality constraints
warnstate = warning;
warning off;
opts = struct('Display','off','Algorithm','active-set');
for i = 1:n
    fun = @(x) -score(x,[lambda(1:i-1,:);lambda(i+1:end,:)]);
    [lambda(i,:),f,e] = fmincon(fun,lambda(i,:),[],[],Aeq,beq,lb,ub,[],opts);
    if e < 0
        lambda(i,:) = lambda(i,:)/sum(lambda(i,:));
    end
end
warning(warnstate);

%-----------Objective function for LHS criteria---------------
function s = score(a,arg)
x = [a;arg];
c = corrcoef(x);
s = -sum(sum(triu(c,1).^2));
