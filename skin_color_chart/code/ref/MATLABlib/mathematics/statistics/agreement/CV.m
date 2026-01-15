function CVval = CV(deltaEi,deltaVi,tol)
%calculate coefficient of variation CV
%tol can be used to avoid division by zero (set to small number)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
N=length(deltaEi);
if nargin==2;tol=0;end
deltaEi(deltaEi==0)=tol;%no divide by zero!
deltaVi(deltaVi==0)=tol;%no divide by zero!

log10gamma = ((1/N)*sum((log10(deltaEi./deltaVi)-(sum(log10(deltaEi./deltaVi))/N)).^2)).^0.5;

F= (sum(deltaEi./deltaVi)/sum(deltaVi./deltaEi)).^0.5;
VAB = ((1/N)*sum(((deltaEi-F.*deltaVi).^2)./(deltaEi.*deltaVi.*F)))^0.5;

f= (sum(deltaEi.*deltaVi)./(sum(deltaVi.^2)));
CV = 100* ((1/N)*sum(((deltaEi-f.*deltaVi).^2)./(sum(abs(deltaEi.^2))/N)))^0.5;

PF3val = 100*(((10^log10gamma)-1)+VAB+CV/100)/3;
CVval=CV;