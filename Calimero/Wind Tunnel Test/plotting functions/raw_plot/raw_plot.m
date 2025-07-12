% **************************************************************** %
% **********************Plotting Measurements********************* %
% **************************************************************** %
% This function provides preliminary force data in the form of a 2 x 3
% grid plot.
function raw_plot(time, force, voltAdj, curAdj, theta, case_name, drift, rate, fc,...
    f1, f2, f3, f4, tiles_1, tiles_2, tiles_3, tiles_4)
    % close all
    titles = ["F_x","F_y","F_z","M_x","M_y","M_z","Voltage","Position","Current"];

    if (contains(case_name, '-'))
        case_name = strrep(case_name,'-','neg');
    end

    %% Figure with force data: raw and filtered overlaid

    raw_force_plot(f1, tiles_1, time, force, case_name, drift, rate, fc, titles);

    saveas(f1,'data\plots\' + case_name + "_raw_force.fig")

    % Same plot, but trimmed to only show a few wingbeat cycles between the
    % 2 and 4 second mark
    trimmed_force = force(:,2*rate:4*rate);
    trimmed_time = time(2*rate:4*rate);

    raw_force_plot(f2, tiles_2, trimmed_time, trimmed_force, case_name, drift, rate, fc, titles);

    %% Figure with voltage, current, and encoder data

    extra_data = [voltAdj, curAdj, theta];
    extra_data = extra_data';
    raw_extra_plot(f3, tiles_3, time, extra_data, case_name, rate, fc, titles);

    saveas(f3,'data\plots\' + case_name + "_raw_extra.fig")

    % Same plot, but trimmed to only show a few wingbeat cycles between the
    % 2 and 4 second mark
    trimmed_extra_data = extra_data(:,2*rate:4*rate);

    raw_extra_plot(f4, tiles_4, trimmed_time, trimmed_extra_data, case_name, rate, fc, titles);
end