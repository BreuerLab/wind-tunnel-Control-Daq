% Ronan Gissler June 2023
clear
close all
addpath 'process trial'
addpath 'process trial/functions'
addpath 'plotting'

% -----------------------------------------------------------------
% The parameter combinations for which you'd like to see the data
% -----------------------------------------------------------------
wing_freq_sel = [2,3,4,5];
AoA_sel = [0];
wind_speed_sel = [4];
type_sel = "blue wings";

% path to folder where all processed data (.mat files) are stored
processed_data_path = "../processed data/";

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

% Produce overlay plots comparing the different cases
% main_title = "Force Transducer Measurement for " + wind_speed_sel + " m/s " + AoA_sel + " deg " + wing_freq_sel + " Hz ";
main_title = "Force Transducer Measurement for " + type_sel;
sub_title = "Trimmed, Rotated, Non-dimensionalized, Filtered, Wingbeat Averaged";
% plot_forces_mult(processed_data_path, cases, main_title, sub_title);
plot_forces_mult_subset(processed_data_path, cases, main_title, sub_title);