% ReflectancePredictor.m
classdef ReflectancePredictor
    % ReflectancePredictor: 一个用于预测物体表面反射光谱的MATLAB类。
    % 它将原始 Reflectance_GS 和 rebuild_closepower 的功能整合，
    % 并使用基于CCT的自定义光源代替固定光源列表。
    properties (Access = private)
        CMFs_xyz_data   % (43x3 double) 标准观察者颜色匹配函数 (360:10:780nm)
        ReflectanceDB   % (struct) 反射光谱数据库 (例如 R_Types.mat 的内容)
        isDataLoaded    % (logical) 标记数据是否已加载
    end
    methods
        function obj = ReflectancePredictor()
            % 构造函数
            obj.isDataLoaded = false;
        end
        function obj = load_data(obj, cmfs_data_input, reflectance_db_path)
            % load_data: 加载颜色匹配函数和反射光谱数据库。
            %
            % 输入:
            %   cmfs_data_input (43x3 double): CMF数据。
            %   reflectance_db_path (string): 反射光谱数据库文件路径 (例如 'R_Types.mat')。
            if isnumeric(cmfs_data_input) && ismatrix(cmfs_data_input) && ...
               size(cmfs_data_input,1) == 43 && size(cmfs_data_input,2) == 3
                obj.CMFs_xyz_data = cmfs_data_input;
            else
                error('CMF数据必须是一个43x3的double类型矩阵。');
            end
            if exist(reflectance_db_path, 'file')
                obj.ReflectanceDB = load(reflectance_db_path); % 直接加载整个 .mat 文件内容
            else
                error('反射光谱数据库文件 "%s" 未找到。', reflectance_db_path);
            end
            obj.isDataLoaded = true;
            % disp('数据加载成功。'); % 可选的提示信息
        end
        function [RefP_out, XYZP_calculated, labP_predicted, m_deP] = predict_ref(obj, XYZ_target_Nx3, Type_idx, XYZ_ref_white)
            % predict_ref: 根据目标XYZ和参考白XYZ预测反射光谱。
            %              核心逻辑基于Reflectance_GS，但使用自定义光源。
            %
            % 输入:
            %   XYZ_target_Nx3 (Nx3 double): N个目标样本在参考光源下的XYZ值。
            %   Type_idx (integer): 数据库类型索引 (0-'all', 1-'coating', 等)。
            %   XYZ_ref_white (1x3 double): 参考白在自定义光源下的XYZ值。
            %
            % 输出 (与原Reflectance_GS一致):
            %   RefP_out (Nx43 double): 预测的反射光谱 (0-100范围)。
            %   XYZP_calculated (Nx3 double): 根据RefP_out计算得到的预测XYZ值。
            %   labP_predicted (Nx3 double): 根据XYZP_calculated预测的Lab值。
            %   m_deP (scalar): XYZ_target_Nx3 和 XYZP_calculated 之间的平均DeltaE2000。
            if ~obj.isDataLoaded
                error('请先调用 load_data 方法加载所需数据。');
            end
            
            N_samples = size(XYZ_target_Nx3, 1);
            wavelengths = (360:10:780)'; % 波长定义
            % --- 1. 从参考白XYZ_ref_white推导自定义光源特性 ---
            % 假设 XYZ2CCT 和 CCT2CIEref 函数在MATLAB路径中可用
            CCT_custom = XYZ2CCT(XYZ_ref_white, 2); % 获取CCT (假设10度观察者)
            S_custom_illuminant_raw = CCT2CIEref(CCT_custom, min(wavelengths), max(wavelengths), 10); % 获取SPD，预期为43x2，第一列波长，第二列SPD
            S_custom_illuminant = S_custom_illuminant_raw(:, 2); % 提取SPD值
            S_custom_illuminant = S_custom_illuminant(:); % 确保是43x1列向量
            
            % 自定义光源下的白点XYZW (用于Lab转换) 就是输入的 XYZ_ref_white
            XYZW_custom = XYZ_ref_white;

            %% --- 修改开始：对用于构建Aeq的光源SPD进行归一化 ---
            % 计算原始S_custom_illuminant在理想白板下的Y值
            Y_S_unnormalized = sum(obj.CMFs_xyz_data(:,2) .* S_custom_illuminant);
            if abs(Y_S_unnormalized) < 1e-9 % 避免除以零
                error('推导出的光源 S_custom_illuminant 的Y值接近零，无法进行归一化。请检查XYZ_ref_white或CCT2CIEref的输出。');
            end
            % 计算归一化因子，使归一化后的光源SPD在理想白板下的Y值为100
            normalization_ratio_for_Aeq_S = 100.0 / Y_S_unnormalized;
            S_illuminant_for_Aeq = S_custom_illuminant * normalization_ratio_for_Aeq_S;
            % --- 修改结束 ---

            % --- 2. 调用内部修改版的 rebuild_closepower 获取初始反射光谱 ---
            % rebuild_closepower_modified 内部有自己的归一化逻辑，
            % 因此传递给它的 S_custom_illuminant 应该是未经上述Y=100归一化的原始SPD。
            [r_rebuild_Nx43, ~,~,~] = obj.rebuild_closepower_modified( ...
                                        XYZ_target_Nx3, ...
                                        Type_idx, ...
                                        S_custom_illuminant, ... % <-- 使用原始的 S_custom_illuminant
                                        XYZW_custom, ...
                                        obj.CMFs_xyz_data, ...
                                        obj.ReflectanceDB ...
                                     );
            if isempty(r_rebuild_Nx43)
                error('rebuild_closepower_modified未能成功执行或返回空结果。');
            end
            % 准备用于 lsqlin 的初始反射光谱 (Ref_initial_guess)
            Ref_initial_guess_43xN = (r_rebuild_Nx43)' / 100.0; % 转为0-1范围, 43xN

            % --- 3. lsqlin 优化 (与原Reflectance_GS结构一致) ---
            n_wavelengths = 43;
            G = obj.create_smoothness_matrix_G(n_wavelengths); % 一阶平滑矩阵
            C_lsqlin = G;
            
            %% --- 修改开始：构建 Aeq 时使用归一化后的光源SPD ---
            % 使用 S_illuminant_for_Aeq 来构建Aeq_custom，确保其尺度与目标XYZ一致
            Aeq_custom_components = obj.CMFs_xyz_data .* S_illuminant_for_Aeq; % 43x3
            Aeq_custom = Aeq_custom_components'; % 3x43
            % --- 修改结束 ---
            
            lb = zeros(n_wavelengths,1);
            ub = ones(n_wavelengths,1);
            
            RefP_estimated_43xN = zeros(n_wavelengths, N_samples); % 存储优化结果 (43xN)
            lsqlin_options = optimoptions('lsqlin','Algorithm','interior-point','Display','off');
            
            XYZ_target_3xN = XYZ_target_Nx3'; 
            for k_sample = 1:N_samples % 循环处理每个样本
                d_smoothness = G * Ref_initial_guess_43xN(:, k_sample);
                beq_xyz_match = XYZ_target_3xN(:, k_sample); % 当前样本的目标XYZ (3x1)
                
                x_optimized = lsqlin(C_lsqlin, d_smoothness, [], [], Aeq_custom, beq_xyz_match, lb, ub, [], lsqlin_options);
                RefP_estimated_43xN(:, k_sample) = x_optimized; % <<--- 这是你之前报错的第119行
            end

            % --- 4. 计算输出结果 (与原Reflectance_GS结构一致) ---
            % 计算预测的XYZ值时，同样使用与lsqlin中一致的Aeq_custom (它基于归一化光源)
            XYZP_calculated_Nx3 = (Aeq_custom * RefP_estimated_43xN)'; % (3x43 * 43xN)' -> Nx3
            
            lab_target_Nx3 = xyz2lab(XYZ_target_Nx3, 'user', XYZW_custom);
            labP_predicted_Nx3 = xyz2lab(XYZP_calculated_Nx3, 'user', XYZW_custom);
            
            deP_vector_Nx1 = deltaE2000(lab_target_Nx3, labP_predicted_Nx3);
            if size(deP_vector_Nx1,2) > 1 && size(deP_vector_Nx1,1) == 1 
                 deP_vector_Nx1 = deP_vector_Nx1';
            end
            m_deP = mean(deP_vector_Nx1);
            
            RefP_out_Nx43 = RefP_estimated_43xN' * 100.0;
            
            RefP_out = RefP_out_Nx43;
            XYZP_calculated = XYZP_calculated_Nx3;
            labP_predicted = labP_predicted_Nx3;
        end
    end
    methods (Access = private)
        function [r_rebuild_Nx43, de_00_final, t_lab_final, r_lab_final] = rebuild_closepower_modified(obj, ...
                XYZ_target_Nx3, Type_idx, S_custom_illuminant, XYZW_custom, cmfs_data, reflectance_db_struct)
            % rebuild_closepower_modified: 内部实现的、适配自定义光源的初始光谱估计算法。
            % 结构上严格遵循用户提供的rebuild_closepower函数，仅修改光源处理部分。
            
            % --- 1. 根据Type_idx选择数据库 ---
            if Type_idx == 1
                rdata = reflectance_db_struct.R_Coating;
            elseif Type_idx == 2
                rdata = reflectance_db_struct.R_Printing;
            elseif Type_idx == 3
                rdata = reflectance_db_struct.R_Skin;
            elseif Type_idx == 4
                rdata = reflectance_db_struct.R_Plastics;
            elseif Type_idx == 5
                rdata = reflectance_db_struct.R_Textile;
            elseif Type_idx == 6
                rdata = reflectance_db_struct.R_Cotton;
            elseif Type_idx == 7
                rdata = reflectance_db_struct.R_Polyester;
            elseif Type_idx == 0
                rdata = reflectance_db_struct.R_alltypes;
            else
                r_rebuild_Nx43 = []; de_00_final = []; t_lab_final = []; r_lab_final = [];
                return;
            end
            % --- 2. 初始化和参数设置 ---
            num_target_samples = size(XYZ_target_Nx3,1);
            num_database_samples = size(rdata,1);
            n_closest = 10; 
            
            % --- 3. 计算目标和数据库样本的LAB值 ---
            t_lab_final = xyz2lab(XYZ_target_Nx3, 'user', XYZW_custom); 
            
            xyz_database_Dx3 = zeros(num_database_samples,3);
            for i_db = 1:num_database_samples
                reflectance_0_1 = rdata(i_db,:)' / 100.0; 
                % rebuild_closepower_modified 内部的XYZ计算应该使用其自身的归一化逻辑
                XYZw_calc_internal = (cmfs_data' * S_custom_illuminant); % S_custom_illuminant 是未经Y=100归一化的原始SPD
                ratio_internal = 100 / XYZw_calc_internal(2);
                XYZ_sample_calc = (cmfs_data' * (reflectance_0_1 .* S_custom_illuminant)) * ratio_internal; 
                xyz_database_Dx3(i_db,:) = XYZ_sample_calc';
            end
            lab_database_Dx3 = xyz2lab(xyz_database_Dx3, 'user', XYZW_custom); 
            
            % --- 4. 计算色差并排序 ---
            indices_closest_NxNclosest = zeros(num_target_samples, n_closest); 
            sorted_deltaEs_NxNclosest = zeros(num_target_samples, n_closest);  
            for i_target = 1:num_target_samples
                current_target_lab_1x3 = t_lab_final(i_target,:);
                deltaE_vector_Dx1 = zeros(num_database_samples, 1);
                for i_db = 1:num_database_samples
                    deltaE_vector_Dx1(i_db) = deltaE2000(lab_database_Dx3(i_db,:), current_target_lab_1x3);
                end
                [sorted_DE_values, sorted_DB_indices] = sort(deltaE_vector_Dx1);
                
                indices_closest_NxNclosest(i_target, :) = sorted_DB_indices(1:n_closest)';
                sorted_deltaEs_NxNclosest(i_target, :) = sorted_DE_values(1:n_closest)';
            end
            % --- 5. 反射率加权重建 ---
            r_rebuild_Nx43_weighted = zeros(num_target_samples, 43);
            for i_target = 1:num_target_samples
                sum_inv_deltaE_cubed = 0;
                current_weighted_sum_r = zeros(1,43);
                for k_closest_idx = 1:n_closest
                    deltaE_val = sorted_deltaEs_NxNclosest(i_target, k_closest_idx);
                    if deltaE_val < 1e-6 
                        effective_deltaE_val = 1e-6; 
                    else
                        effective_deltaE_val = deltaE_val;
                    end
                    weight = 1 / (effective_deltaE_val^3);
                    sum_inv_deltaE_cubed = sum_inv_deltaE_cubed + weight;
                    database_actual_idx = indices_closest_NxNclosest(i_target, k_closest_idx);
                    current_weighted_sum_r = current_weighted_sum_r + rdata(database_actual_idx, :) * weight;
                end
                if sum_inv_deltaE_cubed > 1e-9 
                    normalization_factor_a = 1 / sum_inv_deltaE_cubed;
                else 
                    normalization_factor_a = 0; 
                    if n_closest > 0
                         closest_idx_fallback = indices_closest_NxNclosest(i_target, 1);
                         r_rebuild_Nx43_weighted(i_target, :) = rdata(closest_idx_fallback, :);
                    else
                         r_rebuild_Nx43_weighted(i_target, :) = zeros(1,43); 
                    end
                end
                if normalization_factor_a ~= 0 
                    r_rebuild_Nx43_weighted(i_target, :) = normalization_factor_a * current_weighted_sum_r;
                end
            end
            r_rebuild_Nx43 = r_rebuild_Nx43_weighted; 
            
            % --- 6. 计算重建反射率的XYZ, LAB, 以及与目标的最终色差 ---
            % 注意：这里计算重建XYZ时，也应该使用与 rebuild_closepower_modified 内部一致的归一化逻辑
            % 即，使用原始 S_custom_illuminant 和 ratio_internal
            r_xyz_rebuilt_Nx3 = zeros(num_target_samples,3);
            XYZw_calc_for_final_ratio = (cmfs_data' * S_custom_illuminant); % 与上面一致的XYZw计算
            ratio_for_final_rebuilt_xyz = 100 / XYZw_calc_for_final_ratio(2);

            for i_target = 1:num_target_samples
                reflectance_0_1 = r_rebuild_Nx43(i_target,:)' / 100.0; 
                XYZ_sample_rebuilt = (cmfs_data' * (reflectance_0_1 .* S_custom_illuminant)) * ratio_for_final_rebuilt_xyz; % 应用ratio
                r_xyz_rebuilt_Nx3(i_target,:) = XYZ_sample_rebuilt';
            end
            r_lab_final = xyz2lab(r_xyz_rebuilt_Nx3, 'user', XYZW_custom);
            de_00_final_vector = deltaE2000(r_lab_final, t_lab_final);
            if size(de_00_final_vector,2) > 1 && size(de_00_final_vector,1) == 1 
                 de_00_final_vector = de_00_final_vector';
            end
            de_00_final = de_00_final_vector; 
        end 
        function G = create_smoothness_matrix_G(obj, n_wavelengths)
            G = zeros(n_wavelengths-1, n_wavelengths);
            for k_g = 1:(n_wavelengths-1)
                G(k_g,k_g) = 1;
                G(k_g,k_g+1) = -1;
            end
        end 
    end 
end