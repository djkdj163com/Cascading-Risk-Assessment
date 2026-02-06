%% ===== 本地函数：用 annotation 画 Facet 条带（与 createfigure 一致）=====
function drawFacetStrip_anno(fig, ax, titleTxt, subTxt, stripCol, titleCol, subCol, fontName, titleFS, subFS)
    % 确保布局完成后再取像素位置
    drawnow limitrate;
    figPx  = getpixelposition(fig);          % [x y w h] (pixels)
    axPx   = getpixelposition(ax,true);      % 相对 figure 的像素
    % 条带高度与间距（按 figure 高度的比例）
    stripH = 0.0609587046940154;             % 与 createfigure 匹配
    padY   = 0.007;                          % 轴顶到条带的间距（figure 归一化）
    % 归一化到 figure
    x = axPx(1)/figPx(3);
    yTop = (axPx(2)+axPx(4))/figPx(4);
    w = axPx(3)/figPx(3);
    h = stripH;
    y = min(max(yTop + padY, 0), 1 - h);     % 防溢出
    % 背景矩形
    annotation(fig,'rectangle',[x y w h], ...
        'LineWidth',2,'FaceColor',stripCol);
    % 标题
    annotation(fig,'textbox',[x y w h], ...
        'String',titleTxt, 'Color',titleCol, ...
        'FontName',fontName,'FontSize',titleFS,'FontWeight','bold', ...
        'HorizontalAlignment','center','VerticalAlignment','middle', ...
        'FitBoxToText','off','EdgeColor','none');
    % 右上角小字 “Rank”
    subW = 0.10*w; subH = 0.55*h;
    annotation(fig,'textbox',[x + w - subW - 0.01*w, y + (h - subH)/2, subW, subH], ...
        'String',subTxt, 'Color',subCol, ...
        'FontName',fontName,'FontSize',subFS,'FontWeight','normal', ...
        'HorizontalAlignment','right','VerticalAlignment','middle', ...
        'FitBoxToText','off','EdgeColor','none');
end