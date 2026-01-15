%% Multiobjective Genetic Algorithm Options
% This is a demonstration of how to create and manage options for the
% multiobjective genetic algorithm function GAMULTIOBJ using GAOPTIMSET in
% Global Optimization Toolbox.

%   Copyright 2007-2010 The MathWorks, Inc.
%   $Revision: 1.1.6.3 $  $Date: 2010/02/08 22:34:27 $

%% Setting Up a Problem for GAMULTIOBJ
% GAMULTIOBJ finds a local Pareto front for multiple objective functions
% using the genetic algorithm. For this demo, we will use GAMULTIOBJ to
% obtain a Pareto front for two objective functions described in the MATLAB
% file kur_multiobjective.m. It is a real-valued function that consists of 
% two objectives, each of three decision variables. We also impose bound
% constraints on the decision variables -5 <= x(i) <= 5, i = 1,2,3.
type kur_multiobjective.m

%%
% We need to provide a fitness function, the number of variables, and bound
% constraints in the problem to GAMULTIOBJ function. Refer to the help for
% the GAMULTIOBJ function for the syntax. Here we also want to plot the
% Pareto front in every generation using the plot function @GAPLOTPARETO.
% We use GAOPTIMSET function to specify this plot function.
FitnessFunction = @kur_multiobjective; % Function handle to the fitness function
numberOfVariables = 3; % Number of decision variables
lb = [-5 -5 -5]; % Lower bound
ub = [5 5 5]; % Upper bound
A = []; b = []; % No linear inequality constraints
Aeq = []; beq = []; % No linear equality constraints
options = gaoptimset('PlotFcns',@gaplotpareto);
%%
% Run the GAMULTIOBJ solver and display the number of solutions found on
% the Pareto front and the number of generations.
[x,Fval,exitFlag,Output] = gamultiobj(FitnessFunction,numberOfVariables,A, ...
    b,Aeq,beq,lb,ub,options);

fprintf('The number of points on the Pareto front was: %d\n', size(x,1));
fprintf('The number of generations was : %d\n', Output.generations);

%%
% The Pareto plot displays two competing objectives. For this problem,
% the Pareto front is known to be disconnected. The solution from
% GAMULTIOBJ can capture the Pareto front even if it is disconnected. Note
% that when you run this demo, your result may be different from the results
% shown because GAMULTIOBJ uses random number generators.

%% Elitist Multiobjective Genetic Algorithm
% The multiobjective genetic algorithm (GAMULTIOBJ) works on a population
% using a set of operators that are applied to the population. A population
% is a set of points in the design space. The initial population is
% generated randomly by default. The next generation of the population is
% computed using the non-dominated rank and a distance measure of the
% individuals in the current generation.

%%
% A non-dominated rank is assigned to each individual using the relative
% fitness. Individual 'p' dominates 'q' ('p' has a lower rank than 'q') if
% 'p' is strictly better than 'q' in at least one objective and 'p' is no
% worse than 'q' in all objectives. This is same as saying 'q' is dominated
% by 'p' or 'p' is non-inferior to 'q'. Two individuals 'p' and 'q' are
% considered to have equal ranks if neither dominates the other. The
% distance measure of an individual is used to compare individuals with
% equal rank. It is a measure of how far an individual is from the
% other individuals with the same rank.

%%
% The multiobjective GA function GAMULTIOBJ uses a controlled elitist
% genetic algorithm (a variant of NSGA-II [1]). An elitist GA always favors
% individuals with better fitness value (rank) whereas, a controlled
% elitist GA also favors individuals that can help increase the diversity
% of the population even if they have a lower fitness value. It is very
% important to maintain the diversity of population for convergence to an
% optimal Pareto front. This is done by controlling the elite members of
% the population as the algorithm progresses. Two options 'ParetoFraction'
% and 'DistanceFcn' are used to control the elitism. The Pareto fraction
% option limits the number of individuals on the Pareto front (elite
% members) and the  distance function helps to maintain diversity on a
% front by favoring individuals that are relatively far away on the front. 

%% Specifying Multiobjective GA Options
% We can chose the default distance measure function, @distancecrowding,
% that is provided in the toolbox or write our own function to calculate
% the distance measure of an individual. The crowding distance measure
% function in the toolbox takes an optional argument to calculate distance
% either in function space (phenotype) or design space (genotype). If
% 'genotype' is chosen, then the diversity on a Pareto front is based on
% the design space. The default choice is 'phenotype' and, in that case, the
% diversity is based on the function space. Here we choose 'genotype' for
% our distance function. We will pass our options structure 'options',
% created above, to GAOPTIMSET to modify the value of the parameter
% 'DistanceMeasureFcn'.

options = gaoptimset(options,'DistanceMeasureFcn',{@distancecrowding,'genotype'});

%%
% The Pareto fraction has a default value of 0.35 i.e., the solver will try
% to limit the number of individuals in the current population that are on
% the Pareto front to 35 percent of the population size. Here we set the
% Pareto fraction to 0.5. 

options = gaoptimset(options,'ParetoFraction',0.5);
%%
% Run the GAMULTIOBJ solver and display the number of solutions found on
% the Pareto front and the average distance measure of solutions.
[x,Fval,exitFlag,Output] = gamultiobj(FitnessFunction,numberOfVariables,A, ...
    b,Aeq,beq,lb,ub,options);

fprintf('The number of points on the Pareto front was: %d\n', size(x,1));
fprintf('The average distance measure of the solutions on the Pareto front was: %g\n', Output.averagedistance);
fprintf('The spread measure of the Pareto front was: %g\n', Output.spread);

%%
% A smaller average distance measure indicates that the solutions on the
% Pareto front are evenly distributed. However, if the Pareto front is
% disconnected, then the distance measure will not indicate the true spread
% of solutions. 

%% Specifying Population Options
% The default initial population is created using a uniform random number
% generator. Default values for the population size and the range of the
% initial population are used to create the initial population.

%%
% *Specify a population size*
%%
% The default population size used by GAMULTIOBJ is '15*numberOfVariables'.
% This may not be sufficient for problems with a large number of variables;
% a smaller population size may be sufficient for smaller problems. 
%%
% In this demo we specify a (larger) population size of 75 that will
% clearly identify the disconnected Pareto front in the plot. We will pass
% our options structure 'options', created above, to GAOPTIMSET to modify
% the value of the parameter 'PopulationSize' to be 75.
options = gaoptimset(options,'PopulationSize',75);

%%
% *Specify initial population range*
%%
% The initial population is generated using a uniform random number
% generator in a default range of [0;1]. This creates an initial population
% where all the points are in the range 0 to 1. For example, a population
% of size 5 in a problem with three variables could look like:
Population = rand(3,3)
%%
% The initial range can be set by changing the 'PopInitRange' option using
% GAOPTIMSET. The range must be a matrix with two rows. If the range has
% only one column, i.e., it is 2-by-1, then the range of every variable is
% the given range. For example, if we set the range to [-1; 1], then the
% initial range for our three variables is -1 to 1. To specify a different
% initial range for each variable, the range must be specified as a matrix
% with two rows and 'numberOfVariables' columns. For example if we set the
% range to
% [-1 0 -2;
%   1 2  2],
% then the first variable will be in the range -1 to 1, the second variable
% will be in the range 0 to 2 and the third variable will be in the range
% -2 to 2 (so each column corresponds to a variable).  
%
% The initial range can be specified using GAOPTIMSET. We will pass our
% options structure 'options' created above to GAOPTIMSET to modify the
% value of the parameter 'PopInitRange' so that initial population is
% created in the feasible region defined by bound constraints. 
options = gaoptimset(options,'PopInitRange',[lb;ub]);
%%
% Run the GAMULTIOBJ solver and display the number of solutions found on
% the Pareto front and the number of generations.
[x,Fval,exitFlag,Output] = gamultiobj(FitnessFunction,numberOfVariables,A, ...
    b,Aeq,beq,lb,ub,options);

fprintf('The number of points on the Pareto front was: %d\n', size(x,1));
fprintf('The number of generations was : %d\n', Output.generations);

%% Modifying the Stopping Criteria
% GAMULTIOBJ uses three different criteria to determine when to stop the
% solver. The solver stops when any one of the stopping criteria is met. It
% stops when the maximum number of generations is reached; by default this
% number is '200*numberOfVariables'. GAMULTIOBJ also stops if the average
% change in the spread of the Pareto front over the 'StallGenLimit'
% generations (default is 100) is less than tolerance specified in
% options.TolFun. The third criterion is the maximum time limit in seconds
% (default is Inf). Here we modify the stopping criteria to change the
% function tolerance (TolFun) to 1e-3 and increase the stall generations
% (StallGenLimit) to 150.
options = gaoptimset(options,'TolFun',1e-3,'StallGenLimit',150);
%%
% Run the GAMULTIOBJ solver and display the number of solutions found on
% the Pareto front and the number of generations.
[x,Fval,exitFlag,Output] = gamultiobj(FitnessFunction,numberOfVariables,A, ...
    b,Aeq,beq,lb,ub,options);

fprintf('The number of points on the Pareto front was: %d\n', size(x,1));
fprintf('The number of generations was : %d\n', Output.generations);

%% Multiobjective GA Hybrid Function
% We will use a hybrid scheme to find an optimal Pareto front for our
% multiobjective problem. GAMULTIOBJ can reach the region near an optimal
% Pareto front relatively quickly, but it can take many function
% evaluations to achieve convergence. A commonly used technique is to run 
% GAMULTIOBJ for a small number of generations to get near an optimum
% front. Then the solution from GAMULTIOBJ is used as an initial point for
% another optimization solver that is faster and more efficient for a local
% search. We use FGOALATTAIN as the hybrid solver with GAMULTIOBJ.
% FGOALATTAIN solves the goal attainment problem, which is one formulation
% for minimizing a multiobjective optimization problem. 

%%
% The hybrid functionality in multiobjective function GAMULTIOBJ is
% slightly different from that of the single objective function GA. In
% single objective GA the hybrid function starts at the best point returned
% by GA. However, in GAMULTIOBJ the hybrid solver will start at all the
% points on the Pareto front returned by GAMULTIOBJ. The new individuals
% returned by the hybrid solver are combined with the existing population
% and a new Pareto front is obtained. It may be useful to see the syntax of
% FGOALATTAIN function to better understand how the output from GAMULTIOBJ
% is internally converted to the input of FGOALATTAIN function. GAMULTIOBJ
% estimates the pseudo weights (required input for FGOALATTAIN) for each
% point on the Pareto front and runs the hybrid solver starting from each
% point on the Pareto front. Another required input, goal, is a vector
% specifying the goal for each objective. GAMULTIOBJ provides this input 
% as the extreme points from the Pareto front found so far.

%%
% Here we run GAMULTIOBJ without the hybrid function.
[x,Fval,exitFlag,Output] = gamultiobj(FitnessFunction,numberOfVariables,A, ...
    b,Aeq,beq,lb,ub,options);

fprintf('The number of points on the Pareto front was: %d\n', size(x,1));
fprintf('The average distance measure of the solutions on the Pareto front was: %g\n', Output.averagedistance);
fprintf('The spread measure of the Pareto front was: %g\n', Output.spread);

%%
% Here we use @fgoalattain as the hybrid function. We also reset the random
% number generators so that we can compare the results with the previous
% run (without the hybrid function).

options = gaoptimset(options,'HybridFcn',@fgoalattain);
% Reset the random state (only to compare with previous run)
set(RandStream.getDefaultStream,'State',Output.rngstate.state);
% Run the GAMULTIOBJ solver with hybrid function.
[x,Fval,exitFlag,Output,Population,Score] = gamultiobj(FitnessFunction,numberOfVariables,A, ...
    b,Aeq,beq,lb,ub,options);

fprintf('The number of points on the Pareto front was: %d\n', size(x,1));
fprintf('The average distance measure of the solutions on the Pareto front was: %g\n', Output.averagedistance);
fprintf('The spread measure of the Pareto front was: %g\n', Output.spread);
%%
% If the Pareto fronts obtained by GAMULTIOBJ alone and by using the
% hybrid function are close, we can compare them using the spread and
% the average distance measures. The average distance of the solutions on
% the Pareto front can be improved by using a hybrid function. The spread
% is a measure of the change in two fronts and that can be higher when
% hybrid function is used. This indicates that the front has changed
% considerably from that obtained by GAMULTIOBJ with no hybrid function.

%%
% It is certain that using the hybrid function will result in a optimal
% Pareto front but we may lose the diversity of the solution (because
% FGOALATTAIN does not try to preserve the diversity). This can be 
% indicated by a higher value of the average distance measure and the
% spread of the front. We can further improve the average distance measure
% of the solutions and the spread of the Pareto front by running GAMULTIOBJ
% again with the final population returned in the last run. Here, we should
% remove the hybrid function. 

options = gaoptimset(options,'HybridFcn',[]); % No hybrid function
% Provide initial population and scores 
options = gaoptimset(options,'InitialPopulation',Population,'InitialScore',Score);
% Run the GAMULTIOBJ solver with hybrid function.
[x,Fval,exitFlag,Output,Population,Score] = gamultiobj(FitnessFunction,numberOfVariables,A, ...
    b,Aeq,beq,lb,ub,options);

fprintf('The number of points on the Pareto front was: %d\n', size(x,1));
fprintf('The average distance measure of the solutions on the Pareto front was: %g\n', Output.averagedistance);
fprintf('The spread measure of the Pareto front was: %g\n', Output.spread);

%% References
%  [1] Kalyanmoy Deb, "Multi-Objective Optimization using Evolutionary
%  Algorithms", John Wiley & Sons ISBN 047187339.

displayEndOfDemoMessage(mfilename)
