classdef (Sealed) GlobalOptimSolution
%GlobalOptimSolution Global Optimization solution class.
%
%   GlobalOptimSolution is a class that encapsulates a solution from a
%   call to an Optimization Toolbox solver for use with the Global
%   Optimization Toolbox. The GlobalOptimSolution class has the following
%   read-only properties:
%
%   GlobalOptimSolution properties:
%      X                - Minimum of the objective function 
%      Fval             - Value of the objective function at X
%      Exitflag         - A flag that describes the exit condition of the 
%                         Optimization Toolbox solver 
%      Output           - Structure describing the final state of the 
%                         Optimization Toolbox solver 
%      X0               - Cell array of start points that lead to the
%                         minimum within the tolerances specified in the 
%                         global solver. 
% 
%   See also FMINCON, FMINUNC, LSQCURVEFIT, LSQNONLIN

%   Copyright 2009 The MathWorks, Inc.
%   $Revision: 1.1.6.3 $  $Date: 2010/10/08 16:50:48 $

    properties (GetAccess = public, SetAccess = private)
        
%X Minimum of the objective function
%   The X property records the minimum returned by the Optimization Toolbox
%   solver for this solution. Consult the Optimization Toolbox solver help
%   for more details on X.
%
%   See also FMINCON, FMINUNC, LSQCURVEFIT, LSQNONLIN  
        X
        
%FVAL Value of the objective function at the solution
%   The FVAL property records the value of the objective function at the
%   minimum returned by the Optimization Toolbox solver for this solution.
%   Consult the Optimization Toolbox solver help for more details on FVAL.
%
%   See also FMINCON, FMINUNC, LSQCURVEFIT, LSQNONLIN         
        Fval
        
%EXITFLAG Exit condition of the Optimization Toolbox solver
%   The EXITFLAG property records the exit flag returned by the
%   Optimization Toolbox solver for this solution. Consult the Optimization
%   Toolbox solver help for more details on EXITFLAG.
%
%   See also FMINCON, FMINUNC, LSQCURVEFIT, LSQNONLIN         
        Exitflag
        
%OUTPUT Final state of the Optimization Toolbox solver
%   The OUTPUT property records the structure returned by the Optimization
%   Toolbox solver for this solution which describes the final state of the
%   algorithm. Consult the Optimization Toolbox solver help for more
%   details of the output structure.
%
%   See also FMINCON, FMINUNC, LSQCURVEFIT, LSQNONLIN         
        Output

%X0 Start points that lead to the solution
%   The X0 property is a 1-by-NSTART cell array which records the start
%   points that lead to the solution within the tolerances specified in the
%   global solver. If the Optimization Toolbox solver is deterministic, the 
%   first element in the cell array will exactly lead to the solution.         
%       
%   See also FMINCON, FMINUNC, LSQCURVEFIT, LSQNONLIN         
         X0
    end
    
    properties (GetAccess = private, SetAccess = private)
        Version = 1
    end
    
    methods (Hidden)
        function obj = GlobalOptimSolution(varargin)
        %GlobalOptimSolution Construct a new GlobalOptimSolution object.
        %   S = GlobalOptimSolution constructs an empty GlobalOptimSolution
        %   object.
        %
        %   S = GlobalOptimSolution(X, FVAL, EXITFLAG, OUTPUT, X0)
        %   constructs a GlobalOptimSolution object for the specified
        %   solution. X0 is the start point that when the Optimization
        %   Toolbox solver is applied to it exactly returns the solution.
        %   Note that X and X0 must be an array of the same size.
        %
        %   S = GlobalOptimSolution(X, FVAL, EXITFLAG, OUTPUT, X0, OTHERX0)
        %   constructs a GlobalOptimSolution object. OTHERX0 is a cell
        %   array of other start points which return the minimum within the
        %   tolerances specified in the global solver. Note that X, X0 and
        %   the elements of OTHERX0 must have the same size.
        
           if nargin    
               
               % Check that correct number of inputs supplied to
               % constructor
               if nargin < 5
                   error(message('globaloptim:GlobalOptimSolution:InvalidNumberOfInputs'));
               end
               
               % Check that the sizes of X, X0 and OTHERX0 match
               % Store X, X0 and OtherX0 in temporary variables.
               thisX = varargin{1};
               thisX0 = varargin{5};
               if nargin > 5
                   thisOtherX0 = varargin{6};
               else
                   thisOtherX0 = [];
               end
               
               % Sizes of X and X0
               szX = size(thisX);
               szX0 = size(thisX0);
               
               % Create a matrix where each row records the size of each
               % element of OtherX0
               if isempty(thisOtherX0)
                   szOtherX0 = [];
               else
                   szOtherX0 = cellfun(@size, thisOtherX0, ...
                       'UniformOutput', false);
                   szOtherX0 = cell2mat(szOtherX0');
               end
               
               % If X, X0 and elements of OtherX0 have different number of
               % dimenstions, then error.
               if size(szX, 2) ~= size(szX0, 2) || ...
                       (~isempty(szOtherX0) && size(szX, 2) ~= size(szOtherX0, 2))
                   error(message('globaloptim:GlobalOptimSolution:IncorrectXDim'));
               end
               
               % If X and each start point have different sizes, then
               % error.
               allsz = [szX;szX0;szOtherX0];
               uniqueAllsz = unique(allsz, 'rows');
               if size(uniqueAllsz, 1) ~= 1
                   error(message('globaloptim:GlobalOptimSolution:IncorrectXDim'));
               end
               
               % If here, we can initialize the object
               obj.X = thisX;
               obj.Fval = varargin{2};
               obj.Exitflag = varargin{3};
               obj.Output = varargin{4};
               obj.X0 = [{thisX0}, thisOtherX0];
           end
        end
    end
    
end