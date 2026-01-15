function [CVv2,CVv1] = CV2(X,Y)
%calculate coefficient of variation CV
%tol can be used to avoid division by zero (set to small number)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
N=length(X);
if nargin==2;tol=0;end
X(X==0)=tol;%no divide by zero!
Y(Y==0)=tol;%no divide by zero!

CVv2 = 100* ((1/N)*sum((X-Y).^2)./N)./mean(Y);%paper Luo

f= (sum(X.*Y)./(sum(Y.^2)));
CVv1 = 100* ((1/N)*sum(((X-f.*Y).^2)./(sum(X)/N)))^0.5;%paper XU

