clear
close all

% Ronan Gissler June 2023
addpath 'process trial'
addpath 'process trial/functions'
addpath 'plotting'

% path to folder where all raw data (.csv files) are stored
experiment_data_path = "C:\Users\rgissler\Desktop\Ronan Lab Documents\Stability Test Data\06_17_23\experiment data\";
% path to folder where all processed data (.mat files) are stored
processed_data_path = "C:\Users\rgissler\Desktop\Ronan Lab Documents\Stability Test Data\06_17_23\processed data\";

[file,path] = uigetfile(experiment_data_path + '*.csv');
if isequal(file,0)
   disp('User selected Cancel');
else
   disp(['User selected ', fullfile(path,file)]);
end

file = convertCharsToStrings(file);

new_file = process_trial(file, experiment_data_path);

plot_trial(new_file, processed_data_path, false)