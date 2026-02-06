%% ====================== CONFIG ======================
county_shp  = 'D:\毕业论文数据\复杂网络课程\温州县.shp';   % 县级 shp（含 county 字段）
county_name_field = 'county';                              % 以县名对齐与显示（不用 OBJECTID1）

qr_csv      = 'Qr_by_county.csv';          % 必需：包含 county / 或 countyid/objectid1 + Qr 或 t01,t02...
sector_csv  = 'loss_by_sector.csv';        % 必需：包含 county / 或 countyid/objectid1 + Lossmarinebase / Lossfreshbase
loss_allcsv = 'loss_by_county.csv';        % 可选：包含 Losslow / Lossbase / Losshigh（若缺则 Fig.4/5 用合成情景）

outdir = 'fig_out';
if ~exist(outdir,'dir'), mkdir(outdir); end

% SCI 风格（字号/字体/线宽）
set(groot,'defaultAxesFontName','Times New Roman');
set(groot,'defaultTextFontName','Times New Roman');
set(groot,'defaultAxesFontSize',10);
set(groot,'defaultTextFontSize',10);
set(groot,'defaultLineLineWidth',1.5);

% 色盲友好配色（假定你已有这些函数）
cLoss   = brew__ylorrd(256);       % 连续色标（黄→橙→红）：用于 Qr 和 Loss
cShare  = brew__blues(256);        % 连续色标（浅→深蓝）：用于 Marine share
cMarine = [0.15 0.47 0.74];        % 海水
cFresh  = [0.85 0.37 0.01];        % 淡水
%% ====================================================

%% 1) 读取 SHP（主键 county）与 CSV，并容错标准化列名
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

% 合并（以 county 为键）
T = outerjoin(Tqr, Tsec, 'Keys','county','MergeKeys',true);
if ThasAll, T = outerjoin(T, Tall, 'Keys','county','MergeKeys',true); end

% 完善总损失与占比
if ~ismember('Loss_base', T.Properties.VariableNames)
    if all(ismember({'Loss_marine_base','Loss_fresh_base'}, T.Properties.VariableNames))
        T.Loss_base = sum(T{:,{'Loss_marine_base','Loss_fresh_base'}},2,'omitnan');
    else
        error('缺少 Loss_base 或分部门损失列。');
    end
end

% —— 数值清洗（防止 SizeData 非法 & NaN 传播）——
T.Q_r              = sanitize_numeric(T.Q_r_T);
T.Loss_base        = sanitize_numeric(T.Loss_base);
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

% 与 SHP 对齐（按县名；用不区分大小写+去两端空格的匹配）
[tf, loc] = ismember_norm(cty_name, T.county);
V_Qr    = nan(numel(Cty),1); V_Qr(tf)    = T.Q_r(loc(tf));
V_Loss  = nan(numel(Cty),1); V_Loss(tf)  = T.Loss_base(loc(tf));
V_share = nan(numel(Cty),1); V_share(tf) = T.marine_share(loc(tf));

% polyshape（简化构造）
polyC = repmat(polyshape(), numel(Cty),1);
for i=1:numel(Cty)
    polyC(i) = polyshape(Cty(i).X, Cty(i).Y, 'Simplify', true);
end

%% 2) 图1：县域着色地图（Qr / Loss / Marine share）——不遮挡色条 + 中间图更大 + 标县名
fig1 = figure('Color','w','Units','centimeters','Position',[2 2 20 10]); % 稍加宽
tiledlayout(fig1,1,3,'TileSpacing','compact','Padding','compact');

% a) Q_r
ax1 = nexttile; draw_choropleth(ax1, polyC, V_Qr, cLoss);
title(ax1,'a. Effective outage Q_r'); axis(ax1,'equal'); axis(ax1,'off');

% b) Loss_base
ax2 = nexttile; draw_choropleth(ax2, polyC, V_Loss, cLoss);
title(ax2,'b. Fishery loss (base)'); axis(ax2,'equal'); axis(ax2,'off');

% c) Marine share
ax3 = nexttile; draw_choropleth(ax3, polyC, V_share, cShare);
title(ax3,'c. Marine share of loss (%)'); axis(ax3,'equal'); axis(ax3,'off');

% —— 调大中间图（先调轴位置，再放色条）——
drawnow;
p1 = ax1.Position; p2 = ax2.Position; p3 = ax3.Position;
grow = 0.08;                        % 中间加宽
p2(1) = p2(1)-grow/2; p2(3) = p2(3)+grow;
set(ax1,'Position',p1); set(ax2,'Position',p2); set(ax3,'Position',p3);

% —— 竖向色条：细、在轴外，且不遮挡 —— 
cb1 = neat_colorbar_right(ax1, 'Q_r', [], []);
cb2 = neat_colorbar_right(ax2, 'Loss (base)', [], []);
cb3 = neat_colorbar_right(ax3, 'Marine share', 0:0.25:1, compose('%.0f%%',0:25:100));

% 县名标注
label_counties(ax1, polyC, cty_name);
label_counties(ax2, polyC, cty_name);
label_counties(ax3, polyC, cty_name);

exportgraphics(fig1, fullfile(outdir,'Fig1_maps_Qr_Loss_Share.png'), 'Resolution',600);
exportgraphics(fig1, fullfile(outdir,'Fig1_maps_Qr_Loss_Share.pdf'));

%% 3) 图2：县域损失排序 + 分部门堆叠（美观+Box，刻度内侧）
[~, ord] = sort(T.Loss_base, 'descend');
To = T(ord,:);

% 2a：棒棒糖排序图
fig2a = figure('Color','w','Units','centimeters','Position',[2 2 20 9]);
x = 1:height(To);
stem(x, To.Loss_base,'-','Marker','o','Color',[0.25 0.25 0.25], ...
    'MarkerFaceColor',[0.25 0.25 0.25],'LineWidth',1.6,'MarkerSize',4);
xlim([0.5, numel(x)+0.5]);
xticks(x); xticklabels(string(To.county)); xtickangle(60);
ylabel('Loss (base)'); title('Ranked fishery loss by county');
grid on; ax=gca; ax.GridColor=[0.85 0.85 0.85]; ax.GridAlpha=1;
box on; set(ax,'TickDir','in','LineWidth',1);
exportgraphics(fig2a, fullfile(outdir,'Fig2a_ranked_lollipop_loss.png'), 'Resolution',600);
exportgraphics(fig2a, fullfile(outdir,'Fig2a_ranked_lollipop_loss.pdf'));

% 2b：海/淡堆叠
fig2b = figure('Color','w','Units','centimeters','Position',[2 2 20 9]);
B = [To.Loss_marine_base, To.Loss_fresh_base];
hb = bar(x, B, 'stacked','BarWidth',0.8);
hb(1).FaceColor = cMarine; hb(2).FaceColor = cFresh;
xlim([0.5, numel(x)+0.5]);
xticks(x); xticklabels(string(To.county)); xtickangle(60);
ylabel('Loss (base)'); legend({'Marine','Freshwater'},'Location','northeastoutside','Box','off');
title('Marine vs freshwater loss (stacked)');
grid on; ax=gca; ax.GridColor=[0.88 0.88 0.88]; ax.GridAlpha=1;
box on; set(ax,'TickDir','in','LineWidth',1);
exportgraphics(fig2b, fullfile(outdir,'Fig2b_stacked_marine_fresh.png'), 'Resolution',600);
exportgraphics(fig2b, fullfile(outdir,'Fig2b_stacked_marine_fresh.pdf'));

%% 4) 图3：Q_r – Loss 散点（去回归线；风格同 Fig2；刻度内侧）
fig3 = figure('Color','w','Units','centimeters','Position',[2 2 13 11]);

xv = sanitize_numeric(T.Q_r);
yv = sanitize_numeric(T.Loss_base);
cv = sanitize_numeric(T.marine_share);

lb = yv; lb(~isfinite(lb) | lb < 0) = NaN;
denLoss = max(lb, [], 'omitnan'); if isempty(denLoss) || ~isfinite(denLoss) || denLoss==0, denLoss = 1; end
s  = 100 * (lb/denLoss + 0.1);     % 保证为正
s(~isfinite(s)) = 60;             % 缺失默认 30
cv(~isfinite(cv)) = 0.5;          % 缺失置中性色

scatter(xv, yv, s, cv, 'filled', ...
    'MarkerEdgeColor',[0.2 0.2 0.2],'MarkerFaceAlpha',0.8,'MarkerEdgeAlpha',0.9);
xlabel('Q_r (effective outage)'); ylabel('Fishery loss (base)');
colormap(fig3, cShare);
cb = colorbar; cb.Label.String='Marine share'; cb.Ticks=0:0.25:1; cb.TickLabels=compose('%.0f%%',cb.Ticks*100);
grid on; box on; set(gca,'TickDir','in','LineWidth',1);
title('Outage–loss response');
exportgraphics(fig3, fullfile(outdir,'Fig3_scatter_Qr_vs_Loss.png'), 'Resolution',600);
exportgraphics(fig3, fullfile(outdir,'Fig3_scatter_Qr_vs_Loss.pdf'));

%% 5) 图4：Q_r 分位箱线图 + 中位数连线（兼容写法，刻度内侧）
fig4 = figure('Color','w','Units','centimeters','Position',[2 2 14 10]);

% 清洗
mask = isfinite(xv) & isfinite(yv);
xv2 = xv(mask); yv2 = yv(mask);

if numel(xv2) >= 4
    % 四分位边界（去极端重复）
    edges = quantile(xv2, [0 0.25 0.5 0.75 1]);
    edges(1)  = min(xv2);
    edges(end)= max(xv2);
    G = discretize(xv2, edges);   % 旧版兼容：不加参数名

    % —— 兼容的 boxplot 调用：只用两个参数 —— 
    boxplot(yv2, G);
    set(gca,'XTickLabel',{'Q1','Q2','Q3','Q4'});

    ylabel('Fishery loss (base)'); xlabel('Q_r quartile');
    title('Loss distribution across Q_r quartiles');
    grid on; ax=gca; ax.GridColor=[0.9 0.9 0.9]; box on; set(ax,'TickDir','in','LineWidth',1);

    hold on;
    meds = splitapply(@median, yv2, G);
    plot(1:4, meds, '-o', 'LineWidth',1.8, ...
        'MarkerFaceColor',[0.25 0.25 0.25], 'Color',[0.25 0.25 0.25]);
end

exportgraphics(fig4, fullfile(outdir,'Fig4_box_by_Qr_quantile.png'), 'Resolution',600);
exportgraphics(fig4, fullfile(outdir,'Fig4_box_by_Qr_quantile.pdf'));

%% 6) 图5：情景灵敏度斜线图（图例区分；不标县名；刻度内侧）
% 若无 Low/High → 用 ±20% 合成
needCols = all(ismember({'Loss_low','Loss_base','Loss_high'}, To.Properties.VariableNames));
syntheticScenario = false;
if ~needCols
    To.Loss_low  = To.Loss_base * 0.8;
    To.Loss_high = To.Loss_base * 1.2;
    syntheticScenario = true;
end

% Top-N 县
N = min(10, height(To));
Ttop = To(1:N, {'county','Loss_low','Loss_base','Loss_high'});

fig5 = figure('Color','w','Units','centimeters','Position',[2 2 16 12]); hold on;
% 更美观的配色+标记
cmap = lines(N);       % 也可换成其它 colormap，如 parula(N)
markers = {'o','s','d','^','v','>','<','p','h','x','+'};

for i=1:N
    xk = [1 2 3]; yk = [Ttop.Loss_low(i) Ttop.Loss_base(i) Ttop.Loss_high(i)];
    plot(xk, yk, '-','Color',cmap(i,:), ...
         'Marker',markers{mod(i-1,numel(markers))+1}, ...
         'MarkerSize',5, 'LineWidth',1.8, ...
         'MarkerFaceColor',cmap(i,:), 'MarkerEdgeColor',[0.15 0.15 0.15]);
end
xlim([0.8 3.2]); ax=gca; ax.XTick = [1 2 3]; ax.XTickLabel = {'Low','Base','High'};
ylabel('Fishery loss');
if syntheticScenario
    title('Scenario sensitivity (Top-N counties) — synthetic ±20%');
else
    title('Scenario sensitivity (Top-N counties)');
end
grid on; ax.GridColor=[0.9 0.9 0.9]; box on; set(ax,'TickDir','in','LineWidth',1);

% 用图例区分，不在图上标注 county
lgd = legend(string(Ttop.county), 'Location','eastoutside', 'NumColumns',1);
set(lgd,'Box','off');

exportgraphics(fig5, fullfile(outdir,'Fig5_sensitivity_slopegraph_legend.png'), 'Resolution',600);
exportgraphics(fig5, fullfile(outdir,'Fig5_sensitivity_slopegraph_legend.pdf'));

disp('All figures exported to folder: fig_out');
