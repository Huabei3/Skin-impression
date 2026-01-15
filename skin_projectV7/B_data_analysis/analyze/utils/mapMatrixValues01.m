function mappedMatrix = mapMatrixValues01(matrix)
    mappedMatrix = matrix;
    [rows, cols] = size(matrix);
    for i = 1:rows
        for j = 1:cols
            if matrix(i, j) == -3
                mappedMatrix(i, j) = 0;
            elseif matrix(i, j) == -2
                mappedMatrix(i, j) = 0;
            elseif matrix(i, j) == -1
                mappedMatrix(i, j) = 0;
            elseif matrix(i, j) == 1
                mappedMatrix(i, j) = 1;
            elseif matrix(i, j) == 2
                mappedMatrix(i, j) = 1;
            elseif matrix(i, j) == 3
                mappedMatrix(i, j) = 1;
            end
        end
    end
end