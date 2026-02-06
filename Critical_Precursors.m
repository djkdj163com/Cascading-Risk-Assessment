% plot_cascade_timeseries_3panel_style_refPalette_looserAB_outerLabels.m
% Fig.4 layout: top-left (a), top-right (b), bottom spanning (c)
% Style: reference-like blue/red + soft grid; a/b/c labels OUTSIDE the axes

%% sanity check
assert(exist('out','var')==1 && isfield(out,'steps'), 'Run the simulation first to get out.steps.');
G0 = out.G0; m = numedges(G0); n = numnodes(G0);
T  = numel(out.steps); t = 1:T;

%% series
lost = arrayfun(@(s) s.lostLoadFrac, out.steps);                 % lostLoadFrac(t)
aliveEdgesFrac = arrayfun(@(s) sum(s.edgeAlive)/m, out.steps);   % aliveEdges(t)

aliveCounts = arrayfun(@(s) sum(s.edgeAlive), out.steps);
DeltaE = zeros(1,T);
DeltaE(1) = max(0, m - aliveCounts(1));
if T>=2, DeltaE(2:T) = max(0, aliveCounts(1:T-1)-aliveCounts(2:T)); end

% reproduction number: defined from step 2 onward
Rc = nan(1,T);
if T>=2
    Rc(2:end) = DeltaE(2:end) ./ max(DeltaE(1:end-1), 1);
end

% largest connected component fraction (by original n)
LCCfrac = zeros(1,T);
ends = G0.Edges.EndNodes;
for k = 1:T
    na = out.steps(k).nodeAlive(:);
    ea = out.steps(k).edgeAlive(:);
    keep = ea & na(ends(:,1)) & na(ends(:,2));
    if ~any(na) || ~any(keep)
        LCCfrac(k) = 0;
    else
        Gt = graph(ends(keep,1), ends(keep,2), [], n);
        Gt = subgraph(Gt, find(na));
        comps = conncomp(Gt);
        cnts  = accumarray(comps(:),1);
        LCCfrac(k) = max(cnts)/n;
    end
end

%% ===== style (match your reference palette) =====
FONT = 'Times New Roman';

% reference-like blue/red + neutral grays
C_BLUE   = [ 68 114 196]/255;   % muted blue
C_RED    = [220  85  90]/255;   % muted red/salmon
C_GRAY   = [0.25 0.25 0.28];
C_GRID   = [0.90 0.90 0.92];
C_REF    = [0.55 0.55 0.60];

LW   = 2.0;
AXLW = 1.2;
MS   = 5;
SHOW_GRID = true;

mkStep = max(1, round(T/12));
mkIdx  = 1:mkStep:T;

%% plotting
fig = figure('Color','w');
try, set(fig,'WindowState','maximized'); catch, set(fig,'Position',[80 80 1200 700]); end
set(fig,'DefaultAxesFontName',FONT,'DefaultTextFontName',FONT);

tl = tiledlayout(fig,2,2,'Padding','loose','TileSpacing','loose');

% label OUTSIDE: use annotation in figure-normalized coords (robust)
addPanelLabel = @(fig, ax, ch) addPanelLabel_anno(fig, ax, ch, FONT);

applyAxesStyle = @(ax) set(ax,'FontName',FONT,'TickDir','out','LineWidth',AXLW,'Layer','top','Box','on');
applyGridStyle = @(ax) setGrid_local(ax, SHOW_GRID, C_GRID);

%% ---- (a) top-left: lostLoadFrac & aliveEdges ----
ax1 = nexttile(tl,1); hold(ax1,'on');
applyAxesStyle(ax1); applyGridStyle(ax1);

yyaxis(ax1,'left');
p1 = plot(ax1, t, lost, '-', 'Color', C_RED, 'LineWidth', LW, ...
    'Marker','o','MarkerSize',MS,'MarkerIndices',mkIdx,'MarkerFaceColor','w');
ylabel(ax1,'Lost-load fraction','FontName',FONT);
ax1.YAxis(1).Color = C_RED;

yyaxis(ax1,'right');
p2 = plot(ax1, t, aliveEdgesFrac, '-', 'Color', C_BLUE, 'LineWidth', LW, ...
    'Marker','s','MarkerSize',MS,'MarkerIndices',mkIdx,'MarkerFaceColor','w');
ylabel(ax1,'Alive-edges fraction','FontName',FONT);
ax1.YAxis(2).Color = C_BLUE;

xlabel(ax1,'t','FontName',FONT);
title(ax1,'Cascade response','FontName',FONT,'FontWeight','bold');
ax1.Title.Units = 'normalized'; ax1.Title.Position(2) = 1.02;

lg1 = legend(ax1,[p1 p2],{'Lost-load fraction','Alive-edges fraction'}, ...
    'Location','northoutside','Orientation','horizontal','Box','off','FontName',FONT);
try, lg1.ItemTokenSize = [12 8]; catch, end

addPanelLabel(fig, ax1, 'a');

%% ---- (b) top-right: LCC fraction ----
ax2 = nexttile(tl,2); hold(ax2,'on');
applyAxesStyle(ax2); applyGridStyle(ax2);

plot(ax2, t, LCCfrac, '-', 'Color', C_GRAY, 'LineWidth', LW, ...
    'Marker','o','MarkerSize',MS,'MarkerIndices',mkIdx,'MarkerFaceColor','w');
xlabel(ax2,'t','FontName',FONT);
ylabel(ax2,'Largest connected component (node share)','FontName',FONT);
title(ax2,'Connectivity','FontName',FONT,'FontWeight','bold');
ax2.Title.Units = 'normalized'; ax2.Title.Position(2) = 1.02;

addPanelLabel(fig, ax2, 'b');

%% ---- (c) bottom spanning: DeltaE & Rc ----
ax3 = nexttile(tl,3,[1 2]); hold(ax3,'on');
applyAxesStyle(ax3); applyGridStyle(ax3);

yyaxis(ax3,'left');
b = stairs(ax3, t, DeltaE, '-', 'Color', C_BLUE, 'LineWidth', LW);
ylabel(ax3,'\DeltaE(t): new tripped edges','FontName',FONT);
ax3.YAxis(1).Color = C_BLUE;

yyaxis(ax3,'right');
r = plot(ax3, t, Rc, '-', 'Color', C_RED, 'LineWidth', LW, ...
    'Marker','s','MarkerSize',MS,'MarkerIndices',mkIdx,'MarkerFaceColor','w');
ylabel(ax3,'R_c(t)','FontName',FONT);
ax3.YAxis(2).Color = C_RED;

yline(ax3, 1, '--', 'R_c=1', 'Color', C_REF, 'LineWidth', 1.0, ...
    'LabelHorizontalAlignment','left','LabelVerticalAlignment','middle', ...
    'FontName',FONT);

% highlight Rc>1 intervals
yyaxis(ax3,'left');
ax3.SortMethod = 'depth';
yl = ylim(ax3);

grow = false(1,T);
if T>=2
    grow(2:end) = (DeltaE(1:end-1) > 0) & (Rc(2:end) > 1);
end
edgesLR = diff([false, grow, false]);
starts  = find(edgesLR == 1);
endsIx  = find(edgesLR == -1) - 1;

for i = 1:numel(starts)
    xs = [t(starts(i)) , t(endsIx(i)) + 1];
    ph = patch('Parent',ax3, ...
        'XData',[xs(1) xs(2) xs(2) xs(1)], ...
        'YData',[yl(1) yl(1) yl(2) yl(2)], ...
        'FaceColor', C_RED, 'FaceAlpha',0.08, 'EdgeColor','none', ...
        'HitTest','off','PickableParts','none','HandleVisibility','off');
    set(ph,'ZData',[-1 -1 -1 -1]);
end

xlabel(ax3,'t','FontName',FONT);
title(ax3,'Propagation intensity','FontName',FONT,'FontWeight','bold');

legend(ax3,[b r],{'\DeltaE(t)','R_c(t)'}, ...
    'Location','northwest','Box','off','FontName',FONT);

addPanelLabel(fig, ax3, 'c');

% optional export
% exportgraphics(gcf,'figure4_timeseries_style_refPalette_outerLabels.png','Resolution',300);

axs = findall(gcf,'Type','axes');
for k = 1:numel(axs)
    grid(axs(k),'off');
    axs(k).XMinorGrid = 'off';
    axs(k).YMinorGrid = 'off';
end

