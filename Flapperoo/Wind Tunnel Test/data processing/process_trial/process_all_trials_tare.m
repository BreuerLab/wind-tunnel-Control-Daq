% Author: Ronan Gissler
% Last updated: October 2023

% Note: Your current working directory in Matlab must include this file
% (i.e. you must be in the process trial folder)
clear
close all
addpath 'functions'
addpath '../plotting'

raw_data_path = "../../taring_v3/experiment data/";
processed_data_path = "../../taring_v3/processed data/";

% Get a list of all files in the folder with the desired file name pattern.
filePattern = fullfile(raw_data_path, '*.csv');
theFiles = dir(filePattern);

% Grab each file and process the data from that file, storing the results
for k = 1 : length(theFiles)
    baseFileName = theFiles(k).name;

    process_trial_tare(baseFileName, raw_data_path, processed_data_path);

    percent_complete = round((k / length(theFiles)) * 100, 2);
    disp(percent_complete + "% complete")
end