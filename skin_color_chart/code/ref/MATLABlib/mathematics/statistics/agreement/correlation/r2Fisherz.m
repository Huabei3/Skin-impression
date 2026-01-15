function zf=r2Fisherz(r,k)
%convert correlation r to Fisher's Z
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
r(r>=k)=k;r(r<=-k)=-k;
zf = .5.*log((1+r)./(1-r));
end