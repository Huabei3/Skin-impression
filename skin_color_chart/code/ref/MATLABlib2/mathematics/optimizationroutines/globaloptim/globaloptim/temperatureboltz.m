function temperature = temperatureboltz(optimValues,options)
%TEMPERATUREBOLTZ Updates the temperature vector for annealing process 
%   TEMPERATURE = TEMPERATUREBOLTZ(optimValues,options) implements Boltzman
%   annealing by updating the current temperature based on the initial
%   temperature and the current annealing parameter k  
%
%   OPTIMVALUES is a structure containing the following information:
%              x: current point 
%           fval: function value at x
%          bestx: best point found so far
%       bestfval: function value at bestx
%    temperature: current temperature
%      iteration: current iteration 
%             t0: start time
%              k: annealing parameter
%
%   OPTIONS: options structure created by using SAOPTIMSET.
%
%   Example:
%    Create an options structure using TEMPERATUREBOLTZ as the annealing
%    function
%    options = saoptimset('TemperatureFcn',@temperatureboltz);

%   Copyright 2006-2010 The MathWorks, Inc.
%   $Revision: 1.1.6.2 $  $Date: 2010/05/10 17:16:57 $

temperature = options.InitialTemperature./log(optimValues.k);

% If this yields any negative temperatures, bring the temperature positive
temperature(optimValues.temperature < 0) = eps;
