%% ============================================================
%  Sensitivity compact (nodes only; 3 panels in one figure)
%  依赖：simulate_dynamic_cascade_final.m（无需改动）
%  输出：crit41_out/sensitivity_nodes_compact.(png|pdf)
%% ============================================================

%% ---------- 基本配置 ----------
node_csv = 'tower_failure_probabilities.csv';
edge_csv = 'system_failure_probabilities.csv';

% 与论文一致的基线参数（可按需微调）
BASE = { ...
  'FlowModel','dc', 'Seed',2025, 'MaxSteps',60, ...
  'Beta',6, 'TripMargin',1.15, 'RandomTrip',false, ...
  'GammaWind',1.0, 'LenEta',0.2, ...
  'ReduceThreshold',0.06, 'DemandCut',0.03, ...
  'DeterministicNodes',true, 'NodeFailThresh',0.20, ...
  'DeterministicEdges',true, 'EdgeFailThresh',0.10, ...
  'CapCalibK',2.4, 'CapFloorFrac',0.40, ...
  'DoubleCircuit',true, 'UseStationCouplers',true, ...
  'StationTol',60, 'StationCapMult',10, 'MaxCoupleEachLow',1, ...
  'SourceMinKV',500, 'Verbose',false };

outdir = 'crit41_out';
if ~exist(outdir,'dir'), mkdir(outdir); end

% SCI 风格
set(groot,'defaultAxesFontName','Times New Roman');
set(groot,'defaultTextFontName','Times New Roman');
set(groot,'defaultAxesFontSize',9);
set(groot,'defaultTextFontSize',9);

% 颜色
col_init = [0.05 0.08 0.18];   % 初始：深黑蓝
col_casc = [0.86 0.39 0.20];   % 级联：橙

%% ---------- 仅扫 3 个“有代表性”的参数（节点视角） ----------
X_NodeFailThresh = [0.10 0.20 0.30 0.40 0.50];
X_TripMargin     = [1.02 1.10 1.20 1.30];
X_CapCalibK      = [2.0 2.4 3.0 3.6];

% 逐参扫描并得到：x、n_init、n_casc、n_final（节点）
S1 = sweep_nodes(node_csv, edge_csv, BASE, 'NodeFailThresh', X_NodeFailThresh);
S2 = sweep_nodes(node_csv, edge_csv, BASE, 'TripMargin',     X_TripMargin);
S3 = sweep_nodes(node_csv, edge_csv, BASE, 'CapCalibK',      X_CapCalibK);

%% ---------- 单图三面板（上排两幅：TM & K；下排跨两列：NFT） ----------
fig = figure('Color','w','Units','centimeters','Position',[2 2 16 12]);
t = tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');

% (1) TripMargin — nodes（上左）
ax1 = nexttile(1); hold(ax1,'on');
h1a = plot(ax1, S2.x, S2.n_init,'-o','Color',col_init,'MarkerFaceColor',col_init,'LineWidth',1.8,'MarkerSize',5);
h1b = plot(ax1, S2.x, S2.n_casc,'-s','Color',col_casc,'MarkerFaceColor',col_casc,'LineWidth',1.8,'MarkerSize',5);
format_axes(ax1); set(ax1,'Layer','top'); uistack([h1a h1b],'top');
xlabel(ax1,'Trip Margin F/C'); ylabel(ax1,'Number of Failed Nodes');
lg1 = legend(ax1,{'Cascading Failures','Initial Failures'},'Location','northeast');
set(lg1,'Box','on','LineWidth',0.75);

% (2) CapCalibK — nodes（上右）
ax2 = nexttile(2); hold(ax2,'on');
h2a = plot(ax2, S3.x, S3.n_init,'-o','Color',col_init,'MarkerFaceColor',col_init,'LineWidth',1.8,'MarkerSize',5);
h2b = plot(ax2, S3.x, S3.n_casc,'-s','Color',col_casc,'MarkerFaceColor',col_casc,'LineWidth',1.8,'MarkerSize',5);
format_axes(ax2); set(ax2,'Layer','top'); uistack([h2a h2b],'top');
xlabel(ax2,'Capacity scaling K'); ylabel(ax2,'Number of Failed Nodes');
lg2 = legend(ax2,{'Cascading Failures','Initial Failures'},'Location','northeast');
set(lg2,'Box','on','LineWidth',0.75);

% (3) NodeFailThresh — nodes（下排跨两列）
ax3 = nexttile(3,[1 2]); hold(ax3,'on');
h3a = plot(ax3, S1.x, S1.n_init,'-o','Color',col_init,'MarkerFaceColor',col_init,'LineWidth',1.8,'MarkerSize',5);
h3b = plot(ax3, S1.x, S1.n_casc,'-s','Color',col_casc,'MarkerFaceColor',col_casc,'LineWidth',1.8,'MarkerSize',5);
format_axes(ax3); set(ax3,'Layer','top'); uistack([h3a h3b],'top');
xlabel(ax3,'Failure Probability Threshold'); ylabel(ax3,'Number of Failed Nodes');
lg3 = legend(ax3,{'Cascading Failures','Initial Failures'},'Location','northeast');
set(lg3,'Box','on','LineWidth',0.75);

% —— 统一 y 轴上限（便于对比） —— %
Ymax = max([ylim(ax1), ylim(ax2), ylim(ax3)]);
ylim(ax1,[0 Ymax]); ylim(ax2,[0 Ymax]); ylim(ax3,[0 Ymax]);

% 高分辨率导出
exportgraphics(fig, fullfile(outdir,'sensitivity_nodes_compact.png'), 'Resolution',1200);
exportgraphics(fig, fullfile(outdir,'sensitivity_nodes_compact.pdf'));

disp('已输出：crit41_out/sensitivity_nodes_compact.(png|pdf)');
