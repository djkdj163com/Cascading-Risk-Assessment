function draw_panel_header(ax, titleStr, bgcol, fontname)
    % 在每个 tile 内部上方画一条浅灰色“标题条”，并写标题
    pos = ax.Position;
    inset = 0.018;  % 与四周的间隔
    h = 0.08 * pos(4);                 % 标题条高度基于轴高
    rectangle('Position',[ax.XLim(1) ax.YLim(1) 0 0],'Visible','off'); % 强制轴已初始化
    % 用 annotation 画位于 figure 的条幅
    ax.Units = 'normalized';
    pos = ax.Position;
    x = pos(1) + inset; 
    w = pos(3) - 2*inset;
    y = pos(2) + pos(4) - h - inset;
    annotation('rectangle',[x y w h],'FaceColor',bgcol,'EdgeColor',[0.8 0.8 0.85]);
    % 写标题（覆盖在条幅上）
    text(ax, 0.5, -0.09, titleStr, 'Units','normalized', ...
        'HorizontalAlignment','center','VerticalAlignment','bottom', ...
        'FontWeight','bold','FontSize',11,'Color',[0.2 0.2 0.25], ...
        'FontName',fontname);
end