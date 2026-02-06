function draw_choropleth(ax, polys, values, cmap)
    % —— 每个子图独立色标 —— %
    hold(ax,'on');
    v = values;
    vmin = min(v(~isnan(v))); vmax = max(v(~isnan(v)));
    if isempty(vmin) || isempty(vmax) || vmin==vmax, vmin = 0; vmax = 1; end
    for i=1:numel(polys)
        if isnan(v(i))
            pc = [0.93 0.93 0.93];
        else
            t = (v(i)-vmin) / max(vmax-vmin, eps); t = min(max(t,0),1);
            idx = max(1, min(size(cmap,1), round(1 + t*(size(cmap,1)-1))));
            pc = cmap(idx,:);
        end
        plot(ax, polys(i), 'FaceColor', pc, 'EdgeColor', [0.85 0.85 0.85], 'LineWidth', 0.5);
    end
    axis(ax,'equal'); axis(ax,'tight'); axis(ax,'off');
    colormap(ax, cmap);           % ★ 关键：为该 axes 单独设置 colormap
    caxis(ax, [vmin vmax]);       % ★ 关键：为该 axes 单独设置 caxis
end