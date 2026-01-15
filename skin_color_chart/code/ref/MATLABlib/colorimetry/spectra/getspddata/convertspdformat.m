function data=convertspdformat(filename)
%convert komma decimal numbers to point decimal numbers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
datastring=textread(filename,'%s');
chardatastring=char(datastring);
kommapos=find(chardatastring==',');
chardatastring(kommapos)='.';
data=str2double(cellstr(chardatastring));
lendata=length(data);
positions=(1:lendata);
oddn=find(mod(positions,2)~=0);
evenn=find(mod(positions,2)==0);
lamb=data(oddn);
spdy=data(evenn);
data=[lamb,spdy];
format long
dlmwrite(filename,data,'delimiter','\t','precision','%.15g');
end



