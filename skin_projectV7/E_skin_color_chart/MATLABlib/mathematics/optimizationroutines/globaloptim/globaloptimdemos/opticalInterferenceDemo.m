%% Maximizing Monochromatic Polarized Light Interference Patterns Using GlobalSearch and MultiStart
% This demonstration shows how to use the functions |GlobalSearch| and |MultiStart|.

%   Copyright 2009-2010 The MathWorks, Inc.
%   $Revision: 1.1.8.3 $   $Date: 2010/11/01 19:37:00 $

%% Introduction
%
% This demo shows how Global Optimization Toolbox functions,
% particularly |GlobalSearch| and |MultiStart|, can help locate the maximum
% of an electromagnetic interference pattern. For simplicity of modeling,
% the pattern arises from monochromatic polarized light spreading out from
% point sources.
% 
% The electric field due to source i measured in the direction of
% polarization at point x and time t is 
%
% $$E_i = \frac{A_i}{d_i(x)} \sin(\phi_i + \omega (t - d_i(x)/c) ),$$ 
%
% where $\phi_i$ is the phase at time zero for source $i$, $c$ is the speed
% of light, $\omega$ is the frequency of the light, $A_i$ is the amplitude
% of source $i$, and $d_i(x)$ is the distance from source $i$ to $x$.
%  
% For a fixed point $x$ the intensity of the light is the time average of
% the square of the net electric field. The net electric field is sum of
% the electric fields due to all sources. The time average depends only on
% the sizes and relative phases of the electric fields at $x$. To calculate
% the net electric field, add up the individual contributions using the
% phasor method. For phasors, each source contributes a vector. The length
% of the vector is the amplitude divided by distance from the source, and
% the angle of the vector, $\phi_i - \omega d_i(x)/c$ is the phase at the
% point.
%
% For this demo, we define three point sources with the same frequency
% ($\omega$) and amplitude ($A$), but varied initial phase ($\phi_i$). We
% arrange these sources on a fixed plane.

% Frequency is proportional to the number of peaks
relFreqConst = 2*pi*2.5;
amp = 2.2;
phase = -[0; 0.54; 2.07];

numSources = 3;
height = 3;

% All point sources are aligned at [x_i,y_i,z]
xcoords = [2.4112
           0.2064
           1.6787];
ycoords = [0.3957
           0.3927
           0.9877];
zcoords = height*ones(numSources,1);          

origins = [xcoords ycoords zcoords];

%% Visualize the Interference Pattern
% Now let's visualize a slice of the interference pattern on the plane z = 0.
%
% As you can see from the plot below, there are many peaks and valleys
% indicating constructive and destructive interference.

% Pass additional parameters via an anonymous function:
waveIntensity_x = @(x) waveIntensity(x,amp,phase, ...
    relFreqConst,numSources,origins);
% Generate the grid
[X,Y] = meshgrid(-4:0.035:4,-4:0.035:4);
% Compute the intensity over the grid
Z = arrayfun(@(x,y) waveIntensity_x([x y]),X,Y);
% Plot the surface and the contours
figure;surf(X,Y,Z,'EdgeColor','none'),xlabel('x'),ylabel('y'),zlabel('intensity')

%% Posing the Optimization Problem
% We are interested in the location where this wave intensity reaches
% its highest peak. 
%
% The wave intensity ($I$) falls off as we move away from the source 
% proportional to $1/d_i(x)$. Therefore, let's restrict the space of
% viable solutions by adding constraints to the problem.
%
% If we limit the exposure of the sources with an aperture, then we can
% expect the maximum to lie in the intersection of the projection of the
% apertures onto our observation plane. We model the effect of an aperture
% by restricting the search to a circular region centered at each source. 
%
% We also restrict the solution space by adding bounds to the problem.
% Although these bounds may be redundant (given the nonlinear constraints),
% they are useful since they restrict the range in which start points are
% generated (see the
% <http://www.mathworks.com/access/helpdesk/help/toolbox/gads/bsc59ag-2.html
% documentation> for more information).
%
% Now our problem has become:
%
% $$ \max_{x,y} I(x,y) $$
%
% subject to
%
% $$ (x - x_{c1})^2 + (y - y_{c1})^2 \le r_1^2 $$
%
% $$ (x - x_{c2})^2 + (y - y_{c2})^2 \le r_2^2 $$
%
% $$ (x - x_{c3})^2 + (y - y_{c3})^2 \le r_3^2 $$
%
% $$-0.5 \leq x \leq 3.5$$
%
% $$-2 \leq y \leq 3$$
%
% where $(x_{cn},y_{cn})$ and $r_n$ are the coordinates and aperture radius
% of the $n^{th}$ point source, respectively. Each source is given an
% aperture with radius 3. The given bounds encompass the feasible region.
%
% The objective ($I(x,y)$) and nonlinear constraint functions are defined
% in separate MATLAB(R) files, |waveIntensity.m| and |apertureConstraint.m|,
% respectively, which are listed at the end of this demo.
%

%% Visualization with Constraints
% Now let's visualize the contours of our interference pattern with the
% nonlinear constraint boundaries superimposed. The feasible region is the
% interior of the intersection of the three circles (yellow, green, and
% blue). The bounds on the variables are indicated by the dashed-line box.
%

% Visualize the contours of our interference surface
domain = [-3 5.5 -4 5];
figure;
ezcontour(@(X,Y) arrayfun(@(x,y) waveIntensity_x([x y]),X,Y),domain,150);
hold on

% Plot constraints
g1 = @(x,y)  (x-xcoords(1)).^2 + (y-ycoords(1)).^2 - 9;
g2 = @(x,y)  (x-xcoords(2)).^2 + (y-ycoords(2)).^2 - 9;
g3 = @(x,y)  (x-xcoords(3)).^2 + (y-ycoords(3)).^2 - 9;
h1 = ezplot(g1,domain);
set(h1,'Color',[0.8 0.7 0.1],'LineWidth',1.5); % yellow
h2 = ezplot(g2,domain);
set(h2,'Color',[0.3 0.7 0.5],'LineWidth',1.5); % green
h3 = ezplot(g3,domain);
set(h3,'Color',[0.4 0.4 0.6],'LineWidth',1.5); % blue

% Plot bounds
lb = [-0.5 -2];
ub = [3.5 3];
line([lb(1) lb(1)],[lb(2) ub(2)],'LineStyle','--')
line([ub(1) ub(1)],[lb(2) ub(2)],'LineStyle','--')
line([lb(1) ub(1)],[lb(2) lb(2)],'LineStyle','--')
line([lb(1) ub(1)],[ub(2) ub(2)],'LineStyle','--')
title('Pattern Contours with Constraint Boundaries')

%% Setting Up and Solving the Problem with a Local Solver
% Given the nonlinear constraints, we need a constrained nonlinear solver,
% namely, |fmincon|. 
%
% Let's set up a problem structure describing our optimization problem. We
% want to maximize the intensity function, so we negate the values returned
% form |waveIntensity|. Let's choose an arbitrary start point that happens
% to be near the feasible region. 
%
% For this small problem, we'll use |fmincon|'s SQP algorithm.

% Pass additional parameters via an anonymous function:
apertureConstraint_x = @(x) apertureConstraint(x,xcoords,ycoords);

% Set up fmincon's options
x0 = [3 -1];
opts = optimset('Algorithm','sqp');
problem = createOptimProblem('fmincon','objective', ...
    @(x) -waveIntensity_x(x),'x0',x0,'lb',lb,'ub',ub, ...
    'nonlcon',apertureConstraint_x,'options',opts);

% Call fmincon
[xlocal,fvallocal] = fmincon(problem)

%% 
% Now, let's see how we did by showing the result of |fmincon| in our contour
% plot. Notice that |fmincon| did not reach the global maximum, which is also
% annotated on the plot. Note that we'll only plot the bound that was
% active at the solution.

[~,maxIdx] = max(Z(:));
xmax = [X(maxIdx),Y(maxIdx)]
figure;contour(X,Y,Z);hold on

% Show bounds
line([lb(1) lb(1)],[lb(2) ub(2)],'LineStyle','--')

% Create textarrow showing the location of xlocal
annotation('textarrow',[0.25 0.21],[0.86 0.60],'TextEdgeColor',[0 0 0],...
    'TextBackgroundColor',[1 1 1],'FontSize',11,'String',{'Single Run Result'});

% Create textarrow showing the location of xglobal
annotation('textarrow',[0.44 0.50],[0.63 0.58],'TextEdgeColor',[0 0 0],...
    'TextBackgroundColor',[1 1 1],'FontSize',12,'String',{'Global Max'});

axis([-1 3.75 -3 3])

%% Using |GlobalSearch| and |MultiStart|
% Given an arbitrary initial guess, |fmincon| gets stuck at a nearby local
% maximum. Global Optimization Toolbox solvers, particularly
% |GlobalSearch| and |MultiStart|, give us a better chance at finding the
% global maximum since they will try |fmincon| from multiple generated
% initial points (or our own custom points, if we choose).
%
% Our problem has already been set up in the |problem| structure, so now we
% construct our solver objects and run them. The first output from |run| is
% the location of the best result found. 

% Construct a GlobalSearch object
gs = GlobalSearch; 
% Construct a MultiStart object based on our GlobalSearch attributes
ms = MultiStart;

% Run GlobalSearch
tic;
[xgs,~,~,~,solsgs] = run(gs,problem);
toc
xgs

% Run MultiStart with 15 randomly generated points
tic;
[xms,~,~,~,solsms] = run(ms,problem,15);
toc
xms

%% Examining Results
% Let's examine the results that both solvers have returned. An important
% thing to note is that the results will vary based on the random start
% points created for each solver. Another run through this demo may give
% different results. The coordinates of the best results |xgs| and |xms|
% printed to the command line. We'll show unique results returned by
% |GlobalSearch| and |MultiStart| and highlight the best results from each
% solver, in terms of proximity to the global solution. 
%
% The fifth output of each solver is a vector containing distinct minima
% (or maxima, in this case) found. We'll plot the (x,y) pairs of the
% results, |solsgs| and |solsms|, against our contour plot we used before.

% Plot GlobalSearch results using the '*' marker
xGS = cell2mat({solsgs(:).X}');
scatter(xGS(:,1),xGS(:,2),'*','MarkerEdgeColor',[0 0 1],'LineWidth',1.25)

% Plot MultiStart results using a circle marker
xMS = cell2mat({solsms(:).X}');
scatter(xMS(:,1),xMS(:,2),'o','MarkerEdgeColor',[0 0 0],'LineWidth',1.25)
legend('Intensity','Bound','GlobalSearch','MultiStart','Location','best')

title('GlobalSearch and MultiStart Results')

%% Relaxing the Bounds
% With the tight bounds on the problem, both |GlobalSearch| and
% |MultiStart| were able to locate the global maximum in this run.
% 
% Finding tight bounds can be difficult to do in practice, when not much is
% known about the objective function or constraints. In general though, we
% may be able to guess a reasonable region in which we would like to
% restrict the set of start points. For demonstration purposes, let's relax
% our bounds to define a larger area in which to generate start points and
% re-try the solvers. 

% Relax the bounds to spread out the start points
problem.lb = -5*ones(2,1);
problem.ub = 5*ones(2,1);

% Run GlobalSearch
tic;
[xgs,~,~,~,solsgs] = run(gs,problem);
toc
xgs

% Run MultiStart with 15 randomly generated points
tic;
[xms,~,~,~,solsms] = run(ms,problem,15);
toc
xms

%%

% Show the contours
figure;contour(X,Y,Z);hold on

% Create textarrow showing the location of xglobal
annotation('textarrow',[0.44 0.50],[0.63 0.58],'TextEdgeColor',[0 0 0],...
    'TextBackgroundColor',[1 1 1],'FontSize',12,'String',{'Global Max'});
axis([-1 3.75 -3 3])

% Plot GlobalSearch results using the '*' marker
xGS = cell2mat({solsgs(:).X}');
scatter(xGS(:,1),xGS(:,2),'*','MarkerEdgeColor',[0 0 1],'LineWidth',1.25)

% Plot MultiStart results using a circle marker
xMS = cell2mat({solsms(:).X}');
scatter(xMS(:,1),xMS(:,2),'o','MarkerEdgeColor',[0 0 0],'LineWidth',1.25)

% Highlight the best results from each: 
% GlobalSearch result in red, MultiStart result in blue
plot(xgs(1),xgs(2),'sb','MarkerSize',12,'MarkerFaceColor',[1 0 0])
plot(xms(1),xms(2),'sb','MarkerSize',12,'MarkerFaceColor',[0 0 1])
legend('Intensity','GlobalSearch','MultiStart','Best GS','Best MS','Location','best')

title('GlobalSearch and MultiStart Results with Relaxed Bounds')
%%
% The best result from |GlobalSearch| is shown by the red square and the
% best result from |MultiStart| is shown by the blue square.

%% Tuning |GlobalSearch| Parameters
% Notice that in this run, given the larger area defined by the bounds,
% neither solver was able to identify the point of maximum intensity. We
% could try to overcome this in a couple of ways. First, we examine
% |GlobalSearch|. 
%
% Notice that |GlobalSearch| only ran |fmincon| a few times. To increase
% the chance of finding the global maximum, we would like to run more
% points. To restrict the start point set to the candidates most likely to
% find the global maximum, we'll instruct each solver to ignore start
% points that do not satisfy constraints by setting the |StartPointsToRun|
% property to |bounds-ineqs|. Additionally, we will set the |MaxWaitCycle|
% and |BasinRadiusFactor| properties so that |GlobalSearch| will be able to
% identify the narrow peaks quickly. Reducing |MaxWaitCycle| causes
% |GlobalSearch| to decrease the basin of attraction radius by the
% |BasinRadiusFactor| more often than with the default setting. 

% Increase the total candidate points, but filter out the infeasible ones
gs = GlobalSearch(gs,'StartPointsToRun','bounds-ineqs', ...
    'MaxWaitCycle',3,'BasinRadiusFactor',0.3);
% Run GlobalSearch
tic;
xgs = run(gs,problem);
toc
xgs

%% Utilizing |MultiStart|'s Parallel Capabilities
% A brute force way to improve our chances of finding the global maximum is
% to simply try more start points. Again, this may not be practical in all
% situations. In our case, we've only tried a small set so far and the run
% time was not terribly long. So, it's reasonable to try more start points.
% To speed the computation we'll run |MultiStart| in parallel if Parallel
% Computing Toolbox(TM) is available.

% Set the UseParallel property of MultiStart
ms = MultiStart(ms,'UseParallel','always');

try
    demoOpenedMLPool = false;
    % Open a matlabpool if one is not already open
    % (requires Parallel Computing Toolbox)
    if matlabpool('size') == 0
        matlabpool open
        demoOpenedMLPool = true;
    end
catch ME
    warning('globaloptimdemos:opticalInterferenceDemo:noPCT', ...
        'Unable to open a matlabpool. Parallel Computing Toolbox is required to use matlabpool. Running MultiStart in serial...');
end

% Run the solver
tic;
xms = run(ms,problem,50);
toc
xms

if demoOpenedMLPool
    % Make sure to close the matlabpool if one was opened in this demo
    matlabpool close
end
    

%% Objective and Nonlinear Constraints
% Here we list the functions that define the optimization problem:
type waveIntensity
type apertureConstraint
type distanceFromSource


displayEndOfDemoMessage(mfilename)
