% Global Optimization Toolbox
% Version 3.1.1 (R2011a) 09-Mar-2011
%
% Solvers
%   ga                    - Genetic algorithm solver.
%   gamultiobj            - Multi-objective genetic algorithm solver.
%   GlobalSearch          - A scatter-search based global optimization
%                           solver. 
%   MultiStart            - A multi-start global optimization solver.
%   patternsearch         - Pattern search solver.
%   simulannealbnd        - Simulated annealing solver.
%
% Accessing options
%   gaoptimset            - Create/modify a genetic algorithm options 
%                           structure.
%   gaoptimget            - Get options for genetic algorithm.
%   GlobalSearch          - Get/set options for GlobalSearch solver.
%   MultiStart            - Get/set options for MultiStart solver.
%   psoptimset            - Create/modify a pattern search options
%                           structure.
%   psoptimget            - Get options for pattern search.
%   saoptimset            - Create/modify a simulated annealing 
%                           options structure.
%   saoptimget            - Get options for simulated annealing.
%
% Graphical user interface
%   optimtool             - Optimization Tool graphical user interface.
%
% Utility for GlobalSearch and MultiStart solvers
%   createOptimProblem    - Create an optimization problem.
%
% Start point sets for MultiStart solver
%   CustomStartPointSet   - A start point set that contains custom start
%                           points.
%   RandomStartPointSet   - A random start point set.
% 
% Fitness scaling for genetic algorithm 
%   fitscalingshiftlinear - Offset and scale fitness to desired range.
%   fitscalingprop        - Proportional fitness scaling.
%   fitscalingrank        - Rank based fitness scaling.
%   fitscalingtop         - Top individuals reproduce equally.
%
% Selection for genetic algorithm
%   selectionremainder    - Remainder stochastic sampling without replacement.
%   selectionroulette     - Choose parents using roulette wheel.
%   selectionstochunif    - Choose parents using stochastic universal
%                           sampling (SUS). 
%   selectiontournament   - Each parent is the best of a random set.
%   selectionuniform      - Choose parents at random.
%
% Crossover (recombination) functions for genetic algorithm.
%   crossoverheuristic    - Move from worst parent to slightly past best 
%                           parent.
%   crossoverintermediate - Weighted average of the parents.
%   crossoverscattered    - Position independent crossover function.
%   crossoversinglepoint  - Single point crossover.
%   crossovertwopoint     - Two point crossover.
%   crossoverarithmetic   - Arithmetic mean between two parents satisfying 
%                           linear constraints and bound.
%
% Mutation functions for genetic algorithm
%   mutationgaussian      - Gaussian mutation.
%   mutationuniform       - Uniform multi-point mutation.
%   mutationadaptfeasible - Adaptive mutation for linearly constrained 
%                           problems.
%
% Distance function for multi-objective genetic algorithm
%   distancecrowding      - Calculates crowding distance for individuals
%
% Plot functions for genetic algorithm
%   gaplotbestf           - Plots the best score and the mean score.
%   gaplotbestindiv       - Plots the best individual in every generation
%                           as a bar plot.
%   gaplotdistance        - Plots average distance between some individuals.
%   gaplotexpectation     - Plots raw scores vs the expected number of 
%                           offspring.
%   gaplotgenealogy       - Plot the ancestors of every individual.
%   gaplotrange           - Plots the min, mean, and max of the scores.
%   gaplotscorediversity  - Plots a histogram of this generations scores.
%   gaplotscores          - Plots the scores of every member of the population.
%   gaplotselection       - Plots a histogram of parents.
%   gaplotstopping        - Plots stopping criteria levels.
%   gaplotmaxconstr       - Plots maximum nonlinear constraint violation
%   gaplotpareto          - Plots Pareto front for a multi-objective GA
%   gaplotparetodistance  - Plots distance measure of individuals on 
%                           Pareto front in multi-objective GA
%   gaplotrankhist        - Plots histogram of rank of the population
%   gaplotspread          - Plots spread of Pareto front in multi-objective 
%                           GA
%
% Output functions for genetic algorithm
%   gaoutputfile          - Writes iteration history of the genetic algorithm 
%                           solver to a file.
%   gaoutputoptions       - Prints all of the non-default options settings.
%   gaoutputfcntemplate   - Template file for a custom output function.
%
% Search methods for pattern search 
%   searchlhs             - Implements Latin hypercube sampling as a search
%                           method.
%   searchneldermead      - Implements Nelder-Mead simplex method
%                           (FMINSEARCH) to use as a search method.
%   searchga              - Implements genetic algorithm (GA) to use as a 
%                           search method.
%   searchfcntemplate     - Template file for a custom search method.
%
% Plot functions for pattern search
%   psplotbestf           - Plots best function value.
%   psplotbestx           - Plots current point in every iteration as a bar
%                           plot.
%   psplotfuncount        - Plots the number of function evaluation in every
%                           iteration.
%   psplotmeshsize        - Plots mesh size used in every iteration.
%   psplotmaxconstr       - Plots maximum nonlinear constraint violation
%
% Output functions for pattern search 
%   psoutputfile          - Writes iteration history of the pattern search 
%                           solver to a file.
%   psoutputfcntemplate   - Template file for a custom output function.
%
% Annealing functions for simulated annealing
%   annealingboltz        - Boltzman annealing.
%   annealingfast         - Fast annealing.
%   saannealingfcntemplate - Template file to write annealing function.
%
% Acceptance functions for simulated annealing
%   acceptancesa          - Simulated annealing acceptance function.
%   saacceptancefcntemplate -  Template file to write acceptance function.
%
% Temperature functions for simulated annealing
%   temperatureboltz      - Boltzman annealing temperature function.
%   temperatureexp        - Exponential annealing temperature function.
%   temperaturefast       - Fast annealing temperature function.
%   satemperaturefcntemplate - Template file to write temperature function.
%
% Plot functions for simulated annealing
%   saplotbestf           - Plots best function value.
%   saplotbestx           - Plots best point in every iteration as a bar plot.
%   saplotf               - Plots current function value.
%   saplotx               - Plots current point in every iteration as a bar plot.
%   saplotstopping        - Plots stopping criteria levels.
%   saplottemperature     - Plots mean temperature.
%

%   Copyright 2011 The MathWorks, Inc.
%   $Revision  $   $Date: 2010/10/08 16:50:46 $
