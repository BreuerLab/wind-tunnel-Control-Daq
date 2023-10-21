function filename = process_trial(file,path)

frame_rate = 9000; % Hz
num_wingbeats = 180;

[case_name, type, wing_freq, AoA, wind_speed] = parse_filename(file);

% Get data from file
data = readmatrix(path + file);

raw_data = data(:,1:7);
raw_trigger = data(:,8);

trimmed_results = trim_data(raw_data, raw_trigger);

time_data = trimmed_results(:,1);
force_data = trimmed_results(:,2:7);

results_lab = coordinate_transformation(force_data, AoA);

[norm_data, St, Re] = non_dimensionalize_data(results_lab, case_name, wing_freq, wind_speed);

filtered_data = filter_data(results_lab, frame_rate);
filtered_norm_data = filter_data(norm_data, frame_rate);

% filtered_data(:,5) = move_pitch(filtered_data(:,5));

filename = case_name + ".mat";

[freq, freq_power, dominant_freq] = freq_spectrum(norm_data, frame_rate);

if (wing_freq > 0)

[wingbeat_forces, frames, wingbeat_avg_forces, wingbeat_std_forces, ...
    wingbeat_rmse_forces, wingbeat_max_forces, wingbeat_min_forces, wingbeat_COP] = wingbeat_transformation(num_wingbeats, filtered_data);

save('..\processed data\' + filename, 'wingbeat_forces', ...
    'frames', 'wingbeat_avg_forces', 'wingbeat_std_forces', ...
    'wingbeat_rmse_forces', 'wingbeat_max_forces', ...
    'wingbeat_min_forces', 'wingbeat_COP', 'time_data', 'results_lab', ...
    'filtered_data', 'filtered_norm_data', 'St', 'Re', 'freq', 'freq_power', 'dominant_freq')
else
    save('..\processed data\' + filename, 'time_data', 'results_lab', ...
    'filtered_data', 'filtered_norm_data', 'St', 'Re', 'freq', 'freq_power', 'dominant_freq')
end
end