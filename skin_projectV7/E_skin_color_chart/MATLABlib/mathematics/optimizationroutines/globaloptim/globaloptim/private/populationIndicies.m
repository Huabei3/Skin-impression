function indices = populationIndicies(population)
%POPULATIONINDICIES Find the indices of each sub-population
%   POPULATIONINDICIES has been replaced by POPULATIONINDICES, and will be 
%   removed in a later version
%   indices = populationIndicies(population); returns a 2 by n array
%   containing the locations of each subpopulation in the population array.
%
%   Private to GA

%   Copyright 2003-2009 The MathWorks, Inc.
%   $Revision: 1.1.6.3 $  $Date: 2010/10/08 16:51:41 $


warning(message('globaloptim:populationIndicies:obsoleteFcn'));
indices = populationIndices(population);

