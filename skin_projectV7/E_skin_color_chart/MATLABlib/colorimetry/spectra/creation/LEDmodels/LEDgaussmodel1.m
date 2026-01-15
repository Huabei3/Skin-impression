function g = LEDgaussmodel1(lamb0, halflamb,wavrange)
%create single color LED using LED model proposed by Y.Ohno
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin<3;wavrange=[360 830 1];end
lb=wavrange(1);
le = wavrange(2);
stepsize = wavrange(3);

for k = 1 : ((le-lb)/stepsize + 1);
    lamb = (k-1)*stepsize + lb;
    gauss1 = exp(-((lamb-lamb0)./halflamb).^2);
    g(k,1) = ((gauss1)+2.*(gauss1)^5)./3;
end
g=g./max(g);
end

