function stop = psplotwashington(optimvalues,flag,x,y,Z)
%PSPLOTWASHINGTON PlotFcn to plot best function value.
%   STOP = PSPLOTWASHINGTON(OPTIMVALUES,FLAG) plots current best point.
%   In the first iteration it creates a contour plot.
%   It also delays plotting according to the position of a slider, so the
%   user can control the speed of the demo.
%   OPTIMVALUES: A structure containing information about the state of
%   the solver including X, FVAL, iteration number, etc.

%   Copyright 2004-2008 The MathWorks, Inc.
%   $Revision: 1.1.6.1 $  $Date: 2009/08/29 08:28:17 $

stop = false;
switch flag
    case 'init' % initialization needed
        set(0,'Units','pixels')
        scnsize = get(0,'ScreenSize');
        leftbdr = 5; topbdr = 70;
        thepos = [leftbdr,scnsize(4) - topbdr - 420,590,420];
        set(gcf,'renderer','zbuffer','Position', thepos,...
            'ToolBar','none')
        set(gcf,'Color','w')
        contour(x,y,Z);
        colormap(terrain);
        shading interp;
        hold on;
        view(157,90);
        plot(optimvalues.x(1), ...
            optimvalues.x(2), ...
            'o','Tag','bestSoFar', ...
            'MarkerFaceColor','yellow', ...
            'MarkerEdgeColor',[1 0 1],'MarkerSize',8);
        set(gca,'Xlim',[min(x),max(x)],'Ylim',[min(y),max(y)])
        maxpause = 1; minpause = 1e-6;
        slider_step(1) = 0.4/(maxpause-minpause);
        slider_step(2) = 1/(maxpause-minpause);
        handles = uicontrol(gcf,'style','slider','Position',[550 50 20 300], ...
            'Tag','Myslider');
        set(handles,'sliderstep',slider_step,...
            'max',maxpause,'min',minpause,'Value',((minpause+maxpause)/2));
        shg
        title('Topography Map of White Mountains');
        xlabel('Move the slider to control the speed');
        set(handles,'ToolTipString','Move the slider to control the speed');
        drawnow
    case 'iter'
        handles = findobj(0,'Tag','Myslider');
        % Plot the best point with a 'cyan' color marker
        plot(optimvalues.x(1), ...
            optimvalues.x(2), ...
            'o','Tag','bestSoFar', ...
            'MarkerFaceColor','c', ...
            'MarkerEdgeColor','c','MarkerSize',8);
        % Pause for some time
        pause(get(handles,'value'))
        % Change the color of all the trial points (previous iteration) to
        % 'black'
        allPoints = findobj(gcf,'Tag','allpoints');
        if ~isempty(allPoints)
            set(allPoints,'Color','k')
        end
        
        % Plot all the new points tried by pattern search that are in the range of
        % the data; the data is saved by the objective function
        % 'terrainfun2.m'
        pop = getappdata(0,'PointsInPattern');
        if size(pop,2) > 1 % plot the pattern
            good = pop(:,1) <= max(x) & pop(:,1) >= min(x) & ...
                pop(:,2) <= max(y) & pop(:,2) >= min(y);
            plot(pop(good,1),pop(good,2), ...
                '+','Tag','allpoints', ...
                'Color','red','MarkerSize',8,'LineWidth',2); drawnow;
        end
        % Pause for some time
        pause(get(handles,'value'))
        % Update the color of the best point to 'black'
        bestPoint = findobj(gcf,'Tag','bestSoFar');
        if ~isempty(bestPoint)
            set(bestPoint,'MarkerFaceColor','k')
        end
    case 'done' % Remove the appdata
        if isappdata(0,'PointsInPattern')
            rmappdata(0,'PointsInPattern');
        end
end
