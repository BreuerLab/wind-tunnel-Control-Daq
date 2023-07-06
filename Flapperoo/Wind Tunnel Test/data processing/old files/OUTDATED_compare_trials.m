clear
close all

% Ronan Gissler June 2023
path = "C:\Users\rgissler\Desktop\Ronan Lab Documents\Stability Test Data\06_17_23\experiment data\";

% Get a list of all files in the folder with the desired file name pattern.
filePattern = fullfile(path, '*.csv'); % Change to whatever pattern you need.
theFiles = dir(filePattern);

cases = "";
wing_freq_sel = 4;
AoA_sel = [4];
wind_speed_sel = [0, 2, 4];
type_sel = "mylar";

for k = 1 : length(theFiles)
    baseFileName = theFiles(k).name;
%     disp("Now reading " + baseFileName)

    [case_name, type, wing_freq, AoA, wind_speed] = parse_filename(baseFileName);

    if (ismember(wing_freq, wing_freq_sel) && ismember(AoA, AoA_sel) && ismember(wind_speed, wind_speed_sel) && type == type_sel)
        process_trial(baseFileName, path, false);
        if (cases == "")
            cases = convertCharsToStrings(case_name);
        else
            cases = [cases, case_name];
        end
    end
end

clearvars -except cases wing_freq_sel AoA_sel wind_speed_sel type_sel
data_path = "C:\Users\rgissler\Desktop\Ronan Lab Documents\Stability Test Data\06_17_23\processed data\";
for i = 1:length(cases)
    load(data_path + cases(i) + '.mat');
    frames_mult(i,:) = frames;
    wingbeat_avg_forces_mult(i,:,:) = wingbeat_avg_forces;
    wingbeat_rmse_forces_mult(i,:,:) = wingbeat_rmse_forces;
    wingbeat_std_forces_mult(i,:,:) = wingbeat_std_forces;
end

x_label = "Wingbeat Period (t/T)";
% y_label_F = "Force Coefficient";
% y_label_M = "Moment Coefficient";
y_label_F = "Force (N)";
y_label_M = "Moment Coefficient";
axes_labels = [x_label, y_label_F, y_label_M];
% main_title = "Force Transducer Measurement for " + wind_speed_sel + " m/s " + AoA_sel + " deg " + wing_freq_sel + " Hz ";
main_title = "Force Transducer Measurement for " + type_sel;
sub_title = "Trimmed, Rotated, Non-dimensionalized, Filtered, Wingbeat Averaged";
plot_forces_mult_mean(frames_mult, wingbeat_avg_forces_mult, wingbeat_std_forces_mult, cases, main_title, sub_title, axes_labels, length(cases));

x_label = "Wingbeat Period (t/T)";
y_label_F = "RMSE";
y_label_M = "RMSE";
axes_labels = [x_label, y_label_F, y_label_M];
% main_title = "Force Transducer Measurement for " + wind_speed_sel + " m/s " + AoA_sel + " deg " + wing_freq_sel + " Hz ";
main_title = "Force Transducer Measurement for " + type_sel;
sub_title = "Trimmed, Rotated, Non-dimensionalized, Filtered, Wingbeat RMS'd";
plot_forces_mult(frames_mult, wingbeat_rmse_forces_mult, cases, main_title, sub_title, axes_labels, length(cases));