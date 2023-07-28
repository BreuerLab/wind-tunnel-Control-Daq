% Ronan Gissler June 2023
clear
close all
addpath 'process trial'
addpath 'process trial/functions'
addpath 'plotting'

% -----------------------------------------------------------------
% The parameter combinations for which you'd like to see the data
% -----------------------------------------------------------------
wing_freq_sel = [2, 3, 4, 4.5, 5];
wind_speed_sel = [4];
type_sel = "mylar";
names = ["2 Hz", "3 Hz", "4 Hz", "4.5 Hz", "5 Hz"];
sub_title = "At Wind Speed of 4 m/s";

% path to folder where all processed data (.mat files) are stored
processed_data_path = "../processed data/";

% -----------------------------------------------------------------
AoA_sel = -14:2:14; % you can narrow this range if you like

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

clearvars -except processed_data_path cases names sub_title ...
    wing_freq_sel AoA_sel wind_speed_sel type_sel

plot_forces_AoA(processed_data_path, cases, AoA_sel, names, sub_title);