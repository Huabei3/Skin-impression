function copydir(source,destination,exts)
%copy all files with extensions exts from source to destination folder
if nargin<3;exts={'png','jpg','bmp','txt','dat','xls','xlsx'};end
    
[pathstr_S,name_S,ext_S] = fileparts(source);
[pathstr_D,name_D,ext_D] = fileparts(destination);
if isempty(name_D) & isempty(name_S) & isempty(ext_D) & isempty(ext_S) %= dirs
    
    files=ls_(source)
        for i=3:numel(files)
            
            [pathstr_S,name_S,ext_S] = fileparts(char(files{i}));
            ext_S=ext_S(2:end);
            ext_D=ext_D(2:end);
            if ismember({ext_S},{exts{1:3}})
                data=imread([char(pathstr_S),char(name_S),'.',char(ext_S)],char(ext_S));
                size(data)
                imwrite([pathstr_D,name_S,'.',ext_S],data);
                clear data
            end

            if ismember({ext_S},{exts{4:6}})
                fid=fopen([pathstr_S,name_S,'.',ext_S],'r');
                data=textread(fid,'%s');
                fclose(fid);
                fid=fopen([pathstr_D,name_D,'.',ext_S],'w');
                data=fprintf(fid,'%s');
                fclose(fid);
            end
        end
end
end