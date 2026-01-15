function positiveScalarArray(property,value)
%positiveScalarArray positive scalar array

%   Copyright 2007-2009 The MathWorks, Inc.
%   $Revision: 1.1.6.3 $  $Date: 2010/10/08 16:51:45 $

allValid = true;
for i = 1:numel(value)
    valid =  isreal(value(i)) && value(i) > 0;
    allValid = allValid && valid;
end

if(~allValid)
    error(message('globaloptim:positiveScalarArray:notPosScalarArray', property));
end
