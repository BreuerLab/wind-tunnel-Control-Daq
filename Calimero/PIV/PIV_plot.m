function PIV_plot(x, y, C, params)
    figure
    contourf(x, y, C, 71,'linestyle','none');
    xlabel("y/c", FontSize=16)
    ylabel("z/c", FontSize=16)
    
    % Xiaowei color map
    if params.zero ~= 0
    cb = colorbarpzn(params.clims(1), params.clims(2), 'full', 1, 'dft', 'pwg');
    else
    cb = colorbarpzn(params.clims(1), params.clims(2)); % , 'level', 21
    end
    ylabel(cb, params.y_lab,'Interpreter','Latex','FontSize',18,'Rotation',0)
    title(params.title, FontSize=18);
end