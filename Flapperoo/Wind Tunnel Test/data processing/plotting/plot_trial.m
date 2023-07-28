function plot_trial(file,path, movie_bool)
case_name = erase(file, ".mat");
load(path + file);

x_label = "Time (s)";
y_label_F = "Force (N)";
y_label_M = "Moment (N*m)";
subtitle = "Trimmed, Rotated";
axes_labels = [x_label, y_label_F, y_label_M];
plot_forces(time_data, results_lab, case_name, subtitle, axes_labels);

x_label = "Time (s)";
y_label_F = "Force Coefficient";
y_label_M = "Moment Coefficient";
subtitle = "Trimmed, Rotated, Non-dimensionalized";
axes_labels = [x_label, y_label_F, y_label_M];
plot_forces(time_data, norm_data, case_name, subtitle, axes_labels);

x_label = "Time (s)";
y_label_F = "Force Coefficient";
y_label_M = "Moment Coefficient";
subtitle = "Trimmed, Rotated, Non-dimensionalized, Filtered";
axes_labels = [x_label, y_label_F, y_label_M];
plot_forces(time_data, filtered_data, case_name, subtitle, axes_labels);

x_label = "Wingbeat Period (t/T)";
y_label_F = "Force Coefficient";
y_label_M = "Moment Coefficient";
axes_labels = [x_label, y_label_F, y_label_M];
subtitle = "Trimmed, Rotated, Non-dimensionalized, Filtered, Wingbeat Averaged, Shaded -> +/- 1 SD";
plot_forces_mean(frames, wingbeat_avg_forces, wingbeat_std_forces, case_name, subtitle, axes_labels);

x_label = "Wingbeat Period (t/T)";
y_label_F = "Force Coefficient";
y_label_M = "Moment Coefficient";
axes_labels = [x_label, y_label_F, y_label_M];
subtitle = "Trimmed, Rotated, Non-dimensionalized, Filtered, Wingbeat Averaged, Shaded -> Range";
plot_forces_mean_range(frames, wingbeat_avg_forces, wingbeat_max_forces, wingbeat_min_forces, case_name, subtitle, axes_labels);

x_label = "Wingbeat Period (t/T)";
y_label_F = "RMSE";
y_label_M = "RMSE";
axes_labels = [x_label, y_label_F, y_label_M];
subtitle = "Trimmed, Rotated, Non-dimensionalized, Filtered, Wingbeat RMS'd";
plot_forces(frames, wingbeat_rmse_forces, case_name, subtitle, axes_labels);

if (movie_bool)
    y_label_F = "Force Coefficient";
    y_label_M = "Moment Coefficient";
    axes_labels = [x_label, y_label_F, y_label_M];
    subtitle = "Trimmed, Rotated, Non-dimensionalized, Filtered, Wingbeat Averaged";
    wingbeat_movie(frames, wingbeat_forces, case_name, subtitle, axes_labels);
end

subtitle = "Trimmed, Rotated, Non-dimensionalized, Power Spectrum";
plot_spectrum(freq, freq_power, dominant_freq, case_name, subtitle)
end