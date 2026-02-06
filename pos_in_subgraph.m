function idxInSub = pos_in_subgraph(aliveNodesIdx, idxOrig)
% 把“原图节点索引”映射成“子图中的节点索引”
pos = zeros(max(aliveNodesIdx),1);
pos(aliveNodesIdx) = 1:numel(aliveNodesIdx);
idxInSub = pos(idxOrig);
idxInSub = idxInSub(idxInSub>0);
end