clear
close all

% Ronan Gissler June 2023
path = "C:\Users\rgissler\Desktop\Ronan Lab Documents\Stability Test Data\06_17_23\experiment data\";

% [file,path] = uigetfile(folder_path + '*.csv');
% if isequal(file,0)
%    disp('User selected Cancel');
% else
%    disp(['User selected ', fullfile(path,file)]);
% end
% 
% file = convertCharsToStrings(file);

% Get a list of all files in the folder with the desired file name pattern.
filePattern = fullfile(path, '*.csv'); % Change to whatever pattern you need.
theFiles = dir(filePattern);

cases = "";

for k = 1 : length(theFiles)
    baseFileName = theFiles(k).name;
%     disp("Now reading " + baseFileName)

    [case_name, wing_freq, AoA, wind_speed] = parse_filename(baseFileName);

    if (wing_freq == 5 && AoA == 0 && wind_speed == 0)
        process_trial(baseFileName, path);
        cases = [cases, case_name];
    end
end

clearvars -except cases
data_path = "C:\Users\rgissler\Desktop\Ronan Lab Documents\Stability Test Data\06_17_23\processed data\";
for i = 2:length(cases)
    load(data_path + cases(i) + '.mat');
    frames_mult(i,:) = frames;
    wingbeat_avg_forces_mult(i,:,:) = wingbeat_avg_forces;
end

x_label = "Wingbeat Period (t/T)";
y_label_F = "Force Coefficient";
y_label_M = "Moment Coefficient";
axes_labels = [x_label, y_label_F, y_label_M];
subtitle = "Trimmed, Rotated, Non-dimensionalized, Filtered, Wingbeat Averaged";
plot_forces_mult(frames_mult, wingbeat_avg_forces_mult, cases, subtitle, axes_labels, length(cases) - 1);