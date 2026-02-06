%% ===== helper: grid on/off =====
function setGrid_local(ax, SHOW_GRID, gridCol)
    if SHOW_GRID
        grid(ax,'on');
        ax.GridColor = gridCol;
        ax.GridAlpha = 0.25;
        ax.XMinorGrid = 'off';
        ax.YMinorGrid = 'off';
    else
        grid(ax,'off');
        ax.XMinorGrid = 'off';
        ax.YMinorGrid = 'off';
    end
end