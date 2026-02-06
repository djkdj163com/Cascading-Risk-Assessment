function facetAxesTL_local(ax, xlimv, xt, xtl, SHOW_GRID, GRID_COLOR, FONT)
    % tiledlayout-friendly：绝不设置 ax.Position/OuterPosition/Units(用于布局)
    ax.FontName = FONT;
    ax.Box      = 'on';
    ax.TickDir  = 'out';
    ax.LineWidth = 1.2;
    ax.Layer    = 'top';

    xlim(ax, xlimv);
    xticks(ax, xt);
    xticklabels(ax, xtl);

    if SHOW_GRID
        grid(ax,'on');
        ax.GridColor = GRID_COLOR;
        ax.GridAlpha = 0.25;
    else
        grid(ax,'off');
    end
end