function value_=string2values(inputstr)
inputstr=[',',inputstr,','];
inputkomma=find(inputstr== ',');

for i= 1:(length(inputkomma)-1)
    pos1=inputkomma(i)+1;
    pos2=inputkomma(i+1)-1;
    value_(i)=str2double(inputstr(pos1:pos2));
end
end