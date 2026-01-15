function help2file(fname)

% HELP2FILE  extract the help informations from a MATLAB file and save it separately

%   the help information will be saved with the same name but using an underscore as a prefix.

mhelp = help(fname);

fname = [strrep(fname,'.m','') '.m'];

%

fid = fopen(['_' fname],'w');

fwrite(fid,['%' strrep(mhelp,sprintf('\n'),sprintf('\n%%'))]);

fclose(fid);
