%% ====================== 本脚本新增的小工具函数 ======================
function label_counties(ax, polyC, names)
% 在多边形中心标注县名
    axes(ax); hold on;
    for ii = 1:numel(polyC)
        try
            if isempty(polyC(ii).Vertices); continue; end
            [cx, cy] = centroid(polyC(ii));
            if all(isfinite([cx cy]))
                text(cx, cy, string(names(ii)), ...
                    'HorizontalAlignment','center','VerticalAlignment','middle', ...
                    'FontSize',6.5,'Color','k','Interpreter','none','Clipping','on');
            end
        catch
        end
    end
end