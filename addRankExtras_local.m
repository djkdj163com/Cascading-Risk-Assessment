%% ===================== helper functions（放到脚本末尾） =====================

function addRankExtras_local(fig, ax, x, vals_sorted_for_plot, vals_raw, idx_sorted, names, ...
    isLogXY, lineColor, TOPK_MARK, TOPK_LIST, ZOOM_K, PCTS, ...
    SHOW_INSET, SHOW_PCTL_LINES, SHOW_TOPLINES, SHOW_TOPK, SHOW_STATSBOX, refCol, refLW, mode)

    if nargin < 22, mode = "default"; end
    n = numel(x);
    hold(ax,'on');

    % --- Top 1% / Top 5% 竖线（rank 阈值）
    if SHOW_TOPLINES
        r1 = max(1, ceil(0.01*n));
        r5 = max(1, ceil(0.05*n));
        drawVLine_local(ax, r1, refCol, refLW, ':');
        drawVLine_local(ax, r5, refCol, refLW, ':');
        % 文字标签（放在上方）
        yTop = ax.YLim(2);
        text(ax, r1, yTop, '  Top 1%', 'Color', refCol, 'FontSize', 9, ...
            'FontName','Times New Roman','HorizontalAlignment','left','VerticalAlignment','top', 'Clipping','on');
        text(ax, r5, yTop, '  Top 5%', 'Color', refCol, 'FontSize', 9, ...
            'FontName','Times New Roman','HorizontalAlignment','left','VerticalAlignment','top', 'Clipping','on');
    end

    % --- 分位数水平线（median/P90/P95/P99）
    if SHOW_PCTL_LINES
        vals_for_pct = vals_raw(:);
        if isLogXY
            vals_for_pct = max(vals_for_pct, eps);
        end
        yy = prctile(vals_for_pct, PCTS);
        for i = 1:numel(PCTS)
            drawHLine_local(ax, yy(i), refCol, refLW, '--');
            % 右侧轻量标注
            tx = ax.XLim(2);
            text(ax, tx, yy(i), sprintf('  P%d', PCTS(i)), ...
                'Color', refCol, 'FontSize', 8, 'FontName','Times New Roman', ...
                'HorizontalAlignment','left','VerticalAlignment','middle', 'Clipping','on');
        end
    end

    % --- Top-k 打点 + 角落小列表
    if SHOW_TOPK
        K = min(TOPK_MARK, n);
        rk = (1:K)';
        yy = vals_sorted_for_plot(rk);

        scatter(ax, rk, yy, 30, 'o', 'MarkerEdgeColor', lineColor, ...
            'MarkerFaceColor', 'w', 'LineWidth', 1.2, 'HandleVisibility','off');

        % 小列表（TopK_LIST）
        K2 = min(TOPK_LIST, n);
        ids = idx_sorted(1:K2);
        labs = names(ids);
        topStr = compose("%d) %s", (1:K2)', truncateLabels_local(labs, 10));
        topStr = join(topStr, newline);

        text(ax, 0.02, 0.02, "Top nodes" + newline + topStr, ...
            'Units','normalized', 'FontName','Times New Roman', 'FontSize', 9, ...
            'Color',[0.20 0.20 0.25], 'BackgroundColor',[1 1 1]*0.98, ...
            'EdgeColor',[0.85 0.85 0.88], 'Margin', 5, ...
            'HorizontalAlignment','left', 'VerticalAlignment','bottom', 'Clipping','on');
    end

    % --- 统计小框：Top1% 占比 + Gini（+ nonzero）
    if SHOW_STATSBOX
        r1 = max(1, ceil(0.01*n));
        share1 = safeShare_local(vals_sorted_for_plot(1:r1), vals_sorted_for_plot);
        gini   = gini_local(vals_raw(:));

        extra = "";
        if mode == "clustering"
            nz = nnz(vals_raw(:) > 0);
            extra = sprintf('\nNonzero=%.1f%%', 100*nz/n);
        end
        s = sprintf('Top1%% share=%.1f%%\nGini=%.2f%s', 100*share1, gini, extra);

        text(ax, 0.98, 0.02, s, ...
            'Units','normalized', 'FontName','Times New Roman', 'FontSize', 9, ...
            'Color',[0.20 0.20 0.25], 'BackgroundColor',[1 1 1]*0.98, ...
            'EdgeColor',[0.85 0.85 0.88], 'Margin', 5, ...
            'HorizontalAlignment','right', 'VerticalAlignment','bottom', 'Clipping','on');
    end

    % --- inset：放大 rank 1..ZOOM_K
    if SHOW_INSET
        Kz = min(ZOOM_K, n);
        addInset_local(fig, ax, x(1:Kz), vals_sorted_for_plot(1:Kz), isLogXY, lineColor);
    end

    hold(ax,'off');
end