function fwrite_cellstr(filename,cellstr_,appendyn)
%write cellstr_ to textfile specified by filename.
%appendy: 'a' append (default)
%         'w' overwrite existing content
%%%%%%%%%%%ù%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin<3;appendyn='a';end

if exist(filename,'var') | appendyn=='a'
    fid = fopen(filename,'a');
else
    fid = fopen(filename,'w');
end

for i=1:numel(cellstr_)
    fprintf(fid,'%s\n',cellstr_{i});
end

fclose(fid);
    