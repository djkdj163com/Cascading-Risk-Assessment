function idxs = my_randsample(pool, m, w)
% 无统计工具箱时的有放回加权采样
pool = pool(:); w = w(:); w = w./sum(w);
F = cumsum(w); r = rand(m,1);
idxs = zeros(m,1);
for i=1:m
    idxs(i) = pool(find(F>=r(i),1,'first'));
end
end