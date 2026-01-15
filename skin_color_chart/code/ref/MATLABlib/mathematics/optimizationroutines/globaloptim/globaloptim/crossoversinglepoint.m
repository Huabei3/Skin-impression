function xoverKids  = crossoversinglepoint(parents,options,GenomeLength,FitnessFcn,unused,thisPopulation)
%CROSSOVERSINGLEPOINT Single point crossover.
%   XOVERKIDS = CROSSOVERSINGLEPPOINT(PARENTS,OPTIONS,GENOMELENGTH, ...
%   FITNESSFCN,SCORES,THISPOPULATION) creates the crossover children XOVERKIDS
%   of the given population THISPOPULATION using the available parents
%   PARENTS. A single crossover point for each child is chosen at random.
%   The child has the genes of the first parent up to this point and the genes
%   of the other parent after this point.
%
%   Example:
%    Create an options structure using CROSSOVERSINGLEPOINT as the crossover
%    function
%     options = gaoptimset('CrossoverFcn',@crossoversinglepoint);

%   Copyright 2003-2007 The MathWorks, Inc.
%   $Revision: 1.1.6.1 $  $Date: 2009/08/29 08:24:21 $


% How many children to produce?
nKids = length(parents)/2;
% Extract information about linear constraints, if any
linCon = options.LinearConstr;
constr = ~isequal(linCon.type,'unconstrained');
% Allocate space for the kids
xoverKids = zeros(nKids,GenomeLength);

% To move through the parents twice as fast as thekids are
% being produced, a separate index for the parents is needed
index = 1;

for i=1:nKids
    % get parents
    parent1 = thisPopulation(parents(index),:);
    index = index + 1;
    parent2 = thisPopulation(parents(index),:);
    index = index + 1;

    % cut point is AFTER this index.
    xOverPoint = ceil(rand * (length(parent1) - 1));
    % make one child
    xoverKids(i,:) = [ parent1(1:xOverPoint),parent2(( xOverPoint + 1 ):  end )  ];
    % Make sure that offspring are feasible w.r.t. linear constraints
    if constr
        feasible  = isTrialFeasible(xoverKids(i,:)',linCon.Aineq,linCon.bineq,linCon.Aeq, ...
        linCon.beq,linCon.lb,linCon.ub,sqrt(options.TolCon));
        if ~feasible % Kid is not feasible
            % Children are arithmetic mean of two parents (feasible w.r.t
            % linear constraints)
            alpha = rand;
            xoverKids(i,:) = alpha*parent1 + (1-alpha)*parent2;
        end
    end
end