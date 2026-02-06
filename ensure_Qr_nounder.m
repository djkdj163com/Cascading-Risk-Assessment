function T = ensure_Qr_nounder(T)
    % 统一构造 Q_r 列：优先 Qr/Qrsafe；否则把 t01..tNN 合成（均值）
    vn  = T.Properties.VariableNames;
    map = containers.Map; for i=1:numel(vn), map(normkey(vn{i})) = vn{i}; end
    % 直接命中
    for cand = {'qr','qrsafe'}
        if isKey(map, cand{1})
            T.Properties.VariableNames{strcmp(vn,map(cand{1}))} = 'Q_r';
            return;
        end
    end
    % t01/t02... → 均值
    tidx = false(size(vn));
    for i=1:numel(vn)
        if ~isempty(regexp(vn{i}, '^t\d+$', 'once')), tidx(i) = true; end
    end
    if any(tidx)
        if sum(tidx)==1
            T.Q_r = T{:, vn{tidx}};
        else
            T.Q_r = mean(T{:, vn(tidx)}, 2, 'omitnan');
        end
        return;
    end
    error('未找到 Qr / t01..tNN 列。');
end