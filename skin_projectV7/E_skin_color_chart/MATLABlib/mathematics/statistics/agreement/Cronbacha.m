function [Cronbachalpha]=Cronbacha(Yik)
%Calculates Chronbach's alpha

%[N,m]=size(data)
%N: items
%m: test subjects

%get number of items and observers
[N,m]=size(Yik);

Yi=(1/m).*sum(Yik,2);%mean scores for items i (1:N)
Xk=sum(Yik,1);%total scores for test subjects k (1:m)
Xbar=mean(Xk);%mean total score


%calculate cronbach alpha
SYi2=(1/(m-1)).*sum((Yik-repmat(Yi,1,m)).^2,2);
SX2=(1/(m-1)).*sum((Xk-Xbar).^2);
Cronbackalpha=(N./(N-1)).*(1-sum(SYi2,1)./SX2);