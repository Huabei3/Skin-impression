function h=HueAngle(a,b)
h=atan2(b,a)*180/pi;
s1=h<0;
s2=h>=0;
h1=(h+360).*s1;
h2=h.*s2;
h=h1+h2;
end
