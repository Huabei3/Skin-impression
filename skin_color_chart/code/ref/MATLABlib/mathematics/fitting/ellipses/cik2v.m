function [v,theta]=cik2v(cik)
%cik --> v
%ellipse format -->v=[Rmax,Rmin,xc,yc,theta]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
g11=cik(1,1);g22=cik(2,2);g12=cik(1,2);
%if g12^2-g11*g22>0;disp('Not an ellipse!: g12^2-g11*g22>0!');end

theta2=1/2*atan2(2*cik(1,2),(cik(1,1)-cik(2,2)));
theta=theta2+(pi/2)*(cik(1,2)<0);
theta2=theta;
cottheta = cot(theta);
cottheta(isinf(cottheta))=0;

%theta2=1/2*atan(2*cik(1,2)/(cik(1,1)-cik(2,2)))*180/pi

a=1/sqrt((cik(2,2)+cik(1,2)*cottheta));
%d=1;a=sqrt((2*(-d^2))/((-sqrt((cik(1,1)-cik(2,2))^2+4*cik(1,2)^2)-(cik(1,1)-cik(2,2)))))
%a2=sqrt(1/(0.5*(g11+g22-sqrt((g11-g22).^2+4.*g12.^2))))

b=1/sqrt((cik(1,1)-cik(1,2)*cottheta));
%d=1;b=sqrt((2*(-d^2))/((sqrt((cik(1,1)-cik(2,2))^2+4*cik(1,2)^2)-(cik(1,1)-cik(2,2)))));
%b2=sqrt(1/(0.5*(g11+g22+sqrt((g11-g22).^2+4.*g12.^2))));

v=[a,b,0,0,theta];
%v2=[(a2),(b2),0,0,theta2];

end
