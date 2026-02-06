%% County subplots with dual Y-axes — adaptive scales, no grid
clear; clc;

% 如中文显示为方块，可启用下一行设置支持中文的字体（例如 Windows 上的黑体/雅黑）
% set(groot,'defaultAxesFontName','SimHei');

counties = {'Lu Cheng','Long Wan','Ou Hai','Dong Tou','Rui An','Yue Qing', ...
            'Long Gang','Yong Jia','Ping Yang','Cang Nan','Wen Cheng','Tai Shun'};

% 数据（缺失值已按你的要求置为 0）
% 海水
hs_output = [0, 6159, 0, 180081, 218047, 132273, 95177, 0, 138028, 269170, 0, 0];   % 万元
hs_area   = [0, 2841, 0, 88541,  56109,  132273, 28934, 0, 35433,  64536,  0, 0];   % 公顷
% 淡水
fs_output = [1494, 461, 1169, 0, 37356, 8165, 409, 12615, 20512, 1624, 2867, 1495]; % 万元
fs_area   = [783,  461, 1169, 0, 18798, 7144, 314, 6987,  7185,  1432, 1669, 1369]; % 公顷

assert(numel(counties)==numel(hs_output) && numel(hs_output)==numel(fs_output), ...
       'Vector lengths mismatch.');

% 颜色（可按需调整）
col_left  = [0.00 0.45 0.74];  % 左轴：产值
col_right = [0.85 0.33 0.10];  % 右轴：产量（公顷）

figure('Color','w');
tl = tiledlayout(3,4,'TileSpacing','compact','Padding','compact');
sgtitle('County-level Marine vs Freshwater (Dual Y-axes)');

for i = 1:numel(counties)
    ax = nexttile; hold on; box off;

    x = [1 2];  % 1=海水, 2=淡水
    xticks(x); xticklabels({'Marine','Freshwater'});
    xlim([0.8 2.2]);

    % 左Y轴：产值（万元）
    yyaxis left;
    y_left = [hs_output(i), fs_output(i)];
    h1 = plot(x, y_left, '-o', 'MarkerSize',5, ...
        'Color', col_left, 'MarkerFaceColor', col_left);
    ylabel('Output Value (10k CNY)');
    ax.YAxis(1).Color = col_left;
    ax.YAxis(1).Exponent = 0;     % 避免科学计数法
    grid(ax,'off');               % 关闭网格

    % 右Y轴：产量（公顷）
    yyaxis right;
    y_right = [hs_area(i), fs_area(i)];
    h2 = plot(x, y_right, '--s', 'MarkerSize',5, ...
        'Color', col_right, 'MarkerFaceColor', col_right);
    ylabel('Area (ha)');
    ax.YAxis(2).Color = col_right;
    ax.YAxis(2).Exponent = 0;
    grid(ax,'off');               % 关闭网格

    title(counties{i}, 'FontWeight','normal');
end

% 只在第一个子图放图例
axes(tl.Children(end));
legend({'Output Value','Yield (ha)'}, 'Location','northwest', 'Box','off');
