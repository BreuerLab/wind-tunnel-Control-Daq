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
function process_trial(file, raw_data_path, processed_data_path, wind_tunnel_path)

[case_name, time_stamp, type, wing_freq, AoA, wind_speed] = parse_filename(file);

[frame_rate, num_wingbeats] = get_sampling_info(wing_freq);

% Get raw data from file
data = readmatrix(raw_data_path + file);
raw_data = data(:,1:7);
raw_trigger = data(:,8);

% Trim off portion of data where wings are motionless or accelerating
trimmed_results = trim_data(raw_data, raw_trigger, wing_freq);
time_data = trimmed_results(:,1)';
time_data = time_data - time_data(1);
force_data = trimmed_results(:,2:7)';

% Rotate the data from the force transducer reference frame to the wind
% tunnel reference frame (body frame to global frame)
results_lab = coordinate_transformation(force_data, AoA);

% Non-dimensionalize the data. Newtons to Force Coefficients and
% Newton*meters to Moment Coefficients
[norm_data, norm_factors, St, Re] = non_dimensionalize_data(wind_tunnel_path, results_lab, file);

% Smooth the data with a butterworth filter
fc = 50; % cutoff frequency
filtered_data = filter_data(results_lab, frame_rate, fc);
filtered_norm_data = filter_data(norm_data, frame_rate, fc);

if (wing_freq > 1)
    fc = 10*wing_freq; % cutoff frequency
else
    fc = 10;
end
filtered_data_smoothest = filter_data(results_lab, frame_rate, fc);

% if (wing_freq > 1)
%     fc = 5*wing_freq; % cutoff frequency
% else
%     fc = 5;
% end
% % downsample from 9 kHz to 3 kHz so that low order filter works
% % change to using a FIR filter for numerical stability?
% down_sampled_results = downsample(results_lab', 10)';
% filtered_data_smoothest = filter_data(down_sampled_results, frame_rate, fc);

% may add step to shift pitching moment
% filtered_data(:,5) = move_pitch(filtered_data(:,5));

filename = case_name + " " + time_stamp + ".mat"; % file name for processed data

saved_vars = {'time_data', 'force_data', 'results_lab',...
    'filtered_data','filtered_data_smoothest'...
    'filtered_norm_data', 'norm_factors', 'St', 'Re'};

% If this is a flapping trial, analyze data over each wingbeat rather than
% just in time
if (wing_freq > 0)
[wingbeat_forces_raw, frames_raw, wingbeat_avg_forces_raw, wingbeat_std_forces_raw, ...
    wingbeat_rmse_forces_raw, wingbeat_max_forces_raw, wingbeat_min_forces_raw, wingbeat_COP_raw, cycle_avg_forces_raw]...
    = wingbeat_transformation(num_wingbeats, results_lab, AoA);

[wingbeat_forces, frames, wingbeat_avg_forces, wingbeat_std_forces, ...
    wingbeat_rmse_forces, wingbeat_max_forces, wingbeat_min_forces, wingbeat_COP, cycle_avg_forces]...
    = wingbeat_transformation(num_wingbeats, filtered_data, AoA);

% [wingbeat_forces_smoother, frames_smoother, wingbeat_avg_forces_smoother, wingbeat_std_forces_smoother, ...
%     wingbeat_rmse_forces_smoother, wingbeat_max_forces_smoother, wingbeat_min_forces_smoother, ...
%     wingbeat_COP_smoother, cycle_avg_forces_smoother]...
%     = wingbeat_transformation(num_wingbeats, filtered_data_smooth, AoA);

[wingbeat_forces_smoothest, frames_smoothest, wingbeat_avg_forces_smoothest, wingbeat_std_forces_smoothest, ...
    wingbeat_rmse_forces_smoothest, wingbeat_max_forces_smoothest, wingbeat_min_forces_smoothest, ...
    wingbeat_COP_smoothest, cycle_avg_forces_smoothest]...
    = wingbeat_transformation(num_wingbeats, filtered_data_smoothest, AoA);

raw_wing_vars = {'wingbeat_forces_raw', 'frames_raw',...
    'wingbeat_avg_forces_raw', 'wingbeat_std_forces_raw',...
    'wingbeat_rmse_forces_raw', 'wingbeat_max_forces_raw',...
    'wingbeat_min_forces_raw', 'wingbeat_COP_raw', 'cycle_avg_forces_raw'};

filt_wing_vars = {'wingbeat_forces','frames',...
    'wingbeat_avg_forces', 'wingbeat_std_forces',...
    'wingbeat_rmse_forces', 'wingbeat_max_forces',...
    'wingbeat_min_forces', 'wingbeat_COP', 'cycle_avg_forces'};

% filt_smooth_wing_vars = {'wingbeat_forces_smoother', 'frames_smoother',...
%     'wingbeat_avg_forces_smoother', 'wingbeat_std_forces_smoother',...
%     'wingbeat_rmse_forces_smoother', 'wingbeat_max_forces_smoother',...
%     'wingbeat_min_forces_smoother', 'wingbeat_COP_smoother', 'cycle_avg_forces_smoother'};

filt_smoothest_wing_vars = {'wingbeat_forces_smoothest', 'frames_smoothest',...
    'wingbeat_avg_forces_smoothest', 'wingbeat_std_forces_smoothest',...
    'wingbeat_rmse_forces_smoothest', 'wingbeat_max_forces_smoothest',...
    'wingbeat_min_forces_smoothest', 'wingbeat_COP_smoothest', 'cycle_avg_forces_smoothest'};

vars = [saved_vars, raw_wing_vars, filt_wing_vars, filt_smoothest_wing_vars];

save(processed_data_path + filename, vars{:})
else
    cycle_forces = reshape(results_lab, 6, length(results_lab)/24, 24);
    cycle_avg_forces = squeeze(mean(cycle_forces,2));

    vars = [saved_vars 'cycle_avg_forces'];
    save(processed_data_path + filename, vars{:})
end
end