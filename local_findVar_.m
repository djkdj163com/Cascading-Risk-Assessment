%% ====================== Local helpers ======================
function idx = local_findVar_(T, names)
% 大小写不敏感、忽略下划线的列名匹配
v = lower(strrep(string(T.Properties.VariableNames),'_',''));
idx = [];
for i = 1:numel(names)
    target = lower(strrep(string(names{i}),'_',''));
    k = find(v == target, 1);
    if ~isempty(k), idx = k; return; end
end
end