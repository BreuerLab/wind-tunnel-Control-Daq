% **************************************************************** %
% **********************Plotting Measurements********************* %
% **************************************************************** %
% This function provides preliminary force data in the form of a 2 x 3
% grid plot.
function raw_plot(time, force, voltAdj, curAdj, theta, case_name, drift, rate, fc)
    close all
    titles = ["F_x","F_y","F_z","M_x","M_y","M_z","Power","Position"];

    if (contains(case_name, '-'))
        case_name = strrep(case_name,'-','neg');
    end

    x_label = "Time (s)";
    y_label_F = "Force (N)";
    y_label_M = "Moment (N*m)";
    y_label_V = "Voltage (V)";
    y_label_C = "Current (mA)";
    y_label_P = "Angle (rad)";
    axes_labels = [x_label, y_label_F, y_label_M, y_label_V, y_label_C, y_label_P];

    %% Figure with force data: raw and filtered overlaid

    f = raw_force_plot(time, force, case_name, drift, rate, fc, titles, axes_labels);

    saveas(f,'data\plots\' + case_name + "_raw_force.fig")

    % Same plot, but trimmed to only show a few wingbeat cycles between the
    % 2 and 4 second mark
    trimmed_force = force(:,2*rate:4*rate);

    g = raw_force_plot(time, trimmed_force, case_name, drift, rate, fc);

    %% Figure with voltage, current, and encoder data

    extra_data = [voltAdj, curAdj, theta];
    f = raw_extra_plot(time, extra_data, case_name, rate, fc, titles, axes_labels);

    saveas(f,'data\plots\' + case_name + "_raw_extra.fig")

    % Same plot, but trimmed to only show a few wingbeat cycles between the
    % 2 and 4 second mark
    trimmed_extra_data = extra_data(:,2*rate:4*rate);

    g = raw_extra_plot(time, trimmed_extra_data, case_name, rate, fc, titles, axes_labels);
end