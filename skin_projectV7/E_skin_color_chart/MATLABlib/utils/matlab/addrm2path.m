function addrm2path(addorremove,path_1)
global maindir
if exist('maindir','var');
    if isempty(maindir);maindir=cd;
    end;
end
if nargin<2
    if exist([maindir,'\LIB_KS.txt']);
        t=textread([maindir,'\LIB_KS.txt'],'%s','delimiter','\n');
        for i=numel(t):-1:1;
            path_1=char(t(i));
            disp(sprintf('Adding %s.',path_1))
            if strcmp(path_1(1:9),'MATLABlib')==1;path_1=[maindir,path_1(10:end)];end
            switch addorremove
                case 'add'
                    addpath(path_1);
                case 'rm'
                    rmpath(path_1);
                case 'remove'
                    rmpath(path_1);
            end
        end
    else
        fprintf('File "\\LIB_KS.txt" with library locations not found at: %s\n',maindir);
    end
else
    switch addorremove
       case 'add'
            addpath(path_1);
       case 'rm'
            rmpath(path_1);
       case 'remove'
            rmpath(path_1);
    end
end