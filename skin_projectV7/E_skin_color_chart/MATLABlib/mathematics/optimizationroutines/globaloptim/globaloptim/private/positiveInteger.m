function positiveInteger(property,value)
%positiveInteger any positive integer

%   Copyright 2007-2009 The MathWorks, Inc.
%   $Revision: 1.1.6.3 $  $Date: 2010/10/08 16:51:42 $

valid =  isreal(value) && isscalar(value) && (value > 0) && (value == floor(value));
if(~valid)
   error(message('globaloptim:positiveInteger:notPosInteger', property));
end

