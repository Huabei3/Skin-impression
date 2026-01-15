function [W,p,Fdist]=kendallW(X,tied)
%% Computes the Kendall's W.
% X is a n*k ratings matrix.
% n is the number of objects and k is the number of judges.

[n,k]=size(X);
if tied
    [R,TT]=tiedrank(X,1);
    sR=sort(R);
    uR=unique(sR);
    for j=1:k;
        %uR(:,j)=unique(sR(:,j));
        for i=1:length(uR(:,1))
            temp=[(ismember(sR(:,j),uR(i,1))),sR(:,j)];
            tk(i,j)=sum(temp(:,1));
        end
    end
    
    tk=tk-1;sum(tk.^3-tk);
    T=sum(sum(tk.^3-tk)');
    RS=sum(R,2);
    S=sum(RS.^2)-n*mean(RS).^2;
    F=k*k*(n*n*n-n)-k*sum(T.^3-T);
    W=12*S/F;
else
    [Y,I]=sort(X);
    [Y,R]=sort(I);
    RS=sum(R,2);
    S=sum(RS.^2)-n*mean(RS).^2;
    F=k*k*(n*n*n-n);
    W=12*S/F;
end
%Chi=k*(n-1)*W;
%p=chi2pdf(Chi,n-1);
Fdist=W*(k-1)./(1-W);
nu1 = n-1-(2/k);
nu2 = nu1*(k-1);
p=fpdf(Fdist,nu1,nu2);

%_______________________


end