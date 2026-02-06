%% ============================================================
%  4.2 拓扑稳健性对比（真实 vs ER/BA/保序/地理随机）
%  依赖：simulate_dynamic_cascade_final.m（保持不变）
%  输出：fig_42/Fig42A_threshold_compare.(png|pdf)
%  口径：初损 = sum(tower_prob >= 阈值)（与拓扑无关，整图共享一条曲线）
%        “final” = 级联后的最终总失效数（≥ 初损）
%% ============================================================

clear; clc; close all;

%% ---------- I/O 与基线参数 ----------
node_csv = 'tower_failure_probabilities.csv';
edge_csv = 'system_failure_probabilities.csv';

outdir = 'fig_42';
if ~exist(outdir,'dir'), mkdir(outdir); end

BASE = { ...
  'FlowModel','dc', 'Seed',2025, 'MaxSteps',60, ...
  'Beta',6, 'TripMargin',1.15, 'RandomTrip',false, ...
  'GammaWind',1.0, 'LenEta',0.2, ...
  'ReduceThreshold',0.06, 'DemandCut',0.03, ...
  'DeterministicNodes',true, 'NodeFailThresh',0.20, ...
  'DeterministicEdges',true, 'EdgeFailThresh',0.10, ...
  'CapCalibK',2.4, 'CapFloorFrac',0.40, ...
  'DoubleCircuit',true, 'UseStationCouplers',true, ...
  'StationTol',60, 'StationCapMult',10, 'MaxCoupleEachLow',1, ...
  'SourceMinKV',500, 'Verbose',false };

% 画图风格
set(groot,'defaultAxesFontName','Times New Roman');
set(groot,'defaultTextFontName','Times New Roman');
set(groot,'defaultAxesFontSize',9);
set(groot,'defaultTextFontSize',9);

% 颜色（模型 → 颜色）
c_real = [0.10 0.10 0.10];   % Real
c_er   = [0.23 0.49 0.77];   % ER
c_ba   = [0.85 0.33 0.10];   % BA
c_cfg  = [0.47 0.67 0.19];   % Degree-preserving
c_geo  = [0.55 0.27 0.68];   % Geo-shuffle

%% ---------- 读取真实数据，并构造参考网络 ----------
nodes = readtable(node_csv);
edges = readtable(edge_csv);

nodes.node_id = string(nodes.node_id);
if ~ismember('x',nodes.Properties.VariableNames), nodes.x = nan(height(nodes),1); end
if ~ismember('y',nodes.Properties.VariableNames), nodes.y = nan(height(nodes),1); end
if iscell(nodes.x) || isstring(nodes.x), nodes.x = str2double(string(nodes.x)); end
if iscell(nodes.y) || isstring(nodes.y), nodes.y = str2double(string(nodes.y)); end
nodes.x = double(nodes.x); nodes.y = double(nodes.y);

% 去重无向边
u = string(edges.from_id); v = string(edges.to_id);
uv = sort([u v],2);
[uv_uniq, ~] = unique(uv,'rows','stable');
u = uv_uniq(:,1); v = uv_uniq(:,2);

N = height(nodes);
E = size(uv_uniq,1);

% ER: G(n,m)
er_u = strings(E,1); er_v = strings(E,1);
rng(1); cnt=0;
have = containers.Map('KeyType','char','ValueType','logical');
while cnt<E
    a = nodes.node_id(randi(N)); b = nodes.node_id(randi(N));
    if a==b, continue; end
    if a>b, tmp=a; a=b; b=tmp; end
    key = char(a+"|"+b);
    if ~isKey(have,key)
        cnt=cnt+1; er_u(cnt)=a; er_v(cnt)=b; have(key)=true;
    end
end

% BA: 近似同 E
m0 = 3; m = max(1, round(E/N));
ba_u = strings(0,1); ba_v = strings(0,1);
deg = zeros(N,1); id = nodes.node_id;
for i=1:m0
    for j=i+1:m0
        ba_u(end+1,1)=id(i); ba_v(end+1,1)=id(j);
        deg(i)=deg(i)+1; deg(j)=deg(j)+1;
    end
end
ptr = m0+1;
while numel(ba_u)<E && ptr<=N
    targets = randsample(1:ptr-1, m, true, max(deg(1:ptr-1),eps));
    for t = targets
        a=id(ptr); b=id(t); if a>b, tmp=a; a=b; b=tmp; end
        key = a+"|"+b;
        if ~any(string(ba_u)+"|"+string(ba_v) == key)
            ba_u(end+1,1)=a; ba_v(end+1,1)=b;
            deg(ptr)=deg(ptr)+1; deg(t)=deg(t)+1;
            if numel(ba_u)>=E, break; end
        end
    end
    ptr=ptr+1;
end
while numel(ba_u)<E
    a = id(randi(N)); b = id(randi(N)); if a==b, continue; end
    if a>b, tmp=a; a=b; b=tmp; end
    key = a+"|"+b;
    if ~any(string(ba_u)+"|"+string(ba_v) == key)
        ba_u(end+1,1)=a; ba_v(end+1,1)=b;
    end
end

% 保序交换
cfg_u = u; cfg_v = v;
rng(2); numSwap = 5*E;
for s=1:numSwap
    i=randi(E); j=randi(E); if i==j, continue; end
    a1=cfg_u(i); b1=cfg_v(i); a2=cfg_u(j); b2=cfg_v(j);
    if a1==b2 || a2==b1, continue; end
    c1 = sort([a1 b2]); c2 = sort([a2 b1]);
    pair1 = c1(1)+"|"+c1(2); pair2 = c2(1)+"|"+c2(2);
    cur = string(cfg_u)+"|"+string(cfg_v);
    if ~any(cur==pair1) && ~any(cur==pair2)
        cfg_u(i)=c1(1); cfg_v(i)=c1(2);
        cfg_u(j)=c2(1); cfg_v(j)=c2(2);
    end
end

% 地理随机：只打散坐标
geo_nodes = nodes;
perm = randperm(N);
geo_nodes.x = nodes.x(perm);
geo_nodes.y = nodes.y(perm);

% edges 构造器
make_edges_tbl = @(UU,VV,NT) table( ...
    UU, VV, ...
    hypot( NT.x(matchIdx(NT.node_id,UU)) - NT.x(matchIdx(NT.node_id,VV)), ...
           NT.y(matchIdx(NT.node_id,UU)) - NT.y(matchIdx(NT.node_id,VV)) ), ...
    0.08*ones(numel(UU),1), ...
    'VariableNames',{'from_id','to_id','Interval_distance','System_Failure_Prob'});

real_nodes = nodes;               real_edges = make_edges_tbl(u,v,nodes);
er_nodes   = nodes;               er_edges  = make_edges_tbl(er_u,er_v,nodes);
ba_nodes   = nodes;               ba_edges  = make_edges_tbl(ba_u,ba_v,nodes);
cfg_nodes  = nodes;               cfg_edges = make_edges_tbl(cfg_u,cfg_v,nodes);
geo_edges  = make_edges_tbl(u,v,geo_nodes);

%% ---------- 图A：阈值—稳态（初损共享，比较最终总失效） ----------
X = [0.10 0.20 0.30 0.40 0.50];
models = {'Real','ER','BA','Degree-preserving','Geo-shuffle'};
COL = {c_real,c_er,c_ba,c_cfg,c_geo};

% 统一“初损（节点）”——只看同一份 nodes.tower_prob
tp0 = nodes.tower_prob;
if iscell(tp0) || isstring(tp0), tp0 = str2double(string(tp0)); end
tp0(~isfinite(tp0)) = 0;
init_shared = arrayfun(@(thr) sum(tp0 >= thr), X);   % 共享一条

% 结果容器（最终总失效）
finalN = zeros(numel(models), numel(X));

for mi = 1:numel(models)
    switch models{mi}
        case 'Real',             NT=real_nodes; ET=real_edges;
        case 'ER',               NT=er_nodes;   ET=er_edges;
        case 'BA',               NT=ba_nodes;   ET=ba_edges;
        case 'Degree-preserving',NT=cfg_nodes;  ET=cfg_edges;
        case 'Geo-shuffle',      NT=geo_nodes;  ET=geo_edges;
    end
    tmp_node = fullfile(outdir, sprintf('tmp_nodes_%s.csv',models{mi}));
    tmp_edge = fullfile(outdir, sprintf('tmp_edges_%s.csv',models{mi}));
    writetable(NT, tmp_node, 'Encoding','UTF-8');
    writetable(ET, tmp_edge, 'Encoding','UTF-8');

    for k = 1:numel(X)
        args = BASE; args = overrideKV(args,'NodeFailThresh',X(k));
        out  = simulate_dynamic_cascade_final(tmp_node, tmp_edge, args{:});
        finalN(mi,k) = sum(~out.steps(end).nodeAlive);      % 最终（总）失效
        fprintf('[%s] NFT=%.2f | initial=%d, final=%d\n', ...
            models{mi}, X(k), init_shared(k), finalN(mi,k));
    end
end

% 绘图：初损（共享） + 各模型最终（总）失效
figA = figure('Color','w','Units','centimeters','Position',[2 2 16 10]); hold on;

% 初损（共享一条）
p0 = plot(X, init_shared, '-o', ...
          'Color',[0.12 0.12 0.12], 'MarkerFaceColor',[0.12 0.12 0.12], ...
          'LineWidth',1.8, 'MarkerSize',5, 'DisplayName','Initial (shared)');

% 各模型“最终（总）失效”
P = gobjects(numel(models),1);
for mi = 1:numel(models)
    P(mi) = plot(X, finalN(mi,:), '--s', ...
                 'Color',COL{mi}, 'MarkerFaceColor',COL{mi}, ...
                 'LineWidth',1.8, 'MarkerSize',5, ...
                 'DisplayName',[models{mi} ' – final']);
end

xlabel('Failure Probability Threshold');
ylabel('Number of Failed Nodes');
grid on; box on; set(gca,'TickDir','in','LineWidth',0.75,'Layer','top');
legend([p0; P], 'Location','northeastoutside', 'Box','on', 'LineWidth',0.75);

exportgraphics(figA, fullfile(outdir,'Fig42A_threshold_compare.png'), 'Resolution',1200);
exportgraphics(figA, fullfile(outdir,'Fig42A_threshold_compare.pdf'));

disp('完成：4.2 阈值—稳态对比图（初损共享 + 最终总失效）。');
%% ---------- 小世界（WS）网络：生成、仿真并叠加在已有图上 ----------
% 目标：在现有 Fig42A 图上加一条“小世界 – final”曲线
% 设定：k ≈ 2E/N（取偶数并不超过 N-1），重连概率 p=0.10
% 说明：边数与 E 尽量一致；若多则随机下采样，若少则随机补齐

% ----- 1) 生成 WS 小世界边集（无自环、无多重边） -----
p_rewire = 0.10;     % 重连概率（可调：0.05 ~ 0.2 常见）
rng(3);              % 固定随机种子，结果可复现

% 近邻度 k：尽量让边数接近 E
k = round(2*E / N);          % 期望每点度
k = max(2, min(k, N-1));     % [2, N-1] 范围
if mod(k,2)==1, k = k-1; end % 需为偶数
if k < 2, k = 2; end

% 基环格（每点连 k/2 个“右侧”近邻）
sw_i = zeros(N*(k/2),1);
sw_j = zeros(N*(k/2),1);
idx = 0;
for i = 1:N
    for dj = 1:(k/2)
        b = i + dj; if b > N, b = b - N; end
        idx = idx + 1;
        sw_i(idx) = i;
        sw_j(idx) = b;
    end
end

% 构建邻接用于去重与重连
adj = sparse(sw_i, sw_j, true, N, N);
adj = adj | adj.';  % 无向

% WS 重连（仅重连“有向一侧”的边 sw_i->sw_j）
for e = 1:numel(sw_i)
    if rand < p_rewire
        a = sw_i(e);
        b_old = sw_j(e);
        % 先移除旧边
        adj(a,b_old) = false; adj(b_old,a) = false;

        % 选新端点，避免自环/重边
        tries = 0;
        while true
            b = randi(N);
            tries = tries + 1;
            if b ~= a && ~adj(a,b)
                break;
            end
            if tries > 10*N
                % 极端情况下回退到旧边（基本不会触发）
                b = b_old; 
                break;
            end
        end
        sw_j(e) = b;
        adj(a,b) = true; adj(b,a) = true;
    end
end

% 转为“无向唯一”边对
u_idx = min(sw_i, sw_j);
v_idx = max(sw_i, sw_j);
pairs = unique([u_idx, v_idx], 'rows', 'stable');
u_idx = pairs(:,1); v_idx = pairs(:,2);

% 调整边数与真实网络一致（=E）
if size(pairs,1) > E
    pick = randperm(size(pairs,1), E);
    u_idx = u_idx(pick); v_idx = v_idx(pick);
elseif size(pairs,1) < E
    have = containers.Map('KeyType','char','ValueType','logical');
    for t = 1:size(pairs,1)
        have(sprintf('%d|%d', u_idx(t), v_idx(t))) = true;
    end
    while numel(u_idx) < E
        a = randi(N); b = randi(N);
        if a == b, continue; end
        if a > b, tmp=a; a=b; b=tmp; end
        key = sprintf('%d|%d', a, b);
        if ~isKey(have, key)
            u_idx(end+1,1) = a; v_idx(end+1,1) = b;
            have(key) = true;
        end
    end
end

% 映射到节点 ID（与你的表一致）
id = nodes.node_id;
sw_u = id(u_idx); 
sw_v = id(v_idx);

% 组装 edges 表（沿用你的距离与故障列构造方式）
sw_edges = make_edges_tbl(sw_u, sw_v, nodes);

% ----- 2) 跑仿真：同一 X 阈值，得到小世界的最终总失效 -----
finalN_sw = zeros(size(X));
tmp_node = fullfile(outdir, 'tmp_nodes_SmallWorld.csv');
tmp_edge = fullfile(outdir, 'tmp_edges_SmallWorld.csv');
writetable(nodes,   tmp_node, 'Encoding','UTF-8');
writetable(sw_edges,tmp_edge, 'Encoding','UTF-8');

for kx = 1:numel(X)
    args = BASE; 
    args = overrideKV(args, 'NodeFailThresh', X(kx));
    out  = simulate_dynamic_cascade_final(tmp_node, tmp_edge, args{:});
    finalN_sw(kx) = sum(~out.steps(end).nodeAlive);
    fprintf('[Small-world] NFT=%.2f | initial=%d, final=%d\n', ...
        X(kx), init_shared(kx), finalN_sw(kx));
end

% ----- 3) 在现有图 figA 上叠加并更新图例/导出 -----
c_sw = [0.13 0.70 0.67];  % 颜色（青绿），可按需调整

if exist('figA','var') && isgraphics(figA)
    figure(figA); hold on;
else
    % 若 figA 不在当前会话里，重画一次已有内容再叠加
    figA = figure('Color','w','Units','centimeters','Position',[2 2 16 10]); hold on;
    p0 = plot(X, init_shared, '-o', ...
        'Color',[0.12 0.12 0.12], 'MarkerFaceColor',[0.12 0.12 0.12], ...
        'LineWidth',1.8, 'MarkerSize',5, 'DisplayName','Initial (shared)');
    P = gobjects(numel(models),1);
    for mi = 1:numel(models)
        P(mi) = plot(X, finalN(mi,:), '--s', ...
            'Color',COL{mi}, 'MarkerFaceColor',COL{mi}, ...
            'LineWidth',1.8, 'MarkerSize',5, ...
            'DisplayName',[models{mi} ' – final']);
    end
    xlabel('Failure Probability Threshold');
    ylabel('Number of Failed Nodes');
    grid on; box on; set(gca,'TickDir','in','LineWidth',0.75,'Layer','top');
end

p_sw = plot(X, finalN_sw, '--d', ...
    'Color', c_sw, 'MarkerFaceColor', c_sw, ...
    'LineWidth',1.8, 'MarkerSize',5, ...
    'DisplayName','Small-world – final');

% 统一图例（覆盖式重建，确保小世界也被包含）
if exist('p0','var') && exist('P','var') && all(isgraphics(P))
    legend([p0; P; p_sw], 'Location','northeastoutside', 'Box','on', 'LineWidth',0.75);
else
    legend('Location','northeastoutside', 'Box','on', 'LineWidth',0.75);
end

% 另存一份带小世界曲线的输出
exportgraphics(figA, fullfile(outdir,'Fig42A_threshold_compare_sw.png'),  'Resolution',1200);
exportgraphics(figA, fullfile(outdir,'Fig42A_threshold_compare_sw.pdf'));

disp('已在现有图上叠加：Small-world – final（并导出 *_sw.png/pdf）。');

hold on
% —— 在 x=0.20 和 x=0.30 处画竖直虚线（黑色、虚线、略粗，不进图例）——
for xv = [0.20 0.30]
    xline(xv, '--', 'Color', [0.10 0.10 0.10], ...
          'LineWidth', 1.5, 'HandleVisibility','off');
end
