function xoverKids = crossovertwopoint(parents,options,GenomeLength,FitnessFcn,unused,thisPopulation)
%CROSSOVERTWOPOINT Two point crossover.
%   XOVERKIDS = CROSSOVERTWOPOINT(PARENTS,OPTIONS,GENOMELENGTH, ...
%   FITNESSFCN,SCORES,THISPOPULATION) creates the crossover children XOVERKIDS
%   of the given population THISPOPULATION using the available parents PARENTS.
%   Two points A and B are chosen at random.  The child has the genes of the
%   first parent at the locations after A and before B, and the genes of the
%   second parent after B and before A. The individual is treated as a ring so
%   that sections can wrap around the end.
%
%   Example:
%    Create an options structure using CROSSOVERTWOPOINT as the crossover
%    function
%     options = gaoptimset('CrossoverFcn',@crossovertwopoint);

%   Copyright 2003-2007 The MathWorks, Inc.
%   $Revision: 1.1.6.1 $  $Date: 2009/08/29 08:24:22 $

% If GenomeLength is less than equal to 2 then there is one point to do
% crossover and this becomes single point crossover
if GenomeLength <= 2
    xoverKids = crossoversinglepoint(parents,options,GenomeLength,FitnessFcn, ...
        unused,thisPopulation);
    return;
end
% where will the crossover points be?
% uniformly distributed over genome

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

    % choose two (nonequal) crossover points
    sz  = length(parent1) - 1;
    xOverPoint1 = ceil(sz * rand);
    xOverPoint2 = ceil(sz * rand);
    while(xOverPoint2 == xOverPoint1)
        xOverPoint2 = ceil(sz * rand);
    end

    % Deal with the case where the splice wraps around the ends.
    if(xOverPoint1 < xOverPoint2)
        left = xOverPoint1;
        right = xOverPoint2;
    else
        left = xOverPoint2;
        right = xOverPoint1;
        swap = parent1;
        parent1 = parent2;
        parent2 = swap;
    end

    % make one child
    xoverKids(i,:) = [ parent1(1:left),  parent2(( left + 1 ):  right ),    parent1(( right + 1):  end )   ];
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