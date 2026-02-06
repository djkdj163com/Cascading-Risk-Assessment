% —— 关键修复：条带的矩形与文字都用 annotation（figure 坐标系），不会丢失
function drawFacetStrip(ax, titleStr, subStr, stripColor, titleCol, subCol, fontname)
    fig = ancestor(ax,'figure');
    old = ax.Units; ax.Units = 'normalized'; pos = ax.Position; ax.Units = old;
    inset = 0.018; h = 0.11 * pos(4);           % 条带高度
    x = pos(1) + inset;  w = pos(3) - 2*inset;
    y = pos(2) + pos(4) - h - inset;

    % 背景条
    annotation(fig,'rectangle',[x y w h], ...
        'FaceColor',stripColor,'EdgeColor',[0.82 0.82 0.86]);

    % 标题（加粗）
    annotation(fig,'textbox',[x y+0.48*h w 0.50*h], ...
        'String', titleStr, 'EdgeColor','none', 'HorizontalAlignment','center', ...
        'VerticalAlignment','middle', 'FontName',fontname, 'FontWeight','bold', ...
        'FontSize',11, 'Color', titleCol);

    % 副标题（放 “Rank”）
    annotation(fig,'textbox',[x y+0.06*h w 0.38*h], ...
        'String', subStr, 'EdgeColor','none', 'HorizontalAlignment','center', ...
        'VerticalAlignment','middle', 'FontName',fontname, 'FontSize',9, ...
        'Color', subCol);
end