function t=cct(white)%ÊäÈëÎª3*1¾ØÕó
xe=0.3320;
ye=0.1858;
x=white(1)/sum(white);
y=white(2)/sum(white);
n=(x-xe)/(y-ye);
t=-449*n^3+3525*n^2-6823.3*n+5520.33;

