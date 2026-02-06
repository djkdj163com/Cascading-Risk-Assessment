function draw_sig_vlines(ax)
% 在坐标轴 ax 上画两条竖直点线（x=0.20 与 0.30），
% 黑色，端点为实心黑圆点，并在下端点右侧标注“***”。不进入图例。
    if nargin<1, ax = gca; end
    hold(ax,'on');
    xl = xlim(ax); yl = ylim(ax); %#ok<NASGU>
    y1 = yl(1) + 0.45*diff(yl);   % 下端
    y2 = yl(1) + 0.88*diff(yl);   % 上端
    col = [0.10 0.10 0.10];

    for xv = [0.20 0.30]
        % 主体：黑色点线
        plot(ax, [xv xv], [y1 y2], ':', ...
            'Color',col, 'LineWidth',1.6, 'HandleVisibility','off');
        % 两端实心黑圆点
        plot(ax, [xv xv], [y1 y2], 'o', ...
            'MarkerFaceColor',col, 'MarkerEdgeColor',col, ...
            'MarkerSize',5, 'LineStyle','none', 'HandleVisibility','off');
        % “***” 标注
        text(ax, xv+0.008, y1-0.03*diff(ylim(ax)), '***', ...
            'FontName','Times New Roman','FontWeight','bold', ...
            'Color',col, 'HorizontalAlignment','left', ...
            'VerticalAlignment','middle', 'Clipping','on');
    end
end
