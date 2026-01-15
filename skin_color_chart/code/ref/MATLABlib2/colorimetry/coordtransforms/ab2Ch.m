function Ch=ab2Ch(ab)
%FUNCTION ab2Ch 
%   transform from a*b* to Chroma and hue angle;

a=ab(:,1);
b=ab(:,2);
C=(a.^2+b.^2).^0.5;
h_=atand(b./a);
h(a>=0&b>=0,:)=h_(a>=0&b>=0,:);
h(a>=0&b<0,:)=360+h_(a>=0&b<0,:);
h(a<0,:)=180+h_(a<0,:);
h(a==0&b==0,:)=360*rand;
Ch=[C,h];

end

