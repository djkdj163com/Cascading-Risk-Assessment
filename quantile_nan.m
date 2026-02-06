function [qlo, qhi] = quantile_nan(M, qs)
% 沿着样本维（行）取分位数；忽略 NaN
% qs = [qlo qhi], 0~1
qlo = nan(size(M,2),1); qhi = qlo;
for t = 1:size(M,2)
    x = M(:,t);
    x = x(isfinite(x));
    if isempty(x)
        qlo(t)=NaN; qhi(t)=NaN;
    else
        qlo(t) = quantile(x, qs(1));
        qhi(t) = quantile(x, qs(2));
    end
end
qlo = qlo(:)'; qhi = qhi(:)';
end