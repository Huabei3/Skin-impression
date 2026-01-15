function SCORE=rankscoring2(test,ref)
%evaluate rankingorder of test compared to ranking order of reference:
%the same error counting method is used as in 
%the Farnsworth-Munsell 100 Hue test
%____________________________________________________________________
baseline=(1:length(test));
for i=1:length(test)
    ref==test(i);
    t=find(ref==test(i));
    t=t(1);
    ranking(i)=t;
end
ranking;
diff=abs(ranking-baseline);
SCORE=sum(diff);
end