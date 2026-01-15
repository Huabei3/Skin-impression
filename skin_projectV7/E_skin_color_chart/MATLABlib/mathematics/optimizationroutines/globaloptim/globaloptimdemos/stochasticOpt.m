%% Optimization of Stochastic Objective Function
% This is a demonstration of how to find a minimum of a stochastic objective 
% function using PATTERNSEARCH function in the Global Optimization Toolbox. 
% We also demonstrate why the Optimization Toolbox(TM) functions are not 
% suitable for this kind of problems. A simple 2-dimensional optimization 
% problem is selected for this demo to help visualize the objective function.

%   Copyright 2005-2009 The MathWorks, Inc.
%   $Revision: 1.1.6.2 $  $Date: 2009/10/10 20:10:11 $

%% Initialization
X0 = [2.5 -2.5];   % Starting point.
LB = [-5 -5];      % Lower bound
UB = [5 5];        % Upper bound
range = [LB(1) UB(1); LB(2) UB(2)];
Objfcn = @smoothFcn; % Handle to the objective function.
% Plot the smooth objective function
clf;showSmoothFcn(Objfcn,range); hold on;
title('Smooth objective function')
plot3(X0(1),X0(2),Objfcn(X0)+30,'om','MarkerSize',12, ...
    'MarkerFaceColor','r'); hold off;
set(gca,'CameraPosition',[-31.0391  -85.2792 -281.4265]);
set(gca,'CameraTarget',[0 0 -50])
set(gca,'CameraViewAngle',6.7937)
fig = gcf;

%% Run FMINCON on a Smooth Objective Function
% The objective function is smooth (twice continuously differentiable). We
% will solve the optimization problem using FMINCON function from the
% Optimization Toolbox. FMINCON finds a constrained minimum of a function
% of several variables. This function has a unique minimum at the point x*
% = (-5.0,-5) where it has a function value f(x*) = -250.

% Set options to display iterative results.
options = optimset('Algorithm','active-set','Display','iter', ...
    'OutputFcn',@fminuncOutps);
[Xop,Fop] = fmincon(Objfcn,X0,[],[],[],[],LB,UB,[],options)
figure(fig);
hold on;
% Plot the final point
plot3(Xop(1),Xop(2),Fop,'dm','MarkerSize',12,'MarkerFaceColor','m');
hold off;

%% Stochastic Objective Function
% The objective function we use now is the same as the previous example but
% with some random noise added to it. This is done by adding a random
% component to the function value. 

% Reset the state of random number generator
reset(RandStream.getDefaultStream);
peaknoise = 4.5;
Objfcn = @(x) smoothFcn(x,peaknoise); % Handle to the objective function.
% Plot the objective function (non-smooth)
fig = figure;
showSmoothFcn(Objfcn,range);
title('Stochastic objective function')
set(gca,'CameraPosition',[-31.0391  -85.2792 -281.4265]);
set(gca,'CameraTarget',[0 0 -50])
set(gca,'CameraViewAngle',6.7937)
%% Run FMINCON on a Stochastic Objective Function
% The objective function is stochastic and not smooth. FMINCON is a general
% constrained optimization solver which finds a local minima using first
% derivative of the objective function. If derivative of the objective
% function is not provided, FMINCON uses finite difference to approximate
% first derivative  of the objective function. In this example, the
% objective function have some random noise in it. The derivatives hence
% could be highly unreliable. FMINCON can potentially stop at a point which
% is not a minimum. This may happen because the optimal conditions seems to
% be satisfied at the final point because of noise or it could not make any
% progress.
options = optimset('Algorithm','active-set','Display','iter');
[Xop,Fop] = fmincon(Objfcn,X0,[],[],[],[],LB,UB,[],options)
figure(fig);
hold on;
plot3(X0(1),X0(2),Objfcn(X0)+30,'om','MarkerSize',12,'MarkerFaceColor','r');
plot3(Xop(1),Xop(2),Fop,'dm','MarkerSize',12,'MarkerFaceColor','m');

%% Run PATTERNSEARCH
% We will now use PATTERNSEARCH from the Global Optimization Toolbox.
% Pattern search optimization techniques are a class of direct search methods 
% for optimization. A pattern search algorithm does not require any derivative 
% information of the objective function to find an optimal point.
PSoptions = psoptimset('Display','iter','OutputFcn',@psOut);
[Xps,Fps] = patternsearch(Objfcn,X0,[],[],[],[],LB,UB,PSoptions)
figure(fig);
hold on;
plot3(Xps(1),Xps(2),Fps,'dr','MarkerSize',12,'MarkerFaceColor','r');
hold off
%%
% Pattern search algorithm is not affected by random noise in the objective
% functions. Pattern search requires only function value and not the
% derivatives, hence noise (of some uniform kind) may not affect it.
% However, pattern search requires more function evaluation to find the
% true minimum than derivative based algorithms, a cost for not using the
% derivatives.

displayEndOfDemoMessage(mfilename)
