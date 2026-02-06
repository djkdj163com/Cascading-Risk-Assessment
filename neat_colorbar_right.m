function cb = neat_colorbar_right(ax, labelstr, ticks, ticklabels)
% 把竖直色条放到轴外：细、不遮挡；同时略缩窄轴宽度为色条预留沟槽
    ax.Units = 'normalized';
    p = ax.Position;
    gutter = 0.035;                    % 预留色条的沟槽宽度（可按需微调）
    p(3) = max(p(3) - gutter, 0.1);    % 缩窄轴宽，为色条腾出空间
    ax.Position = p;

    cb = colorbar(ax, 'Location','eastoutside');
    cb.Units = 'normalized';
    cb.Label.String = labelstr;
    % 色条更细、更靠外（与轴对齐）
    cb.Position(1) = ax.Position(1) + ax.Position(3) + 0.006;
    cb.Position(3) = gutter * 0.45;
    cb.Position(2) = ax.Position(2) + ax.Position(4)*0.1;  % 上下各留白 10%
    cb.Position(4) = ax.Position(4) * 0.8;

    if ~isempty(ticks), cb.Ticks = ticks; end
    if ~isempty(ticklabels), cb.TickLabels = ticklabels; end
end