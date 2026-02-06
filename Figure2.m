%% ===== 中心性绘图（2×2 同图；无条带框；每子图含 TopK/分位线/Top1%&5%/Inset/统计框）=====
% 依赖：out.G0, harmonic_closeness_local(G), local_clustering_undirected_local(G)

% —— 配色
PALETTE = [237 173 197; 206 170 208; 146 132 193; 108 190 195; 170 215 200; 97 156 217]/255;
COLORS  = [PALETTE(6,:); PALETTE(3,:); PALETTE(4,:); PALETTE(1,:)];
FONT = 'Times New Roman';
LW   = 3.0;

SHOW_GRID  = false;
GRID_COLOR = [0.90 0.90 0.90];

% ===== 信息增强参数（都开着）=====
OPT.TOPK_MARK = 10;      % 曲线上标点+标签的 Top-k
OPT.TOPK_LIST = 5;       % 角落 Top nodes 列表显示多少个
OPT.ZOOM_K    = 200;     % inset 放大到前多少名
OPT.PCTS      = [50 90 95 99];       % 分位数线
OPT.SHOW_TOPLINES   = true;          % Top1%/Top5% 竖线
OPT.SHOW_PCTL_LINES = true;          % 分位数水平线
OPT.SHOW_TOPK       = true;          % Top-k 标注/列表
OPT.SHOW_INSET      = true;          % inset 放大
OPT.SHOW_STATSBOX   = true;          % Top1% share + Gini (+ clustering nonzero)
OPT.SHOW_TOPK_LABELS = false;   % <<< 关闭曲线上的文字标注


OPT.REFLINE_COL = [0.55 0.55 0.60];  % 参考线颜色
OPT.REFLINE_LW  = 1.0;

% ===== 图与指标 =====
Gplot = out.G0;  n = numnodes(Gplot);
if n < 2, warning('节点数过少，跳过中心性绘图。'); return; end

names = getNodeLabels_local(Gplot);

deg_raw = degree(Gplot);
[ds, idx_deg] = sort(deg_raw,'descend');
ds_plot = max(ds, eps);

bet_raw = centrality(Gplot,'betweenness');
bet_raw = max(bet_raw, eps);
[bs, idx_bet] = sort(bet_raw,'descend');
bs_plot = bs;

clo_raw = harmonic_closeness_local(Gplot);
[cs, idx_clo] = sort(clo_raw,'descend');
cs_plot = cs;

clu_raw = local_clustering_undirected_local(Gplot);
[ccs, idx_clu] = sort(clu_raw,'descend');
ccs_plot = ccs;

x = (1:n)';

% 刻度（log 用一套，linear 用一套）
xt      = unique(round(logspace(0, log10(n), 6)));
xtl     = arrayfun(@num2str, xt, 'UniformOutput', false);
xt_lin  = unique(round(linspace(1, n, 6)));
xtl_lin = arrayfun(@num2str, xt_lin, 'UniformOutput', false);

% 全局 meta
m = numedges(Gplot);
isDir  = isa(Gplot,'digraph');
hasW   = ismember('Weight', Gplot.Edges.Properties.VariableNames);
metaStr = sprintf('N=%d, E=%d, %s, %s', n, m, ternary_local(isDir,'Directed','Undirected'), ternary_local(hasW,'Weighted','Unweighted'));

% ===== 2×2 一张图 =====
fig = figure('Color',[1 1 1 1]);
try, set(fig,'WindowState','maximized'); catch, set(fig,'Position',[90 90 1200 700]); end
set(fig,'DefaultAxesFontName',FONT,'DefaultTextFontName',FONT);

t = tiledlayout(fig, 2, 2, 'Padding','compact','TileSpacing','compact');
xlabel(t,'Rank','FontName',FONT,'FontSize',12);

% ---- a) Degree（loglog）
axA = nexttile(t,1);
h = loglog(axA, x, ds_plot, '-', 'Color', COLORS(1,:), 'LineWidth', LW); uistack(h,'top');
facetAxesTL_local(axA, [1 n], xt, xtl, SHOW_GRID, GRID_COLOR, FONT);
ylabel(axA,'Degree','FontName',FONT);
placePanelLabel_local(axA,'a',FONT,16,[0.20 0.20 0.25]);
title(axA,'Degree','FontName',FONT,'FontWeight','bold');
decorateRankPlot_local(fig, axA, x, ds_plot, deg_raw, idx_deg, names, OPT, "default", true);

% ---- b) Betweenness（loglog）
axB = nexttile(t,2);
h = loglog(axB, x, bs_plot, '-', 'Color', COLORS(2,:), 'LineWidth', LW); uistack(h,'top');
facetAxesTL_local(axB, [1 n], xt, xtl, SHOW_GRID, GRID_COLOR, FONT);
ylabel(axB,'Betweenness','FontName',FONT);
placePanelLabel_local(axB,'b',FONT,16,[0.20 0.20 0.25]);
title(axB,'Betweenness','FontName',FONT,'FontWeight','bold');
decorateRankPlot_local(fig, axB, x, bs_plot, bet_raw, idx_bet, names, OPT, "default", true);

% ---- c) Closeness（linear；×10^2）
axC = nexttile(t,3);
h = plot(axC, x, cs_plot, '-', 'Color', COLORS(3,:), 'LineWidth', LW); uistack(h,'top');
facetAxesTL_local(axC, [1 n], xt_lin, xtl_lin, SHOW_GRID, GRID_COLOR, FONT);
ylabel(axC,'Closeness','FontName',FONT);
placePanelLabel_local(axC,'c',FONT,16,[0.20 0.20 0.25]);
title(axC,'Closeness','FontName',FONT,'FontWeight','bold');
try, axC.YRuler.ExponentMode='manual'; axC.YRuler.Exponent=2; catch, axC.YAxis.Exponent=2; end
decorateRankPlot_local(fig, axC, x, cs_plot, clo_raw, idx_clo, names, OPT, "default", false);

% ---- d) Clustering（linear）
axD = nexttile(t,4);
h = plot(axD, x, ccs_plot, '-', 'Color', COLORS(4,:), 'LineWidth', LW); uistack(h,'top');
facetAxesTL_local(axD, [1 n], xt_lin, xtl_lin, SHOW_GRID, GRID_COLOR, FONT);
ylabel(axD,'Clustering coefficient','FontName',FONT);
placePanelLabel_local(axD,'d',FONT,16,[0.20 0.20 0.25]);
title(axD,'Clustering','FontName',FONT,'FontWeight','bold');
decorateRankPlot_local(fig, axD, x, ccs_plot, clu_raw, idx_clu, names, OPT, "clustering", false);

% ---- 全局信息（整张图一行）
annotation(fig,'textbox',[0.01 0.003 0.98 0.035], 'String', metaStr, ...
    'EdgeColor','none','HorizontalAlignment','left','VerticalAlignment','bottom', ...
    'FontName',FONT,'FontSize',10,'Color',[0.35 0.35 0.40]);
