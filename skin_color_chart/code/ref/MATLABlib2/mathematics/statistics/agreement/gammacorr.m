function [G,z]=gammacorr(X,Y)
%calculate the gamma correlation and its z-score
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

table=crosstab(X,Y);table=flipud(fliplr(table));
N=length(X);
tablelr=fliplr(table);
[m,n]=size(table);
t=0;Na_=[];Ni_=[];
for i=1:m
    for j=1:n
        t=t+1;
        if i+1<=m & j+1<=n; sumaij=sum(sum(table(i+1:end,j+1:end))');else sumaij=0;end
        Na_(t)=table(i,j).*sumaij;
        if i+1<=m & j+1<=n; sumiij=sum(sum(tablelr(i+1:end,j+1:end))');else sumiij=0;end
        Ni_(t)=tablelr(i,j).*sumiij;
    end
end
Na=sum(Na_);
Ni=sum(Ni_);
G=(Na-Ni)./(Na+Ni);
z=G*sqrt((Na+Ni)/(N*(1-G^2)));
end