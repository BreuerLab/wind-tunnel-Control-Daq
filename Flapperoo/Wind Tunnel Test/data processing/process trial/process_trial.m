function filename = process_trial(file,path)

frame_rate = 9000; % Hz
num_wingbeats = 180;

[case_name, type, wing_freq, AoA, wind_speed] = parse_filename(file);

% Get data from file
data = readmatrix(path + file);

raw_data = data(:,1:7);
raw_trigger = data(:,8);

trimmed_results = trim_data(raw_data, raw_trigger);

if (length(raw_data) == length(trimmed_results))
    disp("Data was not trimmed.")
end

time_data = trimmed_results(:,1);
force_data = trimmed_results(:,2:7);

results_lab = coordinate_transformation(force_data, AoA);

% norm_data = non_dimensionalize_data(results_lab, wing_freq, wind_speed);
norm_data = results_lab;

filtered_data = filter_data(norm_data, frame_rate);

wingbeats = linspace(0, num_wingbeats, length(trimmed_results));

[wingbeat_forces, frames, wingbeat_avg_forces, wingbeat_std_forces, ...
    wingbeat_rmse_forces, wingbeat_max_forces, wingbeat_min_forces] = wingbeat_transformation(num_wingbeats, norm_data);

[freq, freq_power, dominant_freq] = freq_spectrum(norm_data, frame_rate);

filename = case_name + ".mat";

save(path + '..\processed data\' + filename, 'time_data', 'results_lab', ...
    'norm_data', 'filtered_data', 'wingbeats', 'wingbeat_forces', ...
    'frames', 'wingbeat_avg_forces', 'wingbeat_std_forces', ...
    'wingbeat_rmse_forces', 'wingbeat_max_forces', ...
    'wingbeat_min_forces', 'freq', 'freq_power', 'dominant_freq')
end