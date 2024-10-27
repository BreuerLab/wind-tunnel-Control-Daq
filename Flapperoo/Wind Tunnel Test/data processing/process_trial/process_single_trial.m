% Author: Ronan Gissler
% Last updated: October 2023

% Note: Your current working directory in Matlab must include this file
% (i.e. you must be in the process trial folder)
clear
close all
restoredefaultpath
addpath(genpath('../'))

raw_data_path = "";
processed_data_path = "";
wind_tunnel_path = "";

wind_speed = 5;
type = "half_body_no_wings"; % needs to match folder name only

speed_path = "../../" + wind_speed + " m.s/";
filePattern = fullfile(speed_path); % Change to whatever pattern you need.
dir_names = dir(filePattern);

% path to folders where raw data (.csv files) are stored
for i = 3:length(dir_names)
    cur_name_parts = split(dir_names(i).name);
    cur_name = cur_name_parts{1};
    if (type == cur_name)
        filepath = speed_path + dir_names(i).name;
        raw_data_path = raw_data_path + filepath + "/raw data/experiment data/";
        processed_data_path = processed_data_path + filepath + "/processed data/";
        wind_tunnel_path = wind_tunnel_path + filepath + "/raw data/wind tunnel data/";
    end
end

% Ask the user to select a file to process the data from
file = convertCharsToStrings(uigetfile(raw_data_path + "*.csv"));
if isequal(file,0)
   disp('User selected Cancel');
else
   disp("User selected " + raw_data_path + file);
end

process_trial(file, raw_data_path, processed_data_path, wind_tunnel_path);