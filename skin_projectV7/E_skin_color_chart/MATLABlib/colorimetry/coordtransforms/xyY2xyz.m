function xyz=xyY2xyz(xyY)
%transform from CIE xy, Y to XYZ
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
x=xyY(:,1);
y=xyY(:,2);
if size(xyY,2) == 3
    Y=xyY(:,3);
else
    Y=100*ones(1,length(x))';
end
X=(x./y).*Y;
Z=((1-x-y)./y).*Y;
xyz=[X,Y,Z];
end