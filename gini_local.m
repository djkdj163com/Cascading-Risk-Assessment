function g = gini_local(v)
    v = v(:);
    v(~isfinite(v)) = 0;
    if all(v==0), g = 0; return; end
    v = max(v,0);
    v = sort(v); % ascending
    n = numel(v);
    idx = (1:n)';
    g = (2*sum(idx.*v)/(n*sum(v))) - (n+1)/n;
    g = max(0,min(1,g));
end
