%% ===== helper: panel label outside =====
function addPanelLabel_anno(fig, ax, ch)
    oldUnits = ax.Units;
    ax.Units = 'normalized';
    p = ax.Position;  % [x y w h]
    ax.Units = oldUnits;

    x = p(1) - 0.040;
    y = p(2) + p(4) + 0.010;

    annotation(fig,'textbox',[x y 0.03 0.03], 'String', ch, ...
        'EdgeColor','none','Color',[0.15 0.15 0.18], ...
        'FontName','Times New Roman','FontWeight','bold','FontSize',16, ...
        'HorizontalAlignment','left','VerticalAlignment','bottom');
end