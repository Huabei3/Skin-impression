function SCORE=rankscoring(test,ref)
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
for i=2:(length(test)-1)
    baselinescore(i-1)=abs(baseline(i-1)-baseline(i))+abs(baseline(i)-baseline(i+1));
    score(i-1)=abs(ranking(i-1)-ranking(i))+abs(ranking(i)-ranking(i+1));
end
baselinescore;
score;
baselinescore_=sum(baselinescore);
score_=sum(score);
SCORE=abs(baselinescore_-score_);
end