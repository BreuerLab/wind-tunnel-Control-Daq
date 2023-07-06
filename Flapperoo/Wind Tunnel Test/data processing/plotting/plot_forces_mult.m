function plot_forces_mult(frames, results, cases, main_title, sub_title, axes_labels, num_cases)
    colors = [[0, 0.4470, 0.7410]; [0.8500, 0.3250, 0.0980]; ...
        [0.9290, 0.6940, 0.1250]; [0.4940, 0.1840, 0.5560]; ...
        [0.4660, 0.6740, 0.1880]; [0.3010, 0.7450, 0.9330]; ...
        [0.6350, 0.0780, 0.1840]; [0.25, 0.25, 0.25]];
    alpha = 0.4;

    if (length(results(1,1,:)) == 6)
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
        for i = 1:num_cases
            plot(frames(i,:), results(i, :, 1), DisplayName=cases(i), Color=colors(i,:));
        end
        title(["F_x (streamwise)"]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(2));
        hold off
        
        nexttile(tcl)
        hold on
        for i = 1:num_cases
            plot(frames(i,:), results(i, :, 2), DisplayName=cases(i), Color=colors(i,:));
        end
        title(["F_y (transverse)"]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(2));
        hold off
        
        nexttile(tcl)
        hold on
        for i = 1:num_cases
            plot(frames(i,:), results(i, :, 3), DisplayName=cases(i), Color=colors(i,:));
        end
        title(["F_z (vertical)"]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(2));
        hold off
        
        % Create three subplots to show the moment time histories.
        nexttile(tcl)
        hold on
        for i = 1:num_cases
            plot(frames(i,:), results(i, :, 4), DisplayName=cases(i), Color=colors(i,:));
        end
        title(["M_x (roll)"]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(3));
        hold off
        
        nexttile(tcl)
        hold on
        for i = 1:num_cases
            plot(frames(i,:), results(i, :, 5), DisplayName=cases(i), Color=colors(i,:));
        end
        title(["M_y (pitch)"]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(3));
        hold off
        
        nexttile(tcl)
        hold on
        for i = 1:num_cases
            plot(frames(i,:), results(i, :, 6), DisplayName=cases(i), Color=colors(i,:));
        end
        title(["M_z (yaw)"]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(3));
        hold off
        
        hL = legend();
        hL.Layout.Tile = 'East';

        % Label the whole figure.
        sgtitle([main_title sub_title]);
    else

    end
end