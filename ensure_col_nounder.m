function T = ensure_col_nounder(T, candidates, target)
    vn  = T.Properties.VariableNames;
    map = containers.Map;
    for i=1:numel(vn), map(normkey(vn{i})) = vn{i}; end
    hitName = '';
    for k = 1:numel(candidates)
        nk = candidates{k};
        if isKey(map, nk)
            hitName = map(nk); break;
        end
    end
    if isempty(hitName)
        error('找不到所需列：%s（候选标准键：%s）', target, strjoin(candidates,', '));
    end
    T.Properties.VariableNames{strcmp(vn,hitName)} = target;
end