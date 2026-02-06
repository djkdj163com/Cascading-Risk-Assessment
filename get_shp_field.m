function arr = get_shp_field(Cty, candidates)
    % 返回 string 数组；若均不存在则全 missing
    N = numel(Cty); arr = strings(N,1);
    hit = '';
    vnames = string(fieldnames(Cty));
    for k = 1:numel(candidates)
        idx = find(strcmpi(vnames, candidates{k}), 1);
        if ~isempty(idx), hit = vnames(idx); break; end
    end
    if hit=="", arr(:) = missing; return; end
    for i=1:N
        v = Cty(i).(hit);
        if isstring(v) || ischar(v)
            arr(i) = string(v);
        elseif isnumeric(v)
            arr(i) = string(v);
        else
            arr(i) = missing;
        end
    end
    arr(ismissing(arr)) = "";
end