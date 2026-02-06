function save_if_needed(fig, outDir, baseName, fmts, on)
if ~on, return; end
for k = 1:numel(fmts)
    f = fullfile(outDir, baseName + fmts{k});
    try
        exportgraphics(fig, f, 'Resolution', 300);
    catch
        saveas(fig, f);
    end
end
end