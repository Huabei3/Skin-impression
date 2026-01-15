function state = gaplotmaxconstr(options,state,flag)
%GAPLOTMAXCONSTR Plots the maximum nonlinear constraint violation by GA.
%   STATE = GAPLOTMAXCONSTR(OPTIONS,STATE,FLAG) plots the maximum nonlinear
%   constraint violation
%
%   Example:
%    Create an options structure that will use GAPLOTMAXCONSTR
%    as the plot function
%     options = gaoptimset('PlotFcns',@gaplotmaxconstr);

%   Copyright 2005-2006 The MathWorks, Inc.
%   $Revision: 1.1.6.2 $  $Date: 2010/10/08 16:51:00 $

% If the flag is 'interrupt' simply return
if strcmpi(flag,'interrupt')
    return;
end
if ~(isfield(state,'NonlinIneq') || isfield(state,'NonlinEq'))
    title('zero nonlinear constraint'); 
    return;
end
% Maximum constraint violation
maxConstr = 0;
if ~isempty(state.NonlinIneq)
  maxConstr = max([0;state.NonlinIneq(:)]);
end
if ~isempty(state.NonlinEq)
    maxConstr = max([maxConstr; abs(state.NonlinEq(:))]);
end

switch flag
    case 'init'
        hold on;
        set(gca,'xlim',[0,options.Generations]);
        xlabel('Generation','interp','none');
        ylabel('Max constraint','interp','none');
        plotConstr = plot(state.Generation,maxConstr,'.k');
        set(plotConstr,'Tag','gaplotconstr');
         title(sprintf('Max constraint: %g',maxConstr),'interp','none');
    case 'iter'
        plotConstr = findobj(get(gca,'Children'),'Tag','gaplotconstr');
        newX = [get(plotConstr,'Xdata') state.Generation];
        newY = [get(plotConstr,'Ydata') maxConstr];
        set(plotConstr,'Xdata',newX, 'Ydata',newY);
         title(sprintf('Max constraint: %g',maxConstr),'interp','none');
    case 'done'
        hold off;
end
