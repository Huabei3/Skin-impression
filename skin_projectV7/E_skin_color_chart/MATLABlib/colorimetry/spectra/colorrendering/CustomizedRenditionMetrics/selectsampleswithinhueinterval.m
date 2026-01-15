function [usesamples,Nsamples,h]=selectsampleswithinhueinterval(ab,thetas)
%calculate hue_angle of samples
h=HueAngle(ab(:,1),ab(:,2));
if thetas(1)==0 & thetas(2)==360 
    usesamples=logical(ones(size(ab,1),1));
else
    %select only samples within hue interval thetas
    if thetas(1)>=thetas(2) %e.g. 340-150
        usesamples=logical(((h>=thetas(1)) |  (h<=thetas(2))));
    else % e.g. 40 - 150
        usesamples=logical(((h>=thetas(1)) & (h<=thetas(2))));
    end
end
Nsamples=size(ab,1);