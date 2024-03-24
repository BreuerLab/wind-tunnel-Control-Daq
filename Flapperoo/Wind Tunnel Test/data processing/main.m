% Author: Ronan Gissler
% Last updated: October 2023
clear
close all
addpath 'process trial'
addpath 'process trial/functions'
addpath 'plotting'

% path to folder where all processed data (.mat files) are stored
data_path = "../processed data/";

userSelect = false;

if userSelect
    % Ask the user to select a file to examine the data from
    [file,path] = uigetfile(data_path + '*.mat');
    if isequal(file,0)
       disp('User selected Cancel');
    else
       disp(['User selected ', fullfile(path,file)]);
    end
    file = convertCharsToStrings(file);
else
    type = "blue wings";
    wind_speed = 2;
    wing_freq = 2;
    AoA = 0;
    file = type + " " + wind_speed + "m.s " + AoA + "deg " + wing_freq + "Hz";
end

plot_trial(file, data_path, false)