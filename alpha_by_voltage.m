function a = alpha_by_voltage(voltEdge)
% 电压冗余系数（容量放大因子的一部分）
v = double(voltEdge(:));
v(v==10000) = 500;
a = zeros(size(v));
a(v>=500) = 0.8;            % 500kV 冗余高
a(v>=220 & v<500) = 0.3;    % 220kV
a(v>0   & v<220)  = 0.0;    % 110kV
end