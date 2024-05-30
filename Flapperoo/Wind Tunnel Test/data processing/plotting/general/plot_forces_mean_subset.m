function plot_forces_mean_subset(frames, mean_results, upper_results, lower_results, case_name, subtitle, axes_labels)
    if (ndims(mean_results) == 2)
        force_means = round(mean(mean_results'), 3);
        force_SDs = round(std(mean_results'), 3);
        force_maxs = round(max(mean_results'), 3);
        force_mins = round(min(mean_results'), 3);

        % Open a new figure.
        f = figure;
        f.Position = [200 50 1400 500];
        tcl = tiledlayout(1,3);
        
        % Create three subplots to show the force time histories. 
        nexttile(tcl)
        hold on
        line(xlim, [0,0], 'Color', 'k','HandleVisibility','off'); % Draw line for X axis.
        xconf = [frames, frames(end:-1:1)];         
        yconf = [upper_results(1, :), lower_results(1, end:-1:1)];
        p = fill(xconf, yconf, 'blue');
        p.FaceColor = [0.8 0.8 1];      
        p.EdgeColor = 'none';
        plot(frames, mean_results(1, :),color=[0, 0.4470, 0.7410]);
        plot_wingbeat_patch();
        title(["Drag", "avg: " + force_means(1) + "    SD: " + force_SDs(1), "max: " + force_maxs(1) + "    min: " + force_mins(1)]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(2));
        hold off
        
        nexttile(tcl)
        hold on
        line(xlim, [0,0], 'Color', 'k','HandleVisibility','off'); % Draw line for X axis.
        xconf = [frames, frames(end:-1:1)];         
        yconf = [upper_results(3, :), lower_results(3, end:-1:1)];
        p = fill(xconf, yconf, 'blue');
        p.FaceColor = [0.8 0.8 1];      
        p.EdgeColor = 'none';
        plot(frames, mean_results(3, :),color=[0, 0.4470, 0.7410]);
        plot_wingbeat_patch();
        title(["Lift", "avg: " + force_means(3) + " SD: " + force_SDs(3), "max: " + force_maxs(3) + "    min: " + force_mins(3)]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(2));
        hold off
        
        nexttile(tcl)
        hold on
        line(xlim, [0,0], 'Color', 'k','HandleVisibility','off'); % Draw line for X axis.
        xconf = [frames, frames(end:-1:1)];         
        yconf = [upper_results(5, :), lower_results(5, end:-1:1)];
        p = fill(xconf, yconf, 'blue');
        p.FaceColor = [0.8 0.8 1];      
        p.EdgeColor = 'none';
        plot(frames, mean_results(5, :),color=[0, 0.4470, 0.7410]);
        plot_wingbeat_patch();
        title(["Pitch Moment", "avg: " + force_means(5) + " SD: " + force_SDs(5), "max: " + force_maxs(5) + "    min: " + force_mins(5)]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(3));
        hold off
        
        % Label the whole figure.
        sgtitle(["Force Transducer Measurement for " + case_name subtitle]);
    elseif (ndims(mean_results) == 3)
        colors = [[0, 0.4470, 0.7410]; [0.8500, 0.3250, 0.0980]; ...
            [0.9290, 0.6940, 0.1250]; [0.4940, 0.1840, 0.5560]; ...
            [0.4660, 0.6740, 0.1880]; [0.3010, 0.7450, 0.9330]; ...
            [0.6350, 0.0780, 0.1840]; [0.25, 0.25, 0.25]];
        cases = ["Rigid Wing", "Skeleton Wing", "No wings"];
%         cases = ["Body", "Wing", "Inertial", "Wing - Body"];
%         cases = ["Wing - 4 m/s", "Wing - 0 m/s","4 m/s - 0 m/s"];
        
        % Just using the first entry "Wing - Body" for this
%         force_means = round(mean(squeeze(mean_results(:,:,1)),2), 3);
%         force_SDs = round(std(squeeze(mean_results(:,:,1)),0,2), 3);
%         force_maxs = round(max(squeeze(mean_results(:,:,1)),[],2), 3);
%         force_mins = round(min(squeeze(mean_results(:,:,1)),[],2), 3);

        % Open a new figure.
        f = figure;
        f.Position = [200 50 900 560];
        tcl = tiledlayout(2,3);
        
        f.Position = [200 50 1400 500];
        tcl = tiledlayout(1,3);
        
        % Create three subplots to show the force time histories. 
        nexttile(tcl)
        hold on
        line(xlim, [0,0], 'Color', 'k','HandleVisibility','off'); % Draw line for X axis.
        for i = 1:length(mean_results(1,1,:))
            xconf = [frames, frames(end:-1:1)];         
            yconf = [upper_results(1, :, i), lower_results(1, end:-1:1, i)];
            p = fill(xconf, yconf, colors(i,:),'HandleVisibility','off');
            p.FaceAlpha = 0.2;      
            p.EdgeColor = 'none';
            plot(frames, mean_results(1, :, i), DisplayName=cases(i), Color=colors(i,:));
        end
        plot_wingbeat_patch();
        title("Drag");
        xlabel(axes_labels(1));
        ylabel(axes_labels(2));
        hold off
        
        nexttile(tcl)
        hold on
        line(xlim, [0,0], 'Color', 'k','HandleVisibility','off'); % Draw line for X axis.
        for i = 1:length(mean_results(1,1,:))
            xconf = [frames, frames(end:-1:1)];         
            yconf = [upper_results(3, :, i), lower_results(3, end:-1:1, i)];
            p = fill(xconf, yconf, colors(i,:),'HandleVisibility','off');
            p.FaceAlpha = 0.2;      
            p.EdgeColor = 'none';
            plot(frames, mean_results(3, :, i), DisplayName=cases(i), Color=colors(i,:));
        end
        plot_wingbeat_patch();
        title("Lift");
        xlabel(axes_labels(1));
        ylabel(axes_labels(2));
        hold off
        
        nexttile(tcl)
        hold on
        line(xlim, [0,0], 'Color', 'k','HandleVisibility','off'); % Draw line for X axis.
        for i = 1:length(mean_results(1,1,:))
            xconf = [frames, frames(end:-1:1)];         
            yconf = [upper_results(5, :, i), lower_results(5, end:-1:1, i)];
            p = fill(xconf, yconf, colors(i,:),'HandleVisibility','off');
            p.FaceAlpha = 0.2;      
            p.EdgeColor = 'none';
            plot(frames, mean_results(5, :, i), DisplayName=cases(i), Color=colors(i,:));
        end
        plot_wingbeat_patch();
        title("Pitch Moment");
        xlabel(axes_labels(1));
        ylabel(axes_labels(3));
        hold off
        
        hL = legend();
        hL.Layout.Tile = 'East';
        
        % Label the whole figure.
        sgtitle(["Force Transducer Measurement for " + case_name subtitle]);
        
    end

end