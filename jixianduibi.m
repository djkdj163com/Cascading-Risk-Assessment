%% ========== 3) 画左右镜像堆叠条形图（加大中间间距） ==========
fig = figure('Color','w','Units','centimeters','Position',[2 2 24 14]);

% 关键：中间留更大空隙（label channel）
% 原来大概是 [0.08 0.12 0.40 0.80] 和 [0.52 0.12 0.40 0.80]
% 现在改成：左右各缩一点，中间 gap 变宽
axL = axes('Parent',fig,'Units','normalized','Position',[0.07 0.12 0.38 0.80]); % left
axR = axes('Parent',fig,'Units','normalized','Position',[0.55 0.12 0.38 0.80]); % right
% 中间 gap = 0.55 - (0.07+0.38) = 0.10（比之前约 0.04 大很多）

% ---- Left: Loss_you（向左）----
hold(axL,'on');
BLY = barh(axL, y, [Tplot.marine_you, Tplot.fresh_you], 'stacked', 'BarWidth', BW);
BLY(1).FaceColor = marineColor;  BLY(2).FaceColor = freshColor;
[BLY.EdgeColor]  = deal(edgeCol);
[BLY.LineWidth]  = deal(0.6);

axL.XDir = 'reverse';
axL.YDir = 'reverse';
xlim(axL, [0 xMax]);
ylim(axL, [0.5 n+0.5]);

axL.YTick = y;
axL.YTickLabel = cellstr(Tplot.county_name);
axL.YAxisLocation = 'right';       % 县名在中间
axL.TickDir = 'out';
axL.TickLength = [0.008 0.008];    % 让 tick 不要太长、避免压到文字
axL.Box = 'off';
axL.LineWidth = 1.1;
axL.FontName = FONT; axL.FontSize = 11;   % 字稍微大一点也更清晰

% 左轴刻度显示为正数
xt = axL.XTick;
axL.XTickLabel = arrayfun(@(v) sprintf('%.0f', v), xt, 'UniformOutput', false);

% 左侧中线（x=0 在右边界）
plot(axL, [0 0], [0.5 n+0.5], '-', 'Color', centerCol, 'LineWidth', 1.0);
title(axL, 'Loss\_you', 'FontName', FONT, 'FontWeight','bold');

% ---- Right: Loss_wu（向右）----
hold(axR,'on');
BRW = barh(axR, y, [Tplot.marine_wu, Tplot.fresh_wu], 'stacked', 'BarWidth', BW);
BRW(1).FaceColor = marineColor;  BRW(2).FaceColor = freshColor;
[BRW.EdgeColor]  = deal(edgeCol);
[BRW.LineWidth]  = deal(0.6);

axR.YDir = 'reverse';
xlim(axR, [0 xMax]);
ylim(axR, [0.5 n+0.5]);

axR.YTick = y;
axR.YTickLabel = [];              % 右边不重复显示县名
axR.TickDir = 'out';
axR.TickLength = [0.008 0.008];
axR.Box = 'off';
axR.LineWidth = 1.1;
axR.FontName = FONT; axR.FontSize = 11;

% 右侧中线（x=0 在左边界）
plot(axR, [0 0], [0.5 n+0.5], '-', 'Color', centerCol, 'LineWidth', 1.0);
title(axR, 'Loss\_wu', 'FontName', FONT, 'FontWeight','bold');

xlabel(axL, 'Economic loss (unit)', 'FontName', FONT);
xlabel(axR, 'Economic loss (unit)', 'FontName', FONT);

lg = legend(axR, [BRW(1), BRW(2)], {'Marine','Freshwater'}, ...
    'Location','southwest','Box','off');
lg.FontName = FONT; lg.FontSize = 11;
