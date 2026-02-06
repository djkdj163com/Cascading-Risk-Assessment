%% ====================== CONFIG（沿用原脚本） ======================
county_shp  = 'D:\毕业论文数据\复杂网络课程\温州县.shp';   % 县级 shp（含 county 字段）
county_name_field = 'county';                              % 以县名对齐与显示（不用 OBJECTID1）

qr_csv      = 'Qr_by_county.csv';          % 必需：包含 county / 或 countyid/objectid1 + Qr 或 t01,t02...
sector_csv  = 'loss_by_sector.csv';        % 必需：包含 county / 或 countyid/objectid1 + Lossmarinebase / Lossfreshbase
loss_allcsv = 'loss_by_county.csv';        % 可选：包含 Losslow / Lossbase / Losshigh

outdir = 'fig_out';
if ~exist(outdir,'dir'), mkdir(outdir); end

% SCI 风格（字号/字体/线宽）
set(groot,'defaultAxesFontName','Times New Roman');
set(groot,'defaultTextFontName','Times New Roman');
set(groot,'defaultAxesFontSize',10);
set(groot,'defaultTextFontSize',10);
set(groot,'defaultLineLineWidth',1.5);

% 色盲友好配色（假定你已有这些函数）
cLoss   = brew__ylorrd(256);       % 用不到也保留
cShare  = brew__blues(256);        % 用于 marine_share 颜色
cMarine = [0.15 0.47 0.74];        % 海水
cFresh  = [0.85 0.37 0.01];        % 淡水
%% ================================================================


%% ========== 1) 读取 SHP 与 CSV，并容错标准化列名（沿用原逻辑） ==========
Cty = shaperead(county_shp);

% 读取 shp 的 county（主键）与可能存在的 OBJECTID1/OBJECTID_1（用于映射）
cty_name = get_shp_field(Cty, {county_name_field,'county','name'});  % string[]
cty_id   = get_shp_field(Cty, {'OBJECTID1','OBJECTID_1','id'});      % string[]（若存在）

if all(ismissing(cty_name) | cty_name=="")
    error('SHP 中未找到县名字段（county/name）。请确认 county_name_field。');
end

% CSV
Tqr  = readtable(qr_csv);
Tsec = readtable(sector_csv);
ThasAll = exist(loss_allcsv,'file')==2;
if ThasAll, Tall = readtable(loss_allcsv); end

% 列名唯一化；具体匹配在 ensure_* 完成
Tqr   = fix_names(Tqr);
Tsec  = fix_names(Tsec);
if ThasAll, Tall = fix_names(Tall); end

% —— 为每个 CSV 建立 county（县名）列 —— %
Tqr  = ensure_county_name(Tqr,  cty_id, cty_name);
Tsec = ensure_county_name(Tsec, cty_id, cty_name);
if ThasAll
    Tall = ensure_county_name(Tall, cty_id, cty_name);
end

% Q_r 统一（支持 Qr/Qrsafe 或 t01..tNN -> 均值）
Tqr = ensure_Qr_nounder(Tqr);

% 分部门损失列统一（无下划线版本）
Tsec = ensure_col_nounder(Tsec, {'lossmarinebase','lossmarine','marineloss'}, 'Loss_marine_base');
Tsec = ensure_col_nounder(Tsec, {'lossfreshbase','lossfresh','freshloss'},   'Loss_fresh_base');

% 若有总损失表，统一 low/base/high（无下划线版本）
if ThasAll
    Tall = ensure_col_nounder(Tall, {'losslow','lowloss'},     'Loss_low');
    Tall = ensure_col_nounder(Tall, {'lossbase','baseloss'},   'Loss_base');
    Tall = ensure_col_nounder(Tall, {'losshigh','highloss'},   'Loss_high');
end

T = outerjoin(Tqr, Tsec, 'Keys','county','MergeKeys',true);

if ThasAll
    % 只把 Loss 的三列并进来，避免把 Tall 里的 Q_r 带进来造成重名加后缀
    keep = intersect({'county','Loss_low','Loss_base','Loss_high'}, Tall.Properties.VariableNames);
    Tall_keep = Tall(:, keep);
    T = outerjoin(T, Tall_keep, 'Keys','county','MergeKeys',true);
end


% 完善总损失
if ~ismember('Loss_base', T.Properties.VariableNames)
    if all(ismember({'Loss_marine_base','Loss_fresh_base'}, T.Properties.VariableNames))
        T.Loss_base = sum(T{:,{'Loss_marine_base','Loss_fresh_base'}},2,'omitnan');
    else
        error('缺少 Loss_base 或分部门损失列。');
    end
end

% —— 数值清洗 & 占比 —— 
T.Q_r               = sanitize_numeric(T.Q_r);
T.Loss_base         = sanitize_numeric(T.Loss_base);
if ismember('Loss_marine_base', T.Properties.VariableNames)
    T.Loss_marine_base = sanitize_numeric(T.Loss_marine_base);
end
if ismember('Loss_fresh_base', T.Properties.VariableNames)
    T.Loss_fresh_base  = sanitize_numeric(T.Loss_fresh_base);
end
den = T.Loss_marine_base + T.Loss_fresh_base;
T.marine_share = T.Loss_marine_base ./ max(den, eps);
T.marine_share(~isfinite(T.marine_share)) = NaN;
T.marine_share = max(0, min(1, T.marine_share));  % 夹紧到 [0,1]
T.county = string(T.county);


%% ========== 2) 只画：Loss(base) 堆叠图 + Q_r–Loss 气泡图（同一 figure） ==========
% 先按 Loss_base 降序
[~, ord] = sort(T.Loss_base, 'descend');
To = T(ord,:);
x = 1:height(To);

% 新建 figure：上下两块
fig = figure('Color','w','Units','centimeters','Position',[2 2 22 18]);
tl = tiledlayout(fig, 2, 1, 'TileSpacing','compact','Padding','compact');

% ---------------- 上：海/淡分部门堆叠 ----------------
ax1 = nexttile(tl, 1);
B = [To.Loss_marine_base, To.Loss_fresh_base];
hb = bar(ax1, x, B, 'stacked', 'BarWidth', 0.8);
hb(1).FaceColor = cMarine; 
hb(2).FaceColor = cFresh;

xlim(ax1, [0.5, numel(x)+0.5]);
xticks(ax1, x);
xticklabels(ax1, string(To.county));
xtickangle(ax1, 60);
ylabel(ax1, 'Loss (base)');
title(ax1, 'Marine vs freshwater loss (stacked)');
legend(ax1, {'Marine','Freshwater'}, 'Location','northeastoutside', 'Box','off');

grid(ax1, 'on'); 
ax1.GridColor = [0.88 0.88 0.88]; 
ax1.GridAlpha = 1;
box(ax1, 'on'); 
set(ax1, 'TickDir','in', 'LineWidth',1);

% ---------------- 下：Q_r – Loss 气泡图 ----------------
ax2 = nexttile(tl, 2);

xv = sanitize_numeric(To.Q_r);
yv = sanitize_numeric(To.Loss_base);
cv = sanitize_numeric(To.marine_share);

lb = yv; 
lb(~isfinite(lb) | lb < 0) = NaN;
denLoss = max(lb, [], 'omitnan'); 
if isempty(denLoss) || ~isfinite(denLoss) || denLoss==0
    denLoss = 1;
end
s  = 120 * (lb/denLoss + 0.6);      % 大小随 Loss_base 变化，且保证为正
s(~isfinite(s)) = 40;              
cv(~isfinite(cv)) = 0.5;           % 缺失置中性色

scatter(ax2, xv, yv, s, cv, 'filled', ...
    'MarkerEdgeColor',[0.2 0.2 0.2], 'MarkerFaceAlpha',0.8, 'MarkerEdgeAlpha',0.9);

xlabel(ax2, 'Q_r (effective outage)');
ylabel(ax2, 'Fishery loss (base)');
title(ax2, 'Outage–loss response');

colormap(ax2, cShare);
cb = colorbar(ax2); 
cb.Label.String = 'Marine share';
cb.Ticks = 0:0.25:1; 
cb.TickLabels = compose('%.0f%%', cb.Ticks*100);

grid(ax2, 'on'); 
box(ax2, 'on'); 
set(ax2,'TickDir','in','LineWidth',1);

% --------- 你可手动微调：取消注释并改数值即可 ---------
% p1 = ax1.Position; p2 = ax2.Position;
% p1(4) = p1(4)*0.95;               % 上图高度
% p2(2) = p2(2)*0.95;               % 下图底部间距
% set(ax1,'Position',p1); set(ax2,'Position',p2);
% tl.TileSpacing = 'compact'; tl.Padding = 'compact';

% 导出（可选）
% exportgraphics(fig, fullfile(outdir,'Fig_LossStack_and_Bubble.png'), 'Resolution',600);
% exportgraphics(fig, fullfile(outdir,'Fig_LossStack_and_Bubble.pdf'));

disp('Done: stacked loss + bubble chart (上下布局) 完成。');
