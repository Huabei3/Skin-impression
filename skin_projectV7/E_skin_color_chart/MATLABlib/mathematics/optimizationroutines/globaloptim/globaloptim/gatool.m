function gatool(inputArg)
%GATOOL  starts Optimization Tool for GA function.
%   GATOOL starts a graphical user interface window for editing the default 
%   Genetic Algorithm options and running the Genetic Algorithm solver. 
%
%   GATOOL is obolete; use OPTIMTOOL function instead.

%   Copyright 2003-2009 The MathWorks, Inc.
%   $Revision: 1.1.6.3 $  $Date: 2010/10/08 16:51:03 $

warning(message('globaloptim:gatool:ObsoleteSyntax'));
if nargin < 1
    optimtool('ga');
else
    % Input is a problem structure
    if isfield(inputArg, 'fitnessfcn') && isfield(inputArg, 'options')
       optimtool(inputArg); 
    else % Input is an options structure
         % Create a problem structure and call optimtool
         probStruct.solver = 'ga';
         probStruct.options = inputArg;
         optimtool(probStruct);
    end
end
