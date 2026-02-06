%% ============================================================
%  2.2.4 失供 → 渔业损失（无事件窗；年度口径，最终态并集）
%  Inputs:
%   - nodes_with_w0.csv : node_id, county_id, w0（你已生成）
%   - failed_nodes.csv  : node_id（全时段失效节点清单，可能重复，取并集）
%   - wenzhou_county.shp: 含 fis_dan/fis_hai/chan_dan/chan_hai 四字段
%  Outputs:
%   - q_by_county.csv   : 县级失供（单列 t01）
%   - Qr_by_county.csv  : 县级有效失供 Q_r（=q_r）
%   - loss_by_county.csv: 县级损失（低/基准/高；年度口径）
%   - loss_by_sector.csv: 县×部门分解（基准；年度口径）
%  说明：不做事件窗与季节分摊；P_rk 直接使用年度规模。
% ============================================================

%% -------- 配置（按需修改） --------
county_shp   = 'D:\毕业论文数据\复杂网络课程\温州县.shp';   % 县级 shp
county_key   = 'OBJECTID_1';            % 县唯一ID（若无可改 'NAME'）

use_value_or_yield = 'value';          % P_year口径: 'value'=产值(chan_*), 'yield'=产量(fis_*)

% 用电依赖 θ（三档情景），按你的口径可调整（海水/淡水）
theta_low  = struct('marine',0.40,'fresh',0.40);
theta_base = struct('marine',0.60,'fresh',0.60);
theta_high = struct('marine',0.80,'fresh',0.80);
%% ----------------------------------

%% -------- 读取数据 --------
nodeW  = readtable('nodes_with_w0.csv');      % node_id, county_id, w0
failed = readtable('D:\博士生数据\3个电压\新建文件夹\新台风代码\out_typhoon_prob\failed_nodesTY4.csv');       % node_id

% 标准化为 string，并清理 <missing>
assert(ismember('node_id', nodeW.Properties.VariableNames), 'nodes_with_w0.csv 缺少 node_id 列。');
assert(ismember('county_id', nodeW.Properties.VariableNames), 'nodes_with_w0.csv 缺少 county_id 列。');
nodeW.node_id   = string(nodeW.node_id);
nodeW.county_id = string(nodeW.county_id);
nodeW.county_id(ismissing(nodeW.county_id)) = "";
failed.node_id  = string(failed.node_id);

% 县集合（只用在 nodes_with_w0 里出现过的县）
uCounty = unique(nodeW.county_id(nodeW.county_id~=""));
R = numel(uCounty);

% 县级 shp
Cty = shaperead(county_shp);
if ~isfield(Cty, county_key)
    warning('县级 shp 无字段 %s，改用顺序号作为 county_id。', county_key);
    for i=1:numel(Cty), Cty(i).(county_key) = i; end
end
cty_id = strings(numel(Cty),1);
for i=1:numel(Cty)
    v = Cty(i).(county_key);
    if isstring(v) || ischar(v)
        cty_id(i) = string(v);
    elseif isnumeric(v)
        cty_id(i) = string(v);
    else
        cty_id(i) = "";
    end
end
cty_id(ismissing(cty_id)) = "";

% 检查渔业四字段
need_fields = {'fis_dan','fis_hai','chan_dan','chan_hai'};
for f = need_fields
    assert(isfield(Cty, f{1}), '县级 shp 缺少字段 "%s"', f{1});
end

%% -------- 1) 县级失供 q_r（最终态并集）--------
% 构造 outage 指示：节点曾在任一步失败即视为失供=1
failed_set = unique(failed.node_id(~ismissing(failed.node_id)));
isFailed   = ismember(nodeW.node_id, failed_set);

q = nan(R,1);
for r = 1:R
    rid = uCounty(r);
    idx = (nodeW.county_id==rid);
    if ~any(idx)
        q(r) = NaN;
        continue;
    end
    w = nodeW.w0(idx);
    if all(~isfinite(w)) || sum(w(~isnan(w)))==0
        q(r) = NaN;
        continue;
    end
    w = w / nansum(w);                 % 县内归一（保险）
    q(r) = nansum( w .* double(isFailed(idx)) );
end

% 导出（单步，列名取 t01）
qTab = table(uCounty, q, 'VariableNames',{'county_id','t01'});
writetable(qTab, 'q_by_county.csv','Encoding','UTF-8');

%% -------- 2) 有效失供 Q_r（无时间加权：Q_r = q_r）--------
Q_r = q;
QrTab = table(uCounty, Q_r, 'VariableNames',{'county_id','Q_r'});
writetable(QrTab, 'Qr_by_county.csv','Encoding','UTF-8');

%% -------- 3) P_{r,k}^{year}：海/淡两部门年度规模（无事件窗） --------
% 从 shp 取**年度**规模（按产值或产量），不做月份/天数缩放
marine_year = zeros(R,1);
fresh_year  = zeros(R,1);
for r = 1:R
    idx = find(cty_id==uCounty(r), 1);
    if isempty(idx)
        rid_msg = uCounty(r); if ismissing(rid_msg) || rid_msg==""; rid_msg = "(empty-county-id)"; end
        warning('县 %s 在 shp 中未找到，按 0 处理。', char(rid_msg));
        continue;
    end
    switch lower(use_value_or_yield)
        case 'value'   % 年产值
            marine_year(r) = double(Cty(idx).chan_hai);
            fresh_year(r)  = double(Cty(idx).chan_dan);
        case 'yield'   % 年产量
            marine_year(r) = double(Cty(idx).fis_hai);
            fresh_year(r)  = double(Cty(idx).fis_dan);
    end
    if ~isfinite(marine_year(r)), marine_year(r)=0; end
    if ~isfinite(fresh_year(r)),  fresh_year(r)=0;  end
end

% 年度两部门规模矩阵（R×2）：列顺序 [marine, fresh]
P_rk = [marine_year, fresh_year];

%% -------- 4) 损失 ΔL_r（三档情景；年度口径）--------
theta_vec_low  = [theta_low.marine,  theta_low.fresh]';
theta_vec_base = [theta_base.marine, theta_base.fresh]';
theta_vec_high = [theta_high.marine, theta_high.fresh]';

% 将 NaN 的 Q_r 视为 0（该县无节点/无权重时不计损失）
Q_r_safe = Q_r; Q_r_safe(~isfinite(Q_r_safe)) = 0;

Loss_low  = Q_r_safe .* (P_rk * theta_vec_low);
Loss_base = Q_r_safe .* (P_rk * theta_vec_base);
Loss_high = Q_r_safe .* (P_rk * theta_vec_high);

LossTab = table(uCounty, Q_r_safe, Loss_low, Loss_base, Loss_high, ...
    'VariableNames', {'county_id','Q_r','Loss_low','Loss_base','Loss_high'});
writetable(LossTab, 'loss_by_county.csv','Encoding','UTF-8');

% 分部门分解（基准）
Loss_marine_base = Q_r_safe .* (P_rk(:,1)*theta_base.marine);
Loss_fresh_base  = Q_r_safe .* (P_rk(:,2)*theta_base.fresh);
LossSecTab = table(uCounty, Loss_marine_base, Loss_fresh_base, ...
    'VariableNames', {'county_id','Loss_marine_base','Loss_fresh_base'});
writetable(LossSecTab, 'loss_by_sector.csv','Encoding','UTF-8');

%% -------- 市级汇总（年度口径；无事件窗）--------
city_total_low  = nansum(Loss_low);
city_total_base = nansum(Loss_base);
city_total_high = nansum(Loss_high);

fprintf('\n=== 市级汇总（年度口径；无事件窗）===\n');
fprintf('总损失：Low=%.3g, Base=%.3g, High=%.3g  （单位继承 county shp：%s）\n', ...
    city_total_low, city_total_base, city_total_high, use_value_or_yield);
fprintf('已输出：q_by_county.csv, Qr_by_county.csv, loss_by_county.csv, loss_by_sector.csv\n');
