% **************************************************************** %
% **********************Plotting Measurements********************* %
% **************************************************************** %
% This function provides preliminary force data in the form of a 2 x 3
% grid plot.
function raw_plot(time, force, voltAdj, curAdj, enc_pulse, speed, case_name, drift, rate, fc,...
    f1, f2, f3, f4, tiles_1, tiles_2, tiles_3, tiles_4, async)
    % close all
    titles = ["F_x","F_y","F_z","M_x","M_y","M_z","Voltage","Current","Speed (OC)"];

    if (contains(case_name, '-'))
        case_name = strrep(case_name,'-','neg');
    end

    %% Figure with force data: raw and filtered overlaid

    raw_force_plot(f1, tiles_1, time, force, case_name, drift, rate, fc, titles, false);

    saveas(f1,'data\plots\' + case_name + "_raw_force.png")

    % Same plot, but trimmed to only show a few wingbeat cycles between the
    % 2 and 4 second mark
    rate = round(rate);
    tS = 10; % trim start, 10 seconds into trial
    tE = 12; % trim end, 12 seconds into trial
    trimmed_force = force(:,tS*rate:tE*rate);
    trimmed_time = time(tS*rate:tE*rate);

    raw_force_plot(f2, tiles_2, trimmed_time, trimmed_force, case_name, drift, rate, fc, titles, true);

    %% Figure with voltage, current, and encoder data

    if async
        extra_data = [voltAdj, curAdj, speed];
    else
        extra_data = [voltAdj, curAdj, enc_pulse];
    end
    extra_data = extra_data';
    raw_extra_plot(f3, tiles_3, time, extra_data, case_name, rate, fc, titles);

    saveas(f3,'data\plots\' + case_name + "_raw_extra.png")

    % Same plot, but trimmed to only show a few wingbeat cycles between the
    % 2 and 4 second mark
    trimmed_extra_data = extra_data(:,tS*rate:tE*rate);

    raw_extra_plot(f4, tiles_4, trimmed_time, trimmed_extra_data, case_name, rate, fc, titles);
end