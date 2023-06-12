% This Force Transducer class was built to simplify the process of
% collecting force data from an ATI force transducer using a NI DAQ
% controlled by a PC running Matlab. 

% It includes the following methods:
% - Constructor (to make force transducer object)
% - obtain_cal (used to produce a matrix from an ATI .cal file)
% - get_force_offsets (to record initial offset so that data can be
%                      tared later)
% - measure_force (to record force data and tare it)
% - plot_results (plots force data)

% To use the force transducer you will need the following hardware
% - force transducer
% - amplifier for the force transducer
% - power cord for amplifier
% - cable to connect force transducer to amplifier
% - cable to connect amplifier to NI-DAQ
% - NI-DAQ
% - power cord for NI-DAQ
% - USB connection from NI-DAQ to your computer

% You will also need the following software:
% - Matlab
% - NI-DAQmx Support from Data Acquisition Matlab Toolbox
% - NI Device Driver
% - NI Max

% This code assumes you have wired the force transducer axes to the
% DAQ in the following order:
% AI0 - Fx
% AI1 - Fy
% AI2 - Fz
% AI3 - Mx
% AI4 - My
% AI5 - Mz
% AI6 - A digital output to mark recording period ("trigger")

% Author: Ronan Gissler
% Breuer Lab 2023

classdef ForceTransducer
properties
    voltage; % 5 or 10 volts
    cal_matrix; % matrix with calibration values (volts -> force)
    num_triggers; % 0, 1, or 2
end

methods(Static)

% **************************************************************** %
% *****************Obtaining a Calibration Matrix***************** %
% **************************************************************** %
% This function parses an ATI .cal calibration file into a matrix in
% Matlab that can be worked with more easily.
% Inputs: calibration_filepath - The path to a .cal file
% Returns: cal_mat - A matlab matrix
function cal_mat = obtain_cal(calibration_filepath)

    % Preallocate space for calibration matrix
    cal_mat = zeros(6,6);

    file_id = fopen(calibration_filepath);
    
    % Get first line from file
    tline = convertCharsToStrings(fgetl(file_id));
    
    % Counter for each measurement axis (6 total: Fx, Fy, Fz, Mx, My, Mz)
    axis_count = 1;
    
    % Loop through each line until reaching the end of the file
    while isstring(tline)
        
        % Lines with "UserAxis Name" have the calibration values
        if contains(tline, "UserAxis Name")
            split_line = split(tline);
            
            % Counter for each calibration value (six values for each axis)
            value_count = 1;
            
            for i = 1:length(split_line)
                % Check if phrase is numeric
                [num, status] = str2num(split_line(i));
                if status
                    % add that calibration value to matrix
                    cal_mat(axis_count, value_count) = num;
                    
                    % move on to the next value
                    value_count = value_count + 1;
                end
            end
            
            % move on to the next measurement axis
            axis_count = axis_count + 1;
        end
        
        % get next line
        tline = convertCharsToStrings(fgetl(file_id));
    end
    
    fclose(file_id);

end

function this_DAQ = setup_DAQ()
    % Create DAq session and set its aquisition rate (Hz).
    this_daq = daq("ni");
    this_daq.Rate = rate;
    daq_ID = "Dev1";
    % Don't know your DAQ ID, type "daq.getDevices().ID" into the
    % command window to see what devices are currently connected to
    % your computer

    % Add the input channels.
    ch0 = this_daq.addinput(daq_ID, 0, "Voltage");
    ch1 = this_daq.addinput(daq_ID, 1, "Voltage");
    ch2 = this_daq.addinput(daq_ID, 2, "Voltage");
    ch3 = this_daq.addinput(daq_ID, 3, "Voltage");
    ch4 = this_daq.addinput(daq_ID, 4, "Voltage");
    ch5 = this_daq.addinput(daq_ID, 5, "Voltage");
    
    % Set the voltage range of the channels
    voltage = obj.voltage;
    ch0.Range = [-voltage, voltage];
    ch1.Range = [-voltage, voltage];
    ch2.Range = [-voltage, voltage];
    ch3.Range = [-voltage, voltage];
    ch4.Range = [-voltage, voltage];
    ch5.Range = [-voltage, voltage];

    if (num_triggers >= 1)
        ch6 = this_daq.addinput(daq_ID, 6, "Voltage");
        ch6.Range = [-voltage, voltage];
    end
    
    if (num_triggers == 2)
        ch7 = this_daq.addinput(daq_ID, 7, "Voltage");
        ch7.Range = [-voltage, voltage];
    end
    
end

end

methods
    
function obj = ForceTransducer(voltage, calibration_filepath, num_triggers)
    if (voltage == 5 || voltage == 10)
        obj.voltage = voltage;
    else
        error("Invalid DAQ voltage for force transducer")
    end

    % produce a calibration matrix and assign to this object
    obj.cal_matrix = ForceTransducer.obtain_cal(calibration_filepath);

    obj.num_triggers = num_triggers;
end

% **************************************************************** %
% *******************Taring the Force Transducer****************** %
% **************************************************************** %
% This function measures the forces prior to the experiment so that
% later measurements can be tared accordingly.

% Inputs: 
% case_name - Name of this experimental case (ex: '0.5Hz_PDMS')
% rate - DAQ measurement rate in Hz (ex: 3000)
% tare_duration - Duration of measurement in sec (ex: 2)

% Returns: 
% offsets - 2x6 matrix whose columns represent each axis (3 forces, 3
% moments). First row is the means of the measurement and the second
% row is the standard deviations of the measurements

% Note: This function also writes "offsets" to a .csv file
function [offsets] = get_force_offsets(obj, case_name, rate, tare_duration)
    disp("Starting to Collect Offsets")

    this_DAQ = ForceTransducer.setup_DAQ();

    % Get the offsets for current trial.
    start(this_DAQ, "Duration", tare_duration);
    [bias_timetable, ~] = read(this_DAQ, seconds(tare_duration));
    bias_table = timetable2table(bias_timetable);
    bias_array = table2array(bias_table(:,2:7));
    
    % Preallocate an array to hold the offsets.
    offsets = zeros(2, 6);

    for i = 1:6
        offsets(1, i) = mean(bias_array(:, i));
        offsets(2, i) = std(bias_array(:, i));
    end
    
    % Clear the DAq object.
    clear this_DAQ;
    
    % Write the offsets to a .csv file.
    trial_name = strjoin([case_name, "offsets", datestr(now, "mmddyy")], "_");
    trial_file_name = "data\offsets data\" + trial_name + ".csv";
    writematrix(offsets, trial_file_name);

    disp("Finished Collecting Offsets")
end

% **************************************************************** %
% ***********************Taking Measurements********************** %
% **************************************************************** %
% This function measures the forces during the experiment and tares
% them at the end of measurement. 

% Inputs: 
% case_name - Name of this experimental case (ex: '0.5Hz_PDMS')
% rate - DAQ measurement rate in Hz (ex: 3000)
% session_duration - Duration of measurement in sec (ex: 2)
% offsets - the result produced after calling get_force_offsets

% Returns: 
% these_results - n x 6, n x 7, or n x 8 matrix where n is the number
% of sampled points. The first six columns represent Fx, Fy, Fz, Mx,
% My, and Mz. The additional two optional columns are used for data
% marking ("trigger").

% Note: This function also writes "these_results" to a .csv file
function [these_results] = measure_force(obj, case_name, rate, session_duration, offsets)
    disp("Starting to Collect Data")

    this_DAQ = ForceTransducer.setup_DAQ();
    
    % Start the DAq session.
    start(this_daq, "Duration", session_duration);

    % Read the data from this DAq session.
    these_raw_data = read(this_daq, seconds(session_duration));

    these_raw_data_table = timetable2table(these_raw_data);

    these_raw_data_table_times = these_raw_data_table(:, 1);
    these_raw_data_table_volt_vals = these_raw_data_table(:, 2:7);

    these_raw_times = seconds(table2array(these_raw_data_table_times));
    these_raw_volt_vals = table2array(these_raw_data_table_volt_vals);
    
    if (num_triggers >= 1)
        these_raw_data_table_galil_trigger_vals = these_raw_data_table(:, 8);
        these_raw_galil_trigger_vals = table2array(these_raw_data_table_galil_trigger_vals);
    end

    if (num_triggers == 2)
        these_raw_data_table_camera_trigger_vals = these_raw_data_table(:, 9);
        these_raw_camera_trigger_vals = table2array(these_raw_data_table_camera_trigger_vals);
    end

    % Offset the data and multiply by the calibration matrix.
    volt_vals = these_raw_volt_vals(:, 1:6) - offsets(1,:);
    force_vals = obj.cal_matrix * volt_vals';
    force_vals = force_vals';

    if (num_triggers == 0)
        these_results = [these_raw_times force_vals];
    elseif (num_triggers == 1)
        these_results = [these_raw_times force_vals these_raw_galil_trigger_vals];
    elseif (num_triggers == 2)
        these_results = [these_raw_times force_vals these_raw_galil_trigger_vals these_raw_camera_trigger_vals];
    end

    % Clear the DAq object.
    clear this_daq;

    % Write the experiment data to a .csv file.
    trial_name = strjoin([case_name, "experiment", datestr(now, "mmddyy")], "_");
    trial_file_name = "data\experiment data\" + trial_name + ".csv";
    writematrix(these_results, trial_file_name);

    disp("Finished Collecting Data")
end

% **************************************************************** %
% **********************Plotting Measurements********************* %
% **************************************************************** %
% This function provides preliminary force data in the form of a 2 x 3
% grid plot. The data has not been filtered.
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