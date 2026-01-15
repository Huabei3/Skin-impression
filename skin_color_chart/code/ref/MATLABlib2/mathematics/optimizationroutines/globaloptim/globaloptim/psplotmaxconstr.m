function stop = psplotmaxconstr(optimvalues,flag)
%PSPLOTMAXCONSTR PlotFcn to plot maximum nonlinear constraint violation.
%   STOP = PSPLOTMAXCONSTR(OPTIMVALUES,FLAG) where OPTIMVALUES is a
%   structure with the following fields:
%              x: current point X
%      iteration: iteration count
%           fval: function value
%       meshsize: current mesh size
%      funccount: number of function evaluations
%         method: method used in last iteration
%         TolFun: tolerance on function value in last iteration
%           TolX: tolerance on X value in last iteration
%     nonlinineq: nonlinear inequality constraints at X
%       nonlineq: nonlinear equality constraints at X
%
%   FLAG: Current state in which PlotFcn is called. Possible values are:
%           init: initialization state
%           iter: iteration state
%      interrupt: intermediate state
%           done: final state
%
%   STOP: A boolean to stop the algorithm.
%
%   See also PATTERNSEARCH, GA, PSOPTIMSET.

%   Copyright 2005-2010 The MathWorks, Inc.
%   $Revision: 1.1.6.3 $  $Date: 2010/10/08 16:51:12 $

% Initialize stop boolean to false.
stop = false;

% Update the plot.
switch flag
    case 'init'
        % If this problem type doesn't support nonlinear constraints, just
        % tell the user and not plot anything.
        if ~strcmpi('nonlinearconstr',optimvalues.problemtype)
            title('Max constraint: not available');
        else
            maxConstr = i_calcMaxConstrViol(optimvalues);
            plotConstr = plot(optimvalues.iteration,maxConstr, '.b');
            set(plotConstr,'Tag','psplotmaxconstr');
            xlabel('Iteration','interp','none');
            ylabel('Max constraint','interp','none')
            title(sprintf('Max constraint: %g',maxConstr),'interp','none');
        end
    case 'iter'
        % This plot function only updates if the problem type supports
        % nonlinear constraints.
        if strcmpi('nonlinearconstr',optimvalues.problemtype)
            maxConstr = i_calcMaxConstrViol(optimvalues);
            plotConstr = findobj(get(gca,'Children'),'Tag','psplotmaxconstr');
            newX = [get(plotConstr,'Xdata') optimvalues.iteration];
            newY = [get(plotConstr,'Ydata') maxConstr];
            set(plotConstr,'Xdata',newX,'Ydata',newY);
            set(get(gca,'Title'),'String',sprintf('Max constraint: %g',maxConstr));
        end
    case 'interrupt'
        % This plot function does not update when the algorithm is in an
        % intermediate state.
    case 'done'
        % No clean up tasks required for this plot function.
end

function maxConstr = i_calcMaxConstrViol(optimvalues)
%I_CALCMAXCONSTRVIOL Calculate maximum constraint violation 

maxConstr = 0;
if ~isempty(optimvalues.nonlinineq)
    maxConstr = max([maxConstr; optimvalues.nonlinineq(:)]);
end
if ~isempty(optimvalues.nonlineq)
    maxConstr = max([maxConstr; abs(optimvalues.nonlineq(:))]);
end
