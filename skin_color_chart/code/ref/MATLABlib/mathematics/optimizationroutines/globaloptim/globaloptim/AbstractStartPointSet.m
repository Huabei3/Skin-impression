classdef (Hidden) AbstractStartPointSet
%AbstractStartPointSet Start point set class.
%   AbstractStartPointSet is an abstract class representing a start point
%   set. You cannot create instances of this class directly.  You must
%   create a derived class such as CustomStartPointSet or
%   RandomStartPointSet, by calling the class constructor.
%
%   All start point sets that inherit from AbstractStartPointSet have the
%   following method:
%
%   AbstractStartPointSet method:
%       list                - lists the start points in the set
%
%   See also ABSTRACTGENERATEDSTARTPOINTSET, CUSTOMSTARTPOINTSET

%   Copyright 2009 The MathWorks, Inc.
%   $Revision: 1.1.6.2 $  $Date: 2009/11/05 16:59:15 $
        
    properties(Access = protected)
        % Protected property to keep track of the version for the objects
        Version
    end
    methods (Abstract)
        startPoints = list(obj,problem)
    end
    methods (Access = protected, Static)
        function msgstruct = checkProblemX0Field(problem)
            errmsg = '';
            % Check if x0 is a field in problem
            if ~isfield(problem,'x0')
                errid = 'globaloptim:AbstractStartPointSet:checkProblemX0Field:X0NotAField';
                errmsg = 'PROBLEM structure should have an ''x0'' field.';               
            % Check the content of x0
            elseif isempty(problem.x0)
                errid = 'globaloptim:AbstractStartPointSet:checkProblemX0Field:MissingX0';
                errmsg = 'PROBLEM structure should have a non-empty ''x0'' field.';                           
            elseif ~isnumeric(problem.x0)
                errid = 'globaloptim:AbstractStartPointSet:checkProblemX0Field:NonNumericX0';
                errmsg = 'PROBLEM structure should have a numeric value ''x0'' field.';
            end
            % Create a error message structure
            msgstruct = struct('message', [], 'identifier', []);
            if isempty(errmsg)
                % Need to pass an empty message structure to error to make it return
                % without erroring
                msgstruct(1) = [];
            else
                msgstruct.message = errmsg;
                msgstruct.identifier = errid;
            end
        end
    end
    
end % classdef
