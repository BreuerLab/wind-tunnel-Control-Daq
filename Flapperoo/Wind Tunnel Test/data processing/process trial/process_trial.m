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
function process_trial(file, raw_data_path, processed_data_path)

frame_rate = 9000; % DAQ data sampling rate (Hz)
num_wingbeats = 180; % Number of wingbeats recorded for each trial

[case_name, type, wing_freq, AoA, wind_speed] = parse_filename(file);

% Get raw data from file
data = readmatrix(raw_data_path + file);
raw_data = data(:,1:7);
raw_trigger = data(:,8);

% Trim off portion of data where wings are motionless or accelerating
trimmed_results = trim_data(raw_data, raw_trigger, wing_freq);
time_data = trimmed_results(:,1)';
force_data = trimmed_results(:,2:7)';

% Rotate the data from the force transducer reference frame to the wind
% tunnel reference frame (body frame to global frame)
results_lab = coordinate_transformation(force_data, AoA);

% Non-dimensionalize the data. Newtons to Force Coefficients and
% Newton*meters to Moment Coefficients
[norm_data, norm_factors, St, Re] = non_dimensionalize_data(results_lab, file);

% Smooth the data with a butterworth filter
filtered_data = filter_data(results_lab, frame_rate);
filtered_norm_data = filter_data(norm_data, frame_rate);

% may add step to shift pitching moment
% filtered_data(:,5) = move_pitch(filtered_data(:,5));

% Analyze data in frequency space, identify frequencies that dominate
[freq, freq_power, dominant_freq] = freq_spectrum(norm_data, frame_rate);

filename = case_name + ".mat"; % file name for processed data

% If this is a flapping trial, analyze data over each wingbeat rather than
% just in time
if (wing_freq > 0)

[wingbeat_forces, frames, wingbeat_avg_forces, wingbeat_std_forces, ...
    wingbeat_rmse_forces, wingbeat_max_forces, wingbeat_min_forces, wingbeat_COP]...
    = wingbeat_transformation(num_wingbeats, filtered_data);

save(processed_data_path + filename, 'wingbeat_forces',...
    'frames', 'wingbeat_avg_forces', 'wingbeat_std_forces',...
    'wingbeat_rmse_forces', 'wingbeat_max_forces', 'wingbeat_min_forces',...
    'wingbeat_COP', 'time_data', 'results_lab', 'filtered_data', ...
    'filtered_norm_data', 'norm_factors', 'St', 'Re', 'freq', 'freq_power', 'dominant_freq')
else
    save(processed_data_path + filename, 'time_data', 'results_lab', ...
    'filtered_data', 'filtered_norm_data', 'norm_factors', 'St', 'Re', 'freq', ...
    'freq_power', 'dominant_freq')
end
end