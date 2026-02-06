function T = ensure_county_name(T, cty_id, cty_name)
    % 目标：确保 T 中存在 county 列（县名）
    % 1) 若已有 county，则直接标准化为 string
    vn = T.Properties.VariableNames;
    map = containers.Map; for i=1:numel(vn), map(normkey(vn{i})) = vn{i}; end
    if isKey(map, 'county')
        T.Properties.VariableNames{strcmp(vn, map('county'))} = 'county';
        T.county = string(T.county);
        return;
    end
    % 2) 若有 countyid/objectid1，则通过 shp 映射到县名
    id_col = '';
    for cand = {'countyid','objectid1','objectid_1','id'}
        if isKey(map, cand{1}), id_col = map(cand{1}); break; end
    end
    if id_col~=""
        id_values = string(T.(id_col));
        % 构建 id -> name 映射（基于 shp）
        key_id = lower(strtrim(cty_id));   % shp id（string）
        val_nm = cty_name;                 % shp county（string）
        % 映射
        T.county = strings(height(T),1);
        for i=1:height(T)
            k = lower(strtrim(id_values(i)));
            loc = find(key_id==k, 1);
            if ~isempty(loc), T.county(i) = val_nm(loc); else, T.county(i) = ""; end
        end
        return;
    end
    error('CSV 中既无 county，也无 countyid/objectid1；无法与 shp 对齐县名。');
end