function matrix=mulv(matrix,vector)
%multiplies each column with vector
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[rows,cols]=size(matrix);
if (length(vector(:,1)) ~= rows) & (length(vector(:,1))>1);
    disp('Vector size not compatible with matrix size!');;
    return;
else
    if length(vector(:,1))==1;
        matrix=matrix.*vector;
    else
        for i=1:cols
            matrix(:,i)=matrix(:,i).*vector;
        end
        %matrixt=reshape(matrix,rows*cols,1);vectort=repmat(vector,cols,1);
        %matrixt=matrixt.*vectort;
        %matrix=reshape(matrixt,rows,cols);
    end
end    