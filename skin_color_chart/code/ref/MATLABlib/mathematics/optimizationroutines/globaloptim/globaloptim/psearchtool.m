function psearchtool(inputArg)
%PSEARCHTOOL starts Optimization Tool for PATTERNSEARCH function.
%   PSEARCHTOOL starts a graphical user interface window for editing the
%   default Pattern Search options and running the Pattern Search solver. 
%
%   PSEARCHTOOL is obolete; use OPTIMTOOL function instead.

%   Copyright 2003-2009 The MathWorks, Inc.
%   $Revision: 1.1.6.3 $  $Date: 2010/10/08 16:51:05 $

warning(message('globaloptim:psearchtool:ObsoleteSyntax'));   
if nargin < 1
    optimtool('patternsearch');
else
    % Input is a problem structure
    if isfield(inputArg, 'objective') && isfield(inputArg, 'options')
       optimtool(inputArg); 
    else % Input is an options structure
         % Create a problem structure and call optimtool
         probStruct.solver = 'patternsearch';
         probStruct.options = inputArg;
         optimtool(probStruct);
    end
end

