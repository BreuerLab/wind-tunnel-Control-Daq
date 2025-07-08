% This Force Transducer class was built to simplify the process of
% collecting force data from an ATI force transducer using a NI DAQ
% controlled by a PC running Matlab. 

% It includes the following methods:
% - obtain_cal (used to produce a matrix from an ATI .cal file)
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

% Author: Ronan Gissler
% Breuer Lab 2023

classdef Calimero
properties
    forceVoltage; % 5 or 10 volts
    daq; % National Instruments Data Acquistion Object
end

methods(Static)

% Builds DAQ object, adds channels, and sets appropriate channel
% voltages
% Inputs: forceVoltage - Voltage rating for all channels
%         rate - Data sampling rate for DAQ
% Returns: this_DAQ - A fully constructed DAQ object
function this_DAQ = setup_DAQ(forceVoltage, rate)
    % Create DAQ session and set its aquisition rate (Hz).
    this_DAQ = daq("ni");
    this_DAQ.Rate = rate;
    daq_ID = "Dev4";
    % Don't know your DAQ ID, type "daq.getDevices().ID" into the
    % command window to see what devices are currently connected to
    % your computer

    % -------------- Add the input channels --------------
    % 6 force channels: Fx, Fy, Fz, Mx, My, Mz
    ch0 = this_DAQ.addinput(daq_ID, 0, "Voltage");
    ch1 = this_DAQ.addinput(daq_ID, 1, "Voltage");
    ch2 = this_DAQ.addinput(daq_ID, 2, "Voltage");
    ch3 = this_DAQ.addinput(daq_ID, 3, "Voltage");
    ch4 = this_DAQ.addinput(daq_ID, 4, "Voltage");
    ch5 = this_DAQ.addinput(daq_ID, 5, "Voltage");

    % channel for encoder measurement
    ch6 = this_DAQ.addinput(daq_ID, 21, "Voltage");

    % channel for voltage measurement
    ch7 = this_DAQ.addinput(daq_ID, 20, "Voltage");
    
    % --------- Set the voltage range of the channels ---------
    ch0.Range = [-forceVoltage, forceVoltage];
    ch1.Range = [-forceVoltage, forceVoltage];
    ch2.Range = [-forceVoltage, forceVoltage];
    ch3.Range = [-forceVoltage, forceVoltage];
    ch4.Range = [-forceVoltage, forceVoltage];
    ch5.Range = [-forceVoltage, forceVoltage];
    ch6.Range = [-5, 5];
    ch7.Range = [-5, 5];
end

end

methods

%% Constructor for Force Transducer Class
function obj = Calimero(rate, forceVoltage, calibration_filepath)
    if (forceVoltage == 5 || forceVoltage == 10)
        obj.forceVoltage = forceVoltage;
    else
        error("Invalid DAQ voltage for force transducer")
    end

    obj.daq = Calimero.setup_DAQ(voltage, rate);
end

%% Destructor for Force Transducer Class
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
    % Get the offsets for current trial, including current and voltage channels.
    
    % Start the DAQ session for tare_duration seconds
    start(obj.daq, "Duration", tare_duration);
    
    % Read the data
    [bias_timetable, ~] = read(obj.daq, seconds(tare_duration));
    bias_table = timetable2table(bias_timetable);
    
    % Extract columns 2 to 9 (6 forces + current + voltage + position)
    bias_array = table2array(bias_table(:, 2:9));
    
    % Preallocate 2x8 offset matrix (mean and std for each channel)
    offsets = zeros(2, 8);

    for i = 1:8
        offsets(1, i) = mean(bias_array(:, i));  % mean (offset)
        offsets(2, i) = std(bias_array(:, i));   % std (noise)
    end
    
    % Save offsets to CSV file
    trial_name = strjoin([case_name, "offsets", datestr(now, "mmddyy")], "_");
    trial_file_name = "data\offsets data\" + trial_name + ".csv";
    writematrix(offsets, trial_file_name);

    % Add timestamp to file
    fileID = fopen(trial_file_name, 'a');
    fprintf(fileID, '%s\n', string(datetime));
    fclose(fileID);

    pause(1);

    % Stop and flush DAQ buffer
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
% My, and Mz.

% Note: This function also writes "results" to a .csv file
function [results] = measure_force(obj, case_name, session_duration, offsets)
    % Start the DAQ session.
    start(obj.daq, "Duration", session_duration);

    % Read the data
    raw_data = read(obj.daq, seconds(session_duration));
    raw_data_table = timetable2table(raw_data);

    raw_data_table_times = raw_data_table(:, 1); % timestamps
    raw_data_table_volt_vals = raw_data_table(:, 2:9); % voltage inputs (6 channels)

    raw_times = seconds(table2array(raw_data_table_times));
    raw_volt_vals = table2array(raw_data_table_volt_vals);
    
    force_vals = volt_to_force(raw_volt_vals, offsets, calibration_filepath);

    volt_daq = raw_volt_vals(:, 8);  % tension mesurée DAQ [-5,5] V
    
    % === Convert encoder signal to analog ===
    analog_voltage = raw_volt_vals(:, 7)- offsets(1,7);  % [0 - 3.3 V]
    % Infer min/max from recording
    Vmin = min(analog_voltage);
    Vmax = max(analog_voltage);
    
    % THE LINE OF CODE BELOW DOESNT APPEAR TO DO ANYTHING
    % Clamp between Vmin and Vmax to avoid outliers
    analog_voltage = max(min(analog_voltage, Vmax), Vmin);
    
    % Linear scaling to [0°, 360°]
    angle_per_turn = 360;  
    position_vals = (analog_voltage - Vmin) / (Vmax - Vmin) * angle_per_turn;
    % Vmin and Vmax used since may not be 0 and 3.3V exactly,
    % the assumption here is that Vmin corresponds to an angle of 0°
    
    % === Step 2 : Unwrap to get cumulative absolute angle ===
    theta = deg2rad(position_vals);
    position_vals_absolute = rad2deg(unwrap(theta));

    % === Conversion from absolute angle to Z position via geometry ===
    % angle_per_turn = 360;
    % theta = deg2rad(mod(position_vals_absolute, angle_per_turn));  % angle within one turn [0, 2π] for the geometry
    
    Z = get_wingtip_motion(theta);

    % Add estimated position and digital lines (A and B)
    results = [results volt_reel_offset_corr position_vals_absolute Z];
    
    % Save
    trial_name = strjoin([case_name, "experiment", datestr(now, "mmddyy")], "_");
    trial_file_name = "data\experiment data\" + trial_name + ".csv";
    writematrix(results, trial_file_name);
    
    % Stop and flush DAQ
    stop(obj.daq);
    flush(obj.daq);
end

% **************************************************************** %
% **********************Plotting Measurements********************* %
% **************************************************************** %
% This function provides preliminary force data in the form of a 2 x 3
% grid plot.
function plot_results(obj, results, case_name, drift)
    close all
    titles = ["F_x","F_y","F_z","M_x","M_y","M_z","Power","Position"];

    if (contains(case_name, '-'))
        case_name = strrep(case_name,'-','neg');
    end

    %% Figure with raw data and trimmed data overlaid

    x_label = "Time (s)";
    y_label_F = "Force (N)";
    y_label_M = "Moment (N*m)";
    y_label_V = "Voltage (V)";
    y_label_C = "Current (mA)";
    y_label_P = "Increment";
    y_label_Z = "mm";
    axes_labels = [x_label, y_label_F, y_label_M, y_label_V, y_label_C, y_label_P, y_label_Z];

    % Open a new figure.
    f = figure;
    tcl = tiledlayout(2,5);
    
    raw_time = results(:, 1);

    forces = results(:,2:7);
    force_means = round(mean(forces), 3);
    force_SDs = round(std(forces), 3);
    force_maxs = round(max(forces), 3);
    force_mins = round(min(forces), 3);

    % --- Filtering forces and moments (6 channels)
    frame_rate = 10000;
    fc_force = 100;  % cutoff frequency in Hz
    [bF, aF] = butter(4, fc_force / (frame_rate / 2));
    forces_filtered = filtfilt(bF, aF, forces);  % same size as forces
    
    % Plot forces and moments (6 plots)
    for k = 1:6
        nexttile(tcl)
        hold on
        plot(raw_time, forces(:, k), 'Color', [0.7 0.7 0.7], 'DisplayName', 'raw');  % raw force in gray
        plot(raw_time, forces_filtered(:, k), 'b', 'DisplayName', 'filtered');       % filtered force in blue
    
        title([titles(k), " avg: " + force_means(k) + ...
               "    SD: " + force_SDs(k) + ...
               "    max: " + force_maxs(k) + ...
               "    min: " + force_mins(k)]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(1 + ceil(k/3)));
        legend;
        hold off
    end

    % Additional Data : Voltage, Current, ChanelA, ChanelB
    extra_data = results(:, 8:10);
    extra_means = round(mean(extra_data), 3);
    extra_SDs = round(std(extra_data), 3);
    extra_maxs = round(max(extra_data), 3);
    extra_mins = round(min(extra_data), 3);

    %y_labels_extra = [y_label_V, y_label_C, y_label_P];
    y_labels_extra = [y_label_V, y_label_P, y_label_Z];
    for j = 1:2
        nexttile(tcl)
        hold on
        plot(raw_time, extra_data(:, j), 'DisplayName', 'raw');

        title([titles(j+6), " avg: " + extra_means(j) + ...
               "    SD: " + extra_SDs(j) + ...
               "    max: " + extra_maxs(j) + ...
               "    min: " + extra_mins(j)]);
        xlabel(axes_labels(1));
        ylabel(y_labels_extra(j));
        hold off
    end

    nexttile(tcl)
    hold on
    plot(raw_time, extra_data(:, 3), 'DisplayName', 'raw');
    xlabel(axes_labels(1));
    ylabel(y_labels_extra(3));
    hold off

    drift_string = string(drift);
    % separate numbers by space
    drift_string = [sprintf('%s    ',drift_string{1:end-1}), drift_string{end}];

    % Label the whole figure.
    sgtitle({"Force Transducer Data" strrep(case_name,'_','  ') ...
            "Over the course of the experiment, the force transducer drifted" ...
            "F_x                  F_y                   F_z                   M_x                   M_y                   M_z" ...
            drift_string});

    saveas(f,'data\plots\' + case_name + "_raw.fig")
    

    %% Input data
    data = results;
    angle_per_turn = 360; 
    % Extract useful columns
    position_vals = data(:, end-1);    % Motor angle (ticks or degrees)
    force_Z = data(:, 4);              % Force in z-direction
    Z_vals = data(:, end);             % wingtip position
    raw_times = data(:, 1);            % Time (not used here)
    force_X = data(:,2);


    % Find the first index where the position is no longer zero
    % start_idx = find(position_vals ~= 0, 1, 'first');
    
    % Find the first index where the variation from the first value exceeds
    % angle_threshold
    angle_threshold = 15;  % threshold (in deg)
    initial_angle = position_vals(1);
    delta_from_start = abs(position_vals - initial_angle);
    
    start_idx = find(delta_from_start > angle_threshold, 1, 'first');
    raw_times(start_idx)

    % Truncate all data from there
    position_vals = position_vals(start_idx:end);
    force_Z = force_Z(start_idx:end);
    force_X = force_X(start_idx:end);
    Z_vals = Z_vals(start_idx:end);
    raw_times = raw_times(start_idx:end);


    % Filtering raw data from z-force
    frame_rate = 10000;  % Hz
    fc = 100;
    fc2 = 50;            % cutoff frequency
    size(force_Z);

    fs = frame_rate;
    [b,a] = butter(6, fc/(fs/2));
    [b1,a1] = butter(6, fc2/(fs/2));
    force_Z_filtered = filtfilt(b, a, force_Z);  % direct processing on 1D vector
    force_X_filtered = filtfilt(b1, a1, force_X);

    % Convert ticks to degrees if necessary (adapt according to encoder)
    % position_deg = position_vals * (360 / 1024);  % if 1024 tick encoder
    position_deg = mod(position_vals, angle_per_turn);         % if already in degrees or ticks rescaled

    % Angular sampling parameters
    angle_bins = 0:1:floor(angle_per_turn)-1;

    Z_binned = nan(length(angle_bins), 1);
    Fz_binned = nan(length(angle_bins), 1);
    Fx_binned = nan(length(angle_bins), 1);
    Fz_binned_filtered = nan(length(angle_bins), 1);
    Fx_binned_filtered = nan(length(angle_bins), 1);

    % Storing values ​​by angle
    Z_per_angle = cell(length(angle_bins), 1);
    Fz_per_angle = cell(length(angle_bins), 1);
    Fx_per_angle = cell(length(angle_bins), 1);
    Fz_per_angle_filtered = cell(length(angle_bins), 1);
    Fx_per_angle_filtered = cell(length(angle_bins), 1);

    % Distribution of values ​​by angle bin
    for i = 1:length(position_deg)
        idx = floor(mod(position_deg(i), angle_per_turn)) + 1;
        idx = min(idx, length(Z_per_angle));
        Z_per_angle{idx}(end+1) = Z_vals(i);
        Fz_per_angle{idx}(end+1) = force_Z(i);
        Fz_per_angle_filtered{idx}(end+1) = force_Z_filtered(i);
        Fx_per_angle{idx}(end+1) = force_X(i);
        Fx_per_angle_filtered{idx}(end+1) = force_X_filtered(i);
    end

    % Averages per angle
    for k = 1:length(angle_bins)
        if ~isempty(Z_per_angle{k})
            Z_binned(k) = mean(Z_per_angle{k});
        end
        if ~isempty(Fz_per_angle{k})
            Fz_binned(k) = mean(Fz_per_angle{k});
        end
        if ~isempty(Fz_per_angle_filtered{k})
            Fz_binned_filtered(k) = mean(Fz_per_angle_filtered{k});
        end
        if ~isempty(Fx_per_angle{k})
            Fx_binned(k) = mean(Fx_per_angle{k});
        end
        if ~isempty(Fx_per_angle_filtered{k})
            Fx_binned_filtered(k) = mean(Fx_per_angle_filtered{k});
        end
    end

    % --- Filtering the Z position before derivation
    fc_pos = 100;  % cutoff frequency for position
    [bZ, aZ] = butter(4, fc_pos / (frame_rate / 2));
    Z_vals_filtered = filtfilt(bZ, aZ, Z_vals);

    % --- Time conversion
    times_s = raw_times / 1000;  % conversion ms -> s

    % --- Calculation of speed (dZ/dt)
    dt_v = diff(times_s);  % N-1
    Z_vals_vitesse = [0; diff(Z_vals_filtered) ./ dt_v];


    % --- Calculation of acceleration (d²Z/dt²)
    dt_a = diff(times_s(1:end));  % size N-2
    dV = diff(Z_vals_vitesse);  % size N-2
    size(dt_a);
    size(dV);
    Z_vals_accel = [0; dV ./ dt_a; 0];  % size N

    % --- Distribution of values ​​by angle bin
    VZ_per_angle = cell(length(angle_bins), 1);
    AZ_per_angle = cell(length(angle_bins), 1);
    VZ_binned = nan(length(angle_bins), 1);
    AZ_binned = nan(length(angle_bins), 1);

    for i = 1:length(position_deg)
        idx = floor(mod(position_deg(i), angle_per_turn)) + 1;
        idx = min(idx, length(VZ_per_angle));
        VZ_per_angle{idx}(end+1) = Z_vals_vitesse(i);
        AZ_per_angle{idx}(end+1) = Z_vals_accel(i);
    end

    for k = 1:length(angle_bins)
        if ~isempty(VZ_per_angle{k})
            VZ_binned(k) = mean(VZ_per_angle{k});
        end
        if ~isempty(AZ_per_angle{k})
            AZ_binned(k) = mean(AZ_per_angle{k});
        end
    end


    % Recover voltage and current
    voltage = data(start_idx:end, 8);        % in V
    courant_mA = data(start_idx:end, 9);     % in mA
    current = courant_mA / 1000;             % conversion to A

    power = voltage .* current;          % in W

    % Recover angle
    P_per_angle = cell(length(angle_bins), 1);
    P_binned = nan(length(angle_bins), 1);

    for i = 1:length(position_deg)
        idx = floor(mod(position_deg(i), angle_per_turn)) + 1;
        idx = min(idx, length(P_per_angle));
        P_per_angle{idx}(end+1) = power(i);
    end

    for k = 1:length(angle_bins)
        if ~isempty(P_per_angle{k})
            P_binned(k) = mean(P_per_angle{k});
        end
    end

    f = figure('Name', 'Force et Position Z - Repliée sur 1 période');

    tiledlayout(2,2);

    %% --- Plot 1: Z (wingtip position) with superimposed force
    nexttile;

    ax1 = gca;

    % Left Y axis: acceleration (negative)
    yyaxis(ax1, 'left');
    hold on;
    plot(angle_bins, -AZ_binned, '-', 'LineWidth', 1.5, 'Color', [0.4 0 0.8]); % negative acceleration
    ylabel('Accélération Z (mm/s²)');
    ylim([-6e11 6e11]);
    hold off;

    % Right Y axis: forces
    yyaxis(ax1, 'right');
    hold on;
    %%plot(angle_bins, Fz_binned, 'r-', 'LineWidth', 2);
    plot(angle_bins, Fz_binned_filtered, 'k-', 'LineWidth', 1);
    plot(angle_bins, Fx_binned_filtered, 'g-', 'LineWidth', 1);
    ylabel('Force Z (N)');
    ylim([-0.5 0.5]); % scale adapted to the forces
    hold off;

    title('Z Acceleration and Z Force');
    xlabel('Motor Angle (°)');
    legend('accel', 'force Z', 'forceX');
    grid on;


    %% --- Trace 2: Z force with scatter
    nexttile;
    hold on;
    for k = 1:length(angle_bins)
        scatter(repmat(angle_bins(k), length(Fz_per_angle{k}), 1), Fz_per_angle{k}, 5, [1 0.7 0.7], 'filled');
    end
    plot(angle_bins, Fz_binned, 'r-', 'LineWidth', 2);
    title('Force along Z (full cloud)');
    xlabel('Angle moteur (°)');
    ylabel('Force Z (N)');
    grid on;
    hold off;

    %% --- Plot 3: Position, velocity, Z acceleration
    nexttile;

    % Plot with two Y axes
    yyaxis left
    hold on;
    plot(angle_bins, Z_binned, 'b-', 'LineWidth', 1.5);     % Position
    ylabel('Z / dZ (mm et mm/s)');
    ylim padded

    yyaxis right
    plot(angle_bins, AZ_binned, 'm-', 'LineWidth', 1.2);     % Accélération
    ylabel('Accélération Z (mm/s²)');
    ylim padded
    yline(0, '--k');  % zero line to center well

    title('Position, Speed ​​and Acceleration Z (folded over 1 period)');
    xlabel('Angle moteur (°)');
    legend('Position Z', 'Accélération Z', 'Location', 'best');
    grid on;
    hold off;

    %% --- Graph 4: Electrical power (Voltage x Current)

    nexttile;
    hold on;
    for k = 1:length(angle_bins)
        scatter(repmat(angle_bins(k), length(P_per_angle{k}), 1), P_per_angle{k}, 5, [0.8 1 0.8], 'filled');
    end
    plot(angle_bins, P_binned, 'g-', 'LineWidth', 2);
    title('Puissance électrique (V × I)');
    xlabel('Angle moteur (°)');
    ylabel('Puissance (W)');
    grid on;
    hold off;

    %% === Save ===
    saveas(f, 'data\plots\' + case_name + "_position_forceZ_superposee.fig");


    %% --- Force Z plot by frequency range (multi-curve)

    % Paramètres
    step_duration = 5;            % Duration of a frequency step (s)
    freq_start = 60;               % Hz
    freq_step = 10;

    angle_per_turn = 360;         % <-- Adjustable value if you don't have exactly 360° per turn
    angle_bins = 0:1:floor(angle_per_turn)-1;
    % Préparation
    cmap = jet(20);                 % color palette
    all_Fz_binned = [];
    freqs = [];

    % Detection of passages close to 0° (synchronization by revolution)
    zero_cross_idx = find(mod(position_vals, angle_per_turn) < 2 | ...
                          mod(position_vals, angle_per_turn) > angle_per_turn - 2);
    zero_cross_idx = zero_cross_idx(diff([0; zero_cross_idx]) > 20);  % avoid duplicates that are too close

    % Loop on synchronized segments
    i = 1; % index in zero_cross_idx
    n = 1; % frequency counter
    while i < length(zero_cross_idx) - 1
        t_start = raw_times(zero_cross_idx(i));
        t_end = t_start;

        % Stack full rounds until step_duration is reached
        j = i + 1;
        while j <= length(zero_cross_idx)
            t_next = raw_times(zero_cross_idx(j));
            if t_next - t_start >= step_duration
                break;
            end
            t_end = t_next;
            j = j + 1;
        end

        % Indices of this segment
        idx_segment = find(raw_times >= t_start & raw_times < t_end);
        if isempty(idx_segment)
            i = j;
            continue;
        end

        % Extract the data
        pos_deg_part = mod(position_vals(idx_segment), angle_per_turn);
        force_Z_part = force_Z_filtered(idx_segment);
        freqs(n) = freq_start + (n-1)*freq_step;

        % Binning by angle
        Fz_bins_part = nan(length(angle_bins), 1);
        Fz_angle_part = cell(length(angle_bins), 1);
        for k = 1:length(pos_deg_part)
            idx_bin = floor(pos_deg_part(k));  % from 0 to 359
            if idx_bin >= 0 && idx_bin < angle_per_turn
                idx_cell = min(idx_bin + 1, length(Fz_angle_part));
                Fz_angle_part{idx_cell}(end+1) = force_Z_part(k);
            end
        end

        for k = 1:length(angle_bins)
            if ~isempty(Fz_angle_part{k})
                Fz_bins_part(k) = mean(Fz_angle_part{k});
            end
        end

        all_Fz_binned(n, :) = Fz_bins_part';
        n = n + 1;
        i = j;  % Advance to the next sync
    end

    figure('Name', 'Z force per angle for each frequency');
    hold on;
    for n = 1:length(freqs)
        plot(angle_bins, all_Fz_binned(n, :), 'Color', cmap(n,:), ...
             'DisplayName', sprintf('%.1f Hz', freqs(n)), 'LineWidth', 2);
    end
    xlabel('Angle moteur (°)');
    ylabel('Force Z filtrée (N)');
    title('Z force per beat frequency (synchronized revolutions)');
    legend show;
    grid on;

    % --- BODE dB (Amplitude vs fréquence)
    amplitudes = max(all_Fz_binned, [], 2) - min(all_Fz_binned, [], 2);
    amplitudes_dB = 20 * log10(amplitudes);

    % New figure with subplots
    figure('Name', 'Analyse en fréquence - Force Z');

    % Subplot 1 : angular curves
    subplot(2,1,1);
    hold on;
    for n = 1:length(freqs)
        plot(angle_bins, all_Fz_binned(n, :), 'Color', cmap(n,:), ...
             'DisplayName', sprintf('%.1f Hz', freqs(n)), 'LineWidth', 1.5);
    end
    xlabel('Angle moteur (°)');
    ylabel('Force Z (N)');
    title('Force Z filtrée par angle et fréquence');
    legend show;
    grid on;

    % Subplot 2 : Bode en amplitude (dB)
    subplot(2,1,2);
    plot(freqs, amplitudes_dB, '-o', 'LineWidth', 2, 'Color', 'k');
    xlabel('Fréquence (Hz)');
    ylabel('Amplitude (dB)');
    title('Diagramme de Bode - amplitude de Force Z');
    grid on;



    %% === Sauvegarde ===
    saveas(f, 'data\plots\' + case_name + "_position_forceZ_superposee_multi_freq_membrane.fig");


function filtered_results = filterr_data(results, frame_rate, fc)
    fs = frame_rate;
    [b,a] = butter(6, fc/(fs/2));
    filtered_results = filtfilt(b, a, results);  % Traitement direct sur vecteur 1D
end


end

end
end