function plot_forces_mean(frames, mean_results, upper_results, lower_results, case_name, subtitle, axes_labels)
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
        yconf = [upper_results(:, 2); lower_results(end:-1:1, 2)];
        p = fill(xconf, yconf, 'blue');
        p.FaceColor = [0.8 0.8 1];      
        p.EdgeColor = 'none';
        plot(frames, mean_results(:, 2));
        plot_wingbeat_patch();
        title(["F_y (transverse)", "avg: " + force_means(2) + " SD: " + force_SDs(2), "max: " + force_maxs(2) + "    min: " + force_mins(2)]);
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
        
        % Create three subplots to show the moment time histories.
        nexttile(tcl)
        hold on
        xconf = [frames; frames(end:-1:1)];         
        yconf = [upper_results(:, 4); lower_results(end:-1:1, 4)];
        p = fill(xconf, yconf, 'blue');
        p.FaceColor = [0.8 0.8 1];      
        p.EdgeColor = 'none';
        plot(frames, mean_results(:, 4));
        plot_wingbeat_patch();
        title(["M_x (roll)", "avg: " + force_means(4) + " SD: " + force_SDs(4), "max: " + force_maxs(4) + "    min: " + force_mins(4)]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(3));
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
        
        nexttile(tcl)
        hold on
        xconf = [frames; frames(end:-1:1)];         
        yconf = [upper_results(:, 6); lower_results(end:-1:1, 6)];
        p = fill(xconf, yconf, 'blue');
        p.FaceColor = [0.8 0.8 1];      
        p.EdgeColor = 'none';
        plot(frames, mean_results(:, 6));
        plot_wingbeat_patch();
        title(["M_z (yaw)", "avg: " + force_means(6) + " SD: " + force_SDs(6), "max: " + force_maxs(6) + "    min: " + force_mins(6)]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(3));
        hold off
        
        % Label the whole figure.
        sgtitle(["Force Transducer Measurement for " + case_name subtitle]);
    elseif (length(mean_results(1,:,1)) == 6)
        colors = [[0, 0.4470, 0.7410]; [0.8500, 0.3250, 0.0980]; ...
            [0.9290, 0.6940, 0.1250]; [0.4940, 0.1840, 0.5560]; ...
            [0.4660, 0.6740, 0.1880]; [0.3010, 0.7450, 0.9330]; ...
            [0.6350, 0.0780, 0.1840]; [0.25, 0.25, 0.25]];
        cases = ["Wing - Body", "Body", "Wing"];
        
        % Just using the first entry "Wing - Body" for this
        force_means = round(mean(mean_results(:,:,1)), 3);
        force_SDs = round(std(mean_results(:,:,1)), 3);
        force_maxs = round(max(mean_results(:,:,1)), 3);
        force_mins = round(min(mean_results(:,:,1)), 3);

        % Open a new figure.
        f = figure;
        f.Position = [200 50 900 560];
        tcl = tiledlayout(2,3);
        
        % Create three subplots to show the force time histories. 
        nexttile(tcl)
        hold on
        for i = 1:length(mean_results(1,1,:))
            xconf = [frames; frames(end:-1:1)];         
            yconf = [upper_results(:, 1, i); lower_results(end:-1:1, 1, i)];
            p = fill(xconf, yconf, colors(i,:),'HandleVisibility','off');
            p.FaceAlpha = 0.2;      
            p.EdgeColor = 'none';
            plot(frames, mean_results(:, 1, i), DisplayName=cases(i), Color=colors(i,:));
        end
        plot_wingbeat_patch();
        title(["F_x (streamwise)", "avg: " + force_means(1) + "    SD: " + force_SDs(1), "max: " + force_maxs(1) + "    min: " + force_mins(1)]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(2));
        hold off
        
        nexttile(tcl)
        hold on
        for i = 1:length(mean_results(1,1,:))
            xconf = [frames; frames(end:-1:1)];         
            yconf = [upper_results(:, 2, i); lower_results(end:-1:1, 2, i)];
            p = fill(xconf, yconf, colors(i,:),'HandleVisibility','off');
            p.FaceAlpha = 0.2;      
            p.EdgeColor = 'none';
            plot(frames, mean_results(:, 2, i), DisplayName=cases(i), Color=colors(i,:));
        end
        plot_wingbeat_patch();
        title(["F_y (transverse)", "avg: " + force_means(2) + " SD: " + force_SDs(2), "max: " + force_maxs(2) + "    min: " + force_mins(2)]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(2));
        hold off
        
        nexttile(tcl)
        hold on
        for i = 1:length(mean_results(1,1,:))
            xconf = [frames; frames(end:-1:1)];         
            yconf = [upper_results(:, 3, i); lower_results(end:-1:1, 3, i)];
            p = fill(xconf, yconf, colors(i,:),'HandleVisibility','off');
            p.FaceAlpha = 0.2;      
            p.EdgeColor = 'none';
            plot(frames, mean_results(:, 3, i), DisplayName=cases(i), Color=colors(i,:));
        end
        plot_wingbeat_patch();
        title(["F_z (vertical)", "avg: " + force_means(3) + " SD: " + force_SDs(3), "max: " + force_maxs(3) + "    min: " + force_mins(3)]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(2));
        hold off
        
        % Create three subplots to show the moment time histories.
        nexttile(tcl)
        hold on
        for i = 1:length(mean_results(1,1,:))
            xconf = [frames; frames(end:-1:1)];         
            yconf = [upper_results(:, 4, i); lower_results(end:-1:1, 4, i)];
            p = fill(xconf, yconf, colors(i,:),'HandleVisibility','off');
            p.FaceAlpha = 0.2;      
            p.EdgeColor = 'none';
            plot(frames, mean_results(:, 4, i), DisplayName=cases(i), Color=colors(i,:));
        end
        plot_wingbeat_patch();
        title(["M_x (roll)", "avg: " + force_means(4) + " SD: " + force_SDs(4), "max: " + force_maxs(4) + "    min: " + force_mins(4)]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(3));
        hold off
        
        nexttile(tcl)
        hold on
        for i = 1:length(mean_results(1,1,:))
            xconf = [frames; frames(end:-1:1)];         
            yconf = [upper_results(:, 5, i); lower_results(end:-1:1, 5, i)];
            p = fill(xconf, yconf, colors(i,:),'HandleVisibility','off');
            p.FaceAlpha = 0.2;      
            p.EdgeColor = 'none';
            plot(frames, mean_results(:, 5, i), DisplayName=cases(i), Color=colors(i,:));
        end
        plot_wingbeat_patch();
        title(["M_y (pitch)", "avg: " + force_means(5) + " SD: " + force_SDs(5), "max: " + force_maxs(5) + "    min: " + force_mins(5)]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(3));
        hold off
        
        nexttile(tcl)
        hold on
        for i = 1:length(mean_results(1,1,:))
            xconf = [frames; frames(end:-1:1)];         
            yconf = [upper_results(:, 6, i); lower_results(end:-1:1, 6, i)];
            p = fill(xconf, yconf, colors(i,:),'HandleVisibility','off');
            p.FaceAlpha = 0.2;      
            p.EdgeColor = 'none';
            plot(frames, mean_results(:, 6, i), DisplayName=cases(i), Color=colors(i,:));
        end
        plot_wingbeat_patch();
        title(["M_z (yaw)", "avg: " + force_means(6) + " SD: " + force_SDs(6), "max: " + force_maxs(6) + "    min: " + force_mins(6)]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(3));
        hold off
        
        hL = legend();
        hL.Layout.Tile = 'East';
        
        % Label the whole figure.
        sgtitle(["Force Transducer Measurement for " + case_name subtitle]);
        else
    end
end