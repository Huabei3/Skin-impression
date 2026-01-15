function f = terrainfun(pop,x,y,Z)
%TERRAINFUN finds the elevation at any (x,y) where, (x,y) are in easting
%and northing units. You must load the file "mtWashington.mat" before
%calling this function.
%
%Credit:
%   United States Geological Survey (USGS) 7.5-minute Digital Elevation
%   Model (DEM) in Spatial Data Transfer Standard (SDTS) format for the
%   Mt. Washington quadrangle, with elevation in meters.
%   http://edc.usgs.gov/products/elevation/dem.html

%   Copyright 2004-2008 The MathWorks, Inc.
%   $Revision: 1.1.6.1 $  $Date: 2009/08/29 08:28:34 $

% (x,y) are co-ordinates of a point in easting and northing units
% respectively and Z is the elevation in feet.

f = interp2(x,y,Z,pop(:,1),pop(:,2));
% We want to maximize, so take the negative of elevation as the objective
f = -f;

% Save the points in the pattern to be used for plotting
% This appdata is removed by the plot function psplotwashington2.m
setappdata(0,'PointsInPattern',pop);

