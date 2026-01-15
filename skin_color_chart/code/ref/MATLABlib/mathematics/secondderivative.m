function d2f=secondderivative(fY,h)
d2f(1)=0;
for i=2:length(fY)-1;
    d2f(i)=(1./h^2).*(fY(i-1)-2*fY(i)+fY(i+1));
end
d2f=d2f(2:end);
end