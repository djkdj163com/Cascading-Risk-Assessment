function x = reactance_by_voltage_length(voltEdge, Ledge)
% 极简近似：x ∝ L * k(V)
v = double(voltEdge(:)); L = double(Ledge(:));
v(v==10000) = 500;
k = ones(size(v));
k(v>=500) = 1.0;   % 500kV 电抗低
k(v>=220 & v<500) = 2.0;
k(v>0   & v<220)  = 4.0;
x = max(L .* k, 1e-6);
end