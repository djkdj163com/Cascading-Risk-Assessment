function addInset_local(fig, axMain, xz, yz, isLog)
    pos = axMain.Position; % normalized

    % 右上角 inset（不会与标题/角落框冲突太大）
    w  = 0.36 * pos(3);
    h  = 0.36 * pos(4);
    x0 = pos(1) + 0.60*pos(3);
    y0 = pos(2) + 0.56*pos(4);

    axIn = axes('Parent',fig, 'Units','normalized', 'Position',[x0 y0 w h], ...
        'Color',[1 1 1]*0.98, 'HandleVisibility','off', 'HitTest','off');
    axIn.PickableParts = 'none';

    box(axIn,'on'); hold(axIn,'on');
    set(axIn,'FontName','Times New Roman','FontSize',8);

    if isLog
        loglog(axIn, xz, max(yz, eps), '-', 'LineWidth', 1.4);
        axIn.XScale='log'; axIn.YScale='log';
    else
        plot(axIn, xz, yz, '-', 'LineWidth', 1.4);
    end

    xlim(axIn,[min(xz) max(xz)]);
    grid(axIn,'on'); axIn.GridAlpha = 0.12;
    title(axIn,'Head zoom','FontSize',8,'FontWeight','normal');
    hold(axIn,'off');

    axes(axMain); % 关键：切回主轴
end