function v = safe_final_loss(out)
% 取最终失供；若无数据返回 NaN
if isempty(out) || ~isfield(out,'steps') || isempty(out.steps)
    v = NaN; return;
end
v = out.steps(end).lostLoadFrac;
end