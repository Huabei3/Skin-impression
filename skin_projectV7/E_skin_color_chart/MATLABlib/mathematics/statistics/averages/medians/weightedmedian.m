function [wMed,wiqr,CF,wQ1,wQ3] = weightedMedian(D,W,alpha)

% ----------------------------------------------------------------------
% Function for calculating the weighted median 
% Sven Haase
%
% For n numbers x_1,...,x_n with positive weights w_1,...,w_n, 
% (sum of all weights equal to one) the weighted median is defined as
% the element x_k, such that:
%           --                        --
%           )   w_i  <= 1/2   and     )   w_i <= 1/2
%           --                        --
%        x_i < x_k                 x_i > x_k
%
%
% Input:    D ... matrix of observed values
%           W ... matrix of weights, W = ( w_ij )
% Output:   wMed ... weighted median                   
% ----------------------------------------------------------------------
if nargin<3;alpha=0.05;end

if nargin ~= 2
    error('weightedMedian:wrongNumberOfArguments', ...
      'Wrong number of arguments.');
end

if size(D) ~= size(W)
    error('weightedMedian:wrongMatrixDimension', ...
      'The dimensions of the input-matrices must match.');
end

% normalize the weights, such that: sum ( w_ij ) = 1
% (sum of all weights equal to one)

WSum = sum(W(:));
W = W / WSum;

% (line by line) transformation of the input-matrices to line-vectors
d = reshape(D',1,[]);   
w = reshape(W',1,[]);  

% sort the vectors
A = [d' w'];
ASort = sortrows(A,1);

dSort = ASort(:,1)';
wSort = ASort(:,2)';

sumVec = [];    % vector for cumulative sums of the weights
for i = 1:length(wSort)
    sumVec(i) = sum(wSort(1:i));
end

wMed = [];      
j = 0;         

while isempty(wMed)
    j = j + 1;
    if sumVec(j) >= 0.5
        wMed = dSort(j);    % value of the weighted median
    end
end


% final test to exclude errors in calculation
if ( sum(wSort(1:j-1)) > 0.5 ) & ( sum(wSort(j+1:length(wSort))) > 0.5 )
     error('weightedMedian:unknownError', ...
      'The weighted median could not be calculated.');
end

%calculate iqr
%Q1:
wQ1 = [];      
j = 0;  
while isempty(wQ1)
    j = j + 1;
    if sumVec(j) >= 0.25
        wQ1 = dSort(j);    % value of the weighted median
    end
end
%Q3:
wQ3 = [];      
j = 0;  
while isempty(wQ3)
    j = j + 1;
    if sumVec(j) >= 0.75
        wQ3 = dSort(j);    % value of the weighted median
    end
end
wiqr=abs(wQ3-wQ1)
 
%calculate confidence intervals: Conover, W.J. (1980) Practical
%Nonparametric Statistics John Wiley and Sons, New
%York.(http://www-users.york.ac.uk/~mb55/intro/cicent.htm) 
%Access date, Sep 2, 2014
a=norminv(1-alpha/2);
j=(numel(dSort).*0.5-a.*sqrt(numel(dSort).*0.5.*(1-0.5)));
k=(numel(dSort).*0.5+a.*sqrt(numel(dSort).*0.5.*(1-0.5)));
j(j<1)=1;k(k<1)=1;
j=ceil(j);
k=ceil(k);
CF=[dSort(j),dSort(k)]

%find p-value for H0 --> find alpha such that 0 in CF
% alpha0=[0.000000
% t=dSort(ceil(numel(dSort).*0.5-norminv(1-alpha0/2).*sqrt(numel(dSort).*0.5.*(1-0.5))))