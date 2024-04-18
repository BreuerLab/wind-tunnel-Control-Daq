% Author: Ronan Gissler
% Last updated: October 2023
clear
close all
addpath 'process_trial'
addpath 'process_trial/functions'
addpath 'plotting'
addpath 'modeling'

raw_data_path = "../raw data/experiment data/";
processed_data_path = "../processed data/";

userSelect = false;

% Make a struct of plotting booleans
bools.raw = false;
bools.kinematics = false;
bools.eff_wind = false;
bools.inertial = false;
bools.spectrum = false;
bools.movie =false;

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
    wind_speed = 4;
    wing_freq = 4;
    AoA = 0;
    file = type + " " + wind_speed + "m.s " + AoA + "deg " + wing_freq + "Hz";
end

plot_trial(file, raw_data_path, processed_data_path, bools)