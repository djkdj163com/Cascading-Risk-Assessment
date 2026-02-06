clc; clear; close all;
addpath(fileparts(mfilename('fullpath')));

node_csv = 'D:\博士生数据\3个电压\tower_failure_probabilities.csv';
edge_csv = 'D:\博士生数据\3个电压\system_failure_probabilities.csv';

out = simulate_dynamic_cascade_final(node_csv, edge_csv, ...
    'FlowModel','dc', ...
    'Seed',2025, 'MaxSteps',100, ...
    'Beta',6, ...
    'TripMargin',1.15, ...          % 跳闸更敏感：>115% 才视为过载
    'RandomTrip',false, ...         % 仍关闭纯随机
    'GammaWind',1, ...              % 风致降额更强
    'LenEta',0.2, ...
    'ReduceThreshold',0.06, ...     % 晚一点减载
    'DemandCut',0.03, ...           % 每次小幅减载
    'DeterministicNodes',true,  'NodeFailThresh',0.20, ...  % 塔：≥0.20 判定失效
    'DeterministicEdges',true,  'EdgeFailThresh',0.10, ...  % 线：≥0.10 判定失效
    'CapCalibK',2.4, ...            % 容量放大系数
    'CapFloorFrac',0.4, ...         % 容量地板比例
    'DoubleCircuit',true, ...
    'UseStationCouplers',true, ...
    'StationTol',60, ...            % 同站聚类更“紧”
    'StationCapMult',10, ...        % 站内边容量放大减弱
    'MaxCoupleEachLow',1, ...       % 低压侧只连最近1个高压侧
    'SourceMinKV',500, ...          % 只把≥500 kV(含10000)当源
    'Verbose',true, ...
    ... % === 导出失效清单到 CSV ===
    'ExportFailedCSV',true, ...
    'FailedNodeCSV','failed_nodes.csv', ...
    'FailedEdgeCSV','failed_edges.csv' ...
    );

fprintf('最终失供比例：%.2f%%\n', 100*out.steps(end).lostLoadFrac);
fprintf('最终存活边比例：%.2f%%\n', 100*sum(out.steps(end).edgeAlive)/numedges(out.G0));

% === 失效清单统计与预览 ===
if isfield(out, 'failed_nodes') && isfield(out, 'failed_edges')
    n_failed_nodes = height(out.failed_nodes);
    n_failed_edges = height(out.failed_edges);
    fprintf('失效节点：%d 个；失效线路：%d 条。\n', n_failed_nodes, n_failed_edges);

    % 按首次失效步升序，展示前若干条
    if n_failed_nodes > 0
        fn = sortrows(out.failed_nodes, 'fail_step', 'ascend');
        k = min(10, n_failed_nodes);
        fprintf('\n[节点] 首批失效（前 %d 条）：\n', k);
        % 节点表包含：node_id, DYDJ, x, y, fail_step
        disp(fn(1:k, :));
    end

    if n_failed_edges > 0
        fe = sortrows(out.failed_edges, 'fail_step', 'ascend');
        k = min(10, n_failed_edges);
        fprintf('\n[线路] 首批失效（前 %d 条）：\n', k);
        % 线路表包含：from_id, to_id, from_x, from_y, to_x, to_y, volt_class, length, is_station, fail_step
        disp(fe(1:k, :));
    end

    fprintf('\n失效清单已导出到：%s, %s\n', ...
        out.params.FailedNodeCSV, out.params.FailedEdgeCSV);
else
    warning('当前 simulate_dynamic_cascade_final 未返回失效清单表，请确认已按补丁集成。');
end
