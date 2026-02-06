function d = diffBounds(x)
    x = x(:);
    d = max(x) - min(x);
end