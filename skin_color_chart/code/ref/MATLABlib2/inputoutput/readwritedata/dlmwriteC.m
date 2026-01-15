function dlmwriteC(fid,filename,data,varargin)
% Write data to file. If data is struct than create a file with as codon's 
% the struct's fieldnames.

if isstruct(data)
  codons=fieldnames(data);
  if isempty(fid);
      fid=fopen(filename,'w');%open file for writing (overwrite existing data)
  end
  
  codon=char(codons(1));
  value=getfield(data,codon);
  if iscellstr(value)
      value={value};
  else
      if ischar(value)
          value={value};
      end
  end
  dlmwriteC(fid,filename,value,'codon',codon); %call itself to write first set
  
  fclose(fid);
  fid=fopen(filename,'a');%open file to append new data
  for i=2:numel(codons)
      
      codon=char(codons(i));
      value=getfield(data,codon);
      
      if iscellstr(value)
        value={value};
      else
        if ischar(value)
            value={value};
        end
      end
      
      dlmwriteC(fid,filename,value,'codon',codon) %call itself
    
    
   end
   fclose(fid);   
    
else
      
    if ~iscell(data)
        data={data};
    end


%set defaults
%if nargin<3;
codon='';
%end
precision='%1.6f';
delimiter='\t';
addline='';

%overwrite defaults when given
if ~isempty(varargin)
    for i=1:2:numel(varargin)-1
        switch char(varargin{i})
            case 'delimiter'
                delimiter=varargin{i+1};
            case 'precision'
                precision=varargin{i+1};
            case 'codon'
                codon=varargin{i+1};
            case '\n'
                addline=varargin{i+1};
        end
    end
end


%start writing data to file
if iscell(data) | ~isempty(codon)
    if isempty(fid);
        fid=fopen(filename,'a');
        newfid=1;
    else
        newfid=0;
    end

    if numel(data)==1 & iscell(data{1}) %for blockwriting
            
            blockwriting=1;
            if numel(data{1})==1;
                blockwriting=0;
            end
            data=data{1};    
    else
        blockwriting=0;
    end
    for i=1:numel(data)
             
        if ischar(data{i})
            if isempty(codon);
                %fprintf(fid,'\n%s\n',data{i});
                fprintf(fid,'%s\n',data{i});
            else
                 if blockwriting ==1;
                    switch  i
                        case 1
                            %disp(sprintf('<%s>\n%s\n',codon,data{i}));
                            fprintf(fid,'<%s>\n%s\n',codon,data{i});
                        case numel(data)
                            %disp(sprintf('%s\n</%s>\n\n',data{i},codon));
                            fprintf(fid,'%s\n</%s>\n\n',data{i},codon);
                        otherwise
                            %disp(sprintf('%s\n',data{i}));
                            fprintf(fid,'%s\n',data{i});
                    end
                            
                 else
                    %disp(sprintf('<%s>\n%s\n</%s>\n\n',codon,data{i},codon));
                    fprintf(fid,'<%s>\n%s\n</%s>\n\n',codon,data{i},codon);
                end
            end
        else
            if isnumeric(data{i})
                  if isempty(codon);
                    dlmwrite(filename,data{i},'delimiter',delimiter,'precision',precision,'-append');
                  else
                    fprintf(fid,'<%s>\n',codon);%write data between codons (similar to html) for later retrieval
                    dlmwrite(filename,data{i},'delimiter',delimiter,'precision',precision,'-append');
                    fprintf(fid,'</%s>\n\n',codon);%write data between codons (similar to html) for later retrieval
                  end
            end
        end
    end
    if newfid==1;
        fclose(fid);
    end
else
   
    dlmwrite(filename,data,'delimiter',delimiter,'precision',precision);
end
end            
        