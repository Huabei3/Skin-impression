function f = evaluate_objective(fun, x, M, V)

%% function f = evaluate_objective(fun, x, M, V)
% Function to evaluate the objective functions for the given input vector
% x. x is an array of decision variables and f(1), f(2), etc are the
% objective functions. The algorithm always minimizes the objective
% function hence if you would like to maximize the function then multiply
% the function by negative one. M is the numebr of objective functions and
% V is the number of decision variables. 
%
% This functions is basically written by the user who defines his/her own
% objective function. Make sure that the M and V matches your initial user
% input. Make sure that the 
%
f=feval(fun,x);

%% Check for error
if length(f) ~= M
    error('The number of decision variables does not match you previous input. Kindly check your objective function');
end