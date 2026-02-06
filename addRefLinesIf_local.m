%% ===== helper：可选参考线（不画任何“框”）=====
function addRefLinesIf_local(ax, rawVals, isLog, SHOW_TOPLINES, SHOW_PCTL_LINES, PCTS, col, lw)
    n = numel(rawVals);
    hold(ax,'on');

    if SHOW_TOPLINES
        r1 = max(1, ceil(0.01*n));
        r5 = max(1, ceil(0.05*n));
        try
            xline(ax, r1, ':', 'Color', col, 'LineWidth', lw, 'HandleVisibility','off');
            xline(ax, r5, ':', 'Color', col, 'LineWidth', lw, 'HandleVisibility','off');
        catch
            yl = ax.YLim;
            line(ax,[r1 r1],yl,'Color',col,'LineStyle',':','LineWidth',lw,'HandleVisibility','off');
            line(ax,[r5 r5],yl,'Color',col,'LineStyle',':','LineWidth',lw,'HandleVisibility','off');
        end
    end

    if SHOW_PCTL_LINES
        v = rawVals(:);
        if isLog, v = max(v, eps); end
        yy = prctile(v, PCTS);
        for i = 1:numel(yy)
            try
                yline(ax, yy(i), '--', 'Color', col, 'LineWidth', lw, 'HandleVisibility','off');
            catch
                xl = ax.XLim;
                line(ax,xl,[yy(i) yy(i)],'Color',col,'LineStyle','--','LineWidth',lw,'HandleVisibility','off');
            end
        end
    end

    hold(ax,'off');
end