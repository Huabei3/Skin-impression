function STRESS_=STRESS(dEi,dVi)
%calculate STRESS performance metric
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  F1=sum(dEi.^2)./sum(dEi.*dVi);
%STRESS_1=sqrt(sum((dEi-F1.*dVi).^2)./sum((F1.*dVi).^2));
STRESS_=sqrt(1-((sum(dEi.*dVi)).^2)/(sum(dEi.^2).*sum(dVi.^2)));
end