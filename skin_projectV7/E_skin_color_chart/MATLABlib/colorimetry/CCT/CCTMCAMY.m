function CCTest = CCTMCAMY(xyY)
%Calculates correlated colour temperature using the MCAMY equation
%xyY: CIE xy coordinates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
n=(xyY(:,1)-0.3320)./(xyY(:,2)-0.1858);
CCTest = -449*n.^3 + 3525*n.^2 - 6823.3*n + 5520.33;
end