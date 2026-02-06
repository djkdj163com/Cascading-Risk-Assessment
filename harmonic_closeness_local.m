% —— 谐波接近度（断连稳健）
function c = harmonic_closeness_local(G)
    D = distances(G); n = size(D,1);
    D(1:n+1:end) = inf; invD = 1./D; invD(~isfinite(invD)) = 0; c = sum(invD,2);
end