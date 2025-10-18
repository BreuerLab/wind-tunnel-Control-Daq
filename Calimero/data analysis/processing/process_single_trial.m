% Author: Ronan Gissler
% Last updated: October 2023

% Note: Your current working directory in Matlab must include this file
% (i.e. you must be in the process trial folder)
clear
close all
restoredefaultpath
addpath(genpath('../../'))

% data_path = "F:\Calimero Data\Calimero 09_23_2025_ascending\Calimero\";
% Open a file selection dialog and get the file path
data_path = uigetdir("F:\Calimero Data", 'Select a folder') + "\";
if isequal(data_path, 0)
    disp('User canceled folder selection.');
else
    disp(['Selected folder: ', data_path]);
end

raw_data_path = "";
offsets_path = "";
processed_data_path = "";
wind_tunnel_path = "";

wind_speed = 5;
type = "benchtop"; % needs to match folder name only

% speed_path = "../../" + wind_speed + " m.s/";
% filePattern = fullfile(speed_path); % Change to whatever pattern you need.
% dir_names = dir(filePattern);

% path to folders where raw data (.csv files) are stored
% for i = 3:length(dir_names)
%     cur_name_parts = split(dir_names(i).name);
%     cur_name = cur_name_parts{1};
%     if (type == cur_name)
%         filepath = speed_path + dir_names(i).name;
%         raw_data_path = raw_data_path + filepath + "/raw data/experiment data/";
%         processed_data_path = processed_data_path + filepath + "/processed data/";
%         wind_tunnel_path = wind_tunnel_path + filepath + "/raw data/wind tunnel data/";
%     end
% end

filepath = data_path;
raw_data_path = raw_data_path + filepath + "/raw data/experiment data/";
offsets_path = offsets_path + filepath + "/raw data/offsets data/";
processed_data_path = processed_data_path + filepath + "/processed data/";
% wind_tunnel_path = wind_tunnel_path + filepath + "/raw data/wind tunnel data/";

% Ask the user to select a file to process the data from
file = convertCharsToStrings(uigetfile(raw_data_path + "*.mat"));
if isequal(file,0)
   disp('User selected Cancel');
else
   disp("User selected " + raw_data_path + file);
end

process_trial(file, raw_data_path, offsets_path, processed_data_path, wind_tunnel_path);