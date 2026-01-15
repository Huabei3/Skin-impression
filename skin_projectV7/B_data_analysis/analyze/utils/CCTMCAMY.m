function CCTest = CCTMCAMY(xyz)
xyY=xyz./sum(xyz')';
n=(xyY(:,1)-0.3320)./(xyY(:,2)-0.1858);
CCTest = -449*n.^3 + 3525*n.^2 - 6823.3*n + 5520.33;
end