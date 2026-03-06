function plot_3D(ax, s, cData, params)

p = patch(ax,'vertices', s.vertices, 'faces', s.faces, ...
          'FaceVertexCData', cData, 'FaceColor', 'interp', 'EdgeColor', 'none');

view(ax, 3);
if params.zero ~= 0
    cb = colorbarpzn(ax, params.clims(1), params.clims(2), 'full', 1, 'dft', 'pwg');
else
    cb = colorbarpzn(ax, params.clims(1), params.clims(2)); % , 'level', 21
end
if ~params.movie
    ylabel(cb,'\boldmath$\frac{\omega c}{U_{\infty}}$','Interpreter','Latex','FontSize',18,'Rotation',0)
    % xlabel("x/c", FontSize=16)
    xlabel(ax, "t/T", FontSize=16)
    ylabel(ax, "y/c", FontSize=16)
    zlabel(ax, "z/c", FontSize=16)
else
    cb.Visible = 'off';
    ax = gca;
    ax.XTick = [];
    ax.YTick = [];
    ax.ZTick = [];
    ax.XTickLabel = [];
    ax.YTickLabel = [];
    ax.ZTickLabel = [];
    ax.Box = 'off';
    ax.XColor = 'none'; % hides axis line
    ax.YColor = 'none';
    ax.ZColor = 'none';
end

% Zoom out
% ax = gca;
% ax.XLim = ax.XLim * 2;   % doubles the range in x
% ax.YLim = ax.YLim * 2;   % doubles the range in y
% ax.ZLim = ax.ZLim * 2;   % doubles the range in z

% xlabel("y [m]")
% ylabel("z [m]")
% zlabel("x [m]")

end