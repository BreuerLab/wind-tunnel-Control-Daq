% Author: Ronan Gissler
% Last updated: October 2023

% Note: Your current working directory in Matlab must include this file
% (i.e. you must be in the process trial folder)
clear
close all
addpath functions
addpath ../robot_parameters/
addpath ../plotting
addpath ../general

raw_data_path = "/raw data/experiment data/";
processed_data_path = "/processed data/";
wind_tunnel_path = "/raw data/wind tunnel data/";

date = "08_05_2024";

raw_data_path = "../../" + date + raw_data_path;
processed_data_path = "../../" + date + processed_data_path;
wind_tunnel_path = "../../" + date + wind_tunnel_path;

% Get a list of all files in the folder with the desired file name pattern.
filePattern = fullfile(raw_data_path, '*.csv');
theFiles = dir(filePattern);

% Grab each file and process the data from that file, storing the results
for k = 1 : length(theFiles)
    baseFileName = theFiles(k).name;

    disp("Reading from: ")
    disp(baseFileName)

    process_trial(baseFileName, raw_data_path, processed_data_path, wind_tunnel_path);

    percent_complete = round((k / length(theFiles)) * 100, 2);
    disp(percent_complete + "% complete")
end