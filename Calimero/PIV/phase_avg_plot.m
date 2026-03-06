function [h,t] = phase_avg_plot(x, y, val, params, ax, ind)
    % 1. Cap the data so it doesn't exceed clims
    val_tr = val(:,:,ind);
    val_tr(val_tr < params.clims(1)) = params.clims(1);
    val_tr(val_tr > params.clims(2)) = params.clims(2);

    levels = linspace(params.clims(1), params.clims(2), 71);
    [~,h] = contourf(ax, x, y, val_tr, levels,'linestyle','none');

    axis(ax, 'equal');
    % shading(ax, 'interp');
    % xlim(params.xlims)
    % ylim(params.ylims)
    % xlabel("x [m]")
    % ylabel("y [m]")
    xlabel(ax, "y/c", FontSize=16)
    ylabel(ax, "z/c", FontSize=16)

    % Xiaowei color map
    % min_vort = min(vort_phase_avg,[],'all');
    % max_vort = max(vort_phase_avg,[],'all');
    % vort_scale = max(abs([min_vort max_vort]));
    if params.zero ~= 0
    cb = colorbarpzn(ax, params.clims(1), params.clims(2), 'full', params.zero, 'dft', 'gwp','level',71);
    % y_lab = '\boldmath$\frac{w}{U_{\infty}}$';
    y_lab = '\boldmath$\frac{u}{U_{\infty}}$';
    else
    cb = colorbarpzn(ax, params.clims(1), params.clims(2),'level',71); % , 'level', 21
    y_lab = '\boldmath$\frac{\omega c}{U_{\infty}}$';
    end
    ylabel(cb, y_lab,'Interpreter','Latex','FontSize',18,'Rotation',0)
    t = title(ax, [params.title "Bin number: " + ind], FontSize=18);
end