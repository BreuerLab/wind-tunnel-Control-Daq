function make_movie(x, y, val, params)

    folder_name = params.PIV_case_name + "\" + params.folder + "\";

    if ~exist(params.save_filepath + folder_name, 'dir')
        mkdir(params.save_filepath + folder_name);
    end

    figure('Units','normalized','OuterPosition',[0.6292 0.0454 0.3667 0.8759]);
    % h = contourf(x, y, val(:,:,1),71,'linestyle','none');   % first frame of your data
    % ax = gca;

    k = 1;
    levels = linspace(params.clims(1), params.clims(2), 71);
    [~,h] = contourf(x, y, val(:,:,k), levels,'linestyle','none');
    hold on

    axis equal
    % shading(ax, 'interp');
    % xlim(params.xlims)
    % ylim(params.ylims)
    % xlabel("x [m]")
    % ylabel("y [m]")
    xlabel("y/c", FontSize=16)
    ylabel("z/c", FontSize=16)

    % Xiaowei color map
    % min_vort = min(vort_phase_avg,[],'all');
    % max_vort = max(vort_phase_avg,[],'all');
    % vort_scale = max(abs([min_vort max_vort]));
    if params.zero ~= 0
    cb = colorbarpzn(params.clims(1), params.clims(2), 'full', 1, 'dft', 'pwg','level',71);
    % y_lab = '\boldmath$\frac{w}{U_{\infty}}$';
    y_lab = '\boldmath$\frac{u}{U_{\infty}}$';
    else
    cb = colorbarpzn(params.clims(1), params.clims(2),'level',71); % , 'level', 21
    y_lab = '\boldmath$\frac{\omega c}{U_{\infty}}$';
    end
    ylabel(cb, y_lab,'Interpreter','Latex','FontSize',18,'Rotation',0)
    t = title([params.title "Bin number: " + k], FontSize=18);



    % --- Animation loop ---
    for k = 1:params.num_bins
        % 1. Cap the data so it doesn't exceed clims
        tmp_data = val(:,:,k);
        tmp_data(tmp_data < params.clims(1)) = params.clims(1);
        tmp_data(tmp_data > params.clims(2)) = params.clims(2);

        % UPDATE the existing objects instead of recreating them
        set(h, 'ZData', tmp_data); 
        set(t, 'String', [params.title "Bin number: " + k]);

        drawnow;

        filename = sprintf('frame_%04d.png', k);  
        exportgraphics(gcf, params.save_filepath + folder_name + filename, 'Resolution', 300);

        percent_complete = (k / params.num_bins)*100;
        if mod(k,5) == 0
            disp("Percent complete: " + percent_complete)
        end
    end

    fps = 5;
    gif_name = "animated";
    export_plot_gifs(params.save_filepath + params.PIV_case_name + "\" + params.folder + "\", gif_name, fps)

end