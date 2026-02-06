function SENS = run_sensitivity_cascade()
% 目的：对关键参数做敏感性实验，只输出 5 张关键图（RESS 风格）
% 依赖：simulate_dynamic_cascade_final.m（当前工程中的版本）
% 图集：
%   1) 过载幂指数 β 的箱线图
%   2) 风致降额 γ 的箱线图
%   3) 需求侧减载比例 的箱线图
%   4) 流量模型对比（DC vs 最短路）箱线图
%   5) 带宽图（无/有减载 0.20 的 10–90% 分位带 + 均值）

% ====== 0) 保存开关 ======
saveFigures = false;
outDir      = "figs_sensitivity";
imgFormats  = {".png",".pdf",".svg"};

% ====== 1) 数据与“压力基线”（给敏感性留出空间） ======
node_csv = 'tower_failure_probabilities.csv';
edge_csv = 'system_failure_probabilities.csv';

% —— 压力/可变性基线（和主流程一致，但更“严”且开启随机初损）——
base = struct( ...
    'MaxSteps',           60, ...
    'FlowModel',          'dc', ...
    'Beta',               6, ...
    'GammaWind',          1.0, ...
    'LenEta',             0.2, ...
    'ReduceThreshold',    0.04, ...
    'DemandCut',          0.05, ...
    'Verbose',            false, ...
    'SourceMinKV',        500, ...     % 只将 ≥500kV(含10000) 当源
    'TripMargin',         1.02, ...    % 轻微超载即可触发
    'RandomTrip',         false, ...   % 仅过载触发；保留可解释性
    'DeterministicNodes', false, ...   % ★ 让初损按 CSV 概率抽样（引入seed差异）
    'NodeFailThresh',     0.35, ...    % 占位（未用）
    'DeterministicEdges', false, ...
    'EdgeFailThresh',     0.10, ...    % 占位（未用）
    'CapCalibK',          1.9, ...
    'CapFloorFrac',       0.25, ...
    'DoubleCircuit',      true, ...
    'UseStationCouplers', true, ...
    'StationTol',         60, ...
    'StationCapMult',     10, ...
    'MaxCoupleEachLow',   1 ...
    );

% 单因素集合（围绕基线做对比）
Beta_set   = [1, 10, 15];
Gamma_set  = [0.5, 1.0, 1.5];
Cut_set    = [0.00, 0.25, 0.50, 0.75];
Model_set  = {'dc','shortest'};

% 采样次数（种子）
Nseed = 48;
Seeds = 1000 + (1:Nseed);

% ====== 2) 结果容器 ======
SENS = struct();
clear labels outliers %#ok<NASGU>

% ====== 3) β（\beta） ======
resBeta = nan(Nseed, numel(Beta_set));
for j = 1:numel(Beta_set)
    par = struct('Beta', Beta_set(j));
    for i = 1:Nseed
        out = call_sim(node_csv, edge_csv, Seeds(i), base, par);
        resBeta(i,j) = safe_final_loss(out);
    end
end
SENS.beta = resBeta;

% ====== 4) γ（\gamma） ======
resGamma = nan(Nseed, numel(Gamma_set));
for j = 1:numel(Gamma_set)
    par = struct('GammaWind', Gamma_set(j));
    for i = 1:Nseed
        out = call_sim(node_csv, edge_csv, Seeds(i), base, par);
        resGamma(i,j) = safe_final_loss(out);
    end
end
SENS.gamma = resGamma;

% ====== 5) DemandCut（减载比例） ======
resCut = nan(Nseed, numel(Cut_set));
for j = 1:numel(Cut_set)
    par = struct('DemandCut', Cut_set(j));
    for i = 1:Nseed
        out = call_sim(node_csv, edge_csv, Seeds(i), base, par);
        resCut(i,j) = safe_final_loss(out);
    end
end
SENS.cut = resCut;

% ====== 6) 模型对比（DC vs 最短路） ======
resModel = nan(Nseed, numel(Model_set));
for j = 1:numel(Model_set)
    par = struct('FlowModel', Model_set{j});
    for i = 1:Nseed
        out = call_sim(node_csv, edge_csv, Seeds(i), base, par);
        resModel(i,j) = safe_final_loss(out);
    end
end
SENS.model = resModel;

% ====== 7) 带宽图（无减载 vs 有减载 0.20） ======
Tmax  = base.MaxSteps;
trajA = nan(Nseed, Tmax+1);  % 无减载
trajB = nan(Nseed, Tmax+1);  % 有减载
for i = 1:Nseed
    outA = call_sim(node_csv, edge_csv, Seeds(i), base, struct('DemandCut', 0.00));
    outB = call_sim(node_csv, edge_csv, Seeds(i), base, struct('DemandCut', 0.20));
    trajA(i,:) = pad_traj(get_lost_series(outA), Tmax+1);
    trajB(i,:) = pad_traj(get_lost_series(outB), Tmax+1);
end

% 10–90% 分位带
[q10A, q90A] = quantile_nan(trajA, [0.10, 0.90]);
[q10B, q90B] = quantile_nan(trajB, [0.10, 0.90]);

% 计算均值与差值做检查
muA = nanmean(trajA,1);          % 无减载均值
muB = nanmean(trajB,1);          % 有减载均值
finalDiff = muB(end) - muA(end);
maxDiff   = max(abs(muB - muA));
fprintf('[带宽图检查] 终值差 = %.4f, 全程最大差 = %.4f\n', finalDiff, maxDiff);

SENS.trajA = trajA; 
SENS.trajB = trajB;
SENS.muA = muA;
SENS.muB = muB;
SENS.q10A = q10A; SENS.q90A = q90A;
SENS.q10B = q10B; SENS.q90B = q90B;


% ====== 8) 统一绘图（仅 5 张） ======
if saveFigures && ~exist(outDir,'dir'), mkdir(outDir); end

% 图1：β
fig1 = figure('Color','w'); boxplot(resBeta); grid on;
xticklabels(cellstr("β="+string(Beta_set))); ylim([0 1]);
ylabel('最终失供比例'); title('敏感性：过载幂指数 β');
save_if_needed(fig1, outDir, "box_beta", imgFormats, saveFigures);

% 图2：γ
fig2 = figure('Color','w'); boxplot(resGamma); grid on;
xticklabels(cellstr("\gamma="+string(Gamma_set))); ylim([0 1]);
ylabel('最终失供比例'); title('敏感性：风致降额系数 \gamma');
save_if_needed(fig2, outDir, "box_gamma", imgFormats, saveFigures);

% 图3：减载
fig3 = figure('Color','w'); boxplot(resCut); grid on;
xticklabels(cellstr("减载="+string(Cut_set))); ylim([0 1]);
ylabel('最终失供比例'); title('敏感性：需求侧减载比例');
save_if_needed(fig3, outDir, "box_cut", imgFormats, saveFigures);

% 图4：模型
fig4 = figure('Color','w'); boxplot(resModel); grid on;
xticklabels({'DC/PTDF','最短路'}); ylim([0 1]);
ylabel('最终失供比例'); title('流量重分配模型对比');
save_if_needed(fig4, outDir, "box_model", imgFormats, saveFigures);

% 图5：带宽（分位带）
t = 0:Tmax;
fig5 = figure('Color','w'); hold on;
fill_band(t, q10A, q90A, [0.35 0.60 1.00], 0.35);   % 无减载带（浅）
fill_band(t, q10B, q90B, [0.50 0.30 1.00], 0.50);   % 有减载带（深）
plot(t, nanmean(trajA,1), 'LineWidth', 1.8);
plot(t, nanmean(trajB,1), 'LineWidth', 1.8);
grid on; xlabel('步数'); ylabel('失供负荷比例'); ylim([0 1]);
legend({'无减载 10–90%','有减载 10–90%','无减载均值','有减载均值'}, 'Location','southeast');
title('需求侧减载对级联演化的缓解效应（分位带图）');
hold off;
save_if_needed(fig5, outDir, "bandwidth_DR", imgFormats, saveFigures);

disp('敏感性实验完成（仅输出 5 张关键图）。');
end
