function rankn=rankofdata(test)
%evaluate rankingorder of test
%______________________________
ref=(1:length(test));
r=fliplr(rankdata(test));
for i=1:length(test)
    rankn(r(i))=i;
end
end