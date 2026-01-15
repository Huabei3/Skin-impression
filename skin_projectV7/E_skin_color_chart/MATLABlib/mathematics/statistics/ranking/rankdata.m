function rankorder=rankdata(data)
%calculate the ranknumber of each element in data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

len=length(data);

%maxdata=max(data);
%mindata=min(data);

%for i = 1 : len
%    datatemp(i)=maxdata;
%    t=find(data==max(data));
%    rankorder(i)=t(1);
%    data(rankorder(i))=-1e-10;%set max to -1e-10
%    maxdata=max(data);
data2=fliplr(unique(sort(data)));
data;
i=1;t=1;
while i~=length(data2)+1;
    postemp=[];
    postemp=find(data==data2(i));
    data2(i);
    for j=1:length(postemp)
        pos(t)=postemp(j);
        
        t=t+1;
        
    end
    i=i+1;   
end
    
rankorder=(pos);
end


