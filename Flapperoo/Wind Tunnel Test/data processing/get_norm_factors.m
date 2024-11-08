% Author: Ronan Gissler
% Last updated: October 2023
clear
close all
addpath 'general'
addpath 'process_trial'
addpath 'process_trial/functions'
addpath 'robot_parameters'
addpath 'plotting'

% -----------------------------------------------------------------
% ----The parameter combinations you want to see the data for------
% -----------------------------------------------------------------
% freq_speed_combos = [2, 4; 3, 6; 0, 4; 0, 6];

% wing_freq_sel = [0, 2, 3, 4, 5];
wing_freq_sel = [0, 0.1, 2, 2.5, 3, 3.5, 3.75, 4, 4.5, 5, 2, 4];
% wing_freq_sel = [0, 0.1, 2, 2.5, 3, 3.5, 3.75, 4, 2, 4];
wind_speed_sel = [5];
type_sel = ["blue wings half body"];
% AoA_sel = [-12:1:-9 -8:0.5:8 9:1:12];
AoA_sel = [-16:1.5:-13 -12:1:-9 -8:0.5:8 9:1:12 13:1.5:16];
sub_strings = [];

% make type list from type and subtraction types to add all
% associated folders to the search
type_list = [type_sel sub_strings];
type_list = strrep(type_list, ' ', '_');

% set up Slack messenger
data_path = "D:\Final Force Data/";
s = slackMsg(data_path);
bot = slackProgressBar(data_path);

% assuming that all experiment folders are in the same speed
% folder
dir_names = [];
for i = 1:length(wind_speed_sel)
    speed_path = data_path + "Flapperoo/" + wind_speed_sel(i) + " m.s/";
    filePattern = fullfile(speed_path);
    % dir_names = dir(filePattern);
    cur_names = dir(filePattern);
    % remove . and .. directories
    dir_names = [dir_names; cur_names(3:end)];
end

% path to folders where processed data (.mat files) are stored
processed_data_path = [];
% path to folders where offsets data (.csv files) are stored
offsets_path = [];
for i = 1:(length(dir_names))
    cur_name_parts = split(dir_names(i).name);
    cur_name = cur_name_parts{1}; % strip date from name
    cur_speed = sscanf(extractAfter(dir_names(i).folder, "Flapperoo\"), '%g', 1);
    if (sum(type_list == cur_name) > 0 && sum(wind_speed_sel == cur_speed) > 0) % find matches
        filepath = [dir_names(i).folder '/' dir_names(i).name];
        processed_data_path = [processed_data_path filepath + "/processed data/"];
        offsets_path = [offsets_path filepath + "/raw data/offsets data/"];
    end
end

% Get a list of all files in the folder with the desired file name pattern.
filePattern = fullfile(processed_data_path, '*.mat'); % Change to whatever pattern you need.
processed_files = [];
for i = 1:length(filePattern)
    processed_files = [processed_files; dir(filePattern(i))];
end

% Get a list of all files in the folder with the desired file name pattern.
filePattern = fullfile(offsets_path, '*.csv'); % Change to whatever pattern you need.
offsets_files = [];
for i = 1:length(filePattern)
    offsets_files = [offsets_files; dir(filePattern(i))];
end

norm_bool = false;
shift_bool = false;
regress_bool = false;
sub_drift_bool = false;

% Put all our selected variables into a struct called selected_vars
selected_vars.AoA = AoA_sel;
selected_vars.freq = wing_freq_sel;
selected_vars.wind = wind_speed_sel;
selected_vars.type = type_sel;

time_now = datetime;
time_now.Format = 'yyyy_MM_dd HH_mm_ss';
s.send("Started making plots at: " + string(time_now))

% Post the initial message
[channelID, messageTs] = bot.makeBar();

[avg_forces, err_forces, names, sub_title, norm_factors] = ...
get_data_AoA(selected_vars, processed_files, offsets_files, norm_bool, sub_strings, shift_bool, sub_drift_bool);

time_now = datetime;
time_now.Format = 'yyyy_MM_dd HH_mm_ss';

name = type_sel + " " + wind_speed_sel + "m.s.";
name = name + "_saved_" + string(time_now);

save(name + ".mat","norm_factors", "names")

time_now = datetime;
time_now.Format = 'yyyy_MM_dd HH_mm_ss';
s.send("Finished making plots at: " + string(time_now))