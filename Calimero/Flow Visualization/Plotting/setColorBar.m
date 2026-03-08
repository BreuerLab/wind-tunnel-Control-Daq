function setColorBar(ax, params)
    if params.zero ~= 0
        cb = colorbarpzn(ax, params.clims(1), params.clims(2), 'full', params.zero, 'dft', 'gwp','level',71);
        ylabel(cb,params.cb_lab,'Interpreter','Latex','FontSize',18,'Rotation',0)
    else
        cb = colorbarpzn(ax, params.clims(1), params.clims(2)); % , 'level', 21
        ylabel(cb,params.cb_lab,'Interpreter','Latex','FontSize',18,'Rotation',0)
    end
end