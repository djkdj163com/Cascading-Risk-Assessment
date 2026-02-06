function F_edge = dc_flow_proxy(G, srcSub, loadSub, wLoad, voltEdge, Ledge)
% DC/PTDF 近似，输出每条边潮流幅值（m×1）
m = numedges(G); n = numnodes(G);
F_edge = zeros(m,1);
if m==0 || n==0 || isempty(srcSub) || isempty(loadSub), return; end

voltEdge = double(voltEdge(:)); Ledge = double(Ledge(:));
if numel(voltEdge)~=m || numel(Ledge)~=m
    error('dc_flow_proxy: voltEdge/Ledge 长度必须等于 numedges(G)。');
end
if isempty(wLoad), wLoad = ones(numel(loadSub),1); end
wLoad = double(wLoad(:)); s = sum(wLoad); if s<=0, wLoad = ones(numel(loadSub),1)/numel(loadSub); else, wLoad = wLoad/s; end

ends = G.Edges.EndNodes; u = ends(:,1); v = ends(:,2);
C = sparse((1:m)', u,  1, m, n) + sparse((1:m)', v, -1, m, n); % 任取方向

x_e = reactance_by_voltage_length(voltEdge, Ledge);
good = isfinite(x_e) & x_e>0;
if ~all(good)
    med = median(x_e(good)); if ~isfinite(med) || med<=0, med = 1.0; end
    x_e(~good) = med;
end
b_e = 1 ./ x_e;

B_bus = C' * spdiags(b_e,0,m,m) * C;

ref = srcSub(1);
mask = true(n,1); mask(ref) = false;
B_rr = B_bus(mask,mask);

p = zeros(n,1);
Ptot = sum(wLoad);
p(srcSub) = Ptot / numel(srcSub);
p(loadSub) = p(loadSub) - wLoad;

p_r = p(mask);
eps_reg = 1e-9;
theta_r = (B_rr + eps_reg*speye(size(B_rr))) \ p_r;
theta = zeros(n,1); theta(mask) = theta_r;

f = b_e .* (C * theta);
F_edge = abs(full(f));
end