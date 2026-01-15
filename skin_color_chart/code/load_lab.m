% 清除工作区，方便开始新的操作
clear; 
clc;
% Define the two XLSX files to be processed
the_files = dir("color_chart2_data_i.xlsx");
the_files = [the_files; dir("color_chart2_data_r.xlsx")];

% Initialize empty matrices to hold the data and info
lab_all = []; 
lab_pre = [];
info_all = {}; % Cell array to store model, picname, and attribute for all data
info_pre = {}; % Cell array to store info for the first sheet

% Loop through each found XLSX file
for k = 1:length(the_files)
    file_name = the_files(k).name;
    
    % Get all sheet names from the current file
    [~, sheet_names] = xlsfinfo(file_name);
    
    % Loop through each sheet in the current filelab_clean
    for s = 1:length(sheet_names)
        sheet_name = sheet_names{s};
        
        % Skip the sheet named "10Ruddy"
        if strcmp(sheet_name, "10Ruddy")
            continue;
        end
        
        % Read the data from the sheet into a table
        T = readtable(file_name, 'Sheet', sheet_name);
        
        % Extract model and picname (assuming they are in columns 1 and 2)
        model_col = T(:, 1);
        picname_col = T(:, 2);
        
        % Convert the table to a double array, selecting columns 8, 9, and 10
        lab = table2array(T(:, 8:10)); 
        
        % Get the number of rows to process
        num_rows = size(lab, 1);
        
        % Loop through each row to check for NaNs and apply filters
        for r = 1:num_rows
            % Extract info for the current row
            model = model_col{r, 1};
            picname = picname_col{r, 1};
            current_lab = lab(r, :);
            
            % Skip rows with NaN values
            if any(isnan(current_lab))
                continue;
            end
            if current_lab(3)<-1
                disp(current_lab)
                continue;
            end 
            % --- Filtering Logic (Example) ---
            % Skip specific data points based on model, picname, and sheet_name
            if (ismember(model, ["f10r"]) && ismember(picname, ["9草地逆光"]) && ismember(sheet_name, ["01Preference","06Healthy","03Feminine","05Youth","08Harmony"])) || ...
               (ismember(model, ["m04r"]) && ismember(picname, ["11夕阳草地逆光"]) && ismember(sheet_name, ["09Fair"])) 
                disp(strcat(model, picname, sheet_name))
                continue
            end
            % ---------------------------------
            
            % Concatenate the processed data to the main matrices
            lab_all = [lab_all; current_lab];
            info_all = [info_all; {model, picname, sheet_name}];
            
            % If it's the first sheet of the current file, also append the data to lab_pre
            if s == 1
                lab_pre = [lab_pre; current_lab];
                info_pre = [info_pre; {model, picname, sheet_name}];
            end
        end
    end
end

% Display the final size of the concatenated data matrices
fprintf('Final concatenated data matrix lab_all size: %d x %d\n', size(lab_all, 1), size(lab_all, 2));
fprintf('Final concatenated first-sheet data matrix lab_pre size: %d x %d\n', size(lab_pre, 1), size(lab_pre, 2));

% Save the data and info to a MAT file for future use
save("lab_data.mat", "lab_all", "lab_pre", "info_all", "info_pre");