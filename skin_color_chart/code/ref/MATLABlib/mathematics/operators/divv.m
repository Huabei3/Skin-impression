function matrix=divv(matrix,vector)
%divides each column with vector
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[rows,cols]=size(matrix);
if (length(vector(:,1)) ~= rows) & (length(vector(:,1))>1);
    disp('Vector size not compatible with matrix size!');;
    return;
else
    if length(vector(:,1))==1;
        matrix=matrix./vector;
    else
        for i=1:cols
            matrix(:,i)=matrix(:,i)./vector;
        end
    end
end    
    