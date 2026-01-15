function bicorxy=midcor(X,Y)
ua=abs(X-median(X))./(9.*median(abs(X-median(X))))
va=abs(Y-median(Y))./(9.*median(abs(Y-median(Y))))

%calculate weigthing for x
Ix=zeros(numel(ua),1);%indicator function
Ix((1-abs(ua))>0)=1;
Ix=ua<=1;
wax=(1-ua.^2).^2.*Ix;

%calculate weigthing for x
Iy=zeros(numel(va),1);%indicator function
Iy((1-abs(va))>0)=1;
Iy=va<=1;
way=(1-va.^2).^2.*Iy;

xta=wax.*(X-median(X))./sqrt(sum(wax.*(X-median(X)).^2))
yta=way.*(X-median(X))./sqrt(sum(way.*(Y-median(X)).^2))

bicorxy=sum(xta.*yta);