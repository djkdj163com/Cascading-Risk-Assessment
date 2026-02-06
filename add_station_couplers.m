function [u_all, v_all, L_all, pline_all, isStationFlag] = add_station_couplers(nodes, u, v, L, pline, opt)
% 自动补充“同一变电站内”的跨电压耦合与母线汇接（健壮版）
% 输入：
%   nodes: 节点表（需含 DYDJ；若能有 Name/x/y 更好）
%   u,v,L,pline: 现有边（可为双回路展开后的集合）
%   opt: 结构体，可含：
%       .StationKey (默认 'Name')；若设为 [] 则跳过名称，直接用坐标聚类
%       .TolTight (默认 80 m) 坐标聚类容差
%       .UseBusbar (默认 true) 是否做同电压母线汇接
%       .MaxCoupleEachLow (默认 2) 低压侧每点连接最近的高压侧数量
%       .AllowedPairs ([10000 500; 500 220; 220 110]) 允许的相邻跨压耦合对
%       .StationEdgeLen (默认 1) 站内边长度
%       .StationEdgeProb (默认 0) 站内边初始失效概率
%
% 输出：
%   u_all,v_all,L_all,pline_all: 追加站内耦合后的总边
%   isStationFlag: 逻辑向量（对应 u_all/v_all 的每条边），标记站内耦合/母线边

% ----- 读 opt 并设默认 -----
if nargin < 6, opt = struct(); end
getf = @(f,d) (isfield(opt,f) && ~isempty(opt.(f))) * opt.(f) + ~(isfield(opt,f) && ~isempty(opt.(f))) * d;
StationKey       = getf('StationKey', 'Name');
TolTight         = getf('TolTight', 80);
UseBusbar        = getf('UseBusbar', true);
MaxCoupleEachLow = getf('MaxCoupleEachLow', 2);
AllowedPairs     = getf('AllowedPairs', [10000 500; 500 220; 220 110]);
StationEdgeLen   = getf('StationEdgeLen', 1);
StationEdgeProb  = getf('StationEdgeProb', 0);

% ----- 基本字段准备 -----
n = height(nodes);
% 电压
V = double(nodes.DYDJ(:));
if iscell(V) || isstring(V), V = str2double(string(V)); end
V(~isfinite(V)) = 110;
V(V==10000) = 10000;

% 坐标（若不存在则置空）
lat = []; lon = [];
if ismember('y', nodes.Properties.VariableNames), lat = double(nodes.y(:)); end
if ismember('x', nodes.Properties.VariableNames), lon = double(nodes.x(:)); end
hasXY = ~isempty(lat) && ~isempty(lon);

% 名称字段是否可用？
hasNameKey = false;
if ~isempty(StationKey)
    % StationKey 必须是字符/字符串，且存在于表字段中
    if ischar(StationKey) || (isstring(StationKey) && isscalar(StationKey))
        StationKeyChar = char(StationKey);
        hasNameKey = any(strcmp(nodes.Properties.VariableNames, StationKeyChar));
    end
end

% 若既无名称、也无坐标，则无法聚站：直接返回原边
if ~hasNameKey && ~hasXY
    u_all = u; v_all = v; L_all = L; pline_all = pline;
    isStationFlag = false(numel(u),1);
    return;
end

% ----- Union-Find 并站 -----
parent = 1:n; rankUF = zeros(n,1);
    function r = fnd(a)
        while parent(a)~=a
            parent(a) = parent(parent(a)); a = parent(a);
        end
        r = a;
    end
    function uni(a,b)
        ra=fnd(a); rb=fnd(b); if ra==rb, return; end
        if rankUF(ra)<rankUF(rb), parent(ra)=rb;
        elseif rankUF(ra)>rankUF(rb), parent(rb)=ra;
        else, parent(rb)=ra; rankUF(ra)=rankUF(ra)+1; end
    end

% 1) 先按名称并站（若可用）
if hasNameKey
    key = nodes.(StationKeyChar);
    if iscell(key) || isstring(key), key = string(key); end
    key = string(key);
    [ukey,~,gid] = unique(key,'stable');
    for g = 1:numel(ukey)
        ids = find(gid==g);
        if numel(ids) >= 2
            a = ids(1);
            for k = 2:numel(ids), uni(a, ids(k)); end
        end
    end
end

% 2) 再用坐标近邻并站（若有坐标）
if hasXY && TolTight > 0
    dlat = TolTight/111000;
    dlon = @(phi) TolTight/(111000*cosd(max(1e-3,phi)));
    keyLat = floor(lat / dlat);
    keyLon = floor(lon ./ arrayfun(dlon, lat));

    % 将节点放进格子哈希
    K = keyLat + 1e9*keyLon; % 简易哈希
    M = containers.Map('KeyType','int64','ValueType','any');
    for i=1:n
        kk = int64(K(i));
        if ~isKey(M,kk), M(kk) = i; else, M(kk) = [M(kk), i]; end
    end
    % 九宫格邻域
    neis = [-1 -1; -1 0; -1 1; 0 -1; 0 0; 0 1; 1 -1; 1 0; 1 1];
    for i=1:n
        kl = keyLat(i); klon = keyLon(i);
        cand = [];
        for t=1:9
            dy = neis(t,1); dx = neis(t,2);
            kkl = int64( (kl+dy) + 1e9*(klon+dx) );
            if isKey(M,kkl), cand = [cand, M(kkl)]; end %#ok<AGROW>
        end
        if isempty(cand), continue; end
        % 真距离过滤
        d = haversine_m(lat(i), lon(i), lat(cand), lon(cand));
        cand = cand(d <= TolTight);
        for j = cand
            if j ~= i, uni(i,j); end
        end
    end
end

% 收集簇
root = arrayfun(@(a) fnd(a), (1:n)');
[uroot,~,rid] = unique(root,'stable');
clusters = cell(numel(uroot),1);
for g=1:numel(uroot), clusters{g} = find(rid==g); end

% ----- 在每个簇内添加：母线汇接 & 相邻跨压耦合 -----
u_new = []; v_new = []; L_new = []; p_new = [];
for g=1:numel(clusters)
    idx = clusters{g}; if numel(idx) < 2, continue; end

    % 1) 母线：同电压 → 星形到代表节点
    if UseBusbar
        volts = unique(V(idx))';
        for vv = volts
            ids = idx(V(idx)==vv);
            if numel(ids) >= 2
                rep = ids(1); others = ids(2:end);
                u_new = [u_new; rep*ones(numel(others),1)]; %#ok<AGROW>
                v_new = [v_new; others(:)];                 %#ok<AGROW>
                L_new = [L_new; StationEdgeLen*ones(numel(others),1)]; %#ok<AGROW>
                p_new = [p_new; StationEdgeProb*ones(numel(others),1)]; %#ok<AGROW>
            end
        end
    end

    % 2) 相邻跨压耦合（AllowedPairs，低压侧连最近 K 个高压侧）
    for r=1:size(AllowedPairs,1)
        hi = AllowedPairs(r,1); lo = AllowedPairs(r,2);
        Hi = idx(V(idx)==hi);
        Lo = idx(V(idx)==lo);
        if isempty(Hi) || isempty(Lo), continue; end

        if hasXY
            for j = Lo(:)'
                d = haversine_m(lat(j), lon(j), lat(Hi), lon(Hi));
                [~,ord] = sort(d,'ascend');
                take = Hi(ord(1:min(MaxCoupleEachLow,numel(Hi))));
                u_new = [u_new; j*ones(numel(take),1)]; %#ok<AGROW>
                v_new = [v_new; take(:)];               %#ok<AGROW>
                L_new = [L_new; StationEdgeLen*ones(numel(take),1)]; %#ok<AGROW>
                p_new = [p_new; StationEdgeProb*ones(numel(take),1)]; %#ok<AGROW>
            end
        else
            % 无坐标：全连接（站内）
            [AA,BB] = ndgrid(Lo,Hi);
            u_new = [u_new; AA(:)]; %#ok<AGROW>
            v_new = [v_new; BB(:)]; %#ok<AGROW>
            L_new = [L_new; StationEdgeLen*ones(numel(AA),1)]; %#ok<AGROW>
            p_new = [p_new; StationEdgeProb*ones(numel(AA),1)]; %#ok<AGROW>
        end
    end
end

% ----- 合并边并输出 -----
u_all     = [u; u_new];
v_all     = [v; v_new];
L_all     = [L; L_new];
pline_all = [pline; p_new];

isStationFlag = false(numel(u_all),1);
if ~isempty(u_new)
    isStationFlag(numel(u)+1 : numel(u)+numel(u_new)) = true;
end
end

% ===== 小工具 =====
function d = haversine_m(lat1, lon1, lat2, lon2)
R = 6371000; % m
lat1 = deg2rad(lat1); lon1 = deg2rad(lon1);
lat2 = deg2rad(lat2); lon2 = deg2rad(lon2);
dlat = lat2 - lat1; dlon = lon2 - lon1;
a = sin(dlat/2).^2 + cos(lat1).*cos(lat2).*sin(dlon/2).^2;
d = 2*R*atan2(sqrt(a), sqrt(1-a));
end
