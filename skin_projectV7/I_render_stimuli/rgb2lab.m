function[l,a,b]=rgb2lab(r,g,b,white,w)

[X,Y,Z]=rgb2xyz(r,g,b,w);
%光源色%
 %xn = light10(:,2).*cmf10(:,2);
 %yn = light10(:,2).*cmf10(:,3);
 %zn = light10(:,2).*cmf10(:,4);
 %kn = 100/sum(yn);
 %Xn = kn*sum(xn);
 %Yn = kn*sum(yn);
 %Zn = kn*sum(zn);
 
 %参考白
 Xn = white(1);
 Yn = white(2);
 Zn = white(3);
 
 
 l=116*f(Y/Yn)-16;
 a=500*(f(X/Xn)-f(Y/Yn));
 b=200*(f(Y/Yn)-f(Z/Zn));

  %点运算 