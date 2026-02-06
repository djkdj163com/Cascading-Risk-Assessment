% --- 公共的绘制子程序 ---
    function do_panel(xdata, titleStr, isCloseness)
        ax = nexttile;
        hold(ax,'on');

        % 先算 x 轴边距，让曲线不要贴边
        xpad = 0.06 * max(1e-12, max(xdata) - min(xdata));
        if xpad == 0, xpad = 0.05*max(1,abs(xdata(1))); end
        xmin = min(xdata) - xpad;  xmax = max(xdata) + xpad;

        % 黑色折线 + 实心圆点
        hL = plot(ax, xdata, yVals, '-k', 'LineWidth', LW);
        hP = plot(ax, xdata, yVals, 'ko', 'MarkerFaceColor','k', 'MarkerSize', MS);
        uistack(hL,'top'); uistack(hP,'top');

        % 轴样式：左侧显示标签；x 轴无标题；网格仿 ggplot
        set(ax, 'YDir','reverse', 'YLim',[0.5 numel(yVals)+0.5], ...
            'YTick',yVals, 'YTickLabel',yLabels, ...
            'XLim',[xmin xmax], 'Box','on','LineWidth',1, ...
            'FontName',FONT,'FontSize',10);
        xlabel(ax,''); ylabel(ax,'');        % 不要 xlabel/ylabel（标题在条带）

        if SHOW_GRID
            grid(ax,'on'); ax.GridColor = GRID_COLOR; ax.MinorGridColor = GRID_COLOR;
            ax.XMinorGrid = 'on'; ax.YMinorGrid = 'off';
        else
            grid(ax,'off');
        end
        ax.Layer = 'top';

        % c 面板：y 轴固定 ×10^2（仅改变显示，不改数据）
        if exist('isCloseness','var') && isCloseness
            try
                ax.YRuler.ExponentMode = 'manual'; ax.YRuler.Exponent = CLOSENESS_EXP;
            catch
                ax.YAxis.Exponent = CLOSENESS_EXP;
            end
        end

        % 灰色条带 + 标题（用 annotation，figure 坐标）
        draw_strip_header(fig, ax, titleStr, STRIP_COLOR, STRIP_TEXT, FONT);
    end