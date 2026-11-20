figFile = 'C:\Users\rgissler\Documents\DFD 2026\Figures\x3_wings_30deg_6Hz_S.fig';
[outDir, name] = fileparts(figFile);

fig = openfig(figFile);
ax  = findobj(fig, 'Type', 'axes');
cb  = findobj(fig, 'Type', 'colorbar');
ax = ax(1);  % the 3D plot has one axes

% --- colorbar settings, read before it is deleted
cmap    = colormap(ax);
lims    = clim(ax);                 % caxis(ax) in R2021b or earlier
cbPos   = cb.Position;              % normalized to the figure
cbProps = get(cb, {'Ticks', 'TickLabels', 'TickLabelInterpreter', 'FontSize', 'Color', 'LineWidth'});
lblProps = get(cb.Label, {'String', 'Interpreter', 'FontSize', 'Rotation', ...
                          'HorizontalAlignment', 'VerticalAlignment', 'Units', 'Position'});

% --- 1) plot without the colorbar
delete(cb)
exportgraphics(fig, fullfile(outDir, name + ".png"), 'Resolution', 300)

% --- 2) just the colorbar, same size and position as in the plot
f2 = figure('Color', 'w', 'Units', fig.Units, 'Position', fig.Position);
ax2 = axes(f2, 'Position', [cbPos(1) cbPos(2) 0.001 cbPos(4)]);
axis(ax2, 'off')
colormap(ax2, cmap)
clim(ax2, lims)
cb2 = colorbar(ax2);
cb2.Position = cbPos;
set(cb2, {'Ticks', 'TickLabels', 'TickLabelInterpreter', 'FontSize', 'Color', 'LineWidth'}, cbProps);
set(cb2.Label, {'String', 'Interpreter', 'FontSize', 'Rotation', ...
                'HorizontalAlignment', 'VerticalAlignment', 'Units', 'Position'}, lblProps);
exportgraphics(f2, fullfile(outDir, name + "_cb.png"), 'Resolution', 300, ...
    'BackgroundColor', 'white')

close(fig); close(f2)