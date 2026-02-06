function [Gt, aliveEdgeMask, aliveNodesIdx] = alive_subgraph(G0, nodeAlive, edgeAlive)
% 仅保留存活节点与两端均存活的边；节点重新编号为 1..na
u0 = G0.Edges.EndNodes(:,1); v0 = G0.Edges.EndNodes(:,2);
aliveEdgeMask = edgeAlive & nodeAlive(u0) & nodeAlive(v0);
aliveNodesIdx = find(nodeAlive);
pos = zeros(numnodes(G0),1); pos(aliveNodesIdx) = 1:numel(aliveNodesIdx);
uu = pos(u0(aliveEdgeMask)); vv = pos(v0(aliveEdgeMask));
Gt = graph(uu, vv, [], numel(aliveNodesIdx));
end