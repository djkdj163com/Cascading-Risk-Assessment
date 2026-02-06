% ============ 本地工具函数 ============
function draw_strip_header(figH, ax, titleStr, stripColor, txtColor, fontname)
    old = ax.Units; ax.Units = 'normalized'; pos = ax.Position; ax.Units = old;
    inset = 0.018; h = 0.12 * pos(4);                 % 条带高度
    x = pos(1) + inset;  w = pos(3) - 2*inset;
    y = pos(2) + pos(4) - h - inset;

    % 背景条
    annotation(figH,'rectangle',[x y w h], ...
        'FaceColor',stripColor,'EdgeColor',[0.78 0.78 0.82]);

    % 居中标题
    annotation(figH,'textbox',[x y w h], 'String',titleStr, ...
        'EdgeColor','none', 'HorizontalAlignment','center', ...
        'VerticalAlignment','middle', 'FontName',fontname, ...
        'FontWeight','bold','FontSize',11, 'Color',txtColor);
end