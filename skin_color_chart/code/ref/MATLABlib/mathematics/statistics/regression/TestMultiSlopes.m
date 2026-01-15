function ss=TestMultiSlopes(X,alpha)
%Test for H0 = slope_1 = slope_2 ...= slope_n
%
%Inputs:
%       X - data matrix (Size of matrix must be n-by-3; sample=
%           column 1,  independent variable=column 2, dependent response variable = column 2)
%       alpha - significance level 
% Output: structure with all the data of the analysis steps.
%         Of particular interest:
%          ss.p : p-value for H0 = slope_1 = slope_2 ...= slope_n
%          ss.bc: NaN if p <=alpha; the common slope if p>alpha
%
%
%  Example: X is of the form
% 
%                                    Group
%                    ---------------------------------------                
%                          1           2           3
%                    ---------------------------------------
%                       x1    x2    x1    x2    x1    x2
%                    ---------------------------------------
%                        5    14     4    14     4    13
%                        5    11     4    15     5    15
%                        4    16     1    13     5    14
%                        4    13     1    14     4    14
%                        5    12     4    15     6    13
%                        3    14     6    19     4    20
%                        7    12     5    13     7    13
%                        6    15     5    18     4    16
%                        6    16     2    14     6    14
%                        4    11     5    17     5    18
%                    ---------------------------------------
%
%  Total data matrix must be:
%  X=[1 5 14;1 5 11;1 4 16;1 4 13;1 5 12;1 3 14;1 7 12;1 6 15;1 6 16;1 4 11;
%     2 4 14;2 4 15;2 1 13;2 1 14;2 4 15;2 6 19;2 5 13;2 5 18;2 2 14;2 5 17;
%     3 4 13;3 5 15;3 5 14;3 4 14;3 6 13;3 4 20;3 7 13;3 4 16;3 6 14;3 5 18];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Remove NaN values, if any
X = X(~any(isnan(X),2),:);


g = max(X(:,1)); %Number of groups
fprintf('The number of groups are:%2i\n', g);
c = size(X,2);
% pIDV = c-2; %Number of independent variables
% pDV = 1; %Number of dependent variables
% fprintf('The number of dependent variables are:%2i\n', pIDV);
% disp(' ')

xx = X(:,1);

indice = X(:,1);

%test for homoscedasticity of variances and Homogeneity of Covariance Matrices
fprintf('LEVENE test for homoscedasticity of variances: \n');
LevenetestX=Levenetest([X(:,1),X(:,2)],alpha);
LevenetestY=Levenetest([X(:,1),X(:,3)],alpha); 
ss.pLeveneYX=[LevenetestY,LevenetestX];
fprintf('\n'); 

fprintf('Multivariate Bootstrap Bartletts Test for the Homogeneity of Covariance Matrices: \n');
mbbtest_=mbbtest(X,1000,alpha);ss.pMBBart=mbbtest_;
fprintf('\n');


for i = 1:g
    Xe = indice == i;
    s(i).X = X(Xe,2:c);
    m(i,:) = mean(s(i).X);s(i).m=m(i,:);
    cv(:,:,i) = cov(s(i).X);s(i).cv=cv(:,:,i);
    n(i) = length(s(i).X);s(i).n=n(i);
    s(i).df = s(i).n - 1;
    %pp(i,:)=  polyfit(s(i).X(:,1),s(i).X(:,2),1);
    
    %regression
    cc(i,:)=[rand(1),rand(1),rand(1)];
    figure(1);plot(s(i).X(:,1),s(i).X(:,2),'Color',cc(i,:),'Marker','.','LineStyle','none');hold on
    
    Ai(i) = sum((s(i).X(:,1)-mean(s(i).X(:,1))).^2);s(i).x2=Ai(i);
    Bi(i)= sum((s(i).X(:,1)-mean(s(i).X(:,1))).*(s(i).X(:,2)-mean(s(i).X(:,2))));s(i).xy =Bi(i);
    Ci(i) = sum((s(i).X(:,2)-mean(s(i).X(:,2))).^2);s(i).y2=Ci(i);
    
    SSi(i)=(s(i).y2-(s(i).xy.^2)./s(i).x2);s(i).SSi=SSi(i);
    DFi(i)=s(i).n-2;s(i).DFi=DFi(i);
    b(i)=Bi(i)/Ai(i);s(i).b=b(i);
    %a(i)=sqrt(Ci(i));s(i).a=a(i);
end

ss.s=s;
ss.Ai=Ai;ss.Bi=Bi;ss.Ci=Ci;ss.SSi=SSi;ss.DFi=DFi;ss.n=n;ss.b=b;%ss.b2=b2;
ss.k=g;

figure(1);gscatter(X(:,2),X(:,3),X(:,1),'bgr','x.o');

%pooled regression
ss.SSp=sum(SSi);
ss.DFp=sum(n)-2*ss.k;

%common regression
ss.Ac=sum(Ai);ss.Bc=sum(Bi);ss.Cc=sum(Ci);ss.SSc=ss.Cc-(ss.Bc.^2)./ss.Ac;ss.DFc=sum(n)-ss.k-1;

%total regression
ss.At=sum((X(:,2)-mean(X(:,2))).^2);ss.Bt=sum((X(:,2)-mean(X(:,2))).*(X(:,3)-mean(X(:,3))));ss.Ct=sum((X(:,3)-mean(X(:,3))).^2);
ss.SSt=ss.Ct-(ss.Bt.^2)./ss.At;ss.DFt=sum(n)-2;

%F statistic for slopes
F=((ss.SSc-ss.SSp)./(ss.k-1))./(ss.SSp./ss.DFp);ss.F_slope=F;
fprintf('\n'); 
fprintf('Test of equality of slopes for all groups. \n'); 
fprintf('The F statistic is: %1.3f\n', F);
Ft=finv(1-alpha,ss.k-1,ss.DFp);ss.Ft_slope=Ft;
fprintf('and  F(%1.3f,%2i,%2i) = %1.3f\n', alpha,ss.k-1,ss.DFp,Ft);
p=1-fcdf(F,ss.k-1,ss.DFp);ss.p_slope=p;
fprintf('The p value is: %1.3f\n', p);
if p>alpha; ss.bc=sign(mean(sign(b(:,1)))).*ss.Bc/ss.Ac;fprintf('As p > %1.3f, the common regression coefficient bc = %1.3f can be used as estimate for the slope of the underlying samples.\n', alpha, ss.bc);else;ss.bc=NaN;fprintf('As p <= %1.3f, at least one of the groups has a different slope.\n',alpha);end
%disp(fprintf('\n'));

%F statistic for intercept
F=((ss.SSt-ss.SSc)./(ss.k-1))./(ss.SSc./ss.DFc);ss.F_intercept=F;
fprintf('\n'); 
fprintf('Test of equality of intercepts for all groups. \n'); 
fprintf('The F statistic is: %1.3f\n', F);
Ft=finv(1-alpha,ss.k-1,ss.DFc);ss.Ft_intercept=Ft;
fprintf('and  F(%1.3f,%2i,%2i) = %1.3f\n', alpha,ss.k-1,ss.DFc,Ft);
p=1-fcdf(F,ss.k-1,ss.DFc);ss.p_intercept=p;
fprintf('The p value is: %1.3f\n', p);

Xbp=sum(m(:,1).*n')./sum(n);Ybp=sum(m(:,2).*n')./sum(n);
ss.Xbp=Xbp;ss.Ybp=Ybp;
ac=Ybp-ss.bc.*Xbp;
if p>alpha; ss.ac=ac;fprintf('As p > %1.3f, the common regression coefficient ac = %1.3f can be used as estimate for the intercept of the underlying samples.\n', alpha, ss.ac);else;ss.ac=NaN;fprintf('As p <= %1.3f, at least one of the groups has a different intercept.\n',alpha);end

