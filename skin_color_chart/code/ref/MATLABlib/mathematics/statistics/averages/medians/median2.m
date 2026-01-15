function [med,confI]=median2(X,PCI)
%calculates median and confidence interval using bootstrap
%X = input data 
%PCI = confidence interval (e.g. 0.95)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin==1;PCI=0.95;end
PCI=PCI.*100;
med=median(X);
T = bootstrp(200, @median, X);
pcil=(100-PCI)/2;pciu=100-pcil;
confI=prctile(T,[pcil pciu]);
end