function d1f=firstderivative(fY,h)
d1f(1)=0;
for i=2:length(fY)-1;
    d1f(i)=(1./(2*h)).*(fY(i-1)-fY(i+1));
end
d1f=d1f(2:end);
end