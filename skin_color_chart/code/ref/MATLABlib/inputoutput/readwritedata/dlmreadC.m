function [d]=dlmreadC(filename,datatype)
% Read data from file. 
% If codon's (e.g. <data> 12 </data>) are detected than use codons as 
% fields of a struct: example output: d.data = 12
if nargin==1;datatype='%f';end

%start reading data from file
switch datatype
    case '%s'
        
        delimiter=sprintf('\t');
        fid=fopen(filename,'r');
        i=1;
        tline = fgetl(fid);
        data{i}=tline;
        while ischar(tline)
            i=i+1;
            tline = fgetl(fid);
            data{i}=tline;
        end
        fclose(fid);
        data=data([1:end-1]);
             
        data=data(~ismember(data,''));% remove empty lines

        %convert to numeric and strings and store in temporary cell, 
        isnum=zeros(1,numel(data));
        siz=zeros(numel(data),2);
        
        for ii=1:numel(data)
            string=data{ii};
            
            % Find the delimiters
            delimIdx = find(string == delimiter);

            % Pretend there are delimiters at the beginning and end, for the loop below
            delimIdx = [0  delimIdx  length(string)+1];

            % Preallocate cell array to hold substrings
            subStrings = cell(1, length(delimIdx) - 1);

            % Process each element
            for i = 1:length(subStrings)

                % Find the text between the delimiters
                %(don't include the delimiters)
                startOffset = delimIdx(i)   + 1;
                endOffset   = delimIdx(i+1) - 1;

                % Get the element
                txt = string(startOffset:endOffset);

                % Attempt conversion to number
                num = sscanf(txt, '%f');

                % Number conversion successful if no error message
                if isempty(num)
                    subStrings{1,i} = txt;
                else
                    subStrings{1,i} = num;
                end
        
            end
            data_{ii}=cell2mat(subStrings);
            
            %switch single column vectors to row vectors 
            if size(data_{ii},2)==1;data_{ii}=data_{ii}';end
            
            %store size and datatype of each read subString
            siz(ii,:)=size(data_{ii});
            isnum(ii)=isnumeric(data_{ii});
                 
        end
        
        
        %join numeric data in sequential cell into one array
        clear data
        t=1;i=1;
        while i<=numel(data_)
            
            if isnum(i)==0
                data{t}=data_{i};
                i=i+1;t=t+1;
            else
                temp=[];
                if i<numel(data_)
                    while isnum(i)==1 
                        temp=[temp;data_{i}];%sizes must fit!!
                        i=i+1;
                    end
                else
                    temp=data_{i};
                    i=i+1;
                end
                data{t}=temp;
                t=t+1;
            end
        end
        
          
        %determine if data{i} is codon and if start or end codon
        for t=1:numel(data)
            isnumt(t)=isnumeric(data{t});
            iscodon(t)=0;
            codons{t}='';
            if isnumt(t)==0
                if data{t}(1)=='<' & data{t}(end)=='>'
                    if data{t}(1:2)=='</'
                        iscodon(t)=2;
                        codons{t}=data{t}(2:end-1);
                    else
                        iscodon(t)=1;
                        codons{t}=data{t}(2:end-1);
                    end
                    
                end
            end
        end
            
    
     %read codons if any and store in new struct    
     fields=codons(iscodon>=1);
     pcodons=find(ismember(codons,fields));
     Ncodons=numel(pcodons)/2;
     
      d.file=filename;
      for i=1:2:numel(fields)-1
         field=fields(i);
         value=(data(pcodons(i)+1:pcodons(i+1)-1));
         if ~iscellstr(value);
             value=cell2mat(value);
         end
         d=setfield(d,char(fields(i)),value);
      end

       
    otherwise

       try 
           d=dlmread(filename);
       catch
           d=dlmreadC(filename,'%s');
       end
end

        
