function datarfl=convertrflformat(filename,nrfls);
%convert rfl from elscolab colormeter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin==1;nrfls=1;end
datastring=textread(filename,'%s');
chardatastring=char(datastring);
kommapos=find(chardatastring==',');
if size(kommapos)~=0;
    chardatastring(kommapos)='.';
    rfl=str2double(cellstr(chardatastring));
    size(rfl)
    dlmwrite(['RFL',filename(1:end-4),'_original.txt'],[(350:5:1050)',reshape(rfl,numel(350:5:1050),nrfls)./100 ],'\t');
    %datarfl(:,1)=(380:1:780)';
    datarfl(:,1)=(360:1:830)';
    nrfls=size(rfl)./numel(350:5:1050);
    data=dlmread(['RFL',filename(1:end-4),'_original.txt'])
    for i=1:nrfls
        %data=[];data=[(350:5:1050)',rfl((1+(i-1)*numel(350:5:1050)):numel(350:5:1050)*i)];
        %data=interpK(data(:,1),data(:,2),datarfl(:,1),'linear');data_=data;
        data_=interpK(data(:,1),data(:,i+1),datarfl(:,1),'linear');

        datarfl(:,i+1)=data_;%./100;
    end
    
    dlmwrite(['RFL',filename(1:end-4),'.txt'],datarfl,'\t');
else
    datarfl=readdata(filename,2);
end
end