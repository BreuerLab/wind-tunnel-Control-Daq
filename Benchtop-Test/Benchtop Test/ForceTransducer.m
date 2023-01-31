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

    % Add the input channels.
    ch0 = this_daq.addinput("Dev1", 0, "Voltage");
    ch1 = this_daq.addinput("Dev1", 1, "Voltage");
    ch2 = this_daq.addinput("Dev1", 2, "Voltage");
    ch3 = this_daq.addinput("Dev1", 3, "Voltage");
    ch4 = this_daq.addinput("Dev1", 4, "Voltage");
    ch5 = this_daq.addinput("Dev1", 5, "Voltage");
    ch6 = this_daq.addinput("Dev1", 6, "Voltage");
    
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
    trial_file_name = trial_name + ".csv";
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

    % Add the input channels.
    ch0 = this_daq.addinput("Dev1", 0, "Voltage");
    ch1 = this_daq.addinput("Dev1", 1, "Voltage");
    ch2 = this_daq.addinput("Dev1", 2, "Voltage");
    ch3 = this_daq.addinput("Dev1", 3, "Voltage");
    ch4 = this_daq.addinput("Dev1", 4, "Voltage");
    ch5 = this_daq.addinput("Dev1", 5, "Voltage");
    ch6 = this_daq.addinput("Dev1", 6, "Voltage");

    voltage = obj.voltage;
    ch0.Range = [-voltage, voltage];
    ch1.Range = [-voltage, voltage];
    ch2.Range = [-voltage, voltage];
    ch3.Range = [-voltage, voltage];
    ch4.Range = [-voltage, voltage];
    ch5.Range = [-voltage, voltage];
    ch6.Range = [-voltage, voltage];
    
    % Start the DAq session.
    start(this_daq, "Duration", session_duration);

    % Read the data from this DAq session.
    these_raw_data = read(this_daq, seconds(session_duration));

    these_raw_data_table = timetable2table(these_raw_data);

    these_raw_data_table_times = these_raw_data_table(:, 1);
    these_raw_data_table_volt_vals = these_raw_data_table(:, 2:7);
    these_raw_data_table_trigger_vals = these_raw_data_table(:, 8);

    these_raw_times = seconds(table2array(these_raw_data_table_times));
    these_raw_volt_vals = table2array(these_raw_data_table_volt_vals);
    these_raw_trigger_vals = table2array(these_raw_data_table_trigger_vals);

    % Offset the data and multiply by the calibration matrix.
    volt_vals = these_raw_volt_vals(:, 1:6) - offsets(1,:);
    force_vals = obj.cal_matrix * volt_vals';
    force_vals = force_vals';

    these_results = [these_raw_times force_vals these_raw_trigger_vals];

    % Clear the DAq object.
    clear this_daq;

    % Write the offsets to a .csv file.
    trial_name = strjoin([case_name, "experiment", datestr(now, "mmddyy")], "_");
    trial_file_name = trial_name + ".csv";
    writematrix(these_results, trial_file_name);
end

function plot_results(obj, these_results)
    trigger_start_frame = -1;
    trigger_end_frame = -1;

    these_raw_trigger_vals = these_results(:, 8);
    
    for i = 1:length(these_raw_trigger_vals)
        if (trigger_start_frame == -1) % unassigned?
            if (these_raw_trigger_vals(i) < 1) % pulled low?
                trigger_start_frame = i;
            end
        elseif (trigger_end_frame == -1) % unassigned?
            if (these_raw_trigger_vals(i) > 1) % pulled high?
                trigger_end_frame = i;
            end
        end
    end
    
    
    % Open a new figure.
    f = figure;
    f.Position = [200 50 900 560];

    % Create three subplots to show the force time histories. 
    subplot(2, 3, 1);
    hold on
    plot(these_results(:, 1), these_results(:, 2));
    plot(these_results(trigger_start_frame:trigger_end_frame, 1), ...
        these_results(trigger_start_frame:trigger_end_frame, 2));
    title("F_x");
    xlabel("Time (s)");
    ylabel("Force (N)");
    subplot(2, 3, 2);
    hold on
    plot(these_results(:, 1), these_results(:, 3));
    plot(these_results(trigger_start_frame:trigger_end_frame, 1), ...
        these_results(trigger_start_frame:trigger_end_frame, 3));
    title("F_y");
    xlabel("Time (s)");
    ylabel("Force (N)");
    subplot(2, 3, 3);
    hold on
    plot(these_results(:, 1), these_results(:, 4));
    plot(these_results(trigger_start_frame:trigger_end_frame, 1), ...
        these_results(trigger_start_frame:trigger_end_frame, 4));
    title("F_z");
    xlabel("Time (s)");
    ylabel("Force (N)");

    % Create three subplots to show the moment time histories.
    subplot(2, 3, 4);
    hold on
    plot(these_results(:, 1), these_results(:, 5));
    plot(these_results(trigger_start_frame:trigger_end_frame, 1), ...
        these_results(trigger_start_frame:trigger_end_frame, 5));
    title("M_x");
    xlabel("Time (s)");
    ylabel("Torque (N m)");
    subplot(2, 3, 5);
    hold on
    plot(these_results(:, 1), these_results(:, 6));
    plot(these_results(trigger_start_frame:trigger_end_frame, 1), ...
        these_results(trigger_start_frame:trigger_end_frame, 6));
    title("M_y");
    xlabel("Time (s)");
    ylabel("Torque (N m)");
    subplot(2, 3, 6);
    hold on
    plot(these_results(:, 1), these_results(:, 7));
    plot(these_results(trigger_start_frame:trigger_end_frame, 1), ...
        these_results(trigger_start_frame:trigger_end_frame, 7));
    title("M_z");
    xlabel("Time (s)");
    ylabel("Torque (N m)");

    % Label the whole figure.
    sgtitle("Time Series of Loads for benchtop");
end

end

end