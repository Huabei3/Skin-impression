% check_xlsx_summary.m
% 精简版：只输出汇总信息

clear; clc;

base_path = 'D:\work\VIVOskinExpe\skin_model\data\correlation_results\fullpara\efit_p\new\ACSA\each_self';

ablation_types = {'scene_types', 'no_scene_types', 'full_CAT', 'no_nation', 'no_L_depend'};

expected_models = {'f04', 'f05', 'f06', 'm04', 'm05', 'm06', ...
                   'f01', 'f02', 'f03', 'm01', 'm02', 'm03', ...
                   'f07', 'f08', 'm07', 'm08', ...
                   'f09', 'f10', 'm09', 'm10'};

for a = 1:length(ablation_types)
    at = ablation_types{a};
    folder = fullfile(base_path, at);
    
    fprintf('\n========== %s ==========\n', at);
    
    if ~exist(folder, 'dir')
        fprintf('  folder not found\n');
        continue;
    end
    
    xlsx_files = dir(fullfile(folder, '*.xlsx'));
    
    for f = 1:length(xlsx_files)
        fname = xlsx_files(f).name;
        fpath = fullfile(folder, fname);
        
        fprintf('\n  %s:\n', fname);
        
        n_found = 0;
        missing_list = {};
        
        for m = 1:length(expected_models)
            mn = expected_models{m};
            try
                data = readmatrix(fpath, 'Sheet', mn);
                n_found = n_found + 1;
            catch
                missing_list{end+1} = mn;
            end
        end
        
        fprintf('    Sheets: %d/20', n_found);
        if ~isempty(missing_list)
            fprintf(', MISSING: %s', strjoin(missing_list, ','));
        end
        fprintf('\n');
    end
end

fprintf('\nDone.\n');
