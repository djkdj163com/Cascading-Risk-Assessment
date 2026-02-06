function cost = edge_cost_by_volt_and_length(voltEdge, Ledge)
% 成本 ~ L * w(V)（电压越高权重越小）
v = double(voltEdge(:)); L = double(Ledge(:));
v(v==10000)=500;
w = ones(size(v));
w(v>=500) = 0.6;            % 500kV
w(v>=220 & v<500) = 1.0;    % 220kV
w(v>0   & v<220)  = 1.6;    % 110kV
cost = max(L .* w + 1e-6, 1e-6);
end