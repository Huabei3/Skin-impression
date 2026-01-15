
function [P] = lut3d( r,g,b,lut,method,cubeL)
%建立3DLUT
%r,g,b为三刺激值
%method:linear为线性插值（默认算法），cubic为三次插值，spline为三次样条插值，nearest为最邻近插值
X=lut(:,1);
Y=lut(:,2);
Z=lut(:,3);

[m,j,k]=meshgrid(linspace(0,255,cubeL));
lutX=reshape(X,cubeL,cubeL,cubeL);
lutY=reshape(Y,cubeL,cubeL,cubeL);
lutZ=reshape(Z,cubeL,cubeL,cubeL);
x=interp3(m,j,k,lutX,r,g,b,method);
y=interp3(m,j,k,lutY,r,g,b,method);
z=interp3(m,j,k,lutZ,r,g,b,method);
P=[x y z];

end