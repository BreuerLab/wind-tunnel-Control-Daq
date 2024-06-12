function plot_forces(time_data, results, case_name, subtitle, axes_labels, index)
    titles = ["Drag (F_x)","Transverse (F_y)","Lift (F_z)","Roll Moment (M_x)","Pitch Moment (M_y)","Yaw Moment (M_z)"];

    if (index == 0)
        force_means = round(mean(results'), 3);
        force_SDs = round(std(results'), 3);
        force_maxs = round(max(results'), 3);
        force_mins = round(min(results'), 3);

        % Open a new figure.
        f = figure;
        f.Position = [200 50 900 560];
        tcl = tiledlayout(2,3);
        
        for k = 1:6
        % Create three subplots to show the force time histories. 
        nexttile(tcl)
        hold on
        plot(time_data, results(k, :));
        if (axes_labels(1) == "Wingbeat Period (t/T)")
            plot_wingbeat_patch();
        end
        title([titles(k), "avg: " + force_means(k) + "    SD: " + force_SDs(k), "max: " + force_maxs(k) + "    min: " + force_mins(k)]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(1 + ceil(k/3)));
        hold off
        end
        
        % Label the whole figure.
        sgtitle(["Force Transducer Measurement for " + case_name subtitle]);
    else
        figure;
        hold on
        plot(time_data, results(index, :),Color=[0.8500, 0.3250, 0.0980]);
        title(titles(index));
        xlabel(axes_labels(1));
        ylabel(axes_labels(1 + ceil(index/3)));
    end
end