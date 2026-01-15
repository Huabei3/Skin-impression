function [stop,options,optchanged]  = psoutputwashington(optimvalues,options,flag,x,y,Z)
%PSOUTPUTWASHINGTON OutputFcn to plot best function value.
%   STOP = PSOUTPUTWASHINGTON(OPTIMVALUES,OPTIONS,FLAG) is an output function which
%   plot current best point on a 3-d graph of the function @terrainfun.
%   OPTIMVALUES: A structure containing information about the state of
%   the solver including X, FVAL, iteration number, etc.

%   Copyright 2004-2010 The MathWorks, Inc.
%   $Revision: 1.1.6.3 $  $Date: 2010/04/11 20:32:30 $

stop = false;
fig = findobj(0,'type','figure','name','White Mountains');
optchanged = false;
if(strcmp(flag,'init'))
    % Create a new figure window if it does not exist already
    if isempty(fig)
        fig = figure('visible','off','name','White Mountains');
    end
    set(0,'CurrentFigure',fig);
    clf;
    
    set(0,'Units','pixels')
    scnsize = get(0,'ScreenSize');
    leftbdr = min(scnsize(3)-602,602);
    topbdr = 70;
    thepos = [leftbdr,scnsize(4) - topbdr - 420,590,420];
    
    set(fig,'numbertitle','off','ToolBar','none');
    set(fig,'renderer','zbuffer','Position', thepos)
    set(fig,'Color','w')
    h = surf(x(1:2:end),y(1:2:end),Z(1:2:end, 1:2:end)); %axis equal;
    set(h,'EdgeColor','none');
    rotate3d;
    colormap(terrain);
    shading interp;light;lighting phong
    hold on;view(153,47);
    plot3(optimvalues.x(1), ...
        optimvalues.x(2), ...
        -optimvalues.fval,'o','Tag','bestSoFar', ...
        'MarkerFaceColor','r', ...
        'MarkerEdgeColor','r', 'MarkerSize',8);
    set(gca,'Xlim',[min(x),max(x)],'Ylim',[min(y),max(y)])
    shg
    title('White Mountains');
elseif strcmp(flag,'iter') && ~isempty(fig)
    set(0,'CurrentFigure',fig);
    plot3(optimvalues.x(1), ...
        optimvalues.x(2), ...
        -optimvalues.fval,'o','Tag','bestSoFar', ...
        'MarkerFaceColor','r', ...
        'MarkerEdgeColor','r','MarkerSize',8);
elseif strcmp(flag,'done') && ~isempty(fig)
    set(0,'CurrentFigure',fig);
    plot3(optimvalues.x(1), ...
        optimvalues.x(2), ...
        -optimvalues.fval,'*','Tag','bestSoFar', ...
        'MarkerFaceColor','b', 'LineWidth',4, ...
        'MarkerEdgeColor','b','MarkerSize',16);
end



