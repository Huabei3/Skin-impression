function [smoothspd,lamconv]=smoothK(spd,sigma,type_tol,figyn)
%smooth spd, sigma = std of gaussian to use in convolution (if sigma < 0 or
%if numel(sigma)>1, sigma are the weigths of the convolution function, e.g.
%[1 1 1 1 1] = rectangular smoothing (cfr. moving average)
%type_tol: numerical input : keep only values above type_tol in the conv function
%         or  'same' or 'valid' : see "help smooth"
%figyn: 0 no plotting, 1: plot results
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin<4;figyn=0;end
if sigma==0;
    spdCONV=spd(:,2);lamconv=spd(:,1);
else
delta=abs(spd(1)-spd(2));
d=(0:delta:100);
c=delta*floor(numel(d)/2);

if sigma<0 | numel(sigma)>1;
     gaussCONV=zeros(numel(d),1);gaussCONV(c/delta+1-floor(numel(sigma)/2):c/delta+1+floor(numel(sigma)/2))=abs(sigma);
else;
    gaussCONV=delta/(sqrt(2*pi*sigma^2)).*exp(-0.5*((d-c)/sigma).^2);
    gaussCONV=exp(-0.5*((d-c)/sigma).^2);
end

gaussCONV=gaussCONV./sum(gaussCONV);
if nargin<3;type_tol=1e-6;end
if ~ischar(type_tol);
    tol=type_tol;
    if figyn==1;figure(1);subplot(1,2,1);hold on;plot(d,gaussCONV,'r');end
    d=d(gaussCONV>tol);gaussCONV=gaussCONV(gaussCONV>tol);
    if figyn==1;figure(1);subplot(1,2,1);hold on;plot(d,gaussCONV,'b--');end
    if isempty(gaussCONV);error('Increase tolerance!'),return;end
    spdCONV=conv(spd(:,2),gaussCONV,'valid');
    lamconv= ((spd(1,1)+delta*floor(numel(gaussCONV)/2)):delta:(spd(end,1)-delta*floor(numel(gaussCONV)/2)))';
else
    if figyn==1;figure(1);subplot(1,2,1);hold on;plot(d,gaussCONV,'r');
    figure(1);subplot(1,2,1);hold on;plot(d,gaussCONV,'b--');end
    spdCONV=conv(spd(:,2),gaussCONV,'same');
    lamconv= spd(:,1);
end
end
if nargin<4;figyn=0;end
if figyn==1
    subplot(1,2,2);hold on;plot(spd(:,1)',spd(:,2),'b');plot(lamconv,spdCONV,'r--');
end
smoothspd=spdCONV;
%if nargout==1;smoothspd=[lamconv,spdCONV];else;smoothspd=spdCONV;end


function c = conv(a, b, shape)
%CONV Convolution and polynomial multiplication.
%   C = CONV(A, B) convolves vectors A and B.  The resulting vector is
%   length MAX([LENGTH(A)+LENGTH(B)-1,LENGTH(A),LENGTH(B)]). If A and B are
%   vectors of polynomial coefficients, convolving them is equivalent to
%   multiplying the two polynomials.
%
%   C = CONV(A, B, SHAPE) returns a subsection of the convolution with size
%   specified by SHAPE:
%     'full'  - (default) returns the full convolution,
%     'same'  - returns the central part of the convolution
%               that is the same size as A.
%     'valid' - returns only those parts of the convolution 
%               that are computed without the zero-padded edges. 
%               LENGTH(C)is MAX(LENGTH(A)-MAX(0,LENGTH(B)-1),0).
%
%   Class support for inputs A,B: 
%      float: double, single
%
%   See also DECONV, CONV2, CONVN, FILTER and, 
%   in the Signal Processing Toolbox, XCORR, CONVMTX.

%   Copyright 1984-2010 The MathWorks, Inc.
%   $Revision: 5.16.4.9 $  $Date: 2010/10/25 16:06:08 $

if ~isvector(a) || ~isvector(b)
  error(message('MATLAB:conv:AorBNotVector'));
end

if nargin < 3
    shape = 'full';
end

if ~ischar(shape)
  error(message('MATLAB:conv:unknownShapeParameter'));
end

% compute as if both inputs are column vectors
c = conv2(a(:),b(:),shape);

% restore orientation
if shape(1) == 'f'
    if length(a) > length(b)
        if size(a,1) == 1 %row vector
            c = c.';
        end
    else
        if size(b,1) == 1 %row vector
            c = c.';
        end
    end
else
    if size(a,1) == 1 %row vector
        c = c.';
    end
end

    
    
    
