%MTWASHINGTONDEMO  load data for white mountains and open OPTIMTOOL with a
%problem for pattern search. Credit:
%   United States Geological Survey (USGS) 7.5-minute Digital Elevation
%   Model (DEM) in Spatial Data Transfer Standard (SDTS) format for the Mt.
%   Washington quadrangle, with elevation in meters.
%   http://edc.usgs.gov/products/elevation/dem.html

%   Copyright 2004-2008 The MathWorks, Inc.
%   $Revision: 1.1.6.1 $  $Date: 2009/08/29 08:27:58 $

% Load the problem structure for the pattern search solver that contains
% all the data for White Mountains elevations as well as objective function
% handle and options.
load mtwashproblem
% Open OPTIMTOOL.
optimtool(mtwashproblem)
