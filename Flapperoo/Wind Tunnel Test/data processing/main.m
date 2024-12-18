% Author: Ronan Gissler
% Last updated: October 2023
clear
close all
restoredefaultpath
addpath process_trial/functions
addpath general
addpath(genpath('plotting'))
addpath modeling
addpath robot_parameters/

raw_data_path = [];
processed_data_path = [];

type = "blue wings half body";
wind_speed = 3;
wing_freq = 3;
AoA = 0;

file = type + " " + wind_speed + "m.s " + AoA + "deg " + wing_freq + "Hz";
data_path = "F:/Final Force Data";
% data_path = "/Users/ronangiss/Documents/data/";
flapper_type = "/Flapperoo/";

% If set to true, user is allowed to select their own file
userSelect = false;

nondimensional = true;

% Decide which plots to show using this struct of booleans
bools.raw = true; % Plot the raw data readings?
bools.time_data = true; % Plot the data in time
bools.kinematics = false; % Plot the wingbeat kinematics?
bools.eff_wind = false; % Plot the effective wind and AoA?
bools.model = true; % Plot the modeled forces?
bools.COP = false; % Plot the movement of the Center-of-Pressure?
bools.movie = false; % Make a movie using all wingbeats?
bools.spectrum = false; % Plot a frequency spectrum?

% subtraction only does something for the model data
% (wingbeat_avg_forces)
sub_strings = []; % "blue wings 0m.s", "no wings 4m.s"
sub_string_speeds = [];
for i = 1:length(sub_strings)
    name_parts = split(sub_strings(i));
    speed = str2double(extractBefore(name_parts(end), "m.s"));
    sub_string_speeds = [sub_string_speeds speed];
end

% make type list from type and subtraction types to add all
% associated folders to the search
dir_list = [type + " " + wind_speed + "m.s" sub_strings];

% Get all type folders in the speed folders
dir_names = [];
speed_list = [wind_speed sub_string_speeds];
speed_list = unique(speed_list);
for i = 1:length(speed_list)
    speed_path = data_path + flapper_type + speed_list(i) + " m.s/";
    dir_names = [dir_names; dir(speed_path)];
end

% remove . and .. directories
ind_to_remove = [];
for i = 1:length(dir_names)
    if (dir_names(i).name == "." || dir_names(i).name == "..")
        ind_to_remove = [ind_to_remove i];
    end
end
dir_names(ind_to_remove) = [];

% path to folders where raw data (.csv files) are stored
for i = 1:length(dir_names)
    cur_name_parts = split(dir_names(i).name);
    cur_folder = strrep(dir_names(i).folder, '\', '/');
    cur_type = strrep(cur_name_parts{1},'_',' ');
    cur_speed = string(extractAfter(cur_folder, flapper_type));
    if (sum(contains(dir_list, cur_type)) > 0 && sum(contains(dir_list, erase(cur_speed, " "))) > 0) % find matches
        filepath = data_path + flapper_type + cur_speed + "/" + dir_names(i).name;
        raw_data_path = [raw_data_path filepath + "/raw data/experiment data/"];
        processed_data_path = [processed_data_path filepath + "/processed data/"];
    end
end

raw_data_files = getFiles(raw_data_path, '*.csv');
processed_data_files = getFiles(processed_data_path, '*.mat');

if userSelect
    disp("Default file will be overwritten by user selection.")
    % Ask the user to select a file to examine the data from
    [file,path] = uigetfile(data_path + flapper_type + '*.mat');
    if isequal(file,0)
       disp('User selected Cancel');
    else
       disp(['User selected ', fullfile(path,file)]);
    end
    file = convertCharsToStrings(file);
end

plot_trial(data_path, file, raw_data_files, processed_data_files, bools, sub_strings, nondimensional)

function theFiles = getFiles(filepath, filetype)
    % Get a list of all files in the folder with the desired file name pattern.
    filePattern = fullfile(filepath, filetype); % Change to whatever pattern you need.
    theFiles = [];
    for i = 1:length(filePattern)
        theFiles = [theFiles; dir(filePattern(i))];
    end
end