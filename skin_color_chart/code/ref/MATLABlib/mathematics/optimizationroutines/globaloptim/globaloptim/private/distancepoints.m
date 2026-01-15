function D = distancepoints(X, Y)
%DISTANCEPOINTS Return matrix of distances between points.
%
%  D = DISTANCEPOINTS(X, Y) generates a matrix containing the distance
%  between each point in X and Y.
%
%  D = DISTANCEPOINTS(X) generates a matrix containing the distance between
%  each point in X and every other point in X.
%
%  Note that this function and its corresponding MEX function perform no
%  error checking. If this function is made public, then error checking
%  must be added. It is assumed that X and Y satisfy the following:
%
%  1. X and Y are both double arrays with real elements.
%  2. Each row of X and Y is a point.
%  3. Number of columns of X and Y are identical.

%   Copyright 2009 The MathWorks, Inc.
%   $Revision: 1.1.6.2 $  $Date: 2009/11/05 16:59:42 $

% Calculation performed in MEX function
if nargin==1
    D = mx_distancepoints(X', []);
    % In one input case, the matrix is symmetric with zeros on the
    % diagonal. The mex function just calculates the lower triangular
    % portion of D, we construct the rest here. 
    D = D + D';
else
    D = mx_distancepoints(X', Y');
end

% function D=mx_distancepoints(X,Y)
% [x,y]=meshgrid(X,Y);
% D=(x-y).^2;


