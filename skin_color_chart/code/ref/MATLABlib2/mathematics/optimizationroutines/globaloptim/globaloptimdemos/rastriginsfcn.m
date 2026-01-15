function scores = rastriginsfcn(pop)
%RASTRIGINSFCN Compute the "Rastrigin" function.

%   Copyright 2003-2004 The MathWorks, Inc.
%   $Revision: 1.1.6.1 $  $Date: 2009/08/29 08:28:19 $


    % pop = max(-5.12,min(5.12,pop));
    scores = 10.0 * size(pop,2) + sum(pop .^2 - 10.0 * cos(2 * pi .* pop),2);
  


