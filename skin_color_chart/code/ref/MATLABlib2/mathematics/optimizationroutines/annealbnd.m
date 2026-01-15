function [x,fval,exitflag,output]=annealbnd(fun,x0,LB,UB,options,varargin)
global params
% annealBND: ANNEAL, but with bound constraints by transformation
% usage: x=ANNEALBND(fun,x0)
% usage: x=ANNEALBND(fun,x0,LB)
% usage: x=ANNEALBND(fun,x0,LB,UB)
% usage: x=ANNEALBND(fun,x0,LB,UB,options)
% usage: x=ANNEALBND(fun,x0,LB,UB,options,p1,p2,...)
% usage: [x,fval,exitflag,output]=ANNEALBND(fun,x0,...)
% 
% arguments:
%  fun, x0, options - see the help for ANNEAL
%  x should be in row format!!!
%  LB - lower bound vector or array, must be the same size as x0
%
%       If no lower bounds exist for one of the variables, then
%       supply -inf for that variable.
%
%       If no lower bounds at all, then LB may be left empty.
%
%       Variables may be fixed in value by setting the corresponding
%       lower and upper bounds to exactly the same value.
%
%  UB - upper bound vector or array, must be the same size as x0
%
%       If no upper bounds exist for one of the variables, then
%       supply +inf for that variable.
%
%       If no upper bounds at all, then UB may be left empty.
%
%       Variables may be fixed in value by setting the corresponding
%       lower and upper bounds to exactly the same value.
%
% Notes:
%
%  If options is supplied, then TolX will apply to the transformed
%  variables. All other ANNEAL parameters should be unaffected.
%
%  Variables which are constrained by both a lower and an upper
%  bound will use a sin transformation. Those constrained by
%  only a lower or an upper bound will use a quadratic
%  transformation, and unconstrained variables will be left alone.
%
%  Variables may be fixed by setting their respective bounds equal.
%  In this case, the problem will be reduced in size for FMINSEARCH.
%
%  The bounds are inclusive inequalities, which admit the
%  boundary values themselves, but will not permit ANY function
%  evaluations outside the bounds. These constraints are strictly
%  followed.
%
%  If your problem has an EXCLUSIVE (strict) constraint which will
%  not admit evaluation at the bound itself, then you must provide
%  a slightly offset bound. An example of this is a function which
%  contains the log of one of its parameters. If you constrain the
%  variable to have a lower bound of zero, then FMINSEARCHBND may
%  try to evaluate the function exactly at zero.
%
%
% Example usage:
% rosen = @(x) (1-x(1)).^2 + 105*(x(2)-x(1).^2).^2;
%
% fminsearch(rosen,[3 3])     % unconstrained
% ans =
%    1.0000    1.0000
%
% ANNEALbnd(rosen,[3 3],[2 2],[])     % constrained
% ans =
%    2.0000    4.0000
%
% See test_main.m for other examples of use.
%
%
% See also: ANNEAL, fminspleas
%
%
% Author: John D'Errico
% E-mail: woodchips@rochester.rr.com
% Release: 4
% Release date: 7/23/06

% size checks
xsize = size(x0);
x0 = x0(:);
n=length(x0);

if (nargin<3) || isempty(LB)
  LB = repmat(-inf,n,1);
else
  LB = LB(:);
end
if (nargin<4) || isempty(UB)
  UB = repmat(inf,n,1);
else
  UB = UB(:);
end

if (n~=length(LB)) || (n~=length(UB))
  error 'x0 is incompatible in size with either LB or UB.'
end

% set default options if necessary
if (nargin<5) || isempty(options)
  options = optimset('fminsearch');
end

% stuff into a struct to pass around
params.args = varargin;
params.LB = LB;
params.UB = UB;
params.fun = fun;
params.n = n;
params.OutputFcn = [];

% 0 --> unconstrained variable
% 1 --> lower bound only
% 2 --> upper bound only
% 3 --> dual finite bounds
% 4 --> fixed variable
params.BoundClass = zeros(n,1);
for i=1:n
  k = isfinite(LB(i)) + 2*isfinite(UB(i));
  params.BoundClass(i) = k;
  if (k==3) && (LB(i)==UB(i))
    params.BoundClass(i) = 4;
  end
end

% transform starting values into their unconstrained
% surrogates. Check for infeasible starting guesses.
x0u = x0;
k=1;
for i = 1:n
  switch params.BoundClass(i)
    case 1
      % lower bound only
      if x0(i)<=LB(i)
        % infeasible starting value. Use bound.
        x0u(k) = 0;
      else
        x0u(k) = sqrt(x0(i) - LB(i));
      end
      
      % increment k
      k=k+1;
    case 2
      % upper bound only
      if x0(i)>=UB(i)
        % infeasible starting value. use bound.
        x0u(k) = 0;
      else
        x0u(k) = sqrt(UB(i) - x0(i));
      end
      
      % increment k
      k=k+1;
    case 3
      % lower and upper bounds
      if x0(i)<=LB(i)
        % infeasible starting value
        x0u(k) = -pi/2;
      elseif x0(i)>=UB(i)
        % infeasible starting value
        x0u(k) = pi/2;
      else
        x0u(k) = 2*(x0(i) - LB(i))/(UB(i)-LB(i)) - 1;
        % shift by 2*pi to avoid problems at zero in fminsearch
        % otherwise, the initial simplex is vanishingly small
        x0u(k) = 2*pi+asin(max(-1,min(1,x0u(k))));
      end
      
      % increment k
      k=k+1;
    case 0
      % unconstrained variable. x0u(i) is set.
      x0u(k) = x0(i);
      
      % increment k
      k=k+1;
    case 4
      % fixed variable. drop it before fminsearch sees it.
      % k is not incremented for this variable.
  end
  
end
% if any of the unknowns were fixed, then we need to shorten
% x0u now.
if k<=n
  x0u(k:n) = [];
end

% were all the variables fixed?
if isempty(x0u)
  % All variables were fixed. quit immediately, setting the
  % appropriate parameters, then return.
  
  % undo the variable transformations into the original space
  x = xtransform(x0u,params);
  
  % final reshape
  x = reshape(x,xsize);
  
  % stuff fval with the final value
  fval = feval(params.fun,x,params.args{:});
  
  % ANNEALbnd was not called
  exitflag = 0;
  
  output.iterations = 0;
  output.funcount = 1;
  output.algorithm = 'ANNEAL';
  output.message = 'All variables were held fixed by the applied bounds';
  
  % return with no call at all to fminsearch
  return
end

% Check for an outputfcn. If there is any, then substitute my
% own wrapper function.
if ~isempty(options.OutputFcn)
  params.OutputFcn = options.OutputFcn;
  options.OutputFcn = @outfun_wrapper;
end

% now we can call anneal, but with our own
% intra-objective function.
[xu,fval,exitflag,output] = anneal(@intrafun_,x0u,params,options);

% undo the variable transformations into the original space
x = xtransform(xu,params);

% final reshape
x = reshape(x,xsize);

% Use a nested function as the OutputFcn wrapper
  function stop = outfun_wrapper(x,varargin);
    % we need to transform x first
    xtrans = xtransform(x,params);
    
    % then call the user supplied OutputFcn
    stop = params.OutputFcn(xtrans,varargin{1:(end-1)});
    
  end

end % mainline end


%function ret=anneal(funfun, X0, options, grad, varargin);%wrapper
%ret=fmins(funfun, X0, options, grad, varargin);
%end


% ======================================
% ========= begin subfunctions =========
% ======================================
function fval = intrafun_(x,params)
global params
% transform variables, then call original function

% transform
xtrans = xtransform(x,params);

% and call fun
fval = feval(params.fun,xtrans,params.args{:});

end % sub function intrafun end

% ======================================

function xtrans = xtransform(x,params)
% converts unconstrained variables into their original domains

xtrans = zeros(1,params.n);
% k allows some variables to be fixed, thus dropped from the
% optimization.
k=1;
for i = 1:params.n
  switch params.BoundClass(i)
    case 1
      % lower bound only
      xtrans(i) = params.LB(i) + x(k).^2;
      
      k=k+1;
    case 2
      % upper bound only
      xtrans(i) = params.UB(i) - x(k).^2;
      
      k=k+1;
    case 3
      % lower and upper bounds
      xtrans(i) = (sin(x(k))+1)/2;
      xtrans(i) = xtrans(i)*(params.UB(i) - params.LB(i)) + params.LB(i);
      % just in case of any floating point problems
      xtrans(i) = max(params.LB(i),min(params.UB(i),xtrans(i)));
      
      k=k+1;
    case 4
      % fixed variable, bounds are equal, set it at either bound
      xtrans(i) = params.LB(i);
    case 0
      % unconstrained variable.
      xtrans(i) = x(k);
      
      k=k+1;
  end
end

end % sub function xtransform end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [minimum,fval,exitflag,output] = anneal(loss, parent,params, options)
global params
% ANNEAL  Minimizes a function with the method of simulated annealing
% (Kirkpatrick et al., 1983)
%
%  ANNEAL takes three input parameters, in this order:
%
%  LOSS is a function handle (anonymous function or inline) with a loss
%  function, which may be of any type, and needn't be continuous. It does,
%  however, need to return a single value.
%
%  PARENT is a vector with initial guess parameters. You must input an
%  initial guess.
%
%  OPTIONS is a structure with settings for the simulated annealing. If no
%  OPTIONS structure is provided, ANNEAL uses a default structure. OPTIONS
%  can contain any or all of the following fields (missing fields are
%  filled with default values):
%
%       Verbosity: Controls output to the screen.
%                  0 suppresses all output
%                  1 gives final report only [default]
%                  2 gives temperature changes and final report 
%       Generator: Generates a new solution from an old one.
%                  Any function handle that takes a solution as input and
%                  gives a valid solution (i.e. some point in the solution
%                  space) as output.
%                  The default function generates a row vector which
%                  slightly differs from the input vector in one element:
%                  @(x) (x+(randperm(length(x))==length(x))*randn/100)
%                  Other examples of possible solution generators:
%                  @(x) (rand(3,1)): Picks a random point in the unit cube
%                  @(x) (ceil([9 5].*rand(2,1))): Picks a point in a 9-by-5
%                                                 discrete grid
%                  Note that if you use the default generator, ANNEAL only
%                  works on row vectors. For loss functions that operate on
%                  column vectors, use this generator instead of the
%                  default:
%                  @(x) (x(:)'+(randperm(length(x))==length(x))*randn/100)'
%        InitTemp: The initial temperature, can be any positive number.
%                  Default is 1.
%        StopTemp: Temperature at which to stop, can be any positive number
%                  smaller than InitTemp. 
%                  Default is 1e-8.
%         StopVal: Value at which to stop immediately, can be any output of
%                  LOSS that is sufficiently low for you.
%                  Default is -Inf.
%       CoolSched: Generates a new temperature from the previous one.
%                  Any function handle that takes a scalar as input and
%                  returns a smaller but positive scalar as output. 
%                  Default is @(T) (.8*T)
%      MaxConsRej: Maximum number of consecutive rejections, can be any
%                  positive number.
%                  Default is 1000.
%        MaxTries: Maximum number of tries within one temperature, can be
%                  any positive number.
%                  Default is 300.
%      MaxSuccess: Maximum number of successes within one temperature, can
%                  be any positive number.
%                  Default is 20.
%
%
%  Usage:
%     [MINIMUM,FVAL] = ANNEAL(LOSS,NEWSOL,[OPTIONS]);
%          MINIMUM is the solution which generated the smallest encountered
%          value when input into LOSS.
%          FVAL is the value of the LOSS function evaluated at MINIMUM.
%     OPTIONS = ANNEAL();
%          OPTIONS is the default options structure.
%
%
%  Example:
%     The so-called "six-hump camelback" function has several local minima
%     in the range -3<=x<=3 and -2<=y<=2. It has two global minima, namely
%     f(-0.0898,0.7126) = f(0.0898,-0.7126) = -1.0316. We can define and
%     minimise it as follows:
%          camel = @(x,y)(4-2.1*x.^2+x.^4/3).*x.^2+x.*y+4*(y.^2-1).*y.^2;
%          loss = @(p)camel(p(1),p(2));
%          [x f] = ANNEAL(loss,[0 0])
%     We get output:
%               Initial temperature:     	1
%               Final temperature:       	3.21388e-007
%               Consecutive rejections:  	1027
%               Number of function calls:	6220
%               Total final loss:        	-1.03163
%               x =
%                  -0.0899    0.7127
%               f =
%                  -1.0316
%     Which reasonably approximates the analytical global minimum (note
%     that due to randomness, your results will likely not be exactly the
%     same).

%  Reference:
%    Kirkpatrick, S., Gelatt, C.D., & Vecchi, M.P. (1983). Optimization by
%    Simulated Annealing. _Science, 220_, 671-680.

%   joachim.vandekerckhove@psy.kuleuven.be
%   $Revision: v5 $  $Date: 2006/04/26 12:54:04 $

def = struct(...
        'CoolSched',@(T) (.90*T),...
        'Generator',@(x) (x+(randperm(length(x))==length(x))*randn/100),...
        'InitTemp',1,...
        'MaxConsRej',1000,...
        'MaxSuccess',20,...
        'MaxTries',1000,...
        'StopTemp',1e-12,...
        'StopVal',-Inf,...
        'Verbosity',1);

% Check input
if ~nargin %user wants default options, give it and stop
    minimum = def;
    return
elseif nargin<2, %user gave only objective function, throw error
    error('MATLAB:anneal:noParent','You need to input a first guess.');
elseif nargin<4, %user gave no options structure, use default
    options=def;
else %user gave all input, check if options structure is complete
    if ~isstruct(options)
        error('MATLAB:anneal:badOptions',...
            'Input argument ''options'' is not a structure')
    end
    fs = {'CoolSched','Generator','InitTemp','MaxConsRej',...
        'MaxSuccess','MaxTries','StopTemp','StopVal','Verbosity'};
    for nm=1:length(fs)
        if ~isfield(options,fs{nm}), options.(fs{nm}) = def.(fs{nm}); end
    end
end

% main settings
newsol = options.Generator;      % neighborhood space function
Tinit = options.InitTemp;        % initial temp
minT = options.StopTemp;         % stopping temp
cool = options.CoolSched;        % annealing schedule
minF = options.StopVal;
max_consec_rejections = options.MaxConsRej;
max_try = options.MaxTries;
max_success = options.MaxSuccess;
report = options.Verbosity;
k = 1;                           % boltzmann constant

% counters etc
itry = 0;
success = 0;
finished = 0;
consec = 0;
T = Tinit;
initenergy = loss(parent);
oldenergy = initenergy;
total = 0;
if report==2, fprintf(1,'\n  T = %7.5f, loss = %10.5f\n',T,oldenergy); end

while ~finished;
    itry = itry+1; % just an iteration counter
    current = parent; 
    
    % % Stop / decrement T criteria
    if itry >= max_try || success >= max_success;
        if T < minT || consec >= max_consec_rejections;
            finished = 1;
            total = total + itry;
            break;
        else
            T = cool(T);  % decrease T according to cooling schedule
            if report==2, % output
                fprintf(1,'  T = %7.5f, loss = %10.5f\n',T,oldenergy);
            end
            total = total + itry;
            itry = 1;
            success = 1;
        end
    end

    newparam = newsol(current')';
    newenergy = loss(newparam);
    
    if (newenergy < minF),
        parent = newparam; 
        oldenergy = newenergy;
        break
    end
    
    if (oldenergy-newenergy > 1e-6)
        parent = newparam;
        oldenergy = newenergy;
        success = success+1;
        consec = 0;
    else
        if (rand < exp( (oldenergy-newenergy)/(k*T) ));
            parent = newparam;
            oldenergy = newenergy;
            success = success+1;
        else
            consec = consec+1;
        end
    end
end

minimum = parent;
fval = oldenergy;
exitflag=1;output.Tinit=Tinit;output.T=T;output.consec=consec;output.total=total;output.fval=fval;
if report;
    fprintf(1, '\n  Initial temperature:     \t%g\n', Tinit);
    fprintf(1, '  Final temperature:       \t%g\n', T);
    fprintf(1, '  Consecutive rejections:  \t%i\n', consec);
    fprintf(1, '  Number of function calls:\t%i\n', total);
    fprintf(1, '  Total final loss:        \t%g\n', fval);
end
end