%% ====== 本地辅函数（不与此前重名） ======
function facetAxes_local(ax, xlimv, xtv, xtlv, showGrid, gridColor, fontname)
    set(ax, 'Box','on', 'LineWidth',1, 'FontName',fontname, 'FontSize',10);
    xlim(ax, xlimv);
    if nargin>=3 && ~isempty(xtv),  set(ax,'XTick',xtv); end
    if nargin>=4 && ~isempty(xtlv), set(ax,'XTickLabel',xtlv); end
    if showGrid
        grid(ax,'on'); ax.GridColor = gridColor;
    else
        grid(ax,'off');
    end
    ax.Layer = 'top';
end