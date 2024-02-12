% Author: Ronan Gissler
% Last updated: October 2023

% Inputs: 
% file - filename of trial to process
% raw_data_path - relative path to access existing experiment
%                 data from (.csv files)
% processed_data_path - relative path to the location where the
%                       processed data will be stored (.mat files)

% Outputs:
% A .mat file is produced in the directory described by processed_data_path
% containing a number of variables whose contents describe the results of
% the experiment in more ways than simply the raw data does.
function process_trial_tare(file, raw_data_path, processed_data_path)

frame_rate = 9000; % DAQ data sampling rate (Hz)
num_wingbeats = 180; % Number of wingbeats recorded for each trial

[case_name, type, AoA] = parse_filename_tare(file);

% Get raw data from file
data = readmatrix(raw_data_path + file);
raw_data = data(:,1:7);
time_data = raw_data(:,1);
force_data = raw_data(:,2:7);

% Rotate the data from the force transducer reference frame to the wind
% tunnel reference frame (body frame to global frame)
% results_lab = coordinate_transformation(force_data, AoA);

% Smooth the data with a butterworth filter
filtered_data = filter_data(force_data, frame_rate);

filename = case_name + ".mat"; % file name for processed data

save(processed_data_path + filename, 'time_data', 'force_data', ...
'filtered_data')
end