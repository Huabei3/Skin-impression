function [P,Power,T2Hot2d] = T2Hot2d(X,alpha,mu)
%Hotelling's T-Squared test for two multivariate dependent samples. 
%
%   Syntax: function [P,T2Hot2d] = T2Hot2d(X,alpha) 
%      
%     Inputs:
%          X - multivariate data matrix. 
%      alpha - significance level (default = 0.05).
%
%     Output:
%          n - sample-sizes.
%          p - variables.
%          T2 - Hotelling's T-Squared statistic.
%          Chi-sqr. or F - the approximation statistic test.
%          df - degrees of freedom of the approximation statistic test.
%          P - probability that null Ho: is true.
%
%    If the groups sample-size is at least 50 (sufficiently large), Hotelling's T-Squared
%    test takes a Chi-square approximation; otherwise it takes an F approximation.
%
%    Example: Taken the example given by Johnson and Wichern (1992, p. 223). For a two 
%             dependent samples with two independent variables (p = 3), we are interested
%             to test any difference between its mean vectors with a significance 
%             level = 0.05. The same sample-size, n = 11.
%                                       Sample
%                      ---------------------------------------                
%                            1                        2
%                      ---------------------------------------
%                         x1   x2                  x1   x2
%                      ---------------------------------------
%                          6   27                  25   15
%                          6   23                  28   13
%                         18   64                  36   22
%                          8   44                  35   29
%                         11   30                  15   31
%                         34   75                  44   64
%                         28   26                  42   30
%                         71  124                  54   64
%                         43   54                  34   56
%                         33   30                  29   20
%                         20   14                  39   21
%                      ---------------------------------------
%
%             Total data matrix must be:
%              X=[6 27;6 23;18 64;8 44;11 30;34 75;28 26;71 124;43 54;33 30;20 14;
%                 25 15;28 13;36 22;35 29;15 31;44 64;42 30;54 64;34 56;29 20;39 21];
%
%     Calling on Matlab the function: 
%             T2Hot2iho(X)
%       
%             Immediately it ask: ----> replaced by extra input
%             parameter!!!
%             -Do you have an expected mean vector? (y/n):
%            For this example we must to put:
%             n  (meaning 'no')
%            Otherwise (y; meaning 'yes') you must to give the expected mean vector.
%
%       Answer is:
% ---------------------------------------------------------------------------------------
%   n1      n2       Variables      T2          F           df1          df2          P
% ---------------------------------------------------------------------------------------
%   11      11           2       13.6393     6.1377           2            9       0.0208
% ---------------------------------------------------------------------------------------
% Mean vectors result significant.
%
%
%  Created by A. Trujillo-Ortiz and R. Hernandez-Walls
%             Facultad de Ciencias Marinas
%             Universidad Autonoma de Baja California
%             Apdo. Postal 453
%             Ensenada, Baja California
%             Mexico.
%             atrujo@uabc.mx
%             And the special collaboration of the post-graduate students of the 2002:2
%             Multivariate Statistics Course: Karel Castro-Morales, Alejandro Espinoza-Tenorio,
%             Andrea Guia-Ramirez.
%
%  Copyright (C) November 2002
%
%  References:
% 
%  Johnson, R. A. and Wichern, D. W. (1992), Applied Multivariate Statistical Analysis.
%              3rd. ed. New-Jersey:Prentice Hall. pp. 220-224.
%

if nargin < 1, 
   error('Requires at least one input argument.'); 
end; 

if nargin < 2, 
    alpha = 0.05; 
end;

if (alpha <= 0 | alpha >= 1)
   fprintf('Warning:significance level must be between 0 and 1\n');
   return;
end;

[N,p]=size(X);

if rem(N,2) == 1,
   error('Warning:one of the observation it is not paired.');
   return;
end;

% ask=input('Do you have an expected means vector? (y/n): ','s');
% if ask=='y'
%    mu=input('Give me the expected means vector: ');
% else
%    mu=zeros([1,p]);
% end;

if nargin==3;
    mu=mu;
else
   mu=zeros([1,p]);
end;    

nd=N/2;
n=[N/2,N/2];

if N/2 <= p,
   error('Warning:requires that sample-size must be greater than the number of variables (p).'); 
   return;
end;
   
r=1;
r1=n(1);
g=length(n);
for k=1:g
   eval(['M' num2str(k) '=mean(X(r:r1,:));']);  %Partition of the sample mean vectors.
   eval(['X' num2str(k) '=X(r:r1,:);']);  %Pertition of the total data matrix.
   if k<g
      r=r+n(k);
      r1=r1+n(k+1);
   end;
end;

mD=(M1-M2)-mu;  %Mean-sample differences.
D=X1-X2;  %Sample differences.
Sd=cov(D);  %Covariance matrix of sample differences.
T2=nd*mD*inv(Sd)*mD';  %Hotelling's T-Squared statistic.
F=((n-p)/(p*(n-1)))*T2;  %F approximation.
v1=p;  %Numerator degrees of freedom.
v2=nd-p;  %Denominator degrees of freedom.
P=1-fcdf(F,v1,v2);  %Probability that null Ho: is true.
disp(' ')
fprintf('-----------------------------------------------------------------------------------------\n');
disp('   n1      n2       Variables      T2          F           df1          df2          P')
fprintf('-----------------------------------------------------------------------------------------\n');
fprintf('%5.i%8.i%12.i%14.4f%11.4f%12.i%13.i%13.4f\n',n(1),n(2),p,T2,F,v1,v2,P);       
fprintf('-----------------------------------------------------------------------------------------\n');

if P >= alpha;
   disp('Mean vectors result not significant.');
else
   disp('Mean vectors result significant.');
end;

[Power] = powerT2Hot(F,n(1),n(2),P,alpha);

return;


function [Power] = powerT2Hot(F,n1,n2,p,alpha)
%  Statistical Power of a Performed (a posteriori) Multivariate 
%  Hotelling's T-Squared test.
%
%   Syntax: function [Power] = powerT2Hot(F,n1,n2,p,alpha) 
%      
%     Inputs:
%          F - observed multivariate F-statistic.
%         n1 - number of data of interested sample (group) 1.
%         n2 - number of data of sample (group) 2.
%          p - number of variables.
%      alpha - significance (default = 0.05).
%
%     Output:
%          Power - the output power of the performed Hotelling's T-Squared test.
%  
%    Example: For the example 1 of Stevens (1992, p.179-180) considering a 2-group with
%             25 subjects per group, 4 variables, and a multivariate F = 2.81. What is 
%             the estimated power with a significance = 0.05? 
%
%             Calling on Matlab the function: 
%                powerT2Hot(2.81,25,25,4)
%
%             Answer is:
%                ans= 0.7547
%           

%  Created by A. Trujillo-Ortiz, R. Hernandez-Walls and E.M. Trujillo-Perez
%             Facultad de Ciencias Marinas
%             Universidad Autonoma de Baja California
%             Apdo. Postal 453
%             Ensenada, Baja California
%             Mexico.
%             atrujo@uabc.mx
%
%  August 16, 2003.
%
%  To cite this file, this would be an appropriate format:
%  Trujillo-Ortiz, A., R. Hernandez-Walls and E.M. Trujillo-Perez. (2003). powerT2Hot: Statistical power of a performed
%    multivariate Hotelling's T-Squared test. A MATLAB file. [WWW document]. URL http://www.mathworks.com/matlabcentral/
%    fileexchange/loadFile.do?objectId=3877&objectType=FILE
%
%  References:
%  Cohen, J. (1977), Statistical Power Analysis for the Behavioral Sciences.
%              New York:Academic Press. p. 490-493.
%  Stevens, J. (1992), Applied Multivariate Statistics for the Social Sciences.
%              New:Jersey:Lawrence Erlbaum Assiciates, Pub. p. 179-183
%  Trujillo-Ortiz, A. On the Statistical Power of One-Way 
%              Analysis of Variance Test Model I. The American
%              Statistician. (Submitted).
%  Winer, B.J. (1971), Statistical Concepts in Experimental Design.
%              New York:McGraw-Hill. pp. 220-222; 225-228.
%

if nargin < 5, 
    alpha = 0.05; 
end; 

if nargin < 4, 
    error('Requires at least four input arguments.'); 
end; 

if (n1 <= p)|(n2 <= p),
   error('Requires that one of the sample-sizes must be greater than the number of variables (p).');  
end;

N = n1+n2;  %total sample size
T2 = (N-2)*p*F/(N-p-1);  %Hotelling's T-Squared statistic
D2 = N*T2/(n1*n2);  %squared Mahalanobis distance
p1 = n1/N;  %proportion of the interested sample in the combined samples
p2 = n2/N;  %proportion of the complement sample in the combined samples
R2 = D2/(D2+(1/(p1*p2)));  %multivariate squared correlation [source-residual (error) 
                           %proportion of variances ratio
f2 = R2/(1-R2);  %effect size index
v1 = p;  %numerator degrees of freedom
v2 = (N-p-1);  %denominator degrees of freedom
l = f2*(v1 + v2 + 1);  %estimated noncentrality parameter
%
% Aproximation of the noncentral F distribution to central F distribution.
%
P = 1 - alpha;
Fc=finv(P,v1,v2)/(1+(l/v1)); %Expected F-statistic value adjusted to the estimated
%noncentrality parameter.
v1m=((v1+l)^2)/(v1+(2*l)); %Numerator degrees of freedom adjusted to the estimated
%noncentrality parameter.
%
% Because the numerator degrees of freedom corrected by the noncentrality parameter
% could results a fraction, the probability function associated to the F distribution
% function is resolved by the Simpson's 1/3 numerical integration method.
%
x=linspace(.00001,Fc,10001);
DF=x(2)-x(1);
y=((v1m/v2)^(.5*v1m)/(beta((.5*v1m),(.5*v2))));
y=y*(x.^((.5*v1m)-1)).*(((x.*(v1m/v2))+1).^(-.5*(v1m+v2)));
N1=length(x);
Power=1-(DF.*(y(1)+y(N1) + 4*sum(y(2:2:N1-1))+2*sum(y(3:2:N1-2)))/3.0);
