% ======== 绘图：初损（共享） + 各模型 final（更像参考图风格）========
PALETTE = [237 173 197; 206 170 208; 146 132 193; 108 190 195; 170 215 200; 97 156 217]/255;

COL_INIT = PALETTE(6,:);              % Initial(shared) 统一色
c_real = [0.20 0.20 0.22];
c_er   = PALETTE(3,:);
c_ba   = PALETTE(1,:);
c_cfg  = PALETTE(4,:);
c_geo  = PALETTE(2,:);
c_sw   = PALETTE(5,:);

LW = 2.0; MS = 6; AXLW = 0.9;
GRID_COL = [0.85 0.85 0.88];

figA = figure('Color','w','Units','centimeters','Position',[2 2 18 10]);
axA  = axes('Parent',figA); hold(axA,'on');

% —— 先确定 y 范围（用于背景底色）——
Ymax = max([init_shared(:); finalN(:); finalN_sw(:)]) * 1.05;
ylim(axA, [0 Ymax]);
xlim(axA, [min(X) max(X)]);

% —— 像参考图那样：给关键阈值区间加淡色底（不进图例）——
% 0.10-0.20, 0.20-0.30, 0.30-0.50 三段（你可以按需改）
% —— 背景底色：0–0.2 深一些；0.2–0.3 浅一些；0.3–0.5 很浅 —— 
addBand(axA, 0.10, 0.20, [1.00 0.80 0.80], 0.55);  % 0–0.2：更深红
addBand(axA, 0.20, 0.30, [1.00 0.92 0.92], 0.35);  % 0.2–0.3：更浅红
addBand(axA, 0.30, 0.50, [1.00 0.97 0.97], 0.20);  % 0.3 以后：很浅


% —— 画参考竖线（更像示例：细、虚线）——
for xv = [0.20 0.30]
    xline(axA, xv, '--', 'Color',[0.25 0.25 0.28], 'LineWidth',1.2, 'HandleVisibility','off');
end

% —— Initial(shared)：实心圆点 —— 
p0 = plot(axA, X, init_shared, '-o', ...
    'Color',COL_INIT,'MarkerFaceColor',COL_INIT,'MarkerEdgeColor',COL_INIT, ...
    'LineWidth',LW,'MarkerSize',MS,'DisplayName','Initial (shared)');

% —— 各模型 final：虚线 + 实心方块（每条不同色）——
models = {'Real','ER','BA','Degree-preserving','Geo-shuffle'};
COL = {c_real,c_er,c_ba,c_cfg,c_geo};

P = gobjects(numel(models),1);
for mi = 1:numel(models)
    P(mi) = plot(axA, X, finalN(mi,:), '--s', ...
        'Color',COL{mi}, 'MarkerFaceColor',COL{mi}, 'MarkerEdgeColor',COL{mi}, ...
        'LineWidth',LW,'MarkerSize',MS, ...
        'DisplayName',[models{mi} ' – final']);
end

% —— Small-world final：虚线 + 实心菱形 —— 
p_sw = plot(axA, X, finalN_sw, '--d', ...
    'Color',c_sw,'MarkerFaceColor',c_sw,'MarkerEdgeColor',c_sw, ...
    'LineWidth',LW,'MarkerSize',MS,'DisplayName','Small-world – final');

% —— 轴风格：淡网格、轻轴线、刻度朝外（接近参考图）——
xlabel(axA,'Failure Probability Threshold');
ylabel(axA,'Number of Failed Nodes');

set(axA,'TickDir','out','Box','on','LineWidth',AXLW,'Layer','top', ...
    'FontName','Times New Roman','FontSize',10);

grid(axA,'on');
axA.GridColor = GRID_COL;
axA.GridAlpha = 0.35;
axA.XMinorGrid = 'off'; axA.YMinorGrid = 'off';

% —— 面板标注：放在图内右下角，像你参考图 “a) …” 那样 ——
text(axA, 0.97, 0.06, 'a) Threshold robustness', ...
    'Units','normalized','HorizontalAlignment','right','VerticalAlignment','bottom', ...
    'FontName','Times New Roman','FontSize',11,'Color',[0.20 0.20 0.22]);

% —— legend：外侧、无边框 —— 
lg = legend(axA, [p0; P; p_sw], 'Location','eastoutside', 'Box','off');
lg.FontName = 'Times New Roman'; lg.FontSize = 9;

exportgraphics(figA, fullfile(outdir,'Fig42A_threshold_compare_sw.png'), 'Resolution',1200);
exportgraphics(figA, fullfile(outdir,'Fig42A_threshold_compare_sw.pdf'));

