function format_axes(ax)
set(ax,'TickDir','in','LineWidth',0.75, 'TickLength',[0.015 0.015], ...
       'Box','on','Layer','top');
ax.XMinorTick = 'on'; ax.YMinorTick = 'on';
grid(ax,'on'); ax.GridColor=[0.88 0.88 0.88]; ax.GridAlpha=1;
xx = xlim(ax); rng = xx(2)-xx(1); xlim(ax,[xx(1)-0.02*rng, xx(2)+0.02*rng]);
end