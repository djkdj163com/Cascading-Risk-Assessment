%% ====== Build county-level node weights w0 using your 4 fields ======
% 需要变量 out.nodeTable，且包含节点经纬度字段（默认 x, y）
% 输入 shp:
%   - 县级：包含 fis_dan / fis_hai / chan_dan / chan_hai 四个字段
%   - 海岸线：线要素
%   - 水体：面要素（若是线也可，代码会缓冲）

%% --------- CONFIG (按需改) ---------
county_shp   = 'D:\毕业论文数据\复杂网络课程\温州县.shp';      % 县级 shp
coast_shp    = 'C:\Users\kdj19\Desktop\复杂网络课程论文\新图\新数据\coastline.shp';   % 海岸线 shp（LINE）
water_shp    = 'C:\Users\kdj19\Desktop\复杂网络课程论文\新图\新数据\hedao.shp';       % 水体 shp（POLYGON，若为LINE也可）
county_key   = 'OBJECTID_1';               % 县唯一ID字段（若无改成 'NAME'）
use_measure  = 'value';                   % 'value' = 用 chan_*，'yield' = 用 fis_*
B_coast_km   = 10;                        % 海岸缓冲宽度 (km)
B_water_km   = 3;                         % 水体缓冲宽度 (km)
node_lon_field = 'x';                     % 节点经度字段
node_lat_field = 'y';                     % 节点纬度字段
%% -----------------------------------

assert(exist('out','var')==1 && istable(out.nodeTable), '未找到 out.nodeTable');
nodes = out.nodeTable;
assert(all(ismember({node_lon_field,node_lat_field}, nodes.Properties.VariableNames)), ...
    '节点表缺少经纬度字段：%s/%s', node_lon_field, node_lat_field);

% 读 shp
Cty   = shaperead(county_shp);
Coast = shaperead(coast_shp);
Water = shaperead(water_shp);

% 检查四个字段是否存在（县级 shp）
need_fields = {'fis_dan','fis_hai','chan_dan','chan_hai'};
for f = need_fields
    assert(isfield(Cty, f{1}), '县级 shp 缺少字段 "%s"', f{1});
end
% 县ID
if ~isfield(Cty, county_key)
    warning('县级 shp 无字段 %s，改用顺序号作为 county_id。', county_key);
    county_key = 'auto_id';
    for i=1:numel(Cty), Cty(i).(county_key) = i; end
end
cty_id = arrayfun(@(s) s.(county_key), Cty, 'uni', 0);

% 选择口径：按产值/产量计算海/淡份额 alpha_r
switch lower(use_measure)
    case 'value'   % 产值：chan_*
        marine_field = 'chan_hai';   fresh_field = 'chan_dan';
    case 'yield'   % 产量：fis_*
        marine_field = 'fis_hai';    fresh_field = 'fis_dan';
    otherwise
        error('use_measure 只能是 "value" 或 "yield"');
end

alpha = nan(numel(Cty),1);  % α_r = 海水份额 = marine / (marine + fresh)
for i=1:numel(Cty)
    m = double(Cty(i).(marine_field)); if ~isfinite(m), m=0; end
    f = double(Cty(i).(fresh_field));  if ~isfinite(f), f=0; end
    denom = m + f;
    alpha(i) = (denom>0) * (m/max(denom,eps)) + (denom==0)*0.5; % 无数据取 0.5
end

% 经纬度 -> 局部平面（米）
lon = nodes.(node_lon_field); lat = nodes.(node_lat_field);
R = 6371000; lat0 = mean(lat,'omitnan'); lon0 = mean(lon,'omitnan');
ll2xy = @(LON,LAT) deal( (deg2rad(LON - lon0).*R.*cosd(lat0)), (deg2rad(LAT - lat0).*R) );
[x_node, y_node] = ll2xy(lon, lat);

% 县 polygon
ctyPoly = repmat(polyshape(), numel(Cty),1);
for i=1:numel(Cty)
    [xC,yC] = ll2xy(Cty(i).X, Cty(i).Y);
    ctyPoly(i) = polyshape(xC, yC, 'Simplify', true);
end

% 海岸线 -> 缓冲
coastBuf = polyshape();
for i=1:numel(Coast)
    [xL,yL] = ll2xy(Coast(i).X, Coast(i).Y);
    if ~all(isnan(xL))
        coastBuf = union(coastBuf, polybuffer([xL(:) yL(:)], 'lines', B_coast_km*1000));
    end
end

% 水体(面/线) -> 缓冲
waterBuf = polyshape();
for i=1:numel(Water)
    [xW,yW] = ll2xy(Water(i).X, Water(i).Y);
    if isfield(Water,'Geometry') && strcmpi(Water(i).Geometry,'Line')
        pB = polybuffer([xW(:) yW(:)], 'lines', B_water_km*1000);
    else
        pW = polyshape(xW, yW, 'Simplify',true);
        if area(pW) == 0, continue; end
        pB = polybuffer(pW, B_water_km*1000);
    end
    waterBuf = union(waterBuf, pB);
end

% 节点 -> 县归属
nodes.county_id = strings(height(nodes),1);
for i=1:numel(Cty)
    inC = isinterior(ctyPoly(i), x_node, y_node);
    nodes.county_id(inC) = string(cty_id{i});
end
hasCounty = nodes.county_id ~= "";

% 节点是否在缓冲区
nodes.in_coastBuf = isinterior(coastBuf, x_node, y_node);
nodes.in_waterBuf = isinterior(waterBuf, x_node, y_node);

% 县内权重 w0 = α_r*I(coastBuf) + (1-α_r)*I(waterBuf)，县内归一
nodes.w0 = zeros(height(nodes),1);
uC = unique(nodes.county_id(hasCounty));
for k = 1:numel(uC)
    rid = uC(k);
    idx = hasCounty & nodes.county_id==rid;
    % 取该县 α_r
    rid_num = find(strcmp(string(cty_id), rid), 1);
    ar = alpha(rid_num); if isempty(ar) || ~isfinite(ar), ar = 0.5; end

    tmp = ar*double(nodes.in_coastBuf(idx)) + (1-ar)*double(nodes.in_waterBuf(idx));
    if all(tmp==0), tmp = ones(sum(idx),1); end % 若不在任何缓冲，回退等权
    nodes.w0(idx) = tmp ./ sum(tmp);
end

% 未归属县的节点给 0 权重（不参与计算）
nodes.w0(~hasCounty) = 0;

% 输出
outTable = table(nodes.node_id, nodes.(node_lon_field), nodes.(node_lat_field), ...
                 nodes.county_id, nodes.in_coastBuf, nodes.in_waterBuf, nodes.w0, ...
    'VariableNames', {'node_id','lon','lat','county_id','in_coastBuf','in_waterBuf','w0'});
writetable(outTable, 'nodes_with_w0.csv','Encoding','UTF-8');
fprintf('OK: 已写 nodes_with_w0.csv  (口径=%s, 海岸=%gkm, 水体=%gkm)\n', ...
    use_measure, B_coast_km, B_water_km);

% 快速核对：县内 w0 是否归一
G = groupsummary(outTable(outTable.w0>0,:), 'county_id','sum','w0');
bad = abs(G.sum_w0-1)>1e-6;
if any(bad)
   warning('有县内 w0 归一≠1，请检查：'); disp(G(bad,:));
end
