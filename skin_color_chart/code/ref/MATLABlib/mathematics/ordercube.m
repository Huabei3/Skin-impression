function xyzXYZ=ordercube(XYZ,columns)
if nargin ==1; columns=3;end

%order 1 column
xXYZ=XYZ(rankdata(XYZ(:,1)),:);
jumps(1)=1;
i=1;
temp=1;
while  (jumps(i)<=length(XYZ(:,1)))
temp=(find(xXYZ(:,1)==xXYZ(jumps(i),1)));
jumps(i+1)=temp(end)+1;
i=i+1;
end
%jumps=jumps(1:end-1)
jumps;
if columns>1
%order 2° column
for i = 1:length(jumps)-1
    xXYZ_=xXYZ(jumps(i):jumps(i+1)-1,:);
    xyXYZ(jumps(i):jumps(i+1)-1,:)=xXYZ_(rankdata(xXYZ(jumps(i):jumps(i+1)-1,2)),:);
end
%find jumps of second column
j=1;
for i=2:length(XYZ(:,1))
    if xyXYZ(i-1,2)~=xyXYZ(i,2); jumps(j)=i;j=j+1;end
end
jumps=[1,jumps,length(xyXYZ(:,1))+1];
if columns>2
%order 3° column
for i = 1:length(jumps)-1
    xyXYZ_=xyXYZ(jumps(i):jumps(i+1)-1,:);
    xyzXYZ(jumps(i):jumps(i+1)-1,:)=xyXYZ_(rankdata(xyXYZ(jumps(i):jumps(i+1)-1,3)),:);
end
end
end
switch columns
    case 1
        xyzXYZ=xXYZ;
    case 2
        xyzXYZ=xyXYZ; 
    case 3
        xyzXYZ=xyzXYZ;
end        
end
