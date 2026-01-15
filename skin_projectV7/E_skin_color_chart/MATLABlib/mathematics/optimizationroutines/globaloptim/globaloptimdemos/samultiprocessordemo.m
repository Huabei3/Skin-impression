%% Custom Data Type Optimization Using Simulated Annealing
% This is a demonstration of how to use the simulated annealing to minimize a
% function using a custom data type. Here simulated annealing is customized
% to solve the multiprocessor scheduling problem.

%   Copyright 2006-2009 The MathWorks, Inc.
%   $Revision: 1.1.6.1 $   $Date: 2009/08/29 08:28:20 $

%% Multiprocessor Scheduling Problem
% The multiprocessor scheduling problem consists of finding an optimal
% distribution of task on a set of processors. The number of processors and
% number of tasks are given. Time taken to complete a task by a processor is
% also provided as data. Each processor runs independently, but each can only
% run one job at a time.  We call an assignment of all jobs to available
% processors a "schedule".  The goal of the problem is to determine the shortest
% schedule for the given set of tasks.

%%
% First we determine how to express this problem in terms of a custom data type
% optimization problem that SIMULANNEALBND function can solve. We come up with
% the following scheme: first, let each task be represented by an integer
% between 1 and the total number of tasks. Similarly, each processor is
% represented by an integer between 1 and the number of processors. Now we can
% store the amount of time a given job will take on a given processor in a
% matrix called "lengths". The amount of time "t" that the processor "i" takes
% to complete the task "j" will be stored in lengths(i,j).  
%
% We can represent a schedule in a similar manner. In a given schedule, the rows
% (integer between 1 to number of processors) will represent the processors and
% the columns (integer between 1 to number of tasks) will represent the tasks.
% For example, the schedule [1 2 3;4 5 0;6 0 0] would be tasks 1, 2, and 3
% performed on processor 1, tasks 4 and 5 performed on processor 2, and task 6
% performed on processor 3.
%%
% Here we define our number of tasks, number of processors, and lengths array.
% The different coefficients for the various rows represent the fact that
% different processors work with different speeds.  We also define a
% "sampleSchedule" which will be our starting point input to SIMULANNEALBND.

numberOfProcessors = 11;
numberOfTasks = 40;
lengths = [10*rand(1,numberOfTasks);
           7*rand(1,numberOfTasks);
           2*rand(1,numberOfTasks);
           5*rand(1,numberOfTasks);
           3*rand(1,numberOfTasks);
           4*rand(1,numberOfTasks);
           1*rand(1,numberOfTasks);
           6*rand(1,numberOfTasks);
           4*rand(1,numberOfTasks);
           3*rand(1,numberOfTasks);
           1*rand(1,numberOfTasks)];
       
% Random distribution of task on processors (starting point)
sampleSchedule = zeros(numberOfProcessors,numberOfTasks);
for task = 1:numberOfTasks
    processorID = 1 + floor(rand*(numberOfProcessors));
    index = find(sampleSchedule(processorID,:)==0);
    sampleSchedule(processorID,index(1)) = task;
end

%% Simulated Annealing For a Custom Data Type
% By default, the simulated annealing algorithm solves optimization
% problems assuming that the decision variables are double data types.
% Therefore, the annealing function for generating subsequent points assumes
% that the current point is a vector of type double. However, if the |DataType|
% option is set to 'custom' the simulated annealing solver can also work on
% optimization problems involving arbitrary data types. You can use any valid
% MATLAB(R) data structure you like as decision variable. For example, if we want
% SIMULANNEALBND to use "sampleSchedule" as decision variable, a custom data
% type can be specified using a matrix of integers. In addition to setting the
% |DataType| option to 'custom' we also need to provide a custom annealing
% function via the |AnealingFcn| option that can generate new points.

%% Custom Annealing Functions
% This section demonstrates how to create and use the required custom annealing
% function. A trial point for the multiprocessor scheduling problem is a 
% matrix of processor (rows) and tasks (columns) as discussed before.  The
% custom annealing function for the multiprocessor scheduling problem will take
% a job schedule as input. The annealing function will then modify this schedule
% and return a new schedule that has been changed by an amount proportional to
% the temperature (as is customary with simulated annealing). Here we display
% our custom annealing function.
type mulprocpermute.m

%% Objective Function
% We need an objective function for the multiprocessor scheduling problem. The
% objective function returns the total time required for a given schedule (which
% is the maximum of the times that each processor is spending on its tasks).  As
% such, the objective function also needs the lengths matrix to be able to
% calculate the total times.  We are going to attempt to minimize this total
% time. Here we display our objective function
type mulprocfitness.m

%%
% SIMULANNEALBND will call our objective function with just one argument |x|,
% but our fitness function has two arguments: |x| and "lengths". We can use
% an anonymous function to capture the values of the additional argument,
% the lengths matrix. We create a function handle 'ObjectiveFcn' to an
% anonymous function that takes one input |x|, but calls 'mulprocfitness'
% with |x| and "lengths". The variable "lengths" has a value when the
% function handle 'FitnessFcn' is created so these values are captured by
% the anonymous function.

% lengths was defined earlier
fitnessfcn = @(x) mulprocfitness(x,lengths);

%%
% We can add a custom plot function to plot the length of time that the
% tasks are taking on each processor.  Each bar represents a processor, and
% the differnet colored chunks of each bar are the different tasks.
type mulprocplot.m

%%
% But remember, in simulated annealing the current schedule is not
% necessarily the best schedule found so far. We create a second custom
% plot function that will display to us the best schedule that has been
% discovered so far.
type mulprocplotbest.m

%% Simulated Annealing Options Setup
% We choose the custom annealing and plot functions that we have created,
% as well as change some of the default options. |ReannealInterval| is set to
% 800 because lower values for |ReannealInterval| seem to raise the temperature
% when the solver was beginning to make a lot of local progress. We also
% decrease the |StallIterLimit| to 800 because the default value makes the
% solver too slow. Finally, we must set the |DataType| to 'custom'.
options = saoptimset('DataType', 'custom', 'AnnealingFcn', @mulprocpermute, ...
    'StallIterLimit',800, 'ReannealInterval', 800, 'PlotInterval', 50, ...
    'PlotFcns', {{@mulprocplot, lengths},{@mulprocplotbest, lengths},@saplotf,@saplotbestf});
%%
% Finally, we call simulated annealing with our problem information.
schedule = simulannealbnd(fitnessfcn, sampleSchedule, [], [], options);
% Remove zero columns (all processes are idle)
maxlen = 0;
for i = 1:size(schedule,1)
    if max(nnz(schedule(i,:)))>maxlen
        maxlen = max(nnz(schedule(i,:)));
    end
end
% Display the schedule
schedule = schedule(:,1:maxlen)

displayEndOfDemoMessage(mfilename)