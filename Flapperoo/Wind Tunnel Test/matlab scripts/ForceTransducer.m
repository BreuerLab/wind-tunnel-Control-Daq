% This Force Transducer class was built to simplify the process of
% collecting force data from an ATI force transducer using a NI DAQ
% controlled by a PC running Matlab. 

% It includes the following methods:
% - obtain_cal (used to produce a matrix from an ATI .cal file)
% - trigger_check (to check if a trigger has been detected on one of
%                  the non-force-transducer channels)
% - Constructor (to make force transducer object)
% - Destructor (to delete force transducer object and associated daq
%               object)
% - setup_DAQ (to initialize the DAQ for the force transducer)
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
% AI7 - A digital output to mark recording period ("trigger")
% AI6 and AI7 do not need to be wired up, the trigger is an optional
% feature

% Author: Ronan Gissler
% Breuer Lab 2023

classdef ForceTransducer
properties
    voltage; % 5 or 10 volts
    cal_matrix; % matrix with calibration values (volts -> force)
    num_triggers; % 0, 1, or 2
    daq; % National Instruments Data Acquistion Object
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

% Used after data collection to check if the trigger was activated
% Inputs: trigger_data - time series data from trigger channel on DAQ
% Returns: trigger_detected - true or false
function trigger_detected = trigger_check(trigger_data)
    trigger_detected = true;

    try
        low_trigs_indices = find(trigger_data < 2);
        trigger_start_frame = low_trigs_indices(1);
        trigger_end_frame = low_trigs_indices(end);
        trimmed_results = results(trigger_start_frame:trigger_end_frame, :);
        % disp(trigger_end_frame - trigger_start_frame);
    catch
        trigger_detected = false;
    end

    if (low_trigs_indices(1) == 1 || low_trigs_indices(end) == length(trigger_data))
        trigger_detected = false;
    end
end

end

methods

% Constructor for Force Transducer Class
function obj = ForceTransducer(rate, voltage, calibration_filepath, num_triggers)
    if (voltage == 5 || voltage == 10)
        obj.voltage = voltage;
    else
        error("Invalid DAQ voltage for force transducer")
    end

    % produce a calibration matrix and assign to this object
    obj.cal_matrix = ForceTransducer.obtain_cal(calibration_filepath);

    obj.num_triggers = num_triggers;

    obj.daq = ForceTransducer.setup_DAQ(obj, voltage, rate);
end

% Destructor for Force Transducer Class
function delete(obj)
    delete(obj.daq);
    clear obj.daq;
end

% Builds DAQ object, adds channels, and sets appropriate channel
% voltages
% Inputs: obj - An instance of the force transducer class
%         voltage - Voltage rating for all channels
%         rate - Data sampling rate for DAQ
% Returns: this_DAQ - A fully constructed DAQ object
function this_DAQ = setup_DAQ(obj, voltage, rate)
    % Create DAq session and set its aquisition rate (Hz).
    this_DAQ = daq("ni");
    this_DAQ.Rate = rate;
    daq_ID = "Dev1";
    % Don't know your DAQ ID, type "daq.getDevices().ID" into the
    % command window to see what devices are currently connected to
    % your computer

    % Add the input channels.
    ch0 = this_DAQ.addinput(daq_ID, 0, "Voltage");
    ch1 = this_DAQ.addinput(daq_ID, 1, "Voltage");
    ch2 = this_DAQ.addinput(daq_ID, 2, "Voltage");
    ch3 = this_DAQ.addinput(daq_ID, 3, "Voltage");
    ch4 = this_DAQ.addinput(daq_ID, 4, "Voltage");
    ch5 = this_DAQ.addinput(daq_ID, 5, "Voltage");
    
    % Set the voltage range of the channels
    ch0.Range = [-voltage, voltage];
    ch1.Range = [-voltage, voltage];
    ch2.Range = [-voltage, voltage];
    ch3.Range = [-voltage, voltage];
    ch4.Range = [-voltage, voltage];
    ch5.Range = [-voltage, voltage];

    if (obj.num_triggers >= 1)
        ch6 = this_DAQ.addinput(daq_ID, 6, "Voltage");
        ch6.Range = [-voltage, voltage];
    end
    
    if (obj.num_triggers == 2)
        ch7 = this_DAQ.addinput(daq_ID, 7, "Voltage");
        ch7.Range = [-voltage, voltage];
    end
    
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
function [offsets] = get_force_offsets(obj, case_name, tare_duration)
    % Get the offsets for current trial.
    start(obj.daq, "Duration", tare_duration);
    [bias_timetable, ~] = read(obj.daq, seconds(tare_duration));
    bias_table = timetable2table(bias_timetable);
    bias_array = table2array(bias_table(:,2:7));
    
    % Preallocate an array to hold the offsets.
    offsets = zeros(2, 6);

    for i = 1:6
        offsets(1, i) = mean(bias_array(:, i));
        offsets(2, i) = std(bias_array(:, i));
    end
    
    % Write the offsets to a .csv file.
    trial_name = strjoin([case_name, "offsets", datestr(now, "mmddyy")], "_");
    trial_file_name = "data\offsets data\" + trial_name + ".csv";
    writematrix(offsets, trial_file_name);

    % Flush data from DAQ buffer
    flush(obj.daq);
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
% results - n x 6, n x 7, or n x 8 matrix where n is the number
% of sampled points. The first six columns represent Fx, Fy, Fz, Mx,
% My, and Mz. The additional two optional columns are used for data
% marking ("trigger").

% Note: This function also writes "results" to a .csv file
function [results] = measure_force(obj, case_name, session_duration, offsets)
    % Start the DAq session.
    start(obj.daq, "Duration", session_duration);

    % Read the data from this DAq session.
    raw_data = read(obj.daq, seconds(session_duration));

    raw_data_table = timetable2table(raw_data);

    raw_data_table_times = raw_data_table(:, 1);
    raw_data_table_volt_vals = raw_data_table(:, 2:7);

    raw_times = seconds(table2array(raw_data_table_times));
    raw_volt_vals = table2array(raw_data_table_volt_vals);
    
    if (obj.num_triggers >= 1)
        raw_data_table_galil_trigger_vals = raw_data_table(:, 8);
        raw_galil_trigger_vals = table2array(raw_data_table_galil_trigger_vals);
    end

    if (obj.num_triggers == 2)
        raw_data_table_camera_trigger_vals = raw_data_table(:, 9);
        raw_camera_trigger_vals = table2array(raw_data_table_camera_trigger_vals);
    end

    % Offset the data and multiply by the calibration matrix.
    volt_vals = raw_volt_vals(:, 1:6) - offsets(1,:);
    force_vals = obj.cal_matrix * volt_vals';
    force_vals = force_vals';

    if (obj.num_triggers == 0)
        results = [raw_times force_vals];
    elseif (obj.num_triggers == 1)
        results = [raw_times force_vals raw_galil_trigger_vals];
    elseif (obj.num_triggers == 2)
        results = [raw_times force_vals raw_galil_trigger_vals raw_camera_trigger_vals];
    end

    % Write the experiment data to a .csv file.
    trial_name = strjoin([case_name, "experiment", datestr(now, "mmddyy")], "_");
    trial_file_name = "data\experiment data\" + trial_name + ".csv";
    writematrix(results, trial_file_name);

    % Flush data from DAQ buffer
    flush(obj.daq);
end

% **************************************************************** %
% **********************Plotting Measurements********************* %
% **************************************************************** %
% This function provides preliminary force data in the form of a 2 x 3
% grid plot. The data has not been filtered, but if triggers are being
% used the data will also be plotted as trimmed by the trigger signal.
function plot_results(obj, results, case_name, drift)
    close all

    if (contains(case_name, '-'))
        case_name = strrep(case_name,'-','neg');
    end

    % Check if triggers were activated
    if (obj.num_triggers >= 1)
        A_trigger_detected = ForceTransducer.trigger_check(results(:, 8));
    end
    if (obj.num_triggers == 2)
        B_trigger_detected = ForceTransducer.trigger_check(results(:, 9));
    end

    %% Figure with raw data and trimmed data overlaid

    % Open a new figure.
    f = figure;
    f.Position = [1940 600 1150 750];
    tcl = tiledlayout(2,3);
    
    % Create three subplots to show the force time histories. 
    nexttile(tcl)
    hold on
    raw_line = plot(results(:, 1), results(:, 2), 'DisplayName', 'raw');
    if (obj.num_triggers > 0 && A_trigger_detected)
    first_trigger_line = plot(A_trimmed_results(:, 1), A_trimmed_results(:, 2), ...
        'DisplayName', 'first trigger');
    end
    if (obj.num_triggers == 2 && B_trigger_detected)
        second_trigger_line = plot(B_trimmed_results(:, 1), B_trimmed_results(:, 2), ...
        'DisplayName', 'second trigger');
    end
    title("F_x");
    xlabel("Time (s)");
    ylabel("Force (N)");
    
    nexttile(tcl)
    hold on
    plot(results(:, 1), results(:, 3));
    if (obj.num_triggers > 0 && A_trigger_detected)
    plot(A_trimmed_results(:, 1), A_trimmed_results(:, 3));
    end
    if (obj.num_triggers == 2 && B_trigger_detected)
        plot(B_trimmed_results(:, 1), B_trimmed_results(:, 3));
    end
    title("F_y");
    xlabel("Time (s)");
    ylabel("Force (N)");
    
    nexttile(tcl)
    hold on
    plot(results(:, 1), results(:, 4));
    if (obj.num_triggers > 0 && A_trigger_detected)
    plot(A_trimmed_results(:, 1), A_trimmed_results(:, 4));
    end
    if (obj.num_triggers == 2 && B_trigger_detected)
        plot(B_trimmed_results(:, 1), B_trimmed_results(:, 4));
    end
    title("F_z");
    xlabel("Time (s)");
    ylabel("Force (N)");

    % Create three subplots to show the moment time histories.
    nexttile(tcl)
    hold on
    plot(results(:, 1), results(:, 5));
    if (obj.num_triggers > 0 && A_trigger_detected)
    plot(A_trimmed_results(:, 1), A_trimmed_results(:, 5));
    end
    if (obj.num_triggers == 2 && B_trigger_detected)
        plot(B_trimmed_results(:, 1), B_trimmed_results(:, 5));
    end
    title("M_x");
    xlabel("Time (s)");
    ylabel("Torque (N m)");
    
    nexttile(tcl)
    hold on
    plot(results(:, 1), results(:, 6));
    if (obj.num_triggers > 0 && A_trigger_detected)
    plot(A_trimmed_results(:, 1), A_trimmed_results(:, 6));
    end
    if (obj.num_triggers == 2 && B_trigger_detected)
        plot(B_trimmed_results(:, 1), B_trimmed_results(:, 6));
    end
    title("M_y");
    xlabel("Time (s)");
    ylabel("Torque (N m)");
    
    nexttile(tcl)
    hold on
    plot(results(:, 1), results(:, 7));
    if (obj.num_triggers > 0 && A_trigger_detected)
    plot(A_trimmed_results(:, 1), A_trimmed_results(:, 7));
    end
    if (obj.num_triggers == 2 && B_trigger_detected)
        plot(B_trimmed_results(:, 1), B_trimmed_results(:, 7));
    end
    title("M_z");
    xlabel("Time (s)");
    ylabel("Torque (N m)");

    if (obj.num_triggers == 1 && A_trigger_detected)
        hL = legend([raw_line, first_trigger_line]);
        hL.Layout.Tile = 'East';
    elseif (obj.num_triggers == 2 && A_trigger_detected && B_trigger_detected)
        hL = legend([raw_line, first_trigger_line, second_trigger_line]);
        hL.Layout.Tile = 'East';
    end

    drift_string = string(drift);
    % separate numbers by space
    drift_string = [sprintf('%s    ',drift_string{1:end-1}), drift_string{end}];

    % Label the whole figure.
    sgtitle({"Force Transducer Data" strrep(case_name,'_','  ') ...
            "Over the course of the experiment, the force transducer drifted" ...
            "F_x                  F_y                   F_z                   M_x                   M_y                   M_z" ...
            drift_string});

    saveas(f,'data\plots\' + case_name + "_raw.jpg")

    %% Figure with trimmed data only (using first trigger)
    if (obj.num_triggers == 1 && A_trigger_detected)
    % Open a new figure.
    f = figure;
    f.Position = [1940 -260 1150 750];
    tcl = tiledlayout(2,3);
    
    % Create three subplots to show the force time histories. 
    nexttile(tcl)
    hold on
    plot(A_trimmed_results(:, 1), A_trimmed_results(:, 2), ...
        'DisplayName', 'galil trigger');
    title("F_x");
    xlabel("Time (s)");
    ylabel("Force (N)");
    
    nexttile(tcl)
    plot(A_trimmed_results(:, 1), A_trimmed_results(:, 3));
    title("F_y");
    xlabel("Time (s)");
    ylabel("Force (N)");
    
    nexttile(tcl)
    plot(A_trimmed_results(:, 1), A_trimmed_results(:, 4));
    title("F_z");
    xlabel("Time (s)");
    ylabel("Force (N)");

    % Create three subplots to show the moment time histories.
    nexttile(tcl)
    plot(A_trimmed_results(:, 1), A_trimmed_results(:, 5));
    title("M_x");
    xlabel("Time (s)");
    ylabel("Torque (N m)");
    
    nexttile(tcl)
    plot(A_trimmed_results(:, 1), A_trimmed_results(:, 6));
    title("M_y");
    xlabel("Time (s)");
    ylabel("Torque (N m)");
    
    nexttile(tcl)
    plot(A_trimmed_results(:, 1), A_trimmed_results(:, 7));
    title("M_z");
    xlabel("Time (s)");
    ylabel("Torque (N m)");

    % Label the whole figure.
    sgtitle({"Trimmed Force Transducer Data" strrep(case_name,'_','  ')});

    saveas(f,'data\plots\' + case_name + "_A_trimmed.jpg")

    disp("Standard deviations from this trimmed trial for each axis:")
    disp(std(abs(A_trimmed_results(:,2:4))));
    disp(std(abs(A_trimmed_results(:,5:7))));
    end

    show_plot = false;
    %% Figure with trimmed data only (using second trigger)
    if (show_plot && obj.num_triggers == 2 && B_trigger_detected)
    % Open a new figure.
    f = figure;
    f.Position = [1940 -260 1150 750];
    tcl = tiledlayout(2,3);
    
    % Create three subplots to show the force time histories. 
    nexttile(tcl)
    hold on
    plot(B_trimmed_results(:, 1), B_trimmed_results(:, 2), ...
        'DisplayName', 'galil trigger');
    title("F_x");
    xlabel("Time (s)");
    ylabel("Force (N)");
    
    nexttile(tcl)
    plot(B_trimmed_results(:, 1), B_trimmed_results(:, 3));
    title("F_y");
    xlabel("Time (s)");
    ylabel("Force (N)");
    
    nexttile(tcl)
    plot(B_trimmed_results(:, 1), B_trimmed_results(:, 4));
    title("F_z");
    xlabel("Time (s)");
    ylabel("Force (N)");

    % Create three subplots to show the moment time histories.
    nexttile(tcl)
    plot(B_trimmed_results(:, 1), B_trimmed_results(:, 5));
    title("M_x");
    xlabel("Time (s)");
    ylabel("Torque (N m)");
    
    nexttile(tcl)
    plot(B_trimmed_results(:, 1), B_trimmed_results(:, 6));
    title("M_y");
    xlabel("Time (s)");
    ylabel("Torque (N m)");
    
    nexttile(tcl)
    plot(B_trimmed_results(:, 1), B_trimmed_results(:, 7));
    title("M_z");
    xlabel("Time (s)");
    ylabel("Torque (N m)");

    % Label the whole figure.
    sgtitle({"Trimmed Force Transducer Data" strrep(case_name,'_','  ')});

    saveas(f,'data\plots\' + case_name + "_B_trimmed.jpg")

    disp("Standard deviations from this trimmed trial for each axis:")
    disp(std(abs(trimmed_results(:,2:4))));
    disp(std(abs(trimmed_results(:,5:7))));
    end
end

end

end