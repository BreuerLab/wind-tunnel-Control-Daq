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
    daq_ID = "Dev4";
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

    %ch8 = this_DAQ.addinput(daq_ID, 20, "Voltage");
    %ch9 = this_DAQ.addinput(daq_ID, 21, "Voltage");
    ch6 = this_DAQ.addinput(daq_ID, 21, "Voltage");
    ch6.Range = [-10, 10];
    %ch9.Range = [-10, 10];
    %ch10.Range = [-10, 10];

   
end

%% Used after data collection to trim the data based on the trigger data
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

%% Constructor for Force Transducer Class
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
    
    % Démarrer la session DAQ pour tare_duration secondes
    start(obj.daq, "Duration", tare_duration);
    
    % Lire les données
    [bias_timetable, ~] = read(obj.daq, seconds(tare_duration));
    bias_table = timetable2table(bias_timetable);
    
    % Extraire colonnes 2 à 10 (6 forces + courant + tension + position)
    bias_array = table2array(bias_table(:, 2:8));
    
    % Préallouer tableau offset 2x8 (moyenne et std pour chaque canal)
    offsets = zeros(2, 7);

    for i = 1:7
        offsets(1, i) = mean(bias_array(:, i));  % moyenne (offset)
        offsets(2, i) = std(bias_array(:, i));   % écart type (bruit)
    end
    
    % Sauvegarder les offsets dans un fichier csv
    trial_name = strjoin([case_name, "offsets", datestr(now, "mmddyy")], "_");
    trial_file_name = "data\offsets data\" + trial_name + ".csv";
    writematrix(offsets, trial_file_name);

    % Ajouter l'heure dans le fichier
    fileID = fopen(trial_file_name, 'a');
    fprintf(fileID, '%s\n', string(datetime));
    fclose(fileID);

    pause(1);

    % Arrêter et vider le buffer DAQ
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
    % Start the DAQ session.
    start(obj.daq, "Duration", session_duration);

    % Read the data
    raw_data = read(obj.daq, seconds(session_duration));
    raw_data_table = timetable2table(raw_data);

    raw_data_table_times = raw_data_table(:, 1); % timestamps
    raw_data_table_volt_vals = raw_data_table(:, 2:8); % voltage inputs (6 channels)

    raw_times = seconds(table2array(raw_data_table_times));
    raw_volt_vals = table2array(raw_data_table_volt_vals);

    % === Lecture des données ===
    raw_times = seconds(table2array(raw_data_table_times));
    raw_volt_vals = table2array(raw_data_table_volt_vals);
    

    % N = length(position_vals);
    
    % % === Calcul de la vitesse ===
    % velocity_vals = zeros(N, 1);
    % last_pos = position_vals(1);
    % last_time = raw_times(1);
    % last_velocity = 0;
    % 
    % for i = 2:N
    %     if position_vals(i) ~= last_pos
    %         dt = raw_times(i) - last_time;
    %         dp = position_vals(i) - last_pos;
    % 
    %         if dt > 0
    %             last_velocity = dp / dt;
    %         else
    %             last_velocity = 0;
    %         end
    % 
    %         last_pos = position_vals(i);
    %         last_time = raw_times(i);
    %     end
    %     velocity_vals(i) = last_velocity;
    % end
    % 
    % % === Conversion angle -> Z ===
    % angle_per_turn = 358.32;
    % theta = deg2rad(mod(position_vals, angle_per_turn));
    % 
    % % Paramètres géométriques
    % r = 6;
    % d = 20;
    % L = 200;
    % 
    % numerateur = r * sin(theta);
    % denominateur = sqrt((r * cos(theta) - d).^2 + (r * sin(theta)).^2);
    % Z = L * (numerateur ./ denominateur);

    % Appliquer offset et calibration sur les 6 canaux principaux
    volt_vals = raw_volt_vals(:, 1:6) - offsets(1, 1:6);
    force_vals = obj.cal_matrix * volt_vals';
    force_vals = force_vals';
    
    % Ajouter les 2 colonnes supplémentaires "non calibrées" (brutes), avec offsets
    % Extraction des colonnes brutes (DAQ) pour tension et courant
    %volt_daq = raw_volt_vals(:, 8);  % tension mesurée DAQ [-5,5] V
    %curr_daq = raw_volt_vals(:, 7);  % courant mesuré DAQ [-5,5] V
    
    % % Conversion en signal ESP32 [0,3.3] V
    % volt_esp = (volt_daq - offsets(1,8));
    % curr_esp = (curr_daq - offsets(1,7));
    % 
    % % Conversion en valeur numérique 0-255
    % volt_esp_255 = volt_esp * (255 / 3.3);
    % curr_esp_255 = curr_esp * (255 / 3.3);
    % 
    % % Conversion en grandeur réelle
    % volt_reel = volt_esp_255 * (12 / 255);  % tension réelle 0-12 V
    % curr_reel = curr_esp_255 * (2000 / 255); % courant réel 0-2000 mA
    % 
    % % Appliquer offset si besoin
    % volt_reel_offset_corr = volt_reel;
    % curr_reel_offset_corr = curr_reel;
    % 
    % extra_voltages = [volt_reel_offset_corr, curr_reel_offset_corr];
    % 
    % % Combiner tout dans les résultats
    results = [raw_times, force_vals];
    % 
    % if (obj.num_triggers >= 1)
    %     results = [results raw_galil_trigger_vals];
    % end
    % if (obj.num_triggers == 2)
    %     results = [results raw_camera_trigger_vals];
    % end
    
        % === Convertir le signal encodeur analogique ===
    % Canal 11 (indice 10 en MATLAB 1-based) est l’encodeur analogique
    analog_voltage = raw_volt_vals(:, 7);  % [0 - 3.3 V]
    
    position_vals = analog_voltage;

    % Ajouter la position estimée et les lignes digitales (A et B)
    results = [results position_vals];
    
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
% grid plot. The data has not been filtered, but if triggers are being
% used the data will also be plotted as trimmed by the trigger signal.
function plot_results(obj, results, case_name, drift)
    close all
    titles = ["F_x","F_y","F_z","M_x","M_y","M_z","Voltage","Current","Position","Velocity"];

    if (contains(case_name, '-'))
        case_name = strrep(case_name,'-','neg');
    end

    % Check if triggers were activated and if so trim data
    A_trigger_detected = false;
    B_trigger_detected = false;
    if (obj.num_triggers >= 1)
        A_trimmed_results = ForceTransducer.trim_data(results(:,1:10), results(:, 13));
        if (length(A_trimmed_results) ~= length(results(:,1:12)))
            A_trigger_detected = true;
        end
    end
    if (obj.num_triggers == 2)
        B_trimmed_results = ForceTransducer.trim_data(results(:,1:10), results(:, 14));
        if (length(B_trimmed_results) ~= length(results(:,1:12)))
            B_trigger_detected = true;
        end
    end

    %% Figure with raw data and trimmed data overlaid

    x_label = "Time (s)";
    y_label_F = "Force (N)";
    y_label_M = "Moment (N*m)";
    y_label_V = "Voltage (V)";
    y_label_C = "Current (mA)";
    y_label_P = "Increment";
    axes_labels = [x_label, y_label_F, y_label_M, y_label_V, y_label_C, y_label_P];

    % Open a new figure.
    f = figure;
    % f.Position = [1940 600 1150 750];
    tcl = tiledlayout(2,5);
    
    raw_time = results(:, 1);
    if (A_trigger_detected)
        A_trimmed_time = A_trimmed_results(:, 1);
    end
    if (B_trigger_detected)
        B_trimmed_time = B_trimmed_results(:, 1);
    end

    forces = results(:,2:7);
    force_means = round(mean(forces), 3);
    force_SDs = round(std(forces), 3);
    force_maxs = round(max(forces), 3);
    force_mins = round(min(forces), 3);

    % --- Filtrage des forces et moments (6 canaux)
    frame_rate = 10000;
    fc_force = 100;  % fréquence de coupure en Hz
    [bF, aF] = butter(4, fc_force / (frame_rate / 2));
    forces_filtered = filtfilt(bF, aF, forces);  % même taille que forces
    
    % Tracer forces et moments (6 plots)
    for k = 1:6
        nexttile(tcl)
        hold on
        plot(raw_time, forces(:, k), 'Color', [0.7 0.7 0.7], 'DisplayName', 'raw');  % force brute en gris
        plot(raw_time, forces_filtered(:, k), 'b', 'DisplayName', 'filtered');       % force filtrée en bleu
    
        if (obj.num_triggers > 0 && A_trigger_detected)
            plot(A_trimmed_time, A_trimmed_results(:, k+1), 'r', 'DisplayName', 'first trigger');
        end
        if (obj.num_triggers == 2 && B_trigger_detected)
            plot(B_trimmed_time, B_trimmed_results(:, k+1), 'g', 'DisplayName', 'second trigger');
        end
    
        title([titles(k), " avg: " + force_means(k) + ...
               "    SD: " + force_SDs(k) + ...
               "    max: " + force_maxs(k) + ...
               "    min: " + force_mins(k)]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(1 + ceil(k/3)));
        legend;
        hold off
    end

    % Données supplémentaires : Voltage, Current, ChanelA, ChanelB
    extra_data = results(:, 8:8);
    extra_means = round(mean(extra_data), 3);
    extra_SDs = round(std(extra_data), 3);
    extra_maxs = round(max(extra_data), 3);
    extra_mins = round(min(extra_data), 3);

    %y_labels_extra = [y_label_V, y_label_C, y_label_P];
    y_labels_extra = [y_label_P];
    for j = 1:1
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



    drift_string = string(drift);
    % separate numbers by space
    drift_string = [sprintf('%s    ',drift_string{1:end-1}), drift_string{end}];

    % Label the whole figure.
    sgtitle({"Force Transducer Data" strrep(case_name,'_','  ') ...
            "Over the course of the experiment, the force transducer drifted" ...
            "F_x                  F_y                   F_z                   M_x                   M_y                   M_z" ...
            drift_string});

    saveas(f,'data\plots\' + case_name + "_raw.fig")
    

    % %% ---Données d’entrée
    % data = results;
    % angle_per_turn = 360; 
    % % Extraire les colonnes utiles
    % position_vals = data(:, end-1);    % Angle moteur (ticks ou degrés)
    % force_Z = data(:, 4);              % Force selon Z (colonne 4)
    % Z_vals = data(:, end);             % Position en bout d’aile
    % raw_times = data(:, 1);            % Temps (non utilisé ici)
    % force_X = data(:,2);
    % 
    % % Trouver le premier indice où la position n'est plus nulle
    % start_idx = find(position_vals ~= 0, 1, 'first');
    % 
    % % Tronquer toutes les données à partir de là
    % position_vals = position_vals(start_idx:end);
    % force_Z = force_Z(start_idx:end);
    % force_X = force_X(start_idx:end);
    % Z_vals = Z_vals(start_idx:end);
    % raw_times = raw_times(start_idx:end);
    % 
    % 
    % % Filtrage des données brutes de force_Z
    % frame_rate = 10000;  % Hz
    % fc = 100;
    % fc2 = 50;            % fréquence de coupure
    % size(force_Z);
    % 
    % fs = frame_rate;
    % [b,a] = butter(6, fc/(fs/2));
    % [b1,a1] = butter(6, fc2/(fs/2));
    % force_Z_filtered = filtfilt(b, a, force_Z);  % Traitement direct sur vecteur 1D
    % force_X_filtered = filtfilt(b1, a1, force_X);
    % 
    % % Convertir ticks en degrés si nécessaire (adapter selon encodeur)
    % % position_deg = position_vals * (360 / 1024);  % si encodeur à 1024 ticks
    % position_deg = mod(position_vals, angle_per_turn);         % si déjà en degrés ou ticks rééchelonnés
    % 
    % % Paramètres d’échantillonnage angulaire
    % angle_bins = 0:1:floor(angle_per_turn)-1;
    % 
    % Z_binned = nan(length(angle_bins), 1);
    % Fz_binned = nan(length(angle_bins), 1);
    % Fx_binned = nan(length(angle_bins), 1);
    % Fz_binned_filtered = nan(length(angle_bins), 1);
    % Fx_binned_filtered = nan(length(angle_bins), 1);
    % 
    % % Stockage des valeurs par angle
    % Z_per_angle = cell(length(angle_bins), 1);
    % Fz_per_angle = cell(length(angle_bins), 1);
    % Fx_per_angle = cell(length(angle_bins), 1);
    % Fz_per_angle_filtered = cell(length(angle_bins), 1);
    % Fx_per_angle_filtered = cell(length(angle_bins), 1);
    % 
    % % Répartition des valeurs par bin d’angle
    % for i = 1:length(position_deg)
    %     idx = floor(mod(position_deg(i), angle_per_turn)) + 1;
    %     idx = min(idx, length(Z_per_angle));
    %     Z_per_angle{idx}(end+1) = Z_vals(i);
    %     Fz_per_angle{idx}(end+1) = force_Z(i);
    %     Fz_per_angle_filtered{idx}(end+1) = force_Z_filtered(i);
    %     Fx_per_angle{idx}(end+1) = force_X(i);
    %     Fx_per_angle_filtered{idx}(end+1) = force_X_filtered(i);
    % end
    % 
    % % Moyennes par angle
    % for k = 1:length(angle_bins)
    %     if ~isempty(Z_per_angle{k})
    %         Z_binned(k) = mean(Z_per_angle{k});
    %     end
    %     if ~isempty(Fz_per_angle{k})
    %         Fz_binned(k) = mean(Fz_per_angle{k});
    %     end
    %     if ~isempty(Fz_per_angle_filtered{k})
    %         Fz_binned_filtered(k) = mean(Fz_per_angle_filtered{k});
    %     end
    %     if ~isempty(Fx_per_angle{k})
    %         Fx_binned(k) = mean(Fx_per_angle{k});
    %     end
    %     if ~isempty(Fx_per_angle_filtered{k})
    %         Fx_binned_filtered(k) = mean(Fx_per_angle_filtered{k});
    %     end
    % end
    % 
    % % --- Filtrage de la position Z avant dérivation
    % fc_pos = 100;  % fréquence de coupure pour la position
    % [bZ, aZ] = butter(4, fc_pos / (frame_rate / 2));
    % Z_vals_filtered = filtfilt(bZ, aZ, Z_vals);
    % 
    % % --- Conversion du temps
    % times_s = raw_times / 1000;  % conversion ms -> s
    % 
    % % --- Calcul de la vitesse (dZ/dt)
    % dt_v = diff(times_s);  % N-1
    % Z_vals_vitesse = [0; diff(Z_vals_filtered) ./ dt_v];
    % 
    % 
    % % --- Calcul de l'accélération (d²Z/dt²)
    % dt_a = diff(times_s(1:end));  % taille N-2
    % dV = diff(Z_vals_vitesse);  % taille N-2
    % size(dt_a);
    % size(dV);
    % Z_vals_accel = [0; dV ./ dt_a; 0];  % taille N
    % 
    % % --- Répartition des valeurs par bin d’angle
    % VZ_per_angle = cell(length(angle_bins), 1);
    % AZ_per_angle = cell(length(angle_bins), 1);
    % VZ_binned = nan(length(angle_bins), 1);
    % AZ_binned = nan(length(angle_bins), 1);
    % 
    % for i = 1:length(position_deg)
    %     idx = floor(mod(position_deg(i), angle_per_turn)) + 1;
    %     idx = min(idx, length(VZ_per_angle));
    %     VZ_per_angle{idx}(end+1) = Z_vals_vitesse(i);
    %     AZ_per_angle{idx}(end+1) = Z_vals_accel(i);
    % end
    % 
    % for k = 1:length(angle_bins)
    %     if ~isempty(VZ_per_angle{k})
    %         VZ_binned(k) = mean(VZ_per_angle{k});
    %     end
    %     if ~isempty(AZ_per_angle{k})
    %         AZ_binned(k) = mean(AZ_per_angle{k});
    %     end
    % end
    % 
    % 
    % % Récupérer tension et courant
    % tension = data(start_idx:end, 8);        % en V
    % courant_mA = data(start_idx:end, 9);     % en mA
    % courant = courant_mA / 1000;             % conversion en A
    % 
    % puissance = tension .* courant;          % en W
    % 
    % % Répartition par angle
    % P_per_angle = cell(length(angle_bins), 1);
    % P_binned = nan(length(angle_bins), 1);
    % 
    % for i = 1:length(position_deg)
    %     idx = floor(mod(position_deg(i), angle_per_turn)) + 1;
    %     idx = min(idx, length(P_per_angle));
    %     P_per_angle{idx}(end+1) = puissance(i);
    % end
    % 
    % for k = 1:length(angle_bins)
    %     if ~isempty(P_per_angle{k})
    %         P_binned(k) = mean(P_per_angle{k});
    %     end
    % end
    % 
    % f = figure('Name', 'Force et Position Z - Repliée sur 1 période');
    % 
    % tiledlayout(2,2);
    % 
    % %% --- Tracé 1 : Z (position en bout d’aile) avec force superposée
    % nexttile;
    % 
    % ax1 = gca;
    % 
    % % Axe Y gauche : accélération (negative)
    % yyaxis(ax1, 'left');
    % hold on;
    % plot(angle_bins, -AZ_binned, '-', 'LineWidth', 1.5, 'Color', [0.4 0 0.8]); % accélération négative
    % ylabel('Accélération Z (mm/s²)');
    % ylim([-6e11 6e11]);
    % hold off;
    % 
    % % Axe Y droit : forces
    % yyaxis(ax1, 'right');
    % hold on;
    % %%plot(angle_bins, Fz_binned, 'r-', 'LineWidth', 2);
    % plot(angle_bins, Fz_binned_filtered, 'k-', 'LineWidth', 1);
    % plot(angle_bins, Fx_binned_filtered, 'g-', 'LineWidth', 1);
    % ylabel('Force Z (N)');
    % ylim([-0.5 0.5]); % échelle adaptée aux forces
    % hold off;
    % 
    % title('Accélération Z et Force Z');
    % xlabel('Angle moteur (°)');
    % legend('accel', 'force Z', 'forceX');
    % grid on;
    % 
    % 
    % %% --- Tracé 2 : Force Z seule avec nuage
    % nexttile;
    % hold on;
    % for k = 1:length(angle_bins)
    %     scatter(repmat(angle_bins(k), length(Fz_per_angle{k}), 1), Fz_per_angle{k}, 5, [1 0.7 0.7], 'filled');
    % end
    % plot(angle_bins, Fz_binned, 'r-', 'LineWidth', 2);
    % title('Force selon Z (nuage complet)');
    % xlabel('Angle moteur (°)');
    % ylabel('Force Z (N)');
    % grid on;
    % hold off;
    % 
    % %% --- Tracé 3 : Position, vitesse, accélération Z
    % nexttile;
    % 
    % % Tracé avec deux axes Y
    % yyaxis left
    % hold on;
    % plot(angle_bins, Z_binned, 'b-', 'LineWidth', 1.5);     % Position
    % ylabel('Z / dZ (mm et mm/s)');
    % ylim padded
    % 
    % yyaxis right
    % plot(angle_bins, AZ_binned, 'm-', 'LineWidth', 1.2);     % Accélération
    % ylabel('Accélération Z (mm/s²)');
    % ylim padded
    % yline(0, '--k');  % ligne de zéro pour bien centrer
    % 
    % title('Position, Vitesse et Accélération Z (repliées sur 1 période)');
    % xlabel('Angle moteur (°)');
    % legend('Position Z', 'Accélération Z', 'Location', 'best');
    % grid on;
    % hold off;
    % 
    % %% --- Tracé 4 : Puissance électrique (Tension x Courant)
    % 
    % 
    % % Tracé
    % nexttile;
    % hold on;
    % for k = 1:length(angle_bins)
    %     scatter(repmat(angle_bins(k), length(P_per_angle{k}), 1), P_per_angle{k}, 5, [0.8 1 0.8], 'filled');
    % end
    % plot(angle_bins, P_binned, 'g-', 'LineWidth', 2);
    % title('Puissance électrique (V × I)');
    % xlabel('Angle moteur (°)');
    % ylabel('Puissance (W)');
    % grid on;
    % hold off;
    % 
    % %% === Sauvegarde ===
    % saveas(f, 'data\plots\' + case_name + "_position_forceZ_superposee.fig");
    % 
    % 
    % %% --- Tracé de Force Z par plage de fréquence (multi-courbes)
    % 
    % % Paramètres
    % step_duration = 10;            % Durée d’un palier de fréquence (s)
    % freq_start = 3.5;               % Hz
    % freq_step = 0.5;
    % 
    % angle_per_turn = 360;         % <-- Valeur ajustable si tu n’as pas exactement 360° par tour
    % angle_bins = 0:1:floor(angle_per_turn)-1;
    % % Préparation
    % cmap = jet(20);                 % Palette de couleurs
    % all_Fz_binned = [];
    % freqs = [];
    % 
    % % Détection des passages proches de 0° (synchronisation par tour)
    % zero_cross_idx = find(mod(position_vals, angle_per_turn) < 2 | ...
    %                       mod(position_vals, angle_per_turn) > angle_per_turn - 2);
    % zero_cross_idx = zero_cross_idx(diff([0; zero_cross_idx]) > 20);  % évite doublons trop proches
    % 
    % % Boucle sur les segments synchronisés
    % i = 1; % index dans zero_cross_idx
    % n = 1; % compteur de fréquence
    % while i < length(zero_cross_idx) - 1
    %     t_start = raw_times(zero_cross_idx(i));
    %     t_end = t_start;
    % 
    %     % Empiler des tours complets jusqu’à atteindre step_duration
    %     j = i + 1;
    %     while j <= length(zero_cross_idx)
    %         t_next = raw_times(zero_cross_idx(j));
    %         if t_next - t_start >= step_duration
    %             break;
    %         end
    %         t_end = t_next;
    %         j = j + 1;
    %     end
    % 
    %     % Indices de ce segment
    %     idx_segment = find(raw_times >= t_start & raw_times < t_end);
    %     if isempty(idx_segment)
    %         i = j;
    %         continue;
    %     end
    % 
    %     % Extraire les données
    %     pos_deg_part = mod(position_vals(idx_segment), angle_per_turn);
    %     force_Z_part = force_Z_filtered(idx_segment);
    %     freqs(n) = freq_start + (n-1)*freq_step;
    % 
    %     % Binning par angle
    %     Fz_bins_part = nan(length(angle_bins), 1);
    %     Fz_angle_part = cell(length(angle_bins), 1);
    %     for k = 1:length(pos_deg_part)
    %         idx_bin = floor(pos_deg_part(k));  % de 0 à 359
    %         if idx_bin >= 0 && idx_bin < angle_per_turn
    %             idx_cell = min(idx_bin + 1, length(Fz_angle_part));
    %             Fz_angle_part{idx_cell}(end+1) = force_Z_part(k);
    %         end
    %     end
    % 
    %     for k = 1:length(angle_bins)
    %         if ~isempty(Fz_angle_part{k})
    %             Fz_bins_part(k) = mean(Fz_angle_part{k});
    %         end
    %     end
    % 
    %     all_Fz_binned(n, :) = Fz_bins_part';
    %     n = n + 1;
    %     i = j;  % Avancer à la prochaine synchronisation
    % end
    % 
    % % Tracé des courbes
    % figure('Name', 'Force Z par angle pour chaque fréquence');
    % hold on;
    % for n = 1:length(freqs)
    %     plot(angle_bins, all_Fz_binned(n, :), 'Color', cmap(n,:), ...
    %          'DisplayName', sprintf('%.1f Hz', freqs(n)), 'LineWidth', 2);
    % end
    % xlabel('Angle moteur (°)');
    % ylabel('Force Z filtrée (N)');
    % title('Force Z par fréquence de battement (tours synchronisés)');
    % legend show;
    % grid on;
    % 
    % % --- BODE dB (Amplitude vs fréquence)
    % amplitudes = max(all_Fz_binned, [], 2) - min(all_Fz_binned, [], 2);
    % amplitudes_dB = 20 * log10(amplitudes);
    % 
    % % Nouvelle figure avec subplots
    % figure('Name', 'Analyse en fréquence - Force Z');
    % 
    % % Subplot 1 : courbes angulaires
    % subplot(2,1,1);
    % hold on;
    % for n = 1:length(freqs)
    %     plot(angle_bins, all_Fz_binned(n, :), 'Color', cmap(n,:), ...
    %          'DisplayName', sprintf('%.1f Hz', freqs(n)), 'LineWidth', 1.5);
    % end
    % xlabel('Angle moteur (°)');
    % ylabel('Force Z (N)');
    % title('Force Z filtrée par angle et fréquence');
    % legend show;
    % grid on;
    % 
    % % Subplot 2 : Bode en amplitude (dB)
    % subplot(2,1,2);
    % plot(freqs, amplitudes_dB, '-o', 'LineWidth', 2, 'Color', 'k');
    % xlabel('Fréquence (Hz)');
    % ylabel('Amplitude (dB)');
    % title('Diagramme de Bode - amplitude de Force Z');
    % grid on;
    % 
    % 
    % 
    % %% === Sauvegarde ===
    % saveas(f, 'data\plots\' + case_name + "_position_forceZ_superposee_multi_freq_membrane.fig");
    % 
    % 
    % 



function filtered_results = filterr_data(results, frame_rate, fc)
    fs = frame_rate;
    [b,a] = butter(6, fc/(fs/2));
    filtered_results = filtfilt(b, a, results);  % Traitement direct sur vecteur 1D
end


end

end
end