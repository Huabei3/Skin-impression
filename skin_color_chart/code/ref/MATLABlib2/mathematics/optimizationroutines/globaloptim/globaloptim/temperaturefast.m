function temperature = temperaturefast(optimValues,options)
%TEMPERATUREFAST Updates the temperature vector for annealing process 
%   TEMPERATURE = TEMPERATUREFAST(optimValues,options) uses fast 
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
%    Create an options structure using TEMPERATUREFAST as the annealing
%    function
%    options = saoptimset('TemperatureFcn' ,@temperaturefast);

%   Copyright 2006-2010 The MathWorks, Inc.
%   $Revision: 1.1.6.2 $  $Date: 2010/05/10 17:16:59 $

temperature = options.InitialTemperature./optimValues.k;

