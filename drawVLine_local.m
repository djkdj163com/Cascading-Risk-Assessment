function drawVLine_local(ax, x0, col, lw, ls)
    try
        xline(ax, x0, ls, 'Color', col, 'LineWidth', lw, 'HandleVisibility','off');
    catch
        yl = ax.YLim;
        line(ax, [x0 x0], yl, 'Color', col, 'LineStyle', ls, 'LineWidth', lw, 'HandleVisibility','off');
    end
end