function plot_forces_mult(time_data, results, cases, subtitle, axes_labels, num_cases)
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
            plot(time_data(i), results(i, :, 1), DisplayName=cases(i));
        end
        title(["F_x (streamwise)"]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(2));
        
        nexttile(tcl)
        hold on
        for i = 1:num_cases
            plot(time_data(i), results(i, :, 2));
        end
        title(["F_y (transverse)"]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(2));
        
        nexttile(tcl)
        hold on
        for i = 1:num_cases
            plot(time_data(i), results(i, :, 3));
        end
        title(["F_z (vertical)"]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(2));
        
        % Create three subplots to show the moment time histories.
        nexttile(tcl)
        hold on
        for i = 1:num_cases
            plot(time_data(i), results(i, :, 4));
        end
        title(["M_x (roll)"]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(3));
        
        nexttile(tcl)
        hold on
        for i = 1:num_cases
            plot(time_data(i), results(i, :, 5));
        end
        title(["M_y (pitch)"]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(3));
        
        nexttile(tcl)
        hold on
        for i = 1:num_cases
            plot(time_data(i), results(i, :, 6));
        end
        title(["M_z (yaw)"]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(3));
        
%         hL = legend();
%         hL.Layout.Tile = 'East';

        % Label the whole figure.
        sgtitle(["Force Transducer Measurement for " subtitle]);
    else

    end
end