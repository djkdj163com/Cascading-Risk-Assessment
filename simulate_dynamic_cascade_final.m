function out = simulate_dynamic_cascade_final(node_csv, edge_csv, varargin)
% 电压分层感知的动态级联（DC/PTDF + 容量校准 + 确定性初损 + 双回路 + 同站耦合）
%
% 必要字段：
%   nodes: node_id, DYDJ, H80, DS, tower_prob, （建议有 x(经度), y(纬度), Name）
%   edges: from_id, to_id, Interval_distance, （line_prob 或 System_Failure_Prob 至少一个）
%
% 关键“控制旋钮”（Name-Value，可在主脚本里按需覆盖）：
%   FlowModel('dc'|'shortest')     — 潮流重分配模型（默认 'dc'）
%   SourceMinKV (默认 220)         — ≥该电压(含10000)并入源集合（现实 220→110 常供电）
%   TripMargin  (默认 1.10)        — 跳闸裕度：F/Ce>TripMargin 才视为过载
%   RandomTrip  (默认 false)       — 是否允许非过载的随机跳闸（建议 false）
%
%   DeterministicNodes(true), NodeFailThresh(0.3/0.4)   — 节点初损确定性阈值
%   DeterministicEdges(false), EdgeFailThresh(0.3)      — 线路初损确定性阈值
%
%   CapCalibK(2.5~4), CapFloorFrac(0.30~0.50)           — DC基准潮流→容量的放大与地板
%   GammaWind(0.5~1.1), LenEta(~0.2)                    — 风致降额与线长修正
%
%   DoubleCircuit(true)                                  — 物理线展开为双回路并联
%   UseStationCouplers(true), StationTol(80~150 m)       — 同站母线汇接+跨压耦合
%   StationCapMult(12~20), MaxCoupleEachLow(2~3)         — 站内边容量放大与耦合度
%
%   ReduceThreshold(0.02~0.08), DemandCut(0.02~0.10)     — 多步小幅减载策略

%% 0) 解析参数
p = inputParser;
p.addParameter('Seed', 2025);
p.addParameter('MaxSteps', 20);
p.addParameter('Beta', 4);
p.addParameter('GammaWind', 1.0);
p.addParameter('LenEta', 0.2);
p.addParameter('wRef', []);
p.addParameter('ReduceThreshold', 0.05);
p.addParameter('DemandCut', 0.2);
p.addParameter('Verbose', true);
p.addParameter('FisheryWeight', []);
p.addParameter('FlowModel', 'dc');
% ★ 失效清单导出（可选）
p.addParameter('ExportFailedCSV', false);
p.addParameter('FailedNodeCSV', 'failed_nodes.csv');
p.addParameter('FailedEdgeCSV', 'failed_edges.csv');

% ★ 新增：供电/跳闸控制
p.addParameter('SourceMinKV', 220);    % ≥该电压（含10000）算源
p.addParameter('TripMargin', 1.10);    % 跳闸裕度（>110% 才跳）
p.addParameter('RandomTrip', false);   % 禁用非过载的随机跳闸

% 初损确定性
p.addParameter('DeterministicNodes', true);
p.addParameter('DeterministicEdges', false);
p.addParameter('NodeFailThresh', 0.3);
p.addParameter('EdgeFailThresh', 0.3);

% 容量校准
p.addParameter('CapCalibK', 2.5);
p.addParameter('CapFloorFrac', 0.30);

% 双回路
p.addParameter('DoubleCircuit', true);

% 同站耦合
p.addParameter('UseStationCouplers', true);
p.addParameter('StationKey', 'Name');
p.addParameter('StationTol', 80);
p.addParameter('StationCapMult', 12);
p.addParameter('MaxCoupleEachLow', 2);

p.parse(varargin{:});
S = p.Results;
rng(S.Seed);

%% 1) 读表与字段检查
nodes = readtable(node_csv);
edges = readtable(edge_csv);

needN = {'node_id','DYDJ','H80','DS','tower_prob'};
needE = {'from_id','to_id','Interval_distance'};
assert(all(ismember(needN, nodes.Properties.VariableNames)), ...
    'nodes 缺少必要字段（至少需 node_id,DYDJ,H80,DS,tower_prob）');
assert(all(ismember(needE, edges.Properties.VariableNames)), ...
    'edges 缺少必要字段（至少需 from_id,to_id,Interval_distance）');

has_line = ismember('line_prob', edges.Properties.VariableNames);
has_sys  = ismember('System_Failure_Prob', edges.Properties.VariableNames);

nodes.node_id = string(nodes.node_id);
edges.from_id = string(edges.from_id);
edges.to_id   = string(edges.to_id);
node_keys = cellstr(nodes.node_id);
from_keys = cellstr(edges.from_id);
to_keys   = cellstr(edges.to_id);

if iscell(nodes.DYDJ) || isstring(nodes.DYDJ), nodes.DYDJ = str2double(string(nodes.DYDJ)); end
nodes.DYDJ = double(nodes.DYDJ);

% === 新增：确保 x/y 存在且为数值 ===
if ~ismember('x', nodes.Properties.VariableNames), nodes.x = nan(height(nodes),1); end
if ~ismember('y', nodes.Properties.VariableNames), nodes.y = nan(height(nodes),1); end
if iscell(nodes.x) || isstring(nodes.x), nodes.x = str2double(string(nodes.x)); end
if iscell(nodes.y) || isstring(nodes.y), nodes.y = str2double(string(nodes.y)); end
nodes.x = double(nodes.x);
nodes.y = double(nodes.y);

[uniq_node_keys, ~] = unique(node_keys, 'stable');
id2idx = containers.Map(uniq_node_keys, num2cell(1:numel(uniq_node_keys)));
valid = isKey(id2idx, from_keys) & isKey(id2idx, to_keys);
edges = edges(valid,:); from_keys = from_keys(valid); to_keys = to_keys(valid);

u0 = cellfun(@(k) id2idx(k), from_keys);
v0 = cellfun(@(k) id2idx(k), to_keys);
L0 = double(edges.Interval_distance(:));
p_corr = nan(numel(L0),1);
if has_line, p_corr = double(edges.line_prob(:)); end
if any(isnan(p_corr)) || ~has_line
    if has_sys
        tmp = double(edges.System_Failure_Prob(:));
        nan_mask = isnan(p_corr);
        p_corr(nan_mask) = tmp(nan_mask);
    end
end
p_corr = clamp01(p_corr);

n = numel(uniq_node_keys);

%% 2) 双回路并联展开（可关）
if S.DoubleCircuit
    C = 2;
    p_circ = 1 - (1 - p_corr).^(1/C);   % 两回都失效的概率 = 原走廊概率
    u = repelem(u0, C);
    v = repelem(v0, C);
    L = repelem(L0, C);
    pline = repelem(p_circ, C);
else
    u = u0; v = v0; L = L0; pline = p_corr;
end

%% 3) （可选）同站内耦合 + 母线汇接（仅站内）
isStationEdgeFlag = false(numel(u),1);
if S.UseStationCouplers
    opt = struct('StationKey', S.StationKey, ...
                 'TolTight', S.StationTol, ...
                 'UseBusbar', true, ...
                 'MaxCoupleEachLow', S.MaxCoupleEachLow, ...
                 'AllowedPairs', [10000 500; 500 220; 220 110], ...
                 'StationEdgeLen', 1, ...
                 'StationEdgeProb', 0);
    [u, v, L, pline, isStationEdgeFlag] = add_station_couplers(nodes, u, v, L, pline, opt);
end

%% 4) 建图并对齐属性到边序
G0 = graph(u, v, [], n);
m  = numedges(G0);
ends = G0.Edges.EndNodes;

Lmat = sparse(u, v, L, n, n); Lmat = max(Lmat, Lmat');     % 无向
Pmat = sparse(u, v, pline, n, n); Pmat = max(Pmat, Pmat');

L = full(Lmat(sub2ind([n,n], ends(:,1), ends(:,2))));
pline = clamp01(full(Pmat(sub2ind([n,n], ends(:,1), ends(:,2)))));

%% 5) 电压、成本、源-荷集合
voltEdge = derive_edge_voltage(nodes.DYDJ, G0.Edges.EndNodes);        % 10000→500 处理
edgeCost = edge_cost_by_volt_and_length(voltEdge, L);

% 基本源/荷初选
srcTmp  = find( (nodes.DYDJ==10000) | (nodes.DYDJ>=500) );
loadTmp = find( nodes.DYDJ<=110 );
if isempty(srcTmp),  srcTmp  = find(nodes.DYDJ >= max(nodes.DYDJ(nodes.DYDJ<10000))); end
if isempty(loadTmp)
    finiteV = nodes.DYDJ(nodes.DYDJ>0 & nodes.DYDJ<10000);
    if ~isempty(finiteV), loadTmp = find(nodes.DYDJ == min(finiteV)); else, loadTmp = setdiff((1:n)', srcTmp); end
end
wLoad0 = ones(numel(loadTmp),1); wLoad0 = wLoad0 / sum(wLoad0);

%% 6) DC 基准潮流 → 容量校准
DS  = double(nodes.DS(:));
H80 = double(nodes.H80(:));
% 参考风速：DS 的 95分位常数，更稳
if isempty(S.wRef), wRef_const = prctile(DS,95); else, wRef_const = S.wRef; end

F0_edge = dc_flow_proxy(G0, srcTmp, loadTmp, wLoad0, voltEdge, L); % 全网完好

F0_pos   = F0_edge(F0_edge>0);
medF0    = iff(isempty(F0_pos), 1, median(F0_pos));
cap_floor= S.CapFloorFrac * medF0;

phi_len  = (1 + S.LenEta) ./ (1 + S.LenEta*(L./max(prctile(L,95),1e-3)));
wEdge    = max(H80(ends(:,1)), H80(ends(:,2)));
psi_wind = exp( -S.GammaWind .* max(0, wEdge./max(wRef_const,1e-6) - 1) );
alpha_v  = alpha_by_voltage(voltEdge);

capacityEdge = S.CapCalibK .* max(F0_edge, cap_floor) .* phi_len .* psi_wind .* (1 + alpha_v);
capacityEdge = max(capacityEdge, 1e-6);

% 站内耦合边：容量放大（避免瓶颈）
if any(isStationEdgeFlag)
    nG = numnodes(G0);
    Bflag = sparse(u, v, double(isStationEdgeFlag), nG, nG); Bflag = max(Bflag, Bflag');
    idxEdges      = sub2ind([nG,nG], ends(:,1), ends(:,2));
    isStationOnG0 = full(Bflag(idxEdges)) > 0;         % 逻辑掩码
    if numel(isStationOnG0) ~= numel(capacityEdge)
        tmp = false(numel(capacityEdge),1);
        tmp(1:min(end,numel(isStationOnG0))) = isStationOnG0(1:min(end,numel(isStationOnG0)));
        isStationOnG0 = tmp;
    end
    capacityEdge(isStationOnG0) = capacityEdge(isStationOnG0) * S.StationCapMult;
end

%% 7) 源-荷权重（带渔业权重）；强制把 ≥ SourceMinKV 并入源
[sourceIdx0, loadIdx, wLoad] = build_source_load_weights(nodes, S.FisheryWeight);
DY = double(nodes.DYDJ(:));
srcForce = find( (DY==10000) | (DY>=S.SourceMinKV) );
sourceIdx = union(sourceIdx0(:), srcForce(:));

%% 8) 动态级联
edgeAlive = true(m,1);
nodeAlive = true(n,1);

% t=0 初始破坏（确定性/随机）
ptower = clamp01(nodes.tower_prob(:));
if S.DeterministicNodes
    tp = double(ptower); tp(~isfinite(tp)) = 0;
    nodeAlive = nodeAlive & ~(tp >= S.NodeFailThresh);
else
    nodeAlive = nodeAlive & (rand(n,1) > ptower);
end
if S.DeterministicEdges
    lp = double(pline); lp(~isfinite(lp)) = 0;
    edgeAlive = edgeAlive & ~(lp >= S.EdgeFailThresh);
else
    edgeAlive = edgeAlive & (rand(m,1) > pline);
end

% 预分配 steps
t = 0;
stepsTemplate = save_step(0, true(n,1), true(m,1), 0,0,0, 0,1, []);
steps  = repmat(stepsTemplate, S.MaxSteps, 1);
filled = false(S.MaxSteps,1);

if S.Verbose
    fprintf('[t=%02d] 初始：存活节点 %d/%d，存活边(回路) %d/%d\n', t, sum(nodeAlive), n, sum(edgeAlive), m);
end

while t < S.MaxSteps
    t = t + 1;

    [Gt, aliveEdgeMask, aliveNodesIdx] = alive_subgraph(G0, nodeAlive, edgeAlive);
    if numnodes(Gt)==0 || numedges(Gt)==0
        if S.Verbose, fprintf('[t=%02d] 网络已崩溃。\n', t); end
        s = save_step(t, nodeAlive, edgeAlive, 0,0,0, 1,0, []); s.note = 'empty';
        steps(t) = s; filled(t) = true; break;
    end

    cap_t   = capacityEdge(aliveEdgeMask);
    cost_t  = edgeCost(aliveEdgeMask);
    volt_t  = voltEdge(aliveEdgeMask);
    L_t     = L(aliveEdgeMask);

    srcAlive  = intersect(aliveNodesIdx, sourceIdx);
    loadAlive = intersect(aliveNodesIdx, loadIdx);

    if isempty(srcAlive)
        s = save_step(t, nodeAlive, edgeAlive, 0,0,0, 1,0, []); s.note = 'no_source';
        steps(t) = s; filled(t) = true;
        if S.Verbose, fprintf('[t=%02d] 源全失，全部停电。\n', t); end
        break;
    end
    if isempty(loadAlive)
        s = save_step(t, nodeAlive, edgeAlive, 0,0,0, 0,1, []); s.note = 'no_load';
        steps(t) = s; filled(t) = true;
        if S.Verbose, fprintf('[t=%02d] 无负荷，结束。\n', t); end
        break;
    end

    srcSub  = pos_in_subgraph(aliveNodesIdx, srcAlive);
    loadSub = pos_in_subgraph(aliveNodesIdx, loadAlive);

    wLoadSub = wLoad(ismember(loadIdx, loadAlive));
    if sum(wLoadSub)>0, wLoadSub = wLoadSub / sum(wLoadSub); end

    % 孤岛判定（不含源的分量 → 失供）
    comps = conncomp(Gt);
    compHasSource = false(1, max(comps));
    for c = 1:max(comps), compHasSource(c) = any(ismember(find(comps==c), srcSub)); end
    servedMask = compHasSource(comps(loadSub));
    lostLoadFrac   = sum(wLoadSub(~servedMask));
    servedLoadFrac = 1 - lostLoadFrac;

    % 流量重分配
    L_edge_t = zeros(numedges(Gt),1);
    if any(servedMask)
        if strcmpi(S.FlowModel,'dc')
            loadSub_served = loadSub(servedMask);
            wLoad_served   = wLoadSub(servedMask);
            L_edge_t = dc_flow_proxy(Gt, srcSub, loadSub_served, wLoad_served, volt_t, L_t);
        else
            [L_edge_t, ~] = route_and_accumulate_compat(Gt, srcSub, loadSub(servedMask), wLoadSub(servedMask), cost_t);
        end
    end

    % --- 过载/跳闸（加入裕度；默认禁用随机） ---
    F  = L_edge_t;
    Ce = cap_t + 1e-9;
    margin   = F ./ Ce;
    overload = margin > S.TripMargin;

    if S.RandomTrip
        probTrip = zeros(numedges(Gt),1);
        idx = find(overload);
        probTrip(idx) = 1 - exp(-(margin(idx)).^S.Beta);
        randTrip = (rand(numedges(Gt),1) < probTrip);
    else
        randTrip = false(numedges(Gt),1);
    end

    toTripAliveEdges = overload | randTrip;

    % 回写到全图边状态
    newEdgeAlive = edgeAlive;
    aliveEdgeIdxs = find(aliveEdgeMask);
    newEdgeAlive(aliveEdgeIdxs(toTripAliveEdges)) = false;

    % 孤立节点 → 失效
    newNodeAlive = nodeAlive;
    Gtmp = graph(G0.Edges.EndNodes(:,1), G0.Edges.EndNodes(:,2));
    Gtmp = rmedge(Gtmp, find(~newEdgeAlive));
    degs = degree(Gtmp);
    newNodeAlive(degs==0) = false;

    % 减载（多步小幅）
    cutApplied = false;
    fracOverloaded = mean(toTripAliveEdges);
    if fracOverloaded > S.ReduceThreshold
        wLoad = (1 - S.DemandCut) * wLoad;
        wLoad = wLoad / max(sum(wLoad),1e-12);
        cutApplied = true;
    end

    % 记录
    changedEdges = xor(edgeAlive, newEdgeAlive);
    changedNodes = xor(nodeAlive, newNodeAlive);
    steps(t) = save_step(t, newNodeAlive, newEdgeAlive, ...
        mean(overload), mean(randTrip), fracOverloaded, ...
        lostLoadFrac, servedLoadFrac, find(changedEdges));
    filled(t) = true;

    if S.Verbose
        fprintf('[t=%02d] 存活节点 %d/%d, 存活回路 %d/%d | 失供 %.1f%% | 过载 %.1f%%%s\n', ...
            t, sum(newNodeAlive), n, sum(newEdgeAlive), m, ...
            100*lostLoadFrac, 100*fracOverloaded, ternary(cutApplied,' | 减载',''));
    end

    edgeAlive = newEdgeAlive;
    nodeAlive = newNodeAlive;

    if ~any(changedEdges) && ~any(changedNodes)
        if S.Verbose, fprintf('[t=%02d] 收敛。\n', t); end
        break;
    end
end

%% 输出
out = struct();
out.G0 = G0;
out.steps = steps(filled);
out.params = S;
out.capacityEdge = capacityEdge;
out.baseFlowEdge = F0_edge;
out.sourceIdx = sourceIdx;
out.loadIdx = loadIdx;
out.nodeTable = nodes;
out.edgeTable = edges;

% 小图（可关）
% try
%     mOut = numedges(G0);
%     lost = arrayfun(@(k) out.steps(k).lostLoadFrac, 1:numel(out.steps));
%     aliveE = arrayfun(@(k) sum(out.steps(k).edgeAlive)/mOut, 1:numel(out.steps));
%     figure('Color','w');
%     subplot(2,1,1); plot(0:numel(lost)-1, lost, 'LineWidth',1.8); grid on;
%     xlabel('步数'); ylabel('失供负荷比例'); title('动态级联：失供演化');
%     subplot(2,1,2); plot(0:numel(aliveE)-1, aliveE, 'LineWidth',1.8); grid on;
%     xlabel('步数'); ylabel('存活边比例'); title('动态级联：边存活');
% catch
% end

% === 失效汇总：把失效的节点与线路都输出出来（含首次失效步） ===
T = numel(out.steps);
m = numedges(G0);

nodeAliveHist = false(n, T);
edgeAliveHist = false(m, T);
for k = 1:T
    nodeAliveHist(:,k) = out.steps(k).nodeAlive(:);
    edgeAliveHist(:,k) = out.steps(k).edgeAlive(:);
end

nodeFirstFail = nan(n,1);
for i = 1:n
    ti = find(~nodeAliveHist(i,:), 1, 'first');
    if ~isempty(ti), nodeFirstFail(i) = ti; end
end
edgeFirstFail = nan(m,1);
for e = 1:m
    te = find(~edgeAliveHist(e,:), 1, 'first');
    if ~isempty(te), edgeFirstFail(e) = te; end
end

nodeFailedMask = ~nodeAliveHist(:,end);
edgeFailedMask = ~edgeAliveHist(:,end);

% ★ 节点失效表：包含 x, y
failedNodesTbl = table( ...
    nodes.node_id(nodeFailedMask), ...
    nodes.DYDJ(nodeFailedMask), ...
    nodes.x(nodeFailedMask), ...
    nodes.y(nodeFailedMask), ...
    nodeFirstFail(nodeFailedMask), ...
    'VariableNames', {'node_id','DYDJ','x','y','fail_step'} );

% 线路端点（对应 G0 的边顺序）
ends = out.G0.Edges.EndNodes;
from_id = nodes.node_id(ends(:,1));
to_id   = nodes.node_id(ends(:,2));

% 线路端点坐标
from_x = nodes.x(ends(:,1));
from_y = nodes.y(ends(:,1));
to_x   = nodes.x(ends(:,2));
to_y   = nodes.y(ends(:,2));

isStationOnG0 = false(m,1);
if exist('isStationEdgeFlag','var') && any(isStationEdgeFlag)
    nG = numnodes(out.G0);
    Bflag = sparse(u, v, double(isStationEdgeFlag), nG, nG); Bflag = max(Bflag, Bflag');
    idxEdges = sub2ind([nG,nG], ends(:,1), ends(:,2));
    tmp = full(Bflag(idxEdges)) > 0;
    isStationOnG0(1:numel(tmp)) = tmp;
end

% ★ 线路失效表：包含起止点 x, y
failedEdgesTbl = table( ...
    from_id(edgeFailedMask), ...
    to_id(edgeFailedMask), ...
    from_x(edgeFailedMask), ...
    from_y(edgeFailedMask), ...
    to_x(edgeFailedMask), ...
    to_y(edgeFailedMask), ...
    voltEdge(edgeFailedMask), ...
    L(edgeFailedMask), ...
    isStationOnG0(edgeFailedMask), ...
    edgeFirstFail(edgeFailedMask), ...
    'VariableNames', {'from_id','to_id','from_x','from_y','to_x','to_y','volt_class','length','is_station','fail_step'} );

out.failed_nodes = failedNodesTbl;
out.failed_edges = failedEdgesTbl;
out.node_first_fail_step = nodeFirstFail;
out.edge_first_fail_step = edgeFirstFail;

if S.Verbose
    fprintf('=== 失效汇总 ===\n失效节点：%d 个；失效线路：%d 条。\n', ...
        height(out.failed_nodes), height(out.failed_edges));
end

if isfield(S,'ExportFailedCSV') && S.ExportFailedCSV
    nodeCsvOut = 'failed_nodes.csv'; if isfield(S,'FailedNodeCSV'), nodeCsvOut = S.FailedNodeCSV; end
    edgeCsvOut = 'failed_edges.csv'; if isfield(S,'FailedEdgeCSV'), edgeCsvOut = S.FailedEdgeCSV; end
    try
        % 建议指定编码，避免 Excel 乱码/错位
        writetable(out.failed_nodes, nodeCsvOut, 'FileType','text', 'Encoding','UTF-8');
        writetable(out.failed_edges, edgeCsvOut, 'FileType','text', 'Encoding','UTF-8');
        if S.Verbose, fprintf('已导出：%s, %s\n', nodeCsvOut, edgeCsvOut); end
    catch ME
        warning('导出失败：%s', ME.message);
    end
end

end
