function resetDfltRng(rngstate)
%RESETDFLTRNG Reset the random number generator to a saved state.
%
%   This function is private to the GADS solvers

%   Copyright 2008-2010 The MathWorks, Inc.
%   $Revision: 1.1.6.5 $  $Date: 2010/11/01 19:36:59 $

if ~isempty(rngstate)
    if isfield(rngstate,'state') && isfield(rngstate,'type')
        dflt = RandStream.getDefaultStream;
        if isempty(rngstate.type) || isequal(rngstate.type,dflt.Type)
            try
                dflt.State = rngstate.state;
            catch ME
                error(message('globaloptim:resetDfltRng:InvalidRNGState'));
            end
        else
            error(message('globaloptim:resetDfltRng:RNGType', rngstate.type, dflt.Type));
        end
    else
        error(message('globaloptim:resetDfltRng:InvalidRNGField'));
    end
end
