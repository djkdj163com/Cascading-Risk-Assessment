function [sourceIdx, loadIdx, wLoad] = build_source_load_weights(nodes, FisheryWeight)
% 源：10000 或 ≥500；负荷：≤110
DY = double(nodes.DYDJ(:));
sourceIdx = find( (DY==10000) | (DY>=500) );
loadIdx   = find( DY<=110 );

% 权重：默认均匀；支持 FisheryWeight（key=node_id）
if isempty(loadIdx)
    wLoad = zeros(0,1); return;
end
if isempty(FisheryWeight)
    wLoad = ones(numel(loadIdx),1); 
else
    ids = string(nodes.node_id(loadIdx));
    wLoad = ones(numel(loadIdx),1);
    if isa(FisheryWeight,'containers.Map')
        for k=1:numel(ids)
            key = ids(k);
            if isKey(FisheryWeight, key)
                wLoad(k) = double(FisheryWeight(key));
            end
        end
    elseif isstruct(FisheryWeight)
        fn = fieldnames(FisheryWeight);
        M = containers.Map(string(fn), struct2array(FisheryWeight));
        for k=1:numel(ids)
            key = ids(k);
            if isKey(M, key)
                wLoad(k) = double(M(key));
            end
        end
    end
end
s = sum(wLoad); if s>0, wLoad = wLoad/s; else, wLoad = ones(numel(loadIdx),1)/numel(loadIdx); end
end