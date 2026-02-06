% ======= 工具函数 =======
function r = zero_one_norm(x)
    x = x(:); xmin = min(x); xmax = max(x);
    if xmax>xmin, r = (x - xmin) ./ (xmax - xmin);
    else, r = zeros(size(x)); end
end