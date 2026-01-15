function temperature = satemperaturefcntemplate(optimValues,options)
%SATEMPERATUREFCNTEMPLATE Template to write custom temperature function
%   TEMPERATURE = SATEMPERATUREFCNTEMPLATE(optimValues,options) updates the
%   current temperature
%
%   OPTIMVALUES is a structure containing the following information:
%              x: current point 
%           fval: function value at x
%          bestx: best point found so far
%       bestfval: function value at bestx
%    temperature: current temperature
%      iteration: current iteration 
%             t0: start time
%              k: annealing parameter 'k'
%
%   OPTIONS: options structure created by using SAOPTIMSET.

%   Copyright 2006-2010 The MathWorks, Inc.
%   $Revision: 1.1.6.2 $  $Date: 2010/05/10 17:16:56 $

% The body of this function should simply return a new temperature vector 
% The new temperature will generally depend on either
% options.InitialTemperature or optimValues.temperature and on
% optimValues.k 

% Make sure temperature is of same length as optimValues.k (nvars)
temperature = options.InitialTemperature./(optimValues.k).^2;
