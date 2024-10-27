function plot_force_histogram(time_data, results, case_name, subtitle, axes_labels, index)
    titles = ["Drag (F_x)","Transverse (F_y)","Lift (F_z)","Roll Moment (M_x)","Pitch Moment (M_y)","Yaw Moment (M_z)"];
    force_means = round(mean(results'), 3);
    force_SDs = round(std(results'), 3);
    force_maxs = round(max(results'), 3);
    force_mins = round(min(results'), 3);

    if (index == 0)
        % Open a new figure.
        f = figure;
        f.Position = [200 50 900 560];
        tcl = tiledlayout(2,3);
        
        for k = 1:6
        % Create three subplots to show the force time histories. 
        nexttile(tcl)
        hold on
        h = histogram(results(k, :));
        h.Normalization = 'probability';
        h.EdgeColor = 'none';

        probability = h.Values;
        [M,I] = min(abs(h.BinEdges - force_means(k)));
        prob_at_mean = probability(I);
        ascending_arr = 0:0.5:1;
        l = plot(force_means(k)*ones(1,3), prob_at_mean*ascending_arr);
        l.LineWidth = 2;
        l.Color = 'black';

        title([titles(k), "avg: " + force_means(k) + "    SD: " ...
            + force_SDs(k), "max: " + force_maxs(k) + "    min: " + force_mins(k)]);
        xlabel(axes_labels(1 + ceil(k/3)));
        ylabel(axes_labels(1));
        hold off
        end
        
        % Label the whole figure.
        sgtitle(["Force Transducer Measurement for " + case_name subtitle]);
    else
        figure;
        hold on
        h = histogram(results(index, :));
        h.Normalization = 'probability';
        h.EdgeColor = 'none';

        probability = h.Values;
        [M,I] = min(abs(h.BinEdges - force_means(index)));
        prob_at_mean = probability(I);
        ascending_arr = 0:0.5:1;
        l = plot(force_means(index)*ones(1,3), prob_at_mean*ascending_arr);
        l.LineWidth = 2;
        l.Color = 'black';
        

        title([titles(index), "avg: " + force_means(index) + "    SD: " ...
            + force_SDs(index), "max: " + force_maxs(index) + "    min: " + force_mins(index)]);
        xlabel(axes_labels(1 + ceil(index/3)));
        ylabel(axes_labels(1));
    end
end

