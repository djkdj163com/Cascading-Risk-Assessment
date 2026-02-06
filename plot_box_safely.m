function plot_box_safely(M, ttl, yl, labels)
% 只对“非全 NaN 的列”作箱线图；对全 NaN 列提示“无有效样本”
col_ok = ~all(isnan(M),1);
if ~any(col_ok)
    boxplot(NaN(1,1)); ylim([0 1]); grid on;
    title(ttl); ylabel(yl);
    text(0.5,0.5,'无有效样本','Units','normalized','HorizontalAlignment','center');
    return;
end
M2 = M(:, col_ok);
boxplot(M2); grid on;
set(gca,'XTickLabel',cellstr(labels(col_ok)));
ylabel(yl); title(ttl);
end