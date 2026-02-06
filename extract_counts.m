function C = extract_counts(out)
% 从仿真结果中提取初始/最终失效规模（节点/线路）
C = struct('n_init_nodes',0,'n_final_nodes',0,'n_init_edges',0,'n_final_edges',0);

% 末步
last = out.steps(end);
C.n_final_nodes = sum(~last.nodeAlive);
C.n_final_edges = sum(~last.edgeAlive);

% 初始（fail_step==1 视为 t=0 初损）
if isfield(out,'failed_nodes') && ~isempty(out.failed_nodes)
    fs = out.failed_nodes.fail_step; C.n_init_nodes = sum(fs==1);
else
    fs = out.node_first_fail_step;   C.n_init_nodes = sum(fs==1);
end
if isfield(out,'failed_edges') && ~isempty(out.failed_edges)
    fe = out.failed_edges.fail_step; C.n_init_edges = sum(fe==1);
else
    fe = out.edge_first_fail_step;   C.n_init_edges = sum(fe==1);
end
end