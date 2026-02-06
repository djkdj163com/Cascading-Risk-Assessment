%% ===== 本地辅函数：坐标轴与角标 =====
function natureAxes_local(ax, xlimv, xtv, xtlv)
    set(ax, 'Box','on', 'LineWidth',1, 'FontName','Helvetica', 'FontSize',10);
    xlim(ax, xlimv);
    if nargin >= 3 && ~isempty(xtv),  set(ax, 'XTick', xtv);  end
    if nargin >= 4 && ~isempty(xtlv), set(ax, 'XTickLabel', xtlv); end
    grid(ax, 'off');  ax.Layer = 'top';   % 无网格，边框置顶
end

function tagPanel_local(ax, ch)
    text(ax, 0.98, 0.96, ch, 'Units','normalized', ...
         'FontWeight','bold', 'FontSize',12, ...
         'HorizontalAlignment','right', 'VerticalAlignment','top');
end