% This Force Transducer class was built to simplify the process of
% collecting force data from an ATI force transducer using a NI DAQ
% controlled by a PC running Matlab. 

% It includes the following methods:
% - obtain_cal (used to produce a matrix from an ATI .cal file)
% - trim_data (to trim the data based on another trigger)
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

% The "trigger" is just any digital signal sent to one of the analog
% input pins on the DAQ. It could be coming from a Galil (so that we
% know later during data processing when the beginning of a wingbeat
% cycle occurred or when the robot had finished accelerating). It
% could also be coming from a camera when it starts recording.

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

% Builds DAQ object, adds channels, and sets appropriate channel
% voltages
% Inputs: obj - An instance of the force transducer class
%         voltage - Voltage rating for all channels
%         rate - Data sampling rate for DAQ
% Returns: this_DAQ - A fully constructed DAQ object
function this_DAQ = setup_DAQ(num_triggers, voltage, rate)
    % Create DAq session and set its aquisition rate (Hz).
    this_DAQ = daq("ni");
    this_DAQ.Rate = rate;
    daq_ID = "Dev3";
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

    if (num_triggers >= 1)
        ch6 = this_DAQ.addinput(daq_ID, 6, "Voltage");
        ch6.Range = [-voltage, voltage];
    end
    
    if (num_triggers == 2)
        ch7 = this_DAQ.addinput(daq_ID, 7, "Voltage");
        ch7.Range = [-voltage, voltage];
    end
    
end

% Used after data collection to trim the data based on the trigger data
% Inputs: results - (n x 7) force transducer data in time
%         trigger_data - time series data from trigger channel on DAQ
% Returns: trimmed_results - results for all values where the trigger
%          voltage was low
function trimmed_results = trim_data(results, trigger_data)
    trimmed_results = zeros(size(results));
    low_trigs_indices = find(trigger_data < 2); % <2 Volts = Digital Low
    
    if ~(isempty(low_trigs_indices) || low_trigs_indices(1) == 1 ...
            || low_trigs_indices(end) == length(trigger_data))
        trigger_start_frame = low_trigs_indices(1);
        trigger_end_frame = low_trigs_indices(end);
        trimmed_results = results(trigger_start_frame:trigger_end_frame, :);
        % disp(trigger_end_frame - trigger_start_frame);
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

    obj.daq = ForceTransducer.setup_DAQ(num_triggers, voltage, rate);
end

% Destructor for Force Transducer Class
function delete(obj)
    delete(obj.daq);
    clear obj.daq;
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

    pause(1);

    % Flush data from DAQ buffer and stops background operations
    stop(obj.daq);
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

    % Flush data from DAQ buffer and stops background operations
    stop(obj.daq);
    flush(obj.daq);
end

% **************************************************************** %
% **********************Plotting Measurements********************* %
% **************************************************************** %
% This function provides preliminary force data in the form of a 2 x 3
% grid plot. The data has not been filtered, but if triggers are being
% used the data will also be plotted as trimmed by the trigger signal.
function plot_results(obj, results, case_name, drift, aliasing)
    close all

    if aliasing
        % Filter out noise above 10 kHz
        fc = 10000; % cutoff frequency
        fs = obj.daq.Rate;
        [b,a] = butter(6,fc/(fs/2));
        filtered_results = zeros(size(results));
        for i = 1:length(results(1,:))
            filtered_results(:, i) = filtfilt(b,a,results(:, i));
        end
        
        % Downsample from 80 kHz to 10 kHz
        results = downsample(filtered_results, 8);
    end
    
    if (contains(case_name, '-'))
        case_name = strrep(case_name,'-','neg');
    end

    % Check if triggers were activated and if so trim data
    A_trigger_detected = false;
    B_trigger_detected = false;
    if (obj.num_triggers >= 1)
        A_trimmed_results = ForceTransducer.trim_data(results(:,1:7), results(:, 8));
        if (length(A_trimmed_results) ~= length(results(:,1:7)))
            A_trigger_detected = true;
        end
    end
    if (obj.num_triggers == 2)
        B_trimmed_results = ForceTransducer.trim_data(results(:,1:7), results(:, 9));
        if (length(B_trimmed_results) ~= length(results(:,1:7)))
            B_trigger_detected = true;
        end
    end

    %% Figure with raw data and trimmed data overlaid
    titles = ["F_x","F_y","F_z","M_x","M_y","M_z"];
    x_label = "Time (s)";
    y_label_F = "Force (N)";
    y_label_M = "Moment (N*m)";
    axes_labels = [x_label, y_label_F, y_label_M];

    time = results(:,1);
    forces = results(:,2:7);

    force_means = round(mean(forces), 3);
    force_SDs = round(std(forces), 3);
    force_maxs = round(max(forces), 3);
    force_mins = round(min(forces), 3);

    % Open a new figure.
    f = figure;
    f.Position = [1940 600 1150 750];
    tcl = tiledlayout(2,3);
    
    % Create subplots to show the force and moment time histories
    for k = 1:6
        nexttile(tcl)
        hold on
        raw_line = plot(time, forces(:, k));
        if (obj.num_triggers > 0 && A_trigger_detected)
            first_trigger_line = plot(A_trimmed_results(:, 1), A_trimmed_results(:, k+1));
        end
        if (obj.num_triggers == 2 && B_trigger_detected)
            second_trigger_line = plot(B_trimmed_results(:, 1), B_trimmed_results(:, k+1));
        end

        if (k == 1)
            raw_line.DisplayName = 'raw';
            first_trigger_line.DisplayName = 'first trigger';
            second_trigger_line.DisplayName = 'second trigger';
        end

        title([titles(k), "avg: " + force_means(k) + "    SD: " + force_SDs(k), "max: " + force_maxs(k) + "    min: " + force_mins(k)]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(1 + ceil(k/3)));
        hold off
    end

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
    titles = ["F_x","F_y","F_z","M_x","M_y","M_z"];
    x_label = "Time (s)";
    y_label_F = "Force (N)";
    y_label_M = "Moment (N*m)";
    axes_labels = [x_label, y_label_F, y_label_M];

    time = A_trimmed_results(:,1);
    forces = A_trimmed_results(:,2:7);

    force_means = round(mean(forces), 3);
    force_SDs = round(std(forces), 3);
    force_maxs = round(max(forces), 3);
    force_mins = round(min(forces), 3);
    
    % Open a new figure.
    f = figure;
    f.Position = [1940 -260 1150 750];
    tcl = tiledlayout(2,3);
    
    % Create subplots to show the force and moment time histories
    for k = 1:6
        nexttile(tcl)
        hold on
        plot(time, forces(:, k));
        title([titles(k), "avg: " + force_means(k) + "    SD: " + force_SDs(k), "max: " + force_maxs(k) + "    min: " + force_mins(k)]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(1 + ceil(k/3)));
        hold off
    end

    % Label the whole figure.
    sgtitle({"Trimmed Force Transducer Data" strrep(case_name,'_','  ')});

    saveas(f,'data\plots\' + case_name + "_A_trimmed.jpg")

    %% histogram plot for trimmed data (first trigger)
    % Open a new figure.
    f = figure;
    f.Position = [1940 -260 1150 750];
    tcl = tiledlayout(2,3);

    for k = 1:6
        % Create three subplots to show the force time histories. 
        nexttile(tcl)
        hold on
        h = histogram(forces(k, :));
        h.Normalization = 'probability';
        h.EdgeColor = 'none';

        probability = h.Values;
        [M,I] = min(abs(h.BinEdges - force_means(k)));
        prob_at_mean = probability(I);
        ascending_arr = 0:0.5:1;
        l = plot(force_means(k)*ones(1,3), prob_at_mean*ascending_arr);
        l.LineWidth = 2;
        l.Color = 'black';

        title([titles(k), "avg: " + force_means(k) + "    SD: " ...
            + force_SDs(k), "max: " + force_maxs(k) + "    min: " + force_mins(k)]);
        xlabel(axes_labels(1 + ceil(k/3)));
        ylabel(axes_labels(1));
        hold off
    end

    % Label the whole figure.
    sgtitle({"Histogram of Force Transducer Data" strrep(case_name,'_','  ')});

    saveas(f,'data\plots\' + case_name + "_A_trimmed_hist.jpg")

    end

    show_plot = false;
    %% Figure with trimmed data only (using second trigger)
    if (show_plot && obj.num_triggers == 2 && B_trigger_detected)
    titles = ["F_x","F_y","F_z","M_x","M_y","M_z"];
    x_label = "Time (s)";
    y_label_F = "Force (N)";
    y_label_M = "Moment (N*m)";
    axes_labels = [x_label, y_label_F, y_label_M];

    time = B_trimmed_results(:,1);
    forces = B_trimmed_results(:,2:7);

    force_means = round(mean(forces), 3);
    force_SDs = round(std(forces), 3);
    force_maxs = round(max(forces), 3);
    force_mins = round(min(forces), 3);

    % Open a new figure.
    f = figure;
    f.Position = [1940 -260 1150 750];
    tcl = tiledlayout(2,3);
    
    % Create subplots to show the force and moment time histories
    for k = 1:6
        nexttile(tcl)
        hold on
        plot(time, forces(:, k));
        title([titles(k), "avg: " + force_means(k) + "    SD: " + force_SDs(k), "max: " + force_maxs(k) + "    min: " + force_mins(k)]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(1 + ceil(k/3)));
        hold off
    end

    % Label the whole figure.
    sgtitle({"Trimmed Force Transducer Data" strrep(case_name,'_','  ')});

    saveas(f,'data\plots\' + case_name + "_B_trimmed.jpg")
    end

    %% histogram plot for trimmed data (second trigger)
    % Open a new figure.
    f = figure;
    f.Position = [1940 -260 1150 750];
    tcl = tiledlayout(2,3);

    for k = 1:6
        % Create three subplots to show the force time histories. 
        nexttile(tcl)
        hold on
        h = histogram(forces(k, :));
        h.Normalization = 'probability';
        h.EdgeColor = 'none';

        probability = h.Values;
        [M,I] = min(abs(h.BinEdges - force_means(k)));
        prob_at_mean = probability(I);
        ascending_arr = 0:0.5:1;
        l = plot(force_means(k)*ones(1,3), prob_at_mean*ascending_arr);
        l.LineWidth = 2;
        l.Color = 'black';

        title([titles(k), "avg: " + force_means(k) + "    SD: " ...
            + force_SDs(k), "max: " + force_maxs(k) + "    min: " + force_mins(k)]);
        xlabel(axes_labels(1 + ceil(k/3)));
        ylabel(axes_labels(1));
        hold off
    end

    % Label the whole figure.
    sgtitle({"Histogram of Force Transducer Data" strrep(case_name,'_','  ')});

    saveas(f,'data\plots\' + case_name + "_B_trimmed_hist.jpg")
end

end

end