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
    bias_timetable = read(obj.daq, seconds(tare_duration));
    bias_table = timetable2table(bias_timetable);
    
    % Extract columns 2 to 9 (6 forces + current + voltage + position)
    bias_array = table2array(bias_table(:, 2:9));
    
    % Preallocate 2x8 offset matrix (mean and std for each channel)
    offsets = zeros(2, 8);

    for i = 1:8
        offsets(1, i) = mean(bias_array(:, i));  % mean (offset)
        offsets(2, i) = std(bias_array(:, i));   % std (noise)
    end
    
    % Save data to .mat file with timestamp
    currentDateTime = datetime('now', 'Format', 'yyyy_MM_dd_HH_mm_ss');
    currentDateTimeStr = char(currentDateTime);
    trial_name = strjoin([case_name, "offsets", currentDateTimeStr], "_");
    trial_file_name = "data\offsets data\" + trial_name + ".mat";
    save(trial_file_name, "offsets");

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
function [results] = measure_force(obj, case_name, session_duration)
    % Start the DAQ session.
    start(obj.daq, "Duration", session_duration);

    % Read the data
    raw_data = read(obj.daq, seconds(session_duration));
    raw_data_table = timetable2table(raw_data);

    raw_data_table_times = raw_data_table(:, 1); % timestamps
    raw_data_table_volt_vals = raw_data_table(:, 2:9); % voltage inputs (8 channels)

    raw_times = seconds(table2array(raw_data_table_times));
    raw_volt_vals = table2array(raw_data_table_volt_vals);
    
    results = [raw_times raw_volt_vals];
    
    % Save data to .mat file with timestamp
    currentDateTime = datetime('now', 'Format', 'yyyy_MM_dd_HH_mm_ss');
    currentDateTimeStr = char(currentDateTime);
    trial_name = strjoin([case_name, "experiment", currentDateTimeStr], "_");
    trial_file_name = "data\experiment data\" + trial_name + ".mat";
    save(trial_file_name, "results");
    
    % Flush data from DAQ buffer and stops background operations
    stop(obj.daq);
    flush(obj.daq);
end

end
end