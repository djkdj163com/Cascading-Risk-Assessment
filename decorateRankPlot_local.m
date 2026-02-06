function decorateRankPlot_local(fig, ax, x, yPlot, yRaw, idx_sorted, names, OPT, mode, isLog)
    hold(ax,'on');
    n = numel(x);

    % --- Top1% / Top5% 竖线
    if OPT.SHOW_TOPLINES
        r1 = max(1, ceil(0.01*n));
        r5 = max(1, ceil(0.05*n));
        drawVLine_local(ax, r1, OPT.REFLINE_COL, OPT.REFLINE_LW, ':');
        drawVLine_local(ax, r5, OPT.REFLINE_COL, OPT.REFLINE_LW, ':');
        yTop = ax.YLim(2);
        text(ax, r1, yTop, '  Top1%', 'Color', OPT.REFLINE_COL, 'FontSize', 8, ...
            'FontName','Times New Roman','HorizontalAlignment','left','VerticalAlignment','top','Clipping','on');
        text(ax, r5, yTop, '  Top5%', 'Color', OPT.REFLINE_COL, 'FontSize', 8, ...
            'FontName','Times New Roman','HorizontalAlignment','left','VerticalAlignment','top','Clipping','on');
    end

    % --- 分位数水平线
    if OPT.SHOW_PCTL_LINES
        v = yRaw(:);
        if isLog, v = max(v, eps); end
        yy = prctile(v, OPT.PCTS);
        for i = 1:numel(yy)
            drawHLine_local(ax, yy(i), OPT.REFLINE_COL, OPT.REFLINE_LW, '--');
        end
        % 只给一个总体说明，避免太乱
        txt = "P" + string(OPT.PCTS);
        text(ax, 0.98, 0.98, strjoin(cellstr(txt),' / '), ...
            'Units','normalized','HorizontalAlignment','right','VerticalAlignment','top', ...
            'FontName','Times New Roman','FontSize',8,'Color',OPT.REFLINE_COL,'Clipping','on');
    end

    % --- Top-k：点 +（可选）标签 + 列表
    if OPT.SHOW_TOPK
        K  = min(OPT.TOPK_MARK, n);
        K2 = min(OPT.TOPK_LIST, n);

        rk = (1:K)'; yy = yPlot(rk);
        scatter(ax, rk, yy, 26, 'o', 'MarkerEdgeColor', [0.15 0.15 0.18], ...
            'MarkerFaceColor', [1 1 1], 'LineWidth', 1.0, 'HandleVisibility','off');

        % ===== 关闭曲线文字标注：默认不画 =====
        showLabels = isfield(OPT,'SHOW_TOPK_LABELS') && OPT.SHOW_TOPK_LABELS;
        if showLabels
            ids  = idx_sorted(1:K);
            labs = truncateLabels_local(names(ids), 12);
            for i = 1:K
                if isLog
                    ytxt = max(yy(i), eps) * 10^(0.02);
                else
                    ytxt = yy(i) + 0.02*(ax.YLim(2)-ax.YLim(1));
                end
                text(ax, rk(i)+0.8, ytxt, sprintf('#%d:%s', i, labs(i)), ...
                    'FontName','Times New Roman','FontSize',8,'Color',[0.20 0.20 0.25], 'Clipping','on');
            end
        end

        % Top nodes 列表（保留）
        ids2  = idx_sorted(1:K2);
        labs2 = truncateLabels_local(names(ids2), 14);
        listLines = strings(K2,1);
        for i=1:K2, listLines(i) = sprintf('%d) %s', i, labs2(i)); end
        boxStr = "Top nodes" + newline + strjoin(cellstr(listLines), newline);

        text(ax, 0.02, 0.04, boxStr, ...
            'Units','normalized','FontName','Times New Roman','FontSize',9, ...
            'Color',[0.20 0.20 0.25], 'BackgroundColor',[1 1 1]*0.98, ...
            'EdgeColor',[0.85 0.85 0.88], 'Margin', 4, ...
            'HorizontalAlignment','left','VerticalAlignment','bottom','Clipping','on');
    end

    % --- 统计框：Top1% share + Gini（clustering 额外 Nonzero%）
    if OPT.SHOW_STATSBOX
        r1 = max(1, ceil(0.01*n));
        share1 = safeShare_local(yPlot(1:r1), yPlot);
        gini   = gini_local(yRaw(:));

        extra = "";
        if mode == "clustering"
            extra = sprintf('\nNonzero=%.1f%%', 100*nnz(yRaw(:)>0)/numel(yRaw));
        end
        s = sprintf('Top1%% share=%.1f%%\nGini=%.2f%s', 100*share1, gini, extra);

        text(ax, 0.98, 0.04, s, ...
            'Units','normalized','FontName','Times New Roman','FontSize',9, ...
            'Color',[0.20 0.20 0.25], 'BackgroundColor',[1 1 1]*0.98, ...
            'EdgeColor',[0.85 0.85 0.88], 'Margin', 4, ...
            'HorizontalAlignment','right','VerticalAlignment','bottom','Clipping','on');
    end

    % --- inset：Head zoom
    if OPT.SHOW_INSET
        Kz = min(OPT.ZOOM_K, n);
        addInset_local(fig, ax, x(1:Kz), yPlot(1:Kz), isLog);
        axes(ax); % 关键：切回主轴，避免后续画到 inset
    end

    hold(ax,'off');
    axes(ax); % 再保险
end
