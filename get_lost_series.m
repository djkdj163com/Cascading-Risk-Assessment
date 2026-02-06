function s = get_lost_series(out)
% 从 out.steps 提取失供时间序列；前置 t=0 置 0
if isempty(out) || ~isfield(out,'steps') || isempty(out.steps)
    s = 0; return;
end
lost = arrayfun(@(k) out.steps(k).lostLoadFrac, 1:numel(out.steps));
s = [0, lost(:)'];   % t=0 置 0（便于对齐 0..T）
end
