function [icck,kappa,Ir]=repeatability(data,kscale)
%check repeatability using
%icck: intraclass correlation
%kappa: fleiss kappa
%Ir: Perreault and Leigh index of reliability
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[N,n]=size(data);%N=test subjects; n=total datapoints to be scored

for j=1:kscale
    nij(:,j)=(sum((data==j)'))';%nij represent the number of raters who assigned the i-th subject to the j-th category.
end
pj=1/(N*n)*sum(nij);%pj, the proportion of all assignments to the j-th category
Pi=1/(n*(n-1))*(sum((nij.*nij-1)'))';%the extent to which raters agree for the i-th subject
Pbar=mean(Pi);
Pebar=sum(pj.^2);

%1 fleiss kappa
kappa=(Pbar-Pebar)./(1-Pebar);

%2 Perreault and Leigh index of reliability
Ir=sqrt((Pbar-1/kscale)*(kscale/(kscale-1)));

%3 ICC: intraclass correlation
icck = ICC(2,'k',data);
iccsingle = ICC(2,'single',data);
end