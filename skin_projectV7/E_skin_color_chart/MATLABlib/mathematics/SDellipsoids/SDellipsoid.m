function [M, cov_,a] = SDellipsoid(data,STD,ptype,SDorSE, verbosity)
if nargin < 2 ; STD = [];end
if nargin < 3 ; ptype = 'sample';end
if nargin < 4 ; SDorSE = 2;end %2 = SE
if nargin < 5 ; verbosity = 0; end

n = size(data,1);
p = size(data,2);

%mean: center of SE ellipse
M = mean(data,1);

%covariance of data
cov_ = cov(data);


%calculate scale factor for SD ellipse and apply
switch ptype
    case 'none'
        if isempty(STD) 
            scale = 1;
        else
            scale = STD.^2; % STD = fraction of mahalanobis distance
        end
    case 'sample'
        scale = (p.*(n-1)./(n-p).*finv(1-STD,p,n-p)); %use sample covariance
    case 'pop1' %alpha as input
        conf = 1-STD;
        scale = chi2inv(conf,p); 
    case 'pop2' %fraction of 1 mahalanobis distance as input
        conf = 2*normcdf(STD)-1;
        scale = chi2inv(conf,size(data,2)) ; 

    otherwise
        error('STD invalid')
end




cov_ = cov_.*scale;


%convert from SD cov to SE cov
if SDorSE==2;%use SE
    cov_ = cov_ ./n;
    if verbosity ==1;
        disp(sprintf('ptype: %s | Mahalanobis distance scale factor: %1.4f, SD -> SE factor: %1.4f, total scale factor: %1.4f',ptype,sqrt(scale),sqrt(1./n),sqrt(scale./n)));
    end
else
    if verbosity ==1;
        disp(sprintf('ptype: %s | Mahalanobis distance scale factor: %1.4f',ptype,sqrt(scale)));
    end
end



% inverse of covariance matrix determines ellipse: D2 = X'*SIGMA*X
cik = pinv(cov_);

switch size(data,2)
    case 2
        a = [cik(1,1), cik(2,2), M, cik(1,2)]; % a-format
    case 3
        a = [cik(1,1), cik(2,2), cik(3,3), M, cik(1,2), cik(1,3), cik(2,3)]; % a-format
end

end






