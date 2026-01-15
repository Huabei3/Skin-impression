%% Simulated Annealing Options
% This demonstration shows of how to create and manage options for 
% the simulated annealing function SIMULANNEALBND using SAOPTIMSET 
% in the Global Optimization Toolbox.

%   Copyright 2006-2009 The MathWorks, Inc.
%   $Revision: 1.1.6.2 $  $Date: 2009/10/10 20:10:10 $

%% Optimization Problem Setup
% SIMULANNEALBND searches for a minimum of a function using simulated annealing.
% For this demo we use SIMULANNEALBND to minimize the objective function
% DEJONG5FCN. This function is a real valued function of two variables and has
% many local minima making it difficult to optimize. There is only one global
% minimum at x=(-32,-32), where f(x) = 0.998. To define our problem, we must
% define the objective function, start point, and bounds specified by the range
% -64 <= x(i) <= 64 for each x(i).
ObjectiveFunction = @dejong5fcn;
startingPoint = [-30 0];
lb = [-64 -64];
ub = [64 64];

%% 
% The function PLOTOBJECTIVE in the toolbox plots the objective function over
% the range -64 <= x1 <= 64, -64 <= x2 <= 64.
plotobjective(ObjectiveFunction,[-64 64; -64 64]);
view(-15,150);

%%
% Now, we can run the SIMULANNEALBND solver to minimize our objective function.
[x,fval,exitFlag,output] = simulannealbnd(ObjectiveFunction,startingPoint,lb,ub);

fprintf('The number of iterations was : %d\n', output.iterations);
fprintf('The number of function evaluations was : %d\n', output.funccount);
fprintf('The best function value found was : %g\n', fval);

%%
% Note that when you run this demo, your results may be different from the
% results shown above because simulated annealing algorithm uses random numbers
% to generate points.

%% Adding Visualization
% SIMULANNEALBND can accept one or more plot functions through an 'options'
% argument. This feature is useful for visualizing the performance of the
% solver at run time. Plot functions are selected using SAOPTIMSET. The
% help for SAOPTIMSET contains a list of plot functions to choose from, or you
% can provide your own custom plot functions.
%
% To select multiple plot functions, SAOPTIMSET is used to create an options
% structure. For this example, we select SAPLOTBESTF, which plots the best
% function value every iteration, SAPLOTTEMPERATURE, which shows the current
% temperature in each dimension at every iteration, SAPLOTF, which shows the
% current function value (remember that the current value is not necessarily the
% best one), and SAPLOTSTOPPING, which plots the percentage of stopping criteria
% satisfied every iteration.
options = saoptimset('PlotFcns',{@saplotbestf,@saplottemperature,@saplotf,@saplotstopping});
%%
% Run the solver.
simulannealbnd(ObjectiveFunction,startingPoint,lb,ub,options);


%% Specifying Temperature Options
% The temperature parameter used in simulated annealing controls the
% overall search results. The temperature for each dimension is used to
% limit the extent of search in that dimension. The toolbox lets you
% specify initial temperature as well as ways to update temperature during the
% solution process. The two temperature-related options are the
% |InitialTemperature| and the |TemperatureFcn|. 

%%
% *Specifying initial temperature*
%%
% The default initial temperature is set to 100 for each dimension. If you
% want the initial temperature to be different in different dimensions then
% you must specify a vector of temperatures. This may be necessary in cases
% when problem is scaled differently in each dimensions. For example,
options = saoptimset('InitialTemperature',[300 50]);
%%
% |InitialTemperature| can be set to a vector of length less than the number
% of variables (dimension); the solver expands the vector to the remaining
% dimensions by taking the last element of the initial temperature vector.
% Here we want the initial temperature to be the same in all dimensions    
% so we need only specify the single temperature.
options = saoptimset('InitialTemperature',100);
%%
% *Specifying a temperature function*
%%
% The default temperature function used by SIMULANNEALBND is called
% TEMPERATUREEXP. In the temperatureexp schedule, the temperature at any
% given step is .95 times the temperature at the previous step. This causes
% the temperature to go down slowly at first but ultimately get cooler faster
% than other schemes. If another scheme is desired, e.g. Boltzmann schedule
% or "Fast" schedule annealing, then TEMPERATUREBOLTZ or TEMPERATUREFAST can be
% used respectively. To select the fast temperature schedule, we can update our
% previously created options structure 'options' by passing 'options' to
% SAOPTIMSET.
options = saoptimset(options,'TemperatureFcn',@temperaturefast);

%%
% *Specifying reannealing*
%%
% Reannaling is a part of annealing process. After a certain number of
% new points are accepted, the temperature is raised to a higher value in hope
% to restart the search and move out of a local minima. Performing reannealing
% too soon may not help the solver identify a minimum, so a relatively high
% interval is a good choice. The interval at which reannealing happens can be
% set using the |ReannealInterval| option. Here, we reduce the default
% reannealing interval to 50 because the function seems to be flat in many
% regions and solver might get stuck rapidly.
options = saoptimset(options,'ReannealInterval',50);
%%
% We can also set the |Display| option to control the level of display on
% the command prompt. Here we set the display option to 'iter' and change the
% display interval to 400. 
options = saoptimset(options,'Display','iter','DisplayInterval',400);
%%
% Now that we have setup the new temperature options we run the solver
% again
[x,fval,exitFlag,output] = simulannealbnd(ObjectiveFunction,startingPoint,lb,ub,options);

%%
% Notice that every iteration at which reannealing happens is denoted by a '*'
% and is always displayed. 

fprintf('The number of iterations was : %d\n', output.iterations);
fprintf('The number of function evaluations was : %d\n', output.funccount);
fprintf('The best function value found was : %g\n', fval);
%% Reproducing Results 
% SIMULANNEALBND is a nondeterministic algorithm.  This means that running
% the solver more than once without changing any settings may give different
% results. This is because SIMULANNEALBND utilizes MATLAB(R) random number
% generators when it generates subsequent points and also when it
% determines whether or not to accept new points. Every time a random 
% number is generated the state of the random number generators change.

%%
% To see this, two runs of SIMULANNEALBND solver yields:
[x,fval] = simulannealbnd(ObjectiveFunction,startingPoint,lb,ub,options);
fprintf('The best function value found was : %g\n', fval);
%%
% And, 
[x,fval] = simulannealbnd(ObjectiveFunction,startingPoint,lb,ub,options);
fprintf('The best function value found was : %g\n', fval);

%% 
% In the previous two runs SIMULANNEALBND gives different results.

%%
% We can reproduce our results if we reset the states of the random
% number generators between runs of the solver by using information returned by
% SIMULANNEALBND. SIMULANNEALBND returns the states of the random number
% generators at the time SIMULANNEALBND is called in the output argument. This
% information can be used to reset the states. Here we reset the states between
% runs using this output information so the results of the next two runs are the
% same.

%% 
[x,fval,exitFlag,output] = simulannealbnd(ObjectiveFunction,startingPoint,lb,ub,options);
fprintf('The best function value found was : %g\n', fval);
%%
% We reset the state of the random number generator.
set(RandStream.getDefaultStream,'State',output.rngstate.state);
%%
% Now, let's run SIMULANNEALBND again.
[x,fval] = simulannealbnd(ObjectiveFunction,startingPoint,lb,ub,options);
fprintf('The best function value found was : %g\n', fval);

%% Modifying the Stopping Criteria
% SIMULANNEALBND uses six different criteria to determine when to stop the
% solver. SIMULANNEALBND stops when the maximum number of iterations or function
% evaluation is exceeded; by default the maximum number of iterations is set to
% Inf and the maximum number of function evaluations is
% |3000*numberOfVariables|. SIMULANNEALBND keeps track of the average change in
% the function value for |StallIterLimit| iterations. If the average change is
% smaller than the function tolerance, |TolFun|, then the algorithm will stop.
% The solver will also stop when the objective function value reaches
% |ObjectiveLimit|. Finally the solver will stop after running for |TimeLimit|
% seconds. Here we set the |TolFun| to 1e-8.
options = saoptimset(options,'TolFun',1e-5);
%%
% Run the SIMULANNEALBND solver.
[x,fval,exitFlag,output] = simulannealbnd(ObjectiveFunction,startingPoint,lb,ub,options);
fprintf('The number of iterations was : %d\n', output.iterations);
fprintf('The number of function evaluations was : %d\n', output.funccount);
fprintf('The best function value found was : %g\n', fval);

displayEndOfDemoMessage(mfilename)
