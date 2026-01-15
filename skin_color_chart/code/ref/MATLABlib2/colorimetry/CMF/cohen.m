function C=cohen(spd)
%calculates Cohen's matrix 
%%%%%%%%%%%%%%%%%%%%%%%%%%%
C=spd*inv(spd'*spd)*spd';
end