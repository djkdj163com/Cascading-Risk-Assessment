%% ---------------------- 本脚本用到的局部函数 ----------------------
function idx = matchIdx(keys, query)
% keys: string数组（全集），query: string数组（要匹配）
% 返回每个 query 在 keys 中的下标（假定都存在）。
    [~,loc] = ismember(query, keys);
    idx = loc;
end