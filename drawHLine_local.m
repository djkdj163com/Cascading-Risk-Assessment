function drawHLine_local(ax, y0, col, lw, ls)
    try
        yline(ax, y0, ls, 'Color', col, 'LineWidth', lw, 'HandleVisibility','off');
    catch
        xl = ax.XLim;
        line(ax, xl, [y0 y0], 'Color', col, 'LineStyle', ls, 'LineWidth', lw, 'HandleVisibility','off');
    end
end