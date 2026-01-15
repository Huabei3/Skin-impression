function [pValue X2 medXY iqrXY CFXY]=moodsmediantest(X,Y,wi,type_)
%Mood's nonparametric test for equality of medians
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin<4;type='chi2';end
if nargin<3;wi=ones(numel(X),1);type_='chi2';end

if size(wi,1)==1;wi=wi';end

%normalized weigths
wi=wi./sum(wi,1);

%create weights array
if size(wi,2)==1;
    wi=[wi(:,1),wi(:,1)];
end
wi_=[wi(:,1);wi(:,2)];



%find weigthed medians of individual sets
[medX,wiqrX,CFX]=medianw(X,wi(:,1));
[medY,wiqrY,CFY]=medianw(Y,wi(:,2));
medY=median(Y);
medXY=[medX,medY];
iqrXY=[wiqrX,wiqrY];
CFXY=[CFX,CFY];

%find median of combined set
medC=medianw([X(:);Y(:)],wi_);

%find elements in each set that are larger than the combined median and
%form contingency tabel
observed=[sum(X>medC), sum(Y>medC); sum(X<=medC), sum(Y<=medC)];
[r c]=size(observed);
dof = (r-1)*(c-1);%degrees of freedom

switch type_
    case 'chi2'
        %Chisquare test
            expected = sum(observed,2)*sum(observed,1) / sum(observed(:));
            deltaOE = abs(observed-expected);
            %deltaOE=deltaOE-1/2;%correction for 2x2 tables;
            Chi2contribution=(deltaOE.^2)./expected;

            X2= sum(sum(Chi2contribution));

            %# p-value needed to reject hNull at the significance level with dof
            pValue = 1 - chi2cdf(X2, dof);

    case 'barnard'
        %Barnard's exact test (more accurate when contingency table contains
        %smaller values (<5))
            pValue=Barnardextest(observed);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
