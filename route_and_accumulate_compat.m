function [L_edge, L_node] = route_and_accumulate_compat(G, srcSub, loadSub, wLoad, edgeCost)
% 最短路回退：每个负荷 -> 最近源；沿路累加边流量
% 兼容旧版 MATLAB：不再给 distances/shortestpath 传 'Weights' / 'Method'
m = numedges(G); n = numnodes(G);
L_edge = zeros(m,1); 
L_node = zeros(n,1);
if isempty(srcSub) || isempty(loadSub) || m==0
    return;
end

% 把权重写进图的 Edges.Weight（旧版 distances/shortestpath 会自动使用）
Gw = G;
Gw.Edges.Weight = edgeCost(:);

% 负荷权重
if isempty(wLoad), wLoad = ones(numel(loadSub),1); end
wLoad = wLoad(:);
s = sum(wLoad); 
if s<=0, wLoad = ones(numel(loadSub),1)/numel(loadSub); else, wLoad = wLoad/s; end

for k = 1:numel(loadSub)
    ld = loadSub(k);

    % —— 关键修改：不带 Name-Value —— 
    % 旧版 distances 会自动使用 Gw.Edges.Weight
    d = distances(Gw, ld, srcSub);

    % 选择最近源
    [dmin, idxMin] = min(d);
    if isinf(dmin), continue; end
    src = srcSub(idxMin);

    % —— 同样不带 Name-Value —— 
    [path, ~] = shortestpath(Gw, ld, src);

    % 沿路径累计
    if numel(path) >= 2
        E = findedge(G, path(1:end-1), path(2:end));
        L_edge(E) = L_edge(E) + wLoad(k);
        L_node(path) = L_node(path) + wLoad(k)/numel(path);
    end
end
end
