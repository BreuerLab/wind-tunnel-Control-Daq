clear
close all

% Ronan Gissler June 2023

addpath 'process trial'
addpath 'plotting'

% -----------------------------------------------------------------
% The parameter combinations for which you'd like to see the data
% -----------------------------------------------------------------
wing_freq_sel = [2];
AoA_sel = -14:2:14;
wind_speed_sel = [4];
type_sel = "mylar";

% path to folder where all processed data (.mat files) are stored
processed_data_path = "C:\Users\rgissler\Desktop\Ronan Lab Documents\Stability Test Data\06_17_23\processed data\";

% -----------------------------------------------------------------

% Get a list of all files in the folder with the desired file name pattern.
filePattern = fullfile(processed_data_path, '*.mat'); % Change to whatever pattern you need.
theFiles = dir(filePattern);

% Shorten list of filenames based on parameter requirements
cases = "";
for k = 1 : length(theFiles)
    baseFileName = theFiles(k).name;
    [case_name, type, wing_freq, AoA, wind_speed] = parse_filename(baseFileName);

    if (ismember(wing_freq, wing_freq_sel) && ismember(AoA, AoA_sel) && ismember(wind_speed, wind_speed_sel) && type == type_sel)
        if (cases == "")
            cases = convertCharsToStrings(case_name);
        else
            cases = [cases, case_name];
        end
    end
end

clearvars -except processed_data_path cases ...
    wing_freq_sel AoA_sel wind_speed_sel type_sel

avg_forces = zeros(length(AoA_sel), 6);

for i = 1:length(cases)
        load(path + cases(i) + '.mat');
        for j = 1:6
            avg_forces(i,j) = mean(wingbeat_avg_forces(:, j));
        end
end

x_label = "Angle of Attack (deg)";
y_label_F = "Force (N)";
y_label_M = "Moment (N*m)";
axes_labels = [x_label, y_label_F, y_label_M];

% Open a new figure.
f = figure;
f.Position = [200 50 900 560];
tcl = tiledlayout(2,3);

% Create three subplots to show the force time histories. 
nexttile(tcl)
plot(AoA_sel, avg_forces(:, 1));
title(["F_x (streamwise)"]);
xlabel(axes_labels(1));
ylabel(axes_labels(2));

nexttile(tcl)
plot(AoA_sel, avg_forces(:, 2));
title(["F_y (transverse)"]);
xlabel(axes_labels(1));
ylabel(axes_labels(2));

nexttile(tcl)
plot(AoA_sel, avg_forces(:, 3));
title(["F_z (vertical)"]);
xlabel(axes_labels(1));
ylabel(axes_labels(2));

% Create three subplots to show the moment time histories.
nexttile(tcl)
plot(AoA_sel, avg_forces(:, 4));
title(["M_x (roll)"]);
xlabel(axes_labels(1));
ylabel(axes_labels(3));

nexttile(tcl)
plot(AoA_sel, avg_forces(:, 5));
title(["M_y (pitch)"]);
xlabel(axes_labels(1));
ylabel(axes_labels(3));

nexttile(tcl)
plot(AoA_sel, avg_forces(:, 6));
title(["M_z (yaw)"]);
xlabel(axes_labels(1));
ylabel(axes_labels(3));

% Label the whole figure.
sgtitle(["Force Transducer Measurement for " + case_name subtitle]);