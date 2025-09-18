function raw_force_plot(f, tiles, time, force, case_name, drift, rate, fc, titles, zoomed_bool)
    figure(f);
   
    % --- Filtering forces and moments (6 channels)
    filtered_force = filter_data(force, rate, fc);

    force_means = round(mean(filtered_force, 2), 3);
    force_SDs = round(std(filtered_force, 0, 2), 3);
    force_maxs = round(max(filtered_force, [], 2), 3);
    force_mins = round(min(filtered_force, [], 2), 3);

    if (zoomed_bool)
    forces_max = round(max(max(filtered_force(1:3, :), [], 2)), 3);
    forces_min = round(min(min(filtered_force(1:3, :), [], 2)), 3);
    moments_max = round(max(max(filtered_force(4:6, :), [], 2)), 3);
    moments_min = round(min(min(filtered_force(4:6, :), [], 2)), 3);
    mult_fac = 1.2;
    end
    
    % Plot forces and moments (6 plots)
    for k = 1:6
        axes(tiles{k})
        hold on
        plot(time, force(k, :), 'Color', [0.7 0.7 0.7], 'DisplayName', 'raw');  % raw force in gray
        plot(time, filtered_force(k, :), 'b', 'DisplayName', 'filtered');       % filtered force in blue
    
        title([titles(k), " avg: " + force_means(k) + ...
               "    SD: " + force_SDs(k) + ...
               "    max: " + force_maxs(k) + ...
               "    min: " + force_mins(k)], FontSize=8);
        if (zoomed_bool)
        if (k < 4)
            ylim([mult_fac*forces_min mult_fac*forces_max])
        else
            ylim([mult_fac*moments_min mult_fac*moments_max])
        end
        end
        % xlabel(axes_labels(1));
        % ylabel(axes_labels(1 + ceil(k/3)));
        % legend;
        hold off
    end

    drift_string = string(drift);
    % separate numbers by space
    drift_string = [sprintf('%s    ',drift_string{1:end-1}), drift_string{end}];

    % Label the whole figure.
    sgtitle({"Force Transducer Data" strrep(case_name,'_','  ') ...
            "Over the course of the experiment, the force transducer drifted" ...
            "F_x                  F_y                   F_z                   M_x                   M_y                   M_z" ...
            drift_string});
end