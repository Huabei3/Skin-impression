function stop = fminuncOutps(X, optimvalues, state)
%fminuncOutps output function

%   Copyright 2005-2007 The MathWorks, Inc.
%   $Revision: 1.1.6.1 $  $Date: 2009/08/29 08:27:43 $

stop = false;
figure1 = gcf;

if strcmpi(state,'done')
    annotation(figure1,'arrow',[0.7506 0.7014],[0.3797 0.625]);
    % Create textbox
    annotation(...
        figure1,'textbox',...
        'Position',[0.6857 0.2968 0.1482 0.0746],...
        'FontWeight','bold',...
        'String',{'start point'});

    % Create arrow
    annotation(figure1,'arrow',[0.4738 0.35],[0.1774 0.1833]);
    % Create textbox
    annotation(...
        figure1,'textbox',...
        'Position',[0.4732 0.1444 0.2411 0.06032],...
        'FontWeight','bold',...
        'String',{'FMINCON solution'});
end
