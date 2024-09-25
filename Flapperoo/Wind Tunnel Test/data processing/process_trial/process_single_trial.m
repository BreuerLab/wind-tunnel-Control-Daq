% Author: Ronan Gissler
% Last updated: October 2023

% Note: Your current working directory in Matlab must include this file
% (i.e. you must be in the process trial folder)
clear
close all
addpath 'functions'
addpath '../plotting'

raw_data_path = "../../raw data/experiment data/";
processed_data_path = "../../processed data/";

% Ask the user to select a file to process the data from
file = convertCharsToStrings(uigetfile(raw_data_path + "*.csv"));
if isequal(file,0)
   disp('User selected Cancel');
else
   disp("User selected " + raw_data_path + file);
end

process_trial(file, raw_data_path, processed_data_path);