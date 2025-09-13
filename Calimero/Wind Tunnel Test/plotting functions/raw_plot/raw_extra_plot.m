function raw_extra_plot(f, tiles, time, extra_data, case_name, rate, fc, titles)
    figure(f);

    % --- Filtering extra data (3 channels)
    filtered_extra_data = filter_data(extra_data, rate, fc);

    % Additional Data : Voltage, Current, Encoder
    extra_means = round(mean(filtered_extra_data), 3);
    extra_SDs = round(std(filtered_extra_data), 3);
    extra_maxs = round(max(filtered_extra_data), 3);
    extra_mins = round(min(filtered_extra_data), 3);

    for j = 1:3
        axes(tiles{j})
        hold on
        plot(time, extra_data(j, :), 'Color', [0.7 0.7 0.7], 'DisplayName', 'raw');  % raw force in gray
        if (j < 3)
        plot(time, filtered_extra_data(j, :), 'b', 'DisplayName', 'filtered');       % filtered force in blue
        end

        title([titles(j+6), " avg: " + extra_means(j) + ...
               "    SD: " + extra_SDs(j) + ...
               "    max: " + extra_maxs(j) + ...
               "    min: " + extra_mins(j)], FontSize=8);
        % xlabel(axes_labels(1));
        % ylabel(axes_labels(j+3));
        hold off
    end

    % Label the whole figure.
    sgtitle(["Power and Encoder Data" strrep(case_name,'_','  ')]);
end