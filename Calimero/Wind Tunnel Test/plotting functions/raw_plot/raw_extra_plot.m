function raw_extra_plot(f, tiles, time, extra_data, case_name, rate, fc, titles)
    figure(f);

    % Additional Data : Voltage, Current, Encoder
    extra_means = round(mean(extra_data), 3);
    extra_SDs = round(std(extra_data), 3);
    extra_maxs = round(max(extra_data), 3);
    extra_mins = round(min(extra_data), 3);

    % --- Filtering extra data (3 channels)
    filtered_extra_data = filter_data(extra_data, rate, fc);

    for j = 1:3
        axes(tiles{j})
        hold on
        plot(time, extra_data(j, :), 'Color', [0.7 0.7 0.7], 'DisplayName', 'raw');  % raw force in gray
        plot(time, filtered_extra_data(j, :), 'b', 'DisplayName', 'filtered');       % filtered force in blue

        title([titles(j+6), " avg: " + extra_means(j) + ...
               "    SD: " + extra_SDs(j) + ...
               "    max: " + extra_maxs(j) + ...
               "    min: " + extra_mins(j)]);
        % xlabel(axes_labels(1));
        % ylabel(axes_labels(j+3));
        hold off
    end

    % Label the whole figure.
    sgtitle(["Power and Encoder Data" strrep(case_name,'_','  ')]);
end