% --- Main Script ---

% Define the folder where your input file is and where the output will be saved
save_folder = "documents";
input_filename = fullfile(save_folder, 'VIVO-skindata-average_0731.xlsx');
output_filename = fullfile(save_folder, 'ita_skin_classification.xlsx'); % 更改输出文件名以示区别

% --- 1. Read the XLSX file ---
% Read the entire sheet into a cell array to preserve mixed data types (numbers and text)
[~, ~, raw_data] = xlsread(input_filename);

% Initialize a cell array to build the new, updated data
updated_raw_data = {};
current_row_idx = 1;

% Loop through the raw_data row by row
while current_row_idx <= size(raw_data, 1)
    current_cell_content = raw_data{current_row_idx, 1};

    % Check if the current row starts with 'Male' or 'Female'
    if ischar(current_cell_content) && (strcmp(current_cell_content, 'Male') || strcmp(current_cell_content, 'Female'))
        gender_label = current_cell_content;

        % Append the gender label row to the new data
        updated_raw_data = [updated_raw_data; raw_data(current_row_idx, :)];

        % --- 2. Extract L* and b* data for calculation ---
        % Assuming L* is the row immediately after the gender label (current_row_idx + 1)
        % and b* is the row three rows after the gender label (current_row_idx + 3)
        % The data for 10 models is assumed to be in columns 2 through 11.
        L_vals_row_idx = current_row_idx + 1;
        a_vals_row_idx=current_row_idx + 2;
        b_vals_row_idx = current_row_idx + 3; % Corrected: b* is 3 rows after gender label

        % Basic check to ensure we don't go out of bounds
        if (L_vals_row_idx > size(raw_data, 1)) || (b_vals_row_idx > size(raw_data, 1))
            error('Data structure error: L* or b* rows are missing after the gender label.');
        end

        % Convert cell data to numeric arrays for calculations
        L_vals = cell2mat(raw_data(L_vals_row_idx, 2:11));
        a_vals = cell2mat(raw_data(a_vals_row_idx, 2:11));
        b_vals = cell2mat(raw_data(b_vals_row_idx, 2:11));
        if strcmp(current_cell_content, 'Male')
            Lab_m=[L_vals',a_vals',b_vals'];
        elseif strcmp(current_cell_content, 'Female')
            Lab_f=[L_vals',a_vals',b_vals'];
        end
        

        % Append the 5 data rows (L*, a*, b*, C*, h) for the current gender block
        % Corrected: Loop from 1 to 5 to include 'h' row
        num_data_rows_per_gender = 5;
        for k = 1:num_data_rows_per_gender
            if (current_row_idx + k) <= size(raw_data, 1)
                updated_raw_data = [updated_raw_data; raw_data(current_row_idx + k, :)];
            else
                error('Data structure error: Not enough data rows (L*, a*, b*, C*, h) after gender label.');
            end
        end

        % --- 3. Calculate ITA and 4. Classify Skin Type ---
        % Call the helper function to perform calculations and classification
        [ITA_calculated, skin_classification_calculated] = calculate_ita_and_classify(L_vals, b_vals);

        % --- 5. Prepare new rows for ITA and Skin Classification ---
        % Create new rows in the same format as the original data,
        % with the label in the first column and calculated values in subsequent columns.
        ITA_row_data = [{'ITA'}, num2cell(ITA_calculated)];
        skin_class_row_data = [{'Skin Classification'}, skin_classification_calculated];

        % Append the new calculated rows to the updated data
        updated_raw_data = [updated_raw_data; ITA_row_data; skin_class_row_data];

        % Move the current_row_idx past the processed block:
        % 1 row for the gender label + 5 rows for L*, a*, b*, C*, h data
        current_row_idx = current_row_idx + 1 + num_data_rows_per_gender; % Corrected increment
    else
        % If the current row is not a gender label, just append it as is
        updated_raw_data = [updated_raw_data; raw_data(current_row_idx, :)];
        current_row_idx = current_row_idx + 1;
    end
end
Lab_models=[Lab_f;Lab_m];
for i_row=1:size(Lab_models,1)
    model_table{i_row,1}=Lab_models(i_row,1);
    model_table{i_row,2}=Lab_models(i_row,2);
    model_table{i_row,3}=Lab_models(i_row,3);
    model_table{i_row,4}=sqrt(Lab_models(i_row,1).^2+ Lab_models(i_row,3).^2);
    model_table{i_row,5}=atan2d(Lab_models(i_row,3),Lab_models(i_row,2));
    [model_table{i_row,6}, model_table{i_row,7}] = calculate_ita_and_classify(Lab_models(i_row,1), Lab_models(i_row,3));
end

disp("d")

% --- 7. Write to a new XLSX file ---
% Save the final updated data (including ITA and skin classification for both genders)
% to a new Excel file.
xlswrite(output_filename, updated_raw_data);


disp(['Calculations complete. Results saved to ', output_filename]);


% --- Helper Function: calculate_ita_and_classify ---
% This function takes L* and b* values and returns calculated ITA values
% and their corresponding skin classifications.
function [ITA_vals, skin_classifications] = calculate_ita_and_classify(L_vals, b_vals)
    num_models = length(L_vals); % Get the number of models (columns)
    ITA_vals = zeros(1, num_models); % Pre-allocate array for ITA values
    skin_classifications = cell(1, num_models); % Pre-allocate cell array for skin classifications

    % Loop through each model's L* and b* values
    for i = 1:num_models
        L = L_vals(i); % Current L* value
        b = b_vals(i); % Current b* value

        % Calculate ITA using the provided formula
        ITA_val = atand((L - 50) / b);
        ITA_vals(i) = ITA_val; % Store the calculated ITA value

        % Classify Skin Type based on ITA using the provided rules
        if ITA_val > 55
            skin_classification_val = 'Very light';
        elseif ITA_val > 41 && ITA_val <= 55
            skin_classification_val = 'Light';
        elseif ITA_val > 28 && ITA_val <= 41
            skin_classification_val = 'Intermediate';
        elseif ITA_val > 10 && ITA_val <= 28
            skin_classification_val = 'Tan';
        elseif ITA_val > -30 && ITA_val <= 10
            skin_classification_val = 'Brown';
        elseif ITA_val <= -30
            skin_classification_val = 'Dark';
        else
            % Fallback for any ITA_val that doesn't fit the defined ranges
            skin_classification_val = 'Unknown';
        end
        skin_classifications{i} = skin_classification_val; % Store the classification
    end
end