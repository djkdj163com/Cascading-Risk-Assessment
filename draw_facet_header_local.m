% 在每个 tile 顶部画“条带”+标题，并把 xlabel 文本放到条带的副标题里
function draw_facet_header_local(ax, titleStr, subStr, stripColor, titleCol, subCol, fontname)
    ax.Units = 'normalized';
    pos = ax.Position;
    inset = 0.018; h = 0.10 * pos(4);          % 条带高度
    x = pos(1) + inset; w = pos(3) - 2*inset;
    y = pos(2) + pos(4) - h - inset;
    annotation('rectangle',[x y w h],'FaceColor',stripColor,'EdgeColor',[0.82 0.82 0.86]);

    % 标题
    text(ax, 0.5, -0.12, titleStr, 'Units','normalized', ...
        'HorizontalAlignment','center','VerticalAlignment','bottom', ...
        'FontWeight','bold','FontSize',11,'Color',titleCol, ...
        'FontName',fontname);

    % 副标题（把原来的 xlabel 放到这里）
    text(ax, 0.5, -0.26, subStr, 'Units','normalized', ...
        'HorizontalAlignment','center','VerticalAlignment','bottom', ...
        'FontWeight','normal','FontSize',9,'Color',subCol, ...
        'FontName',fontname);
end