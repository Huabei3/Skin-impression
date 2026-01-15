function xyzc = xyz2xyzcJuddCAT(xyz,xyzw1,xyzw2,cspace);
if nargin < 4; cspace = 'uvY';end

%convert to selected cspace for CAT
Yuv = xyz2cspace(xyz,[],cspace);
Yuvw1 = xyz2cspace(xyzw1,[],cspace);
Yuvw2 = xyz2cspace(xyzw2,[],cspace);

%do a Judd type chromatic adaptation (translational) 
uvc=Yuv(:,2:3)+repmat(Yuvw2(2:3)-Yuvw1(2:3),size(xyz,1),1);
Yuvc=[xyz(:,2),uvc];

%convert back to xyz
xyzc = cspace2xyz(Yuvc,[],cspace);
