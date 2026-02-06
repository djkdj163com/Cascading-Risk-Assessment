function kv = overrideKV(kv, key, val)
% 将 kv(cell) 中名为 key 的键替换为 val；若不存在则追加。
    i = find(strcmpi(kv(1:2:end), key), 1, 'first');
    if isempty(i)
        kv(end+1:end+2) = {key, val};
    else
        kv{2*i} = val;
    end
end