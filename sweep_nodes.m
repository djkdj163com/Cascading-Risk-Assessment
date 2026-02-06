%% ================== 辅助函数 ==================
function S = sweep_nodes(node_csv, edge_csv, BASE, pname, grid)
x = grid(:)'; nX = numel(x);
n_init = zeros(1,nX); n_casc = zeros(1,nX); n_final = zeros(1,nX);
for i = 1:nX
    args = overrideKV(BASE, pname, x(i));
    out  = simulate_dynamic_cascade_final(node_csv, edge_csv, args{:});
    last = out.steps(end);                   % 最终失效节点数
    n_final(i) = sum(~last.nodeAlive);
    if isfield(out,'failed_nodes') && ~isempty(out.failed_nodes)
        fs = out.failed_nodes.fail_step;     % 初始：t=0 视为 fail_step==1
    else
        fs = out.node_first_fail_step;
    end
    n_init(i) = sum(fs==1);
    n_casc(i) = max(0, n_final(i)-n_init(i));
end
S = struct('x',x,'n_init',n_init,'n_casc',n_casc,'n_final',n_final);
end