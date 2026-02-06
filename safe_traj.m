function traj = safe_traj(out, Tlen)
% 稳健提取 0..T 的失供轨迹；失败则全 NaN
traj = NaN(1, Tlen);
if ~isstruct(out) || ~isfield(out,'steps') || isempty(out.steps), return; end
try
    lost = arrayfun(@(k) out.steps(k).lostLoadFrac, 1:numel(out.steps));
    x = [0, lost];                    % t=0 置 0（可改成 lost(1) 也行）
    if numel(x) >= Tlen
        traj = x(1:Tlen);
    else
        traj = [x, repmat(x(end), 1, Tlen - numel(x))];
    end
catch
    % keep NaN
end
end