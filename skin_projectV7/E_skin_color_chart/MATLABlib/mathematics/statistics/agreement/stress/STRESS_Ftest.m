function [sF,p,F,Fv,N,msg]=STRESS_Ftest(STRESSA,STRESSB,N,alpha)
% F test for two STRESS values
% • The color-difference formula A is significantly better
% than B when F <FC.
% • The color-difference formula A is significantly poorer
% than B when F> 1/FC.
% • The color-difference formula A is insignificantly better
% than B when FC<=F< 1.
% • The color-difference formula A is insignificantly
% poorer than B when 1 <F<= 1/FC.
% • The color-difference formula A is equal to B when
% F=1.
if nargin<4;alpha=0.05;end
STRESSA=STRESSA.^2;STRESSB=STRESSB.^2;

F=STRESSA./STRESSB;

Fv=finv(alpha,N-1,N-1);
p=fcdf(F,N-1,N-1);
p(p==0)=fcdf(1/F,N-1,N-1);
if F < Fv
    msg = 'The color-difference formula A is significantly better than B';
elseif F > 1/Fv
    msg = 'The color-difference formula A is significantly poorer than B';
    p = 1-p;
elseif Fv<=F & F<1
    msg ='The color-difference formula A is insignificantly better B';
elseif 1<F & F<=1/Fv
    msg = 'The color-difference formula A is insignificantly poorer than B';
elseif F==1;
    msg = 'The color-difference formula A is equal to B';
end
    
    
    

sF.p=p;sF.F=F;sF.Fv=Fv;sF.df=N-1;sF.STRESSA=sqrt(STRESSA);sF.STRESSB=sqrt(STRESSB);sF.alpha=alpha;sF.msg=msg;