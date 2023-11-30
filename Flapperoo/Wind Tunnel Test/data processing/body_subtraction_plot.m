% Ronan Gissler June 2023
clear
close all
addpath 'process trial'
addpath 'process trial/functions'
addpath 'plotting'

% path to folder where all processed data (.mat files) are stored
data_path = "../processed data/subtraction/";

[file,path] = uigetfile(data_path + '*.mat');
if isequal(file,0)
   disp('User selected Cancel');
else
   disp(['User selected ', fullfile(path,file)]);
end

file = convertCharsToStrings(file);

[case_name, type, wing_freq, AoA, wind_speed] = parse_filename(file);

load("../processed data/no wings" + case_name + ".mat");
body_forces = wingbeat_avg_forces;
body_lower = wingbeat_avg_forces - wingbeat_std_forces;
body_upper = wingbeat_avg_forces + wingbeat_std_forces;

load("../processed data/inertial" + strrep(case_name,"4m.s","0m.s") + ".mat");
inertial_forces = wingbeat_avg_forces;
inertial_lower = wingbeat_avg_forces - wingbeat_std_forces;
inertial_upper = wingbeat_avg_forces + wingbeat_std_forces;

load("../processed data/tubespars v2" + strrep(case_name,"4m.s","0m.s") + ".mat");
wing_inertial_forces = wingbeat_avg_forces;
wing_inertial_lower = wingbeat_avg_forces - wingbeat_std_forces;
wing_inertial_upper = wingbeat_avg_forces + wingbeat_std_forces;

load("../processed data/tubespars v2" + case_name + ".mat");
wing_forces = wingbeat_avg_forces;
wing_lower = wingbeat_avg_forces - wingbeat_std_forces;
wing_upper = wingbeat_avg_forces + wingbeat_std_forces;
wing_norm_factors = norm_factors;

load(path + file);
subtraction_forces = wingbeat_avg_forces;
subtraction_lower = subtraction_forces - ((body_forces - body_lower) + (wing_forces - wing_lower));
subtraction_upper = subtraction_forces + ((body_upper - body_forces) + (wing_upper - wing_forces));

% Non-dimensionalize everything according to values from wing case
subtraction_forces = dimensionless(subtraction_forces, wing_norm_factors);
subtraction_lower = dimensionless(subtraction_lower, wing_norm_factors);
subtraction_upper = dimensionless(subtraction_upper, wing_norm_factors);

body_forces = dimensionless(body_forces, wing_norm_factors);
body_lower = dimensionless(body_lower, wing_norm_factors);
body_upper = dimensionless(body_upper, wing_norm_factors);

wing_forces = dimensionless(wing_forces, wing_norm_factors);
wing_lower = dimensionless(wing_lower, wing_norm_factors);
wing_upper = dimensionless(wing_upper, wing_norm_factors);

inertial_forces = dimensionless(inertial_forces, wing_norm_factors);
inertial_lower = dimensionless(inertial_lower, wing_norm_factors);
inertial_upper = dimensionless(inertial_upper, wing_norm_factors);

wing_inertial_forces = dimensionless(wing_inertial_forces, wing_norm_factors);
wing_inertial_lower = dimensionless(wing_inertial_lower, wing_norm_factors);
wing_inertial_upper = dimensionless(wing_inertial_upper, wing_norm_factors);

subtraction_forces = wing_forces - wing_inertial_forces;
subtraction_lower = subtraction_forces - ((wing_forces - wing_lower) + (wing_inertial_forces - wing_inertial_lower));
subtraction_upper = subtraction_forces + ((wing_upper - wing_forces) + (wing_inertial_upper - wing_inertial_forces));

plot_var = zeros(size(body_forces,1), size(body_forces,2), 3);
% plot_var(:,:,1) = wing_forces;
% plot_var(:,:,2) = wing_inertial_forces;
% plot_var(:,:,3) = subtraction_forces;
plot_var(:,:,1) = wing_forces;
plot_var(:,:,2) = inertial_forces;
plot_var(:,:,3) = body_forces;
% plot_var(:,:,4) = subtraction_forces;

plot_upper = zeros(size(body_upper,1), size(body_upper,2), 3);
% plot_upper(:,:,1) = wing_upper;
% plot_upper(:,:,2) = wing_inertial_upper;
% plot_upper(:,:,3) = subtraction_upper;
plot_upper(:,:,1) = wing_upper;
plot_upper(:,:,2) = inertial_upper;
plot_upper(:,:,3) = body_upper;
% plot_upper(:,:,4) = subtraction_upper;

plot_lower = zeros(size(body_lower,1), size(body_lower,2), 3);
% plot_lower(:,:,1) = wing_lower;
% plot_lower(:,:,2) = wing_inertial_lower;
% plot_lower(:,:,3) = subtraction_lower;
plot_lower(:,:,1) = wing_lower;
plot_lower(:,:,2) = inertial_lower;
plot_lower(:,:,3) = body_lower;
% plot_lower(:,:,4) = subtraction_lower;

x_label = "Wingbeat Period (t/T)";
y_label_F = "Force Coefficient";
y_label_M = "Moment Coefficient";
axes_labels = [x_label, y_label_F, y_label_M];
subtitle = "Trimmed, Rotated, Non-dimensionalized, Filtered, Wingbeat Averaged, Shaded -> +/- 1 SD";
plot_forces_mean(frames, plot_var, plot_upper, plot_lower, case_name, subtitle, axes_labels);

plot_forces_mean_subset(frames, plot_var, plot_upper, plot_lower, case_name, subtitle, axes_labels);

x_label = "Wingbeat Period (t/T)";
y_label_F = "Force Coefficient";
y_label_M = "Moment Coefficient";
axes_labels = [x_label, y_label_F, y_label_M];
subtitle = "Trimmed, Rotated, Non-dimensionalized, Filtered, Wingbeat Averaged, Shaded -> +/- 1 SD";
plot_forces_mean_subset(frames, subtraction_forces, subtraction_upper, subtraction_lower, case_name, subtitle, axes_labels);
% plot_forces_mean(frames, plot_var, plot_var, plot_var, case_name, subtitle, axes_labels);

% x_label = "Wingbeat Period (t/T)";
% y_label_F = "Force Coefficient";
% y_label_M = "Moment Coefficient";
% axes_labels = [x_label, y_label_F, y_label_M];
% subtitle = "Trimmed, Rotated, Non-dimensionalized, Filtered, Wingbeat Averaged, Shaded -> Range";
% plot_forces_mean(frames, wingbeat_avg_forces, wingbeat_max_forces, wingbeat_min_forces, case_name, subtitle, axes_labels);

% x_label = "Wingbeat Period (t/T)";
% y_label_F = "RMSE";
% y_label_M = "RMSE";
% axes_labels = [x_label, y_label_F, y_label_M];
% subtitle = "Trimmed, Rotated, Non-dimensionalized, Filtered, Wingbeat RMS'd";
% plot_forces(frames, wingbeat_rmse_forces, case_name, subtitle, axes_labels);

% --------------Plotting movement of COP--------------------

COP = wingbeat_avg_forces(5, :) ./ wingbeat_avg_forces(3, :); % M_y / F_z
% fc = 20; % cutoff frequency
% fs = 9000;
% [b,a] = butter(6,fc/(fs/2));
% filtered_COP = filtfilt(b,a,COP);
f = figure;
f.Position = [200 50 900 560];
plot(frames, COP)
% plot(frames, filtered_COP)
% plot(frames, wingbeat_COP)
ylim([-1, 1])
title("Movement of Center of Pressure")
xlabel("Wingbeat Period (t/T)");
ylabel("COP Location");