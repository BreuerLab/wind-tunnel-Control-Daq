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

classdef Calimero < handle
properties
    DAQ; % National Instruments Data Acquistion Object
    data;
    time;
end

methods

% Builds DAQ object, adds channels, and sets appropriate channel
% voltages
% Inputs: forceVoltage - Voltage rating for all channels
%         rate - Data sampling rate for DAQ
% Returns: this_DAQ - A fully constructed DAQ object
function setup_DAQ(obj, forceVoltage, rate)
    % Create DAQ session and set its aquisition rate (Hz).
    obj.DAQ.Rate = rate;
    obj.DAQ.ScansAvailableFcnCount = 2000;
        
    % Pass the object handle (by reference)
    obj.DAQ.ScansAvailableFcn = @(src, evt) processData(src, evt, obj);
    daq_ID = "Dev1";
    % Don't know your DAQ ID, type "daq.getDevices().ID" into the
    % command window to see what devices are currently connected to
    % your computer

    % -------------- Add the input channels --------------
    % 6 force channels: Fx, Fy, Fz, Mx, My, Mz
    try
        ch0 = obj.DAQ.addinput(daq_ID, 0, "Voltage");
    catch ME
        daq_ID = DAQ_select(ME.message);
        ch0 = obj.DAQ.addinput(daq_ID, 0, "Voltage");
    end

    % ch9 = this_DAQ.addinput(daq_ID, "ctr0", "EdgeCount"); % rising edges by default

    ch1 = obj.DAQ.addinput(daq_ID, 1, "Voltage");
    ch2 = obj.DAQ.addinput(daq_ID, 2, "Voltage");
    ch3 = obj.DAQ.addinput(daq_ID, 3, "Voltage");
    ch4 = obj.DAQ.addinput(daq_ID, 4, "Voltage");
    ch5 = obj.DAQ.addinput(daq_ID, 5, "Voltage");

    % channel for voltage measurement
    ch6 = obj.DAQ.addinput(daq_ID, 22, "Voltage");

    % channel for current measurement
    ch7 = obj.DAQ.addinput(daq_ID, 21, "Voltage");

    % channel for Galil encoder measurement
    % ch8 = this_DAQ.addinput(daq_ID, 20, "Voltage");
    ch8 = obj.DAQ.addinput(daq_ID, "port0/line24", "Digital");

    obj.DAQ.addinput(daq_ID,"ctr0","EdgeCount")
    
    if ~(forceVoltage == 5 || forceVoltage == 10)
        error("Invalid DAQ voltage for force transducer")
    end
        
    % --------- Set the voltage range of the channels ---------
    ch0.Range = [-forceVoltage, forceVoltage];
    ch1.Range = [-forceVoltage, forceVoltage];
    ch2.Range = [-forceVoltage, forceVoltage];
    ch3.Range = [-forceVoltage, forceVoltage];
    ch4.Range = [-forceVoltage, forceVoltage];
    ch5.Range = [-forceVoltage, forceVoltage];
    ch6.Range = [-5, 5];
    ch7.Range = [-5, 5];
    % ch7.Range = [-1, 1]; % voltage range anticipated for current is 0 - 0.2
    % ch8.Range = [-5, 5];

    % Configure continuous acquisition
    % this_DAQ.ScansAvailableFcn = @(src, evt) processData(src, evt);
    % this_DAQ.ScansAvailableFcnCount = 1000; % callback every 1000 samples

    % function processData(src, evt)
    % % Keep the data between calls
    % persistent allData allTime totalScans
    % 
    % % How many scans are available right now?
    % nScans = evt.ElementsAvailable;
    % 
    % % Read exactly that many scans (one scan == sample across all channels)
    % newData = read(src, nScans, "OutputFormat", "Matrix");
    % 
    % % Initialize on first call
    % if isempty(totalScans)
    %     totalScans = 0;
    %     allData = [];
    %     allTime = [];
    % end
    % 
    % % Build timestamps (seconds) for these new scans
    % % totalScans is the number of scans we've already consumed
    % % newTime runs from totalScans / Rate to (totalScans + nScans - 1) / Rate
    % newTime = (totalScans + (0:(size(newData,1)-1))') / src.Rate;
    % 
    % % Append to cumulative arrays
    % allData = [allData; newData];
    % allTime = [allTime; newTime];
    % 
    % % Update counter
    % totalScans = totalScans + size(newData,1);
    % 
    % % Optionally expose to base workspace or display progress
    % assignin("base","allData",allData);
    % assignin("base","allTime",allTime);
    % end

    function processData(src, ~, obj)
        % disp("Saving Data")
        [newData, newTime, ~] = read(src, src.ScansAvailableFcnCount, "OutputFormat", "Matrix");
        obj.data = [obj.data; newData];
        obj.time = [obj.time; newTime];
    end
end

%% Constructor for Force Transducer Class
function obj = Calimero()
    % obj.DAQ = Calimero.setup_DAQ(forceVoltage, rate);
    obj.DAQ = daq("ni");
    obj.data = [];
    obj.time = [];
end

%% Destructor for Force Transducer Class
function delete(obj)
    delete(obj.DAQ);
    clear obj.DAQ;
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
    % start(obj.daq, "Duration", tare_duration);
    
    % Read the data
    % bias_timetable = read(obj.DAQ, seconds(tare_duration));
    % bias_table = timetable2table(bias_timetable);
    % 
    % % Extract columns (6 forces + current + voltage + position)
    % bias_array = table2array(bias_table(:, 2:end));

    % Stop and flush DAQ buffer
    stop(obj.DAQ);
    flush(obj.DAQ);

    % clear data arrays
    obj.data = [];
    obj.time = [];

    start(obj.DAQ, "continuous");
    pause(tare_duration);
    stop(obj.DAQ)

    % Preallocate offset matrix (mean and std for each channel)
    num_channels = min(size(obj.data));
    offsets = zeros(2, num_channels);

    for i = 1:num_channels
        offsets(1, i) = mean(obj.data(:, i));  % mean (offset)
        offsets(2, i) = std(obj.data(:, i));   % std (noise)
    end
    
    % Save data to .mat file with timestamp
    currentDateTime = datetime('now', 'Format', 'yyyy_MM_dd_HH_mm_ss');
    currentDateTimeStr = char(currentDateTime);
    trial_name = strjoin([case_name, "offsets", currentDateTimeStr], "_");
    trial_file_name = "data\offsets data\" + trial_name + ".mat";
    save(trial_file_name, "offsets");

    pause(1);
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
    % start(obj.daq, "Duration", session_duration);

    %  % Shared variables
    % allData = [];
    % allTime = [];
    % totalScans = 0;
    % 
    % start(obj.daq, "continuous");
    % pause(session_duration)
    % stop(obj.daq)
    % 
    % obj.daq.ScansAvailableFcn = @processData;
    % 
    % % Return data after acquisition
    % time = allTime;
    % data = allData;
    % 
    % % Nested callback function — has access to variables above
    % function processData(src, evt)
    %     nScans = evt.ElementsAvailable;
    %     newData = read(src, nScans, "OutputFormat", "Matrix");
    % 
    %     newTime = (totalScans + (0:(size(newData,1)-1))') / src.Rate;
    %     allData = [allData; newData];
    %     allTime = [allTime; newTime];
    %     totalScans = totalScans + size(newData,1);
    % end

    % Read the data
    % raw_data = read(obj.DAQ, seconds(session_duration));
    % 
    % raw_data_table = timetable2table(raw_data);
    % 
    % raw_data_table_times = raw_data_table(:, 1); % timestamps
    % raw_data_table_volt_vals = raw_data_table(:, 2:end); % voltage inputs (9 channels)
    % 
    % raw_times = seconds(table2array(raw_data_table_times));
    % raw_volt_vals = table2array(raw_data_table_volt_vals);

    % Stop and flush DAQ buffer
    stop(obj.DAQ);
    flush(obj.DAQ);

    % clear data arrays
    obj.data = [];
    obj.time = [];

    tic
    start(obj.DAQ, "continuous");
    pause(session_duration);
    stop(obj.DAQ)
    toc
    
    results = [obj.time obj.data];
    
    % Save data to .mat file with timestamp
    currentDateTime = datetime('now', 'Format', 'yyyy_MM_dd_HH_mm_ss');
    currentDateTimeStr = char(currentDateTime);
    trial_name = strjoin([case_name, "experiment", currentDateTimeStr], "_");
    trial_file_name = "data\experiment data\" + trial_name + ".mat";
    save(trial_file_name, "results");
end

end
end