% Ronan Gissler June 2023
clear
close all
addpath 'process trial'
addpath 'process trial/functions'
addpath 'plotting'

% -----------------------------------------------------------------
% The parameter combinations for which you'd like to see the data
% -----------------------------------------------------------------
wing_freq_sel = [0,3,5,6];
wind_speed_sel = [4];
type_sel = ["small blue flap"];
% type_sel = ["small blue flap","big blue"];
% names = ["Big Blue 0 Hz","Small Blue 0 Hz"];
% names = ["0 Hz, St = 0", "3 Hz, St = 0.24", "5 Hz, St = 0.40"];
names = ["0 Hz, St = 0", "3 Hz, St = 0.20", "5 Hz, St = 0.33", "6 Hz, St = 0.40"];
sub_title = "Small Blue Wind = 4 m/s";

% path to folder where all processed data (.mat files) are stored
processed_data_path = "../processed data/";

% -----------------------------------------------------------------
% AoA_sel = [-14, -10, -6, -2, 0, 2, 6, 10, 14]; % you can narrow this range if you like
AoA_sel = [-10, -4, 0, 4, 10]; % you can narrow this range if you like

% Get a list of all files in the folder with the desired file name pattern.
filePattern = fullfile(processed_data_path, '*.mat'); % Change to whatever pattern you need.
theFiles = dir(filePattern);

% Shorten list of filenames based on parameter requirements
cases = "";
for k = 1 : length(theFiles)
    baseFileName = theFiles(k).name;
    [case_name, type, wing_freq, AoA, wind_speed] = parse_filename(baseFileName);
    
    if (ismember(wing_freq, wing_freq_sel) && ismember(AoA, AoA_sel) && ismember(wind_speed, wind_speed_sel) && ismember(type, type_sel))
        if (cases == "")
            cases = convertCharsToStrings(case_name);
        else
            cases = [cases, case_name];
        end
    end
end

clearvars -except processed_data_path cases names sub_title ...
    wing_freq_sel AoA_sel wind_speed_sel type_sel

cases_final = plot_forces_AoA(processed_data_path, cases, AoA_sel, names, sub_title, true, false, true);