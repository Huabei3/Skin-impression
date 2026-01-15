function var = hall(x,y)

% Calculate error variance model free using Hall's estimator
%
% >> var = hall(x,y)
%
% [1] Hall P. & Marron S. (1990), On variance estimation in nonparametric regression, 
%     Biometrika, 77, 415--419.
%
% [2] Hall P., Kay J.W. & Titterington D.M. (1990), Asymptotically optimal difference-based estimation of 
%     variance in nonparametric regression, Biometrika, 77(3), 521--528.

% Copyright (c) 2011,  KULeuven-ESAT-SCD, License & help @http://www.esat.kuleuven.be/sista/lssvmlab/StatLSSVM

% sorteer de data
[~,sel] = sort(x);
 y      = y(sel);
 
 var = sum((0.809*y(1:end-2) - 0.5*y(2:end-1) - 0.309*y(3:end)).^2);
 var = (1/(length(y)-2))*var;
