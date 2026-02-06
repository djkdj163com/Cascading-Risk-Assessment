%% ===== helper: axes style =====
function styleAxes_local(ax, AXLW)
    set(ax,'TickDir','out','Box','on','LineWidth',AXLW,'Layer','top');
    grid(ax,'off');
end