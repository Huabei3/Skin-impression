function [v,MI] = MutualInformation(X,Y,binSize);
if nargin<3;binSize=[range(X)/std(X)*5,range(Y)/std(Y)*5];end
 
if (size(X,2) > 1)  % More than one predictor?
 
    % Axiom of information theory
    HXX=JointEntropy(X);
    HY=Entropy(Y);
    Hxy=JointEntropy(X, Y, binSize);
    MI = HXX+ HY - Hxy;
    v = sqrt((MI/HXX)*(MI/HY)) ;%normalized MI
else
 
    % Axiom of information theory
    HX=Entropy(X);
    HY=Entropy(Y);
    Hxy=JointEntropy(X, Y, binSize);
    MI = HX + HY - Hxy;
    v = sqrt((MI/HX)*(MI/HY)); %normalized MI
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function H = JointEntropy(x, y, binSize)
%I suggest binSize=[range(x)/std(x)*5,range(y)/std(y)*5]
if nargin<3;binSize=[range(x)/std(x)*5,range(y)/std(y)*5];end

[N,C] = hist3([x y],binSize);
 
hx = C{1,1};
hy = C{1,2};
 
%xyPos=meshgrid(hx,hy);
 
% Normalize the area of the histogram to make it a pdf
N = N ./ sum(sum(N));
b=hx(2)-hx(1);
l=hy(2)-hy(1);
 
% Calculate the entropy
indices = N ~= 0;
H = -b*l*sum(N(indices).*log2(N(indices)));
 
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function H = Entropy(y,binSize)
    % Calculate the entropy for an integer value of y
 
    %I suggest: binSize=range(y)/std(y)*5;
    if nargin < 2;binSize=range(y)/std(y)*5;end
    % Generate the histogram
    [n xout] = hist(y, binSize);
 
    % Normalize the area of the histogram to make it a pdf
    n = n / sum(n);
    b=xout(2)-xout(1);
 
    % Calculate the entropy
    indices = n ~= 0;
    H = -sum(n(indices).*log2(n(indices)).*b);
end