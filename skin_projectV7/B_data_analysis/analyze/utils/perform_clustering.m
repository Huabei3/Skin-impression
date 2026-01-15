%% 聚类函数实现
function [labels, centers] = perform_clustering(data, method, k, eps, minPts, xi, linkage)
% 功能：根据指定方法对数据进行聚类
% 输入：
%   data - 输入数据，每行一个样本
%   method - 聚类方法：'kmeans', 'kmeans++', 'bi-kmeans', 'DBSCAN', 'OPTICS', 'agglomerative'
%   k - 聚类数量(适用于kmeans类方法)
%   eps - DBSCAN邻域半径
%   minPts - DBSCAN最小点数
%   xi - OPTICS xi参数
%   linkage - 层次聚类连接方式
% 输出：
%   labels - 聚类标签
%   centers - 聚类中心(不适用于密度聚类)

    if nargin < 3, k = 3; end
    if nargin < 4, eps = 2.5; end
    if nargin < 5, minPts = 3; end
    if nargin < 6, xi = 0.05; end
    if nargin < 7, linkage = 'ward'; end
    
    % 初始化输出
    labels = zeros(size(data, 1), 1);
    centers = [];
    
    switch lower(method)
        case 'kmeans'
            % 标准K-means
            [labels, centers] = kmeans(data, k, 'Distance', 'sqeuclidean', ...
                'Replicates', 5, 'EmptyAction', 'singleton');
                
        case 'kmeans++'
            % K-means++初始化的K-means
            [labels, centers] = kmeans(data, k, 'Distance', 'sqeuclidean', ...
                'Start', 'plus', 'Replicates', 5, 'EmptyAction', 'singleton');
                
        case 'bi-kmeans'
            % 二分K-means
            labels = zeros(size(data, 1), 1);
            clusters = {data};
            cluster_labels = zeros(size(data, 1), 1);
            
            % 初始只有一个聚类
            for i = 1:k-1
                % 选择方差最大的聚类进行分裂
                max_var = -inf;
                best_split_idx = 0;
                for j = 1:length(clusters)
                    if isempty(clusters{j})
                        continue;
                    end
                    % 计算当前聚类的方差
                    var_j = sum(var(clusters{j}));
                    if var_j > max_var
                        max_var = var_j;
                        best_split_idx = j;
                    end
                end
                
                % 分裂选中的聚类
                if best_split_idx > 0
                    [idx, ~] = kmeans(clusters{best_split_idx}, 2, ...
                        'Distance', 'sqeuclidean', 'Replicates', 3);
                    
                    % 更新聚类
                    cluster1 = clusters{best_split_idx}(idx == 1, :);
                    cluster2 = clusters{best_split_idx}(idx == 2, :);
                    
                    % 更新标签
                    orig_idx = find(cluster_labels == best_split_idx);
                    new_labels = zeros(length(orig_idx), 1);
                    new_labels(idx == 1) = best_split_idx;
                    new_labels(idx == 2) = length(clusters) + 1;
                    cluster_labels(orig_idx) = new_labels;
                    
                    % 替换原聚类并添加新聚类
                    clusters{best_split_idx} = cluster1;
                    clusters{end+1} = cluster2;
                end
            end
            
            % 转换为连续的标签
            unique_labels = unique(cluster_labels);
            for i = 1:length(unique_labels)
                labels(cluster_labels == unique_labels(i)) = i;
            end
            
            % 计算聚类中心
            centers = zeros(k, size(data, 2));
            for i = 1:k
                centers(i, :) = mean(data(labels == i, :));
            end
            
        case 'dbscan'
            % DBSCAN密度聚类
            % 使用Statistics and Machine Learning Toolbox中的函数
            if exist('dbscan', 'file')
                [labels, ~] = dbscan(data, eps,  minPts);
                % 转换为从0开始的标签（-1表示噪声点）
                labels = labels + 1;
            else
                % 如果没有dbscan函数，使用简化实现
                disp('警告：未找到dbscan函数，使用简化实现');
                labels = dbscan_simple(data, eps, minPts);
            end
            
        case 'optics'
            % OPTICS密度聚类
            if exist('optics', 'file')
                [order, reachdist, coredist] = optics(data, eps, 'MinPts', minPts);
                labels = extractDBSCAN(order, reachdist, coredist, xi);
                % 转换为从0开始的标签（-1表示噪声点）
                labels = labels + 1;
            else
                disp('警告：未找到optics函数，使用DBSCAN替代');
                [labels, ~] = dbscan(data, eps, 'MinPts', minPts);
                labels = labels + 1;
            end
            
        case 'agglomerative'
            % 层次聚类
            Y = pdist(data);
            Z = linkage(Y, linkage);
            labels = cluster(Z, 'MaxClust', k);
            
            % 计算聚类中心
            centers = zeros(k, size(data, 2));
            for i = 1:k
                centers(i, :) = mean(data(labels == i, :));
            end
            
        otherwise
            error('不支持的聚类方法: %s', method);
    end
end

