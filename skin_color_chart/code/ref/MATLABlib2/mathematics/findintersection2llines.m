function X=findintersection2llines(xy1,xy2)
%Find the intersection point X of two lines defined by 
%xy1 & xy2; if y=a*x+b then xy = [a,b];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


line1=polyfit(xy1(:,1),xy1(:,2),1);%first straight line


line2=polyfit(xy2(:,1),xy2(:,2),1);%second straight line

%solve A*X=B by X=A\B
A= [line1(1),-1;line2(1),-1];
B=[-line1(2),-line2(2)]';

X=A\B;

%check solution
if norm(A*X-B)<10^(-5)*norm(B);
    X=X;
else
    X=[];
    disp('No solution using X=A\B');
end
end




