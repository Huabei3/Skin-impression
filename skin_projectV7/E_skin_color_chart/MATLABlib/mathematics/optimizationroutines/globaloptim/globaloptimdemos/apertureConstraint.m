function [c,ceq] = apertureConstraint(x,xcoords,ycoords)
% apertureConstraint Aperture constraint function for opticalInterferenceDemo.

%   Copyright 2009 The MathWorks, Inc.  
%   $Revision: 1.1.6.1 $  $Date: 2009/11/05 16:59:58 $

ceq = []; 
c = (x(1) - xcoords).^2 + (x(2) - ycoords).^2 - 9;