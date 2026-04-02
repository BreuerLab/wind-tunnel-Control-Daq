function h = PIV_plot(x, y, val_tr, params, ax)
    % 1. Cap the data so it doesn't exceed clims
    val_tr(val_tr < params.clims(1)) = params.clims(1);
    val_tr(val_tr > params.clims(2)) = params.clims(2);

    levels = linspace(params.clims(1), params.clims(2), 100);
    [~,h] = contourf(ax, x, y, val_tr, levels,'linestyle','none');

    % axis(ax, 'equal');
    % shading(ax, 'interp');
    % xlim(params.xlims)
    % ylim(params.ylims)
    % xlabel("x [m]")
    % ylabel("y [m]")
    % xlabel(ax, "y/c", FontSize=16)
    % ylabel(ax, "z/c", FontSize=16)
    xlabel(ax, "y/c", FontSize=16)
    ylabel(ax, "z/c", FontSize=16)

    % Xiaowei color map
    % min_vort = min(vort_phase_avg,[],'all');
    % max_vort = max(vort_phase_avg,[],'all');
    % vort_scale = max(abs([min_vort max_vort]));

    if params.zero ~= 0 % freestream velocity plot
        cb = colorbarpzn(ax, params.clims(1), params.clims(2), 'full', params.zero, 'dft', 'gwp','level',71);
    elseif params.clims(1) == 0 % uncertainty plots
        colormap(ax, jet);
        cb = colorbar(ax);
    else % vorticity plots
        cb = colorbarpzn(ax, params.clims(1), params.clims(2),'level',71); % , 'level', 21
    end
    ylabel(cb, params.cb_lab,'Interpreter','Latex','FontSize',18,'Rotation',0)
end