classdef ForceTransducer
properties
    voltage; % 5 or 10 volts
    cal_matrix;
end

methods
    
function obj = ForceTransducer
    obj.voltage = 5;

    % Load the load cell's calibration matrix into the Matlab workspace
    load ../'Force Transducer'/cal_FT43243_5V.mat;
    obj.cal_matrix = cal_matrix;
end
%%

% **************************************************************** %
% *******************Taring the Force Transducer****************** %
% **************************************************************** %
function [offsets] = get_force_offsets(obj, case_name, rate, tare_duration)
    % Create DAq session and set its aquisition rate (Hz).
    this_daq = daq("ni");
    this_daq.Rate = rate;
%     daq_ID = daq.getDevices().ID;
    daq_ID = "Dev1";
    
    % Add the input channels.
    ch0 = this_daq.addinput(daq_ID, 0, "Voltage");
    ch1 = this_daq.addinput(daq_ID, 1, "Voltage");
    ch2 = this_daq.addinput(daq_ID, 2, "Voltage");
    ch3 = this_daq.addinput(daq_ID, 3, "Voltage");
    ch4 = this_daq.addinput(daq_ID, 4, "Voltage");
    ch5 = this_daq.addinput(daq_ID, 5, "Voltage");
    ch6 = this_daq.addinput(daq_ID, 6, "Voltage");
    
    voltage = obj.voltage;
    ch0.Range = [-voltage, voltage];
    ch1.Range = [-voltage, voltage];
    ch2.Range = [-voltage, voltage];
    ch3.Range = [-voltage, voltage];
    ch4.Range = [-voltage, voltage];
    ch5.Range = [-voltage, voltage];
    ch6.Range = [-voltage, voltage];

    % Get the offsets for current trial.
    start(this_daq, "Duration", tare_duration);
    [bias_timetable, ~] = read(this_daq, seconds(tare_duration));
    bias_table = timetable2table(bias_timetable);
    bias_array = table2array(bias_table(:,2:7));
    
    % Preallocate an array to hold the offsets.
    offsets = zeros(2, 6);

    for i = 1:6
        offsets(1, i) = mean(bias_array(:, i));
        offsets(2, i) = std(bias_array(:, i)) / sqrt(rate * tare_duration);
    end
    
    % Clear the DAq object.
    clear this_daq;
    
    % Write the offsets to a .csv file.
    trial_name = strjoin([case_name, "offsets", datestr(now, "mmddyy")], "_");
    trial_file_name = "data\offsets data\" + trial_name + ".csv";
    writematrix(offsets, trial_file_name);
end

%%

% **************************************************************** %
% ***********************Taking Measurements********************** %
% **************************************************************** %
function [these_results] = measure_force(obj, case_name, rate, session_duration, offsets)
    % Create DAq session and set its aquisition rate (Hz).
    this_daq = daq("ni");
    this_daq.Rate = rate;
%     daq_ID = daq.getDevices().ID;
    daq_ID = "Dev1";

    % Add the input channels.
    ch0 = this_daq.addinput(daq_ID, 0, "Voltage");
    ch1 = this_daq.addinput(daq_ID, 1, "Voltage");
    ch2 = this_daq.addinput(daq_ID, 2, "Voltage");
    ch3 = this_daq.addinput(daq_ID, 3, "Voltage");
    ch4 = this_daq.addinput(daq_ID, 4, "Voltage");
    ch5 = this_daq.addinput(daq_ID, 5, "Voltage");
    ch6 = this_daq.addinput(daq_ID, 6, "Voltage");
    ch7 = this_daq.addinput(daq_ID, 7, "Voltage");

    voltage = obj.voltage;
    ch0.Range = [-voltage, voltage];
    ch1.Range = [-voltage, voltage];
    ch2.Range = [-voltage, voltage];
    ch3.Range = [-voltage, voltage];
    ch4.Range = [-voltage, voltage];
    ch5.Range = [-voltage, voltage];
    ch6.Range = [-voltage, voltage];
    ch7.Range = [-voltage, voltage];
    
    % Start the DAq session.
    start(this_daq, "Duration", session_duration);

    % Read the data from this DAq session.
    these_raw_data = read(this_daq, seconds(session_duration));

    these_raw_data_table = timetable2table(these_raw_data);

    these_raw_data_table_times = these_raw_data_table(:, 1);
    these_raw_data_table_volt_vals = these_raw_data_table(:, 2:7);
    these_raw_data_table_galil_trigger_vals = these_raw_data_table(:, 8);
    these_raw_data_table_camera_trigger_vals = these_raw_data_table(:, 9);

    these_raw_times = seconds(table2array(these_raw_data_table_times));
    these_raw_volt_vals = table2array(these_raw_data_table_volt_vals);
    these_raw_galil_trigger_vals = table2array(these_raw_data_table_galil_trigger_vals);
    these_raw_camera_trigger_vals = table2array(these_raw_data_table_camera_trigger_vals);

    % Offset the data and multiply by the calibration matrix.
    volt_vals = these_raw_volt_vals(:, 1:6) - offsets(1,:);
    force_vals = obj.cal_matrix * volt_vals';
    force_vals = force_vals';

    these_results = [these_raw_times force_vals these_raw_galil_trigger_vals these_raw_camera_trigger_vals];

    % Clear the DAq object.
    clear this_daq;

    % Write the experiment data to a .csv file.
    trial_name = strjoin([case_name, "experiment", datestr(now, "mmddyy")], "_");
    trial_file_name = "data\experiment data\" + trial_name + ".csv";
    writematrix(these_results, trial_file_name);
end

function plot_results(obj, these_results, case_name, drift)
    close all

    if (contains(case_name, '-'))
        case_name = strrep(case_name,'-','neg');
    end

    try
    these_galil_trigs = these_results(:, 8);
    these_low_galil_trigs_indices = find(these_galil_trigs < 2);
    galil_trigger_start_frame = these_low_galil_trigs_indices(1);
    galil_trigger_end_frame = these_low_galil_trigs_indices(end);
    trimmed_results = these_results(galil_trigger_start_frame:galil_trigger_end_frame, :);
    % disp(trigger_end_frame - trigger_start_frame);

    these_camera_trigs = these_results(:, 9);
    these_low_camera_trigs_indices = find(these_camera_trigs < 2);
    camera_trigger_start_frame = these_low_camera_trigs_indices(1);
    camera_trigger_end_frame = these_low_camera_trigs_indices(end);
    % disp(trigger_end_frame - trigger_start_frame);
    
    % Open a new figure.
    f = figure;
    f.Position = [1940 600 1150 750];
    tcl = tiledlayout(2,3);
    
    % Create three subplots to show the force time histories. 
    nexttile(tcl)
    hold on
    raw_line = plot(these_results(:, 1), these_results(:, 2), 'DisplayName', 'raw');
    galil_trigger_line = plot(trimmed_results(:, 1), trimmed_results(:, 2), ...
        'DisplayName', 'galil trigger');
    title("F_x");
    xlabel("Time (s)");
    ylabel("Force (N)");
    
    nexttile(tcl)
    hold on
    plot(these_results(:, 1), these_results(:, 3));
    plot(trimmed_results(:, 1), trimmed_results(:, 3));
    title("F_y");
    xlabel("Time (s)");
    ylabel("Force (N)");
    
    nexttile(tcl)
    hold on
    plot(these_results(:, 1), these_results(:, 4));
    plot(trimmed_results(:, 1), trimmed_results(:, 4));
    title("F_z");
    xlabel("Time (s)");
    ylabel("Force (N)");

    % Create three subplots to show the moment time histories.
    nexttile(tcl)
    hold on
    plot(these_results(:, 1), these_results(:, 5));
    plot(trimmed_results(:, 1), trimmed_results(:, 5));
    title("M_x");
    xlabel("Time (s)");
    ylabel("Torque (N m)");
    
    nexttile(tcl)
    hold on
    plot(these_results(:, 1), these_results(:, 6));
    plot(trimmed_results(:, 1), trimmed_results(:, 6));
    title("M_y");
    xlabel("Time (s)");
    ylabel("Torque (N m)");
    
    nexttile(tcl)
    hold on
    plot(these_results(:, 1), these_results(:, 7));
    plot(trimmed_results(:, 1), trimmed_results(:, 7));
    title("M_z");
    xlabel("Time (s)");
    ylabel("Torque (N m)");

    hL = legend([raw_line, galil_trigger_line]);
    % Move the legend to the right side of the figure
    hL.Layout.Tile = 'East';

    drift_string = string(drift);
    % separate numbers by space
    drift_string = [sprintf('%s    ',drift_string{1:end-1}), drift_string{end}];

    % Label the whole figure.
    sgtitle({"Force Transducer Data" strrep(case_name,'_','  ') ...
            "Over the course of the experiment, the force transducer drifted" ...
            "F_x                  F_y                   F_z                   M_x                   M_y                   M_z" ...
            drift_string});

    saveas(f,'data\plots\' + case_name + "_raw.jpg")

    % Open a new figure.
    f = figure;
    f.Position = [1940 -260 1150 750];
    tcl = tiledlayout(2,3);
    
    % Create three subplots to show the force time histories. 
    nexttile(tcl)
    hold on
    plot(trimmed_results(:, 1), trimmed_results(:, 2), ...
        'DisplayName', 'galil trigger');
    title("F_x");
    xlabel("Time (s)");
    ylabel("Force (N)");
    
    nexttile(tcl)
    plot(trimmed_results(:, 1), trimmed_results(:, 3));
    title("F_y");
    xlabel("Time (s)");
    ylabel("Force (N)");
    
    nexttile(tcl)
    plot(trimmed_results(:, 1), trimmed_results(:, 4));
    title("F_z");
    xlabel("Time (s)");
    ylabel("Force (N)");

    % Create three subplots to show the moment time histories.
    nexttile(tcl)
    plot(trimmed_results(:, 1), trimmed_results(:, 5));
    title("M_x");
    xlabel("Time (s)");
    ylabel("Torque (N m)");
    
    nexttile(tcl)
    plot(trimmed_results(:, 1), trimmed_results(:, 6));
    title("M_y");
    xlabel("Time (s)");
    ylabel("Torque (N m)");
    
    nexttile(tcl)
    plot(trimmed_results(:, 1), trimmed_results(:, 7));
    title("M_z");
    xlabel("Time (s)");
    ylabel("Torque (N m)");

    % Label the whole figure.
    sgtitle({"Force Transducer Data" strrep(case_name,'_','  ')});

    saveas(f,'data\plots\' + case_name + "_trigger.jpg")

    disp("Standard deviations from this trimmed trial for each axis:")
    disp(std(abs(trimmed_results(:,2:4))));
    disp(std(abs(trimmed_results(:,5:7))));

    catch
    % Open a new figure.
    f = figure;
    f.Position = [1940 600 1150 750];
    tcl = tiledlayout(2,3);
    
    % Create three subplots to show the force time histories. 
    nexttile(tcl)
    hold on
    raw_line = plot(these_results(:, 1), these_results(:, 2), 'DisplayName', 'raw');
    title("F_x");
    xlabel("Time (s)");
    ylabel("Force (N)");
    
    nexttile(tcl)
    hold on
    plot(these_results(:, 1), these_results(:, 3));
    title("F_y");
    xlabel("Time (s)");
    ylabel("Force (N)");
    
    nexttile(tcl)
    hold on
    plot(these_results(:, 1), these_results(:, 4));
    title("F_z");
    xlabel("Time (s)");
    ylabel("Force (N)");

    % Create three subplots to show the moment time histories.
    nexttile(tcl)
    hold on
    plot(these_results(:, 1), these_results(:, 5));
    title("M_x");
    xlabel("Time (s)");
    ylabel("Torque (N m)");
    
    nexttile(tcl)
    hold on
    plot(these_results(:, 1), these_results(:, 6));
    title("M_y");
    xlabel("Time (s)");
    ylabel("Torque (N m)");
    
    nexttile(tcl)
    hold on
    plot(these_results(:, 1), these_results(:, 7));
    title("M_z");
    xlabel("Time (s)");
    ylabel("Torque (N m)");

    hL = legend([raw_line]);
    % Move the legend to the right side of the figure
    hL.Layout.Tile = 'East';

    drift_string = string(drift);
    % separate numbers by space
    drift_string = [sprintf('%s    ',drift_string{1:end-1}), drift_string{end}];

    % Label the whole figure.
    sgtitle({"Force Transducer Data" strrep(case_name,'_','  ') ...
            "Over the course of the experiment, the force transducer drifted" ...
            "F_x                  F_y                   F_z                   M_x                   M_y                   M_z" ...
            drift_string});

    saveas(f,'data\plots\' + case_name + "_raw.jpg")
    end
end

end

end