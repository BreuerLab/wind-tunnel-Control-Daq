function plot_forces_mean_subset(frames, mean_results, upper_results, lower_results, case_name, subtitle, axes_labels)
    if (length(mean_results(1,:)) == 6)
        force_means = round(mean(mean_results), 3);
        force_SDs = round(std(mean_results), 3);
        force_maxs = round(max(mean_results), 3);
        force_mins = round(min(mean_results), 3);

        % Open a new figure.
        f = figure;
        f.Position = [200 50 1400 500];
        tcl = tiledlayout(1,3);
        
        % Create three subplots to show the force time histories. 
        nexttile(tcl)
        hold on
        xconf = [frames; frames(end:-1:1)];         
        yconf = [upper_results(:, 1, 1); lower_results(end:-1:1, 1, 1)];
        p = fill(xconf, yconf, 'blue');
        p.FaceColor = [0.8 0.8 1];      
        p.EdgeColor = 'none';
        plot(frames, mean_results(:, 1));
        plot_wingbeat_patch();
        title(["F_x (streamwise)", "avg: " + force_means(1) + "    SD: " + force_SDs(1), "max: " + force_maxs(1) + "    min: " + force_mins(1)]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(2));
        hold off
        
        nexttile(tcl)
        hold on
        xconf = [frames; frames(end:-1:1)];         
        yconf = [upper_results(:, 3); lower_results(end:-1:1, 3)];
        p = fill(xconf, yconf, 'blue');
        p.FaceColor = [0.8 0.8 1];      
        p.EdgeColor = 'none';
        plot(frames, mean_results(:, 3));
        plot_wingbeat_patch();
        title(["F_z (vertical)", "avg: " + force_means(3) + " SD: " + force_SDs(3), "max: " + force_maxs(3) + "    min: " + force_mins(3)]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(2));
        hold off
        
        nexttile(tcl)
        hold on
        xconf = [frames; frames(end:-1:1)];         
        yconf = [upper_results(:, 5); lower_results(end:-1:1, 5)];
        p = fill(xconf, yconf, 'blue');
        p.FaceColor = [0.8 0.8 1];      
        p.EdgeColor = 'none';
        plot(frames, mean_results(:, 5));
        plot_wingbeat_patch();
        title(["M_y (pitch)", "avg: " + force_means(5) + " SD: " + force_SDs(5), "max: " + force_maxs(5) + "    min: " + force_mins(5)]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(3));
        hold off
        
        % Label the whole figure.
        sgtitle(["Force Transducer Measurement for " + case_name subtitle]);
end