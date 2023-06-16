clear
close all

% Ronan Gissler April 2023

% This file is used to plot the raw force transducer data from a
% single trial, giving a quick view of what that trial looked like.

[file,path] = uigetfile('*.csv');
if isequal(file,0)
   disp('User selected Cancel');
else
   disp(['User selected ', fullfile(path,file)]);
end

file = convertCharsToStrings(file);

frame_rate = 6000; % Hz
num_wingbeats = 180;

% Get case name from file name
case_name = erase(file, ["_experiment_032323.csv", "..\Experiment Data\PDMS_heavy\0ms\"]);
case_name = strrep(case_name,'_',' ');
case_parts = strtrim(split(case_name));
speed = 0;
for j=1:length(case_parts)
    if (contains(case_parts(j), "Hz"))
        speed = str2double(erase(case_parts(j), "Hz"));
    end
end

% Get data from file
data = readmatrix(path + file);

% Trim all data based on trigger data
these_trigs = data(:, 8);
these_low_trigs_indices = find(these_trigs < 3);
trigger_start_frame = these_low_trigs_indices(1);
trigger_end_frame = these_low_trigs_indices(end);

trimmed_data = data(trigger_start_frame:trigger_end_frame, :);

trimmed_time = trimmed_data(:,1) - trimmed_data(1,1);

% Calculate the error associated with the DAQ and Galil using
% different clocks
expected_length = (num_wingbeats / speed) * frame_rate;
trigger_error = length(trimmed_data) - expected_length;
expected_period = frame_rate / speed;
wingbeat_period = vpa(length(trimmed_data) / num_wingbeats, 10);

disp("This trial had was expected to have " + expected_length + " frames.");
disp(length(trimmed_data) + " frames were captured.")
disp("Therefore the trigger error associated with this trial was " + trigger_error);
disp("After dividing by the wingbeat frequency, the normalized trigger error is " + trigger_error/speed)

times = data(1:end,1);
force_vals = data(1:end,2:7);

force_means = round(mean(force_vals), 3);
force_SDs = round(std(force_vals), 3);
force_maxs = round(max(force_vals), 3);
force_mins = round(min(force_vals), 3);

 % Open a new figure.
f = figure;
f.Position = [200 50 900 560];
tcl = tiledlayout(2,3);

% Create three subplots to show the force time histories. 
nexttile(tcl)
hold on
raw_line = plot(data(:, 1), data(:, 2), 'DisplayName', 'raw');
trigger_line = plot(trimmed_data(:,1), trimmed_data(:, 2), ...
    'DisplayName', 'trigger');
title(["F_x", "avg: " + force_means(1) + "    SD: " + force_SDs(1), "max: " + force_maxs(1) + "    min: " + force_mins(1)]);
xlabel("Time (s)");
ylabel("Force (N)");

nexttile(tcl)
hold on
plot(data(:, 1), data(:, 3));
plot(trimmed_data(:,1), trimmed_data(:, 3));
title(["F_y", "avg: " + force_means(2) + " SD: " + force_SDs(2), "max: " + force_maxs(2) + "    min: " + force_mins(2)]);
xlabel("Time (s)");
ylabel("Force (N)");

nexttile(tcl)
hold on
plot(data(:, 1), data(:, 4));
plot(trimmed_data(:,1), trimmed_data(:, 4));
title(["F_z", "avg: " + force_means(3) + " SD: " + force_SDs(3), "max: " + force_maxs(3) + "    min: " + force_mins(3)]);
xlabel("Time (s)");
ylabel("Force (N)");

% Create three subplots to show the moment time histories.
nexttile(tcl)
hold on
plot(data(:, 1), data(:, 5));
plot(trimmed_data(:,1), trimmed_data(:, 5));
title(["M_x", "avg: " + force_means(4) + " SD: " + force_SDs(4), "max: " + force_maxs(4) + "    min: " + force_mins(4)]);
xlabel("Time (s)");
ylabel("Torque (N m)");

nexttile(tcl)
hold on
plot(data(:, 1), data(:, 6));
plot(trimmed_data(:,1), trimmed_data(:, 6));
title(["M_y", "avg: " + force_means(5) + " SD: " + force_SDs(5), "max: " + force_maxs(5) + "    min: " + force_mins(5)]);
xlabel("Time (s)");
ylabel("Torque (N m)");

nexttile(tcl)
hold on
plot(data(:, 1), data(:, 7));
plot(trimmed_data(:,1), trimmed_data(:, 7));
title(["M_z", "avg: " + force_means(6) + " SD: " + force_SDs(6), "max: " + force_maxs(6) + "    min: " + force_mins(6)]);
xlabel("Time (s)");
ylabel("Torque (N m)");

hL = legend([raw_line, trigger_line]);
% Move the legend to the right side of the figure
hL.Layout.Tile = 'East';

% Label the whole figure.
sgtitle("Force Transducer Measurement for " + case_name);