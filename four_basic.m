%% ===== 中心性绘图（Facet 模板；条带标题+Rank；Times New Roman）=====
% 放在统计与预览块 end 之后、simulate_dynamic_cascade_final 定义之前

% —— 6 色调（截图）
PALETTE = [237 173 197; 206 170 208; 146 132 193; 108 190 195; 170 215 200; 97 156 217]/255;
% 用的 4 色（Degree / Betweenness / Closeness / Clustering）
COLORS = [PALETTE(6,:); PALETTE(3,:); PALETTE(4,:); PALETTE(1,:)];
FONT = 'Times New Roman';
LW   = 3.0;

SHOW_GRID  = false;                 % ← 想要浅灰网格改 true
GRID_COLOR = [0.90 0.90 0.90];

% —— 条带与标题样式（与 createfigure 保持一致）
STRIP_COLOR     = [0.901960784313726 0.901960784313726 0.92156862745098];  % 浅灰蓝背景
STRIP_TITLE_COL = [0.20 0.20 0.25];  % 标题颜色
STRIP_SUB_COL   = [0.35 0.35 0.40];  % “Rank”小字颜色
STRIP_TITLE_FS  = 16;                % 标题字号（粗体）
STRIP_SUB_FS    = 11;                % “Rank”字号
PANEL_LABEL_FS  = 16;                % 面板 a/b/c/d 字号
PANEL_LABEL_COL = [0.20 0.20 0.25];  % 面板标签颜色

Gplot = out.G0;  n = numnodes(Gplot);
if n < 2, warning('节点数过少，跳过中心性绘图。'); return; end

% ===== 指标（你的原方法保持不变）=====
deg = degree(Gplot);                   ds  = sort(deg, 'descend');
try, bet = centrality(Gplot,'betweenness'); catch, bet = centrality(Gplot,'betweenness'); end
bs  = sort(max(bet, eps), 'descend');  % 避免 0 取对数
cs  = sort(harmonic_closeness_local(Gplot), 'descend');
ccs = sort(local_clustering_undirected_local(Gplot), 'descend');

% 排名与刻度
x = (1:n)';
xt      = unique(round(logspace(0, log10(n), 6)));   xtl      = arrayfun(@num2str, xt, 'UniformOutput', false);
xt_lin  = unique(round(linspace(1, n, 6)));          xtl_lin  = arrayfun(@num2str, xt_lin, 'UniformOutput', false);

% ===== 1×4 Facet 布局 =====
fig = figure('Color',[1 1 1 1]);
try
    set(fig,'WindowState','maximized');
catch
    set(fig,'Position',[90 90 1200 420]);  % 兼容老版本
end
set(fig,'DefaultAxesFontName',FONT,'DefaultTextFontName',FONT);
tiledlayout(2,2,'Padding','compact','TileSpacing','compact');

% a) Degree — loglog
ax = nexttile;
h = loglog(x, ds, '-', 'Color', COLORS(1,:), 'LineWidth', LW); uistack(h,'top');
facetAxes(ax, [1 n], xt, xtl, SHOW_GRID, GRID_COLOR, FONT);
ylabel(ax,'Degree','FontName',FONT);
drawFacetStrip_anno(fig, ax, 'Degree', 'Rank', ...
    STRIP_COLOR, STRIP_TITLE_COL, STRIP_SUB_COL, FONT, STRIP_TITLE_FS, STRIP_SUB_FS);
placePanelLabel(ax,'a',FONT,PANEL_LABEL_FS,PANEL_LABEL_COL);

% b) Betweenness — loglog
ax = nexttile;
h = loglog(x, bs, '-', 'Color', COLORS(2,:), 'LineWidth', LW); uistack(h,'top');
facetAxes(ax, [1 n], xt, xtl, SHOW_GRID, GRID_COLOR, FONT);
ylabel(ax,'Betweenness','FontName',FONT);
drawFacetStrip_anno(fig, ax, 'Betweenness', 'Rank', ...
    STRIP_COLOR, STRIP_TITLE_COL, STRIP_SUB_COL, FONT, STRIP_TITLE_FS, STRIP_SUB_FS);
placePanelLabel(ax,'b',FONT,PANEL_LABEL_FS,PANEL_LABEL_COL);

% c) Closeness — linear（固定 ×10^2）
ax = nexttile;
h = plot(x, cs, '-', 'Color', COLORS(3,:), 'LineWidth', LW); uistack(h,'top');
facetAxes(ax, [1 n], xt_lin, xtl_lin, SHOW_GRID, GRID_COLOR, FONT);
ylabel(ax,'Closeness','FontName',FONT);
try
    ax.YRuler.ExponentMode = 'manual'; ax.YRuler.Exponent = 2;
catch
    ax.YAxis.Exponent = 2;
end
drawFacetStrip_anno(fig, ax, 'Closeness', 'Rank', ...
    STRIP_COLOR, STRIP_TITLE_COL, STRIP_SUB_COL, FONT, STRIP_TITLE_FS, STRIP_SUB_FS);
placePanelLabel(ax,'c',FONT,PANEL_LABEL_FS,PANEL_LABEL_COL);

% d) Clustering — linear
ax = nexttile;
h = plot(x, ccs, '-', 'Color', COLORS(4,:), 'LineWidth', LW); uistack(h,'top');
facetAxes(ax, [1 n], xt_lin, xtl_lin, SHOW_GRID, GRID_COLOR, FONT);
ylabel(ax,'Clustering coefficient','FontName',FONT);
drawFacetStrip_anno(fig, ax, 'Clustering', 'Rank', ...
    STRIP_COLOR, STRIP_TITLE_COL, STRIP_SUB_COL, FONT, STRIP_TITLE_FS, STRIP_SUB_FS);
placePanelLabel(ax,'d',FONT,PANEL_LABEL_FS,PANEL_LABEL_COL);

