function process_trial(file,path)

frame_rate = 9000; % Hz
num_wingbeats = 180;

[case_name, wing_freq, AoA, wind_speed] = parse_filename(file);

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
x_label = "Time (s)";
y_label_F = "Force (N)";
y_label_M = "Moment (N*m)";
subtitle = "Trimmed, Rotated";
axes_labels = [x_label, y_label_F, y_label_M];
plot_forces(time_data, results_lab, case_name, subtitle, axes_labels);

norm_data = non_dimensionalize_data(results_lab, wing_freq, wind_speed);
x_label = "Time (s)";
y_label_F = "Force Coefficient";
y_label_M = "Moment Coefficient";
subtitle = "Trimmed, Rotated, Non-dimensionalized";
axes_labels = [x_label, y_label_F, y_label_M];
plot_forces(time_data, norm_data, case_name, subtitle, axes_labels);

filtered_data = filter_data(norm_data, frame_rate);
x_label = "Time (s)";
y_label_F = "Force Coefficient";
y_label_M = "Moment Coefficient";
subtitle = "Trimmed, Rotated, Non-dimensionalized, Filtered";
axes_labels = [x_label, y_label_F, y_label_M];
plot_forces(time_data, filtered_data, case_name, subtitle, axes_labels);

freq_spectrum(filtered_data, frame_rate, case_name);

wingbeats = linspace(0, num_wingbeats, length(trimmed_results));

[wingbeat_forces, frames, wingbeat_avg_forces, wingbeat_rmse_forces] = wingbeat_transformation(num_wingbeats, norm_data);
x_label = "Wingbeat Period (t/T)";
y_label_F = "Force Coefficient";
y_label_M = "Moment Coefficient";
axes_labels = [x_label, y_label_F, y_label_M];
subtitle = "Trimmed, Rotated, Non-dimensionalized, Filtered, Wingbeat Averaged";
plot_forces(frames, wingbeat_avg_forces, case_name, subtitle, axes_labels);

x_label = "Wingbeat Period (t/T)";
y_label_F = "RMS";
y_label_M = "RMS";
axes_labels = [x_label, y_label_F, y_label_M];
subtitle = "Trimmed, Rotated, Non-dimensionalized, Filtered, Wingbeat RMS'd";
plot_forces(frames, wingbeat_rmse_forces, case_name, subtitle, axes_labels);

save(path + '..\processed data\' + case_name + '.mat', 'time_data', 'filtered_data', 'wingbeats', 'wingbeat_forces', 'frames', 'wingbeat_avg_forces')
end