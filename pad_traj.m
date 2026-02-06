function y = pad_traj(x, Tlen)
% 把长度不够的轨迹用最后一个值延长到 Tlen
x = x(:)'; 
if numel(x) >= Tlen, y = x(1:Tlen); return; end
y = [x, repmat(x(end), 1, Tlen - numel(x))];
end