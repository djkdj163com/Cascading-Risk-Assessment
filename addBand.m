
%% ===== helper：半透明背景带 =====
function addBand(ax, x1, x2, col, alphaVal)
    yl = ylim(ax);
    ph = patch(ax, [x1 x2 x2 x1], [yl(1) yl(1) yl(2) yl(2)], col, ...
        'EdgeColor','none','FaceAlpha',alphaVal,'HandleVisibility','off');
    uistack(ph,'bottom'); % 放到最底层
end