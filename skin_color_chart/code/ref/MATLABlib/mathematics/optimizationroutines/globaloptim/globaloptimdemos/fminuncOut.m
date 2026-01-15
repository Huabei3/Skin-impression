function stop = fminuncOut(ignored,optimvalues, state)
%fminuncOut output function used in nonSmoothOpt demo.

%   Copyright 2005-2008 The MathWorks, Inc.
%   $Revision: 1.1.6.1 $  $Date: 2009/08/29 08:27:42 $

persistent gaIter
stop = false;
fig = findobj(0,'type','figure','name','Genetic Algorithm');
if ~isempty(fig)
    set(0,'CurrentFigure',fig);
else
    return;
end

switch state
    case 'init'
        limits = get(gca,'XLim');
        gaIter = limits(2);
        hold on;
    case 'iter'
        set(gca,'Xlim', [0 optimvalues.iteration + gaIter]);
        fval = optimvalues.fval;
        iter = gaIter + optimvalues.iteration;
        plot(iter,fval,'dr')
        title(['Best function value: ',num2str(fval)],'interp','none')
    case 'done'
        fval = optimvalues.fval;
        title(['Best function value: ',num2str(fval)],'interp','none')
        % Create textarrow
        annotation(gcf,'textarrow',...
            [0.6643 0.7286],[0.3833 0.119],...
            'String',{'Algorithm switch to FMINUNC'},...
            'FontWeight','bold');
        hold off
end