classdef (Sealed) RandomStartPointSet < AbstractGeneratedStartPointSet
%RandomStartPointSet A random start point set.
%   RandomStartPointSet is a set of start points that are randomly
%   generated using uniformly distributed pseudorandom numbers.  
%
%   RS = RandomStartPointSet constructs a new random start point set
%   with 10 points.
%
%   RS = RandomStartPointSet(PROP, VAL) specifies a set of property-value
%   pairs that are applied to the start point set before creating it.
%   
%   RS = RandomStartPointSet(OLDRS, PROP, VAL) creates a copy of the
%   RandomStartPointSet, OLDRS, with the named properties altered with the
%   specified values.
%
%   RandomStartPointSet properties:
%       NumStartPoints      - number of start points in the set
%       ArtificialBound     - artificial bound for unbounded problems
%
%   RandomStartPointSet method:
%       list                - lists the start points in the set
%
%   Example:
%      Create a set of 30 random start points.
%
%      rsps = RandomStartPointSet('NumStartPoints',30);
%
%   See also CUSTOMSTARTPOINTSET

%   Copyright 2009 The MathWorks, Inc.
%   $Revision: 1.1.6.4 $  $Date: 2010/11/01 19:36:42 $

    methods
        function rtps = RandomStartPointSet(varargin)
%RandomStartPointSet Create a random start point set.
%
%   RS = RandomStartPointSet constructs a new random start point set
%   with 10 points.
%
%   RS = RandomStartPointSet(PROP, VAL) specifies a set of property-value
%   pairs that are applied to the start point set before creating it.
%   
%   RS = RandomStartPointSet(OLDRS, PROP, VAL) creates a copy of the
%   RandomStartPointSet, OLDRS, with the named properties altered with the
%   specified values.
%
%   RandomStartPointSet is a set of start points that are randomly
%   generated using uniformly distributed pseudorandom numbers. This start
%   point set has the following properties and method: 
%
%   RandomStartPointSet properties:
%       NumStartPoints      - number of start points in the set
%       ArtificialBound     - artificial bound for unbounded problems
%
%   RandomStartPointSet method:
%       list                - lists the start points in the set
%
%   See also CUSTOMSTARTPOINTSET, LIST

           rtps = rtps@AbstractGeneratedStartPointSet(varargin{:});
           % Record the version of the class
           rtps.Version = 1;
        end
        function startPoints = list(obj,problem)
%LIST List the start points in the set. 
% 
%   STARTPOINTS = LIST(RS, PROBLEM) returns a RS.NumStartPoints by
%   numel(problem.x0) array of start points. The start points are randomly
%   generated between the upper and lower bounds specified in the
%   optimization problem structure, PROBLEM.
%     
%   Note, if any of these bounds are not specified or are infinite,
%   RS.ArtificialBound is used to specify the missing bounds for the start
%   point generation. For details on how the LIST method specifies the
%   missing bounds, see the reference page in the help browser.

%   See also RANDOMSTARTPOINTSET, NUMSTARTPOINTS    

            % RandomStartPointSet object must be scalar. This check also
            % stops empty objects being passed to the list method.
            if ~isscalar(obj)
                error(message('globaloptim:RandomStartPointSet:list:ObjectNotScalar'));
            end
            if nargin == 2
                if isstruct(problem)
                    % Check x0 field in problem
                    error(obj.checkProblemX0Field(problem));                                      
                    startPoints = generate(obj,problem);
                else
                   errid = 'globaloptim:RandomStartPointSet:list:InvalidInput';
                   errmsg = 'An input to RandomStartPointSet.list can be a problem structure.';
                   error(errid,errmsg);                       
                end
            else
                errid = 'globaloptim:RandomStartPointSet:list:IncorrectNumInput';
                errmsg = 'RandomStartPointSet.list requires a random start point set and a problem structure.';
                error(errid,errmsg);
            end
        end        
    end
    methods (Access = protected)
        function startPoints = generate(obj,problem)
            dimX0 = numel(problem.x0);
            if ~isfield(problem,'lb') || ~isnumeric(problem.lb)
                problem.lb = [];
            end
            if ~isfield(problem,'ub') || ~isnumeric(problem.ub)
                problem.ub = [];
            end            
            [~,lb,ub,errmsg] = ...
                checkbounds(problem.x0,problem.lb,problem.ub,dimX0);
            if ~isempty(errmsg)
                errid = 'globaloptim:RandomStartPointSet:list:InconsistentBounds';
                error(errid,errmsg);
            end
            gtpsLB = lb';
            gtpsUB = ub';
            indLBInfNaN = (isinf(gtpsLB) | isnan(gtpsLB)) & ...
                (~isinf(gtpsUB) & ~isnan(gtpsUB));
            indUBInfNaN = (isinf(gtpsUB) | isnan(gtpsUB)) & ...
                (~isinf(gtpsLB) & ~isnan(gtpsLB));
            gtpsLB(indLBInfNaN) = gtpsUB(indLBInfNaN) - 2*obj.ArtificialBound;
            gtpsUB(indUBInfNaN) = gtpsLB(indUBInfNaN) + 2*obj.ArtificialBound;
            gtpsLB(isinf(gtpsLB) | isnan(gtpsLB)) = -obj.ArtificialBound;
            gtpsUB(isinf(gtpsUB) | isnan(gtpsUB)) = obj.ArtificialBound;
            range = gtpsUB - gtpsLB;
            rangeRep = range(ones(obj.NumStartPoints,1),:);
            gtpsLBRep = gtpsLB(ones(obj.NumStartPoints,1),:);
            startPoints = gtpsLBRep + rangeRep.*rand(obj.NumStartPoints,dimX0);
        end
    end    
end
