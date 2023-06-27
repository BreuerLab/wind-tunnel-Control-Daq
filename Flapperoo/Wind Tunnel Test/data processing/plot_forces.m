function plot_forces(time_data, results, case_name, subtitle, axes_labels)
    if (length(results(1,:)) == 6)
        force_means = round(mean(results), 3);
        force_SDs = round(std(results), 3);
        force_maxs = round(max(results), 3);
        force_mins = round(min(results), 3);

        % Open a new figure.
        f = figure;
        f.Position = [200 50 900 560];
        tcl = tiledlayout(2,3);
        
        % Create three subplots to show the force time histories. 
        nexttile(tcl)
        hold on
        plot(time_data, results(:, 1), 'DisplayName', 'raw');
        title(["F_x (streamwise)", "avg: " + force_means(1) + "    SD: " + force_SDs(1), "max: " + force_maxs(1) + "    min: " + force_mins(1)]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(2));
        
        nexttile(tcl)
        hold on
        plot(time_data, results(:, 2));
        title(["F_y (transverse)", "avg: " + force_means(2) + " SD: " + force_SDs(2), "max: " + force_maxs(2) + "    min: " + force_mins(2)]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(2));
        
        nexttile(tcl)
        hold on
        plot(time_data, results(:, 3));
        title(["F_z (vertical)", "avg: " + force_means(3) + " SD: " + force_SDs(3), "max: " + force_maxs(3) + "    min: " + force_mins(3)]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(2));
        
        % Create three subplots to show the moment time histories.
        nexttile(tcl)
        hold on
        plot(time_data, results(:, 4));
        title(["M_x (roll)", "avg: " + force_means(4) + " SD: " + force_SDs(4), "max: " + force_maxs(4) + "    min: " + force_mins(4)]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(3));
        
        nexttile(tcl)
        hold on
        plot(time_data, results(:, 5));
        title(["M_y (pitch)", "avg: " + force_means(5) + " SD: " + force_SDs(5), "max: " + force_maxs(5) + "    min: " + force_mins(5)]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(3));
        
        nexttile(tcl)
        hold on
        plot(time_data, results(:, 6));
        title(["M_z (yaw)", "avg: " + force_means(6) + " SD: " + force_SDs(6), "max: " + force_maxs(6) + "    min: " + force_mins(6)]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(3));
        
        % Label the whole figure.
        sgtitle(["Force Transducer Measurement for " + case_name subtitle]);
    else

    end
end