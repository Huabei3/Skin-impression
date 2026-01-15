function [yh,h,fval] = bimodNW(x,y)
%
% INTERNAL FUNCTION
%
% This function estimates the regression curve when the errors are
% correlated using a bimodel kernel with the NW kernel
% estimator.

% Copyright (c) 2011,  KULeuven-ESAT-SCD, License & help @http://www.esat.kuleuven.be/sista/lssvmlab/StatLSSVM

% 1) obtain necessary parameters
x = x(:); y = y(:);
n = size(x,1);

% 2) search for optimal tuning paramater (bandwidth)
omega = sum(x,2)*ones(1,n); % caluculate (X_i-X_j)
omega = omega - omega';

opt = optimset('TolX',1e-12,'TolFun',1e-12,'MaxIter',15,'FinDiffType','central',...
               'HessUpdate','steepdesc','Display','off','LargeScale','on','Algorithm','active-set');
[h,fval] = fminsearchbnd(@(r)crossval(r,omega,y),0.3,0.07,inf,opt);
%[h,fval] = fmincon(@(r)crossval(r,omega,y),0.3,[],[],[],[],LB,inf,[],opt);

% 3) Construct regression estimate
K = bimodel_kernel(x,h);
yh = (K*y)./sum(K,2);

function cost = crossval(h,omega,y)
eval('estfct=''mse'';');
%W = 630*(4*(omega./h).^2-1).^2.*((omega./h)).^4.*(abs((omega./h))<=0.5);
%W = 0.5*abs(omega./h).*exp(-abs(omega./h));
W = (2/sqrt(pi))*(omega.^2./h^2).*exp(-omega.^2./h.^2);
%W = 0.5*sqrt(omega.^2/h.^2 + 1e-30) .* exp(-sqrt(omega.^2/h.^2 + 1e-30));
%e = 0.1;
%W = inv((1/4)*(4-3*e-e.^3))*((0.75*(1-(omega./h).^2).*(abs(omega./h)<=1)).*(abs(omega./h)>=e) + ((0.75*(1-e.^2)/e)*abs(omega./h)).*(abs(omega./h)<=e));
W = W./(repmat(sum(W,2),1,size(y,1)));
yh = W*y;
cost = feval(estfct,yh - y);
cost = cost/((1-trace(W)/size(y,1))^2);

function omega = bimodel_kernel(x,h)
omega = sum(x,2)*ones(1,size(x,1));
omega = omega - omega';
%e = 0.1;
%omega = inv((1/4)*(4-3*e-e.^3))*((0.75*(1-(omega./h).^2).*(abs(omega./h)<=1)).*(abs(omega./h)>=e) + ((0.75*(1-e.^2)/e)*abs(omega./h)).*(abs(omega./h)<=e));
%c=1e-30;
%omega = 0.5*sqrt(omega.^2/h.^2 + c) .* exp(-sqrt(omega.^2/h.^2 + c));
omega = (2/sqrt(pi))*(omega./h).^2.*exp(-omega.^2./h^2);
%omega = 630*(4*(omega./h).^2-1).^2.*((omega./h)).^4.*(abs((omega./h))<=0.5);
