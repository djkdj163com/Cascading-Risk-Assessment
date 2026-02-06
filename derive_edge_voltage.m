function voltEdge = derive_edge_voltage(DYDJ, EndNodes)
% 10000 视作 500 kV；边电压取端点较低一侧（保守）
u = EndNodes(:,1); v = EndNodes(:,2);
vu = double(DYDJ(u)); vv = double(DYDJ(v));
vu(vu==10000) = 500; vv(vv==10000) = 500;
vu(~isfinite(vu)|vu<=0) = 110; vv(~isfinite(vv)|vv<=0) = 110;
voltEdge = min(vu, vv);
end