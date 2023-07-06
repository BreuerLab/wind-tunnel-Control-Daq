function plot_forces_mean(frames, mean_results, std_results, case_name, subtitle, axes_labels, num_cases)
    if (length(mean_results(1,:)) == 6)
        force_means = round(mean(mean_results), 3);
        force_SDs = round(std(mean_results), 3);
        force_maxs = round(max(mean_results), 3);
        force_mins = round(min(mean_results), 3);

        % Open a new figure.
        f = figure;
        f.Position = [200 50 900 560];
        tcl = tiledlayout(2,3);
        
        % Create three subplots to show the force time histories. 
        nexttile(tcl)
        hold on
        xconf = [frames; frames(end:-1:1)];         
        yconf = [mean_results(:, 1) + std_results(:, 1); mean_results(end:-1:1, 1) - std_results(end:-1:1, 1)];
        p = fill(xconf, yconf, 'blue');
        p.FaceColor = [0.8 0.8 1];      
        p.EdgeColor = 'none';
        plot(frames, mean_results(:, 1));
        title(["F_x (streamwise)", "avg: " + force_means(1) + "    SD: " + force_SDs(1), "max: " + force_maxs(1) + "    min: " + force_mins(1)]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(2));
        hold off
        
        nexttile(tcl)
        hold on
        xconf = [frames; frames(end:-1:1)];         
        yconf = [mean_results(:, 2) + std_results(:, 2); mean_results(end:-1:1, 2) - std_results(end:-1:1, 2)];
        p = fill(xconf, yconf, 'blue');
        p.FaceColor = [0.8 0.8 1];      
        p.EdgeColor = 'none';
        plot(frames, mean_results(:, 2));
        title(["F_y (transverse)", "avg: " + force_means(2) + " SD: " + force_SDs(2), "max: " + force_maxs(2) + "    min: " + force_mins(2)]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(2));
        hold off
        
        nexttile(tcl)
        hold on
        xconf = [frames; frames(end:-1:1)];         
        yconf = [mean_results(:, 3) + std_results(:, 3); mean_results(end:-1:1, 3) - std_results(end:-1:1, 3)];
        p = fill(xconf, yconf, 'blue');
        p.FaceColor = [0.8 0.8 1];      
        p.EdgeColor = 'none';
        plot(frames, mean_results(:, 3));
        title(["F_z (vertical)", "avg: " + force_means(3) + " SD: " + force_SDs(3), "max: " + force_maxs(3) + "    min: " + force_mins(3)]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(2));
        hold off
        
        % Create three subplots to show the moment time histories.
        nexttile(tcl)
        hold on
        xconf = [frames; frames(end:-1:1)];         
        yconf = [mean_results(:, 4) + std_results(:, 4); mean_results(end:-1:1, 4) - std_results(end:-1:1, 4)];
        p = fill(xconf, yconf, 'blue');
        p.FaceColor = [0.8 0.8 1];      
        p.EdgeColor = 'none';
        plot(frames, mean_results(:, 4));
        title(["M_x (roll)", "avg: " + force_means(4) + " SD: " + force_SDs(4), "max: " + force_maxs(4) + "    min: " + force_mins(4)]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(3));
        hold off
        
        nexttile(tcl)
        hold on
        xconf = [frames; frames(end:-1:1)];         
        yconf = [mean_results(:, 5) + std_results(:, 5); mean_results(end:-1:1, 5) - std_results(end:-1:1, 5)];
        p = fill(xconf, yconf, 'blue');
        p.FaceColor = [0.8 0.8 1];      
        p.EdgeColor = 'none';
        plot(frames, mean_results(:, 5));
        title(["M_y (pitch)", "avg: " + force_means(5) + " SD: " + force_SDs(5), "max: " + force_maxs(5) + "    min: " + force_mins(5)]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(3));
        hold off
        
        nexttile(tcl)
        hold on
        xconf = [frames; frames(end:-1:1)];         
        yconf = [mean_results(:, 6) + std_results(:, 6); mean_results(end:-1:1, 6) - std_results(end:-1:1, 6)];
        p = fill(xconf, yconf, 'blue');
        p.FaceColor = [0.8 0.8 1];      
        p.EdgeColor = 'none';
        plot(frames, mean_results(:, 6));
        title(["M_z (yaw)", "avg: " + force_means(6) + " SD: " + force_SDs(6), "max: " + force_maxs(6) + "    min: " + force_mins(6)]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(3));
        hold off
        
        % Label the whole figure.
        sgtitle(["Force Transducer Measurement for " + case_name subtitle]);
    else

    end
end