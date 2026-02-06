% ====== 辅助函数 ======
function drawStrip(ax, titleStr, stripColor, titleCol, fontname)
    fig = ancestor(ax,'figure');
    old = ax.Units; ax.Units = 'normalized'; pos = ax.Position; ax.Units = old;
    inset = 0.018;
    h = 0.12 * pos(4);     % 条带高度
    x = pos(1) + inset;
    w = pos(3) - 2*inset;
    y = pos(2) + pos(4) - h - inset;

    annotation(fig,'rectangle',[x y w h], ...
        'FaceColor',stripColor,'EdgeColor',[0.82 0.82 0.86]);
    annotation(fig,'textbox',[x y w h], 'String', titleStr, ...
        'HorizontalAlignment','center','VerticalAlignment','middle', ...
        'EdgeColor','none', 'FontName',fontname,'FontWeight','bold', ...
        'FontSize',11,'Color',titleCol);
end