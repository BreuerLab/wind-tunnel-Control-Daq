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

wind_speed_sel = 0;
type = "no_shoulders"; % needs to match folder name only

% set up Slack messenger objects
slack_path = "../../";
s = slackMsg(slack_path);
bot = slackProgressBar(slack_path);

speed_path = "../../Flapperoo/" + wind_speed_sel + " m.s/";
filePattern = fullfile(speed_path); % Change to whatever pattern you need.
dir_names = dir(filePattern);

% path to folders where raw data (.csv files) are stored
raw_data_path = [];
processed_data_path = [];
wind_tunnel_path = [];
for i = 3:length(dir_names)
    cur_name_parts = split(dir_names(i).name);
    cur_name = cur_name_parts{1};
    if (type == cur_name)
        filepath = speed_path + dir_names(i).name;
        raw_data_path = [raw_data_path filepath + "/raw data/experiment data/"];
        processed_data_path = [processed_data_path filepath + "/processed data/"];
        wind_tunnel_path = [wind_tunnel_path filepath + "/raw data/wind tunnel data/"];
    end
end

% Get a list of all files in the folder with the desired file name pattern.
filePattern = fullfile(raw_data_path, '*.csv'); % Change to whatever pattern you need.
exp_files = [];
for i = 1:length(filePattern)
    exp_files = [exp_files; dir(filePattern(i))];
end

% Record log of outputs while processing data
diary("../../processing logs/" + wind_speed_sel + "ms_" + type + ".txt")
percent_complete = 0;
try
time_now = datetime;
time_now.Format = 'yyyy_MM_dd HH_mm_ss';
s.send("Started processing files at: " + string(time_now))

% Post the initial message
[channelID, messageTs] = bot.makeBar();

% Grab each file and process the data from that file, storing the results
for k = 1 : length(exp_files)
    baseFileName = convertCharsToStrings(exp_files(k).name);

    disp("Reading from: ")
    disp(baseFileName)

    process_trial(baseFileName, raw_data_path, processed_data_path, wind_tunnel_path);

    percent_complete = round((k / length(exp_files)) * 100, 2);
    disp(percent_complete + "% complete")
            
    bot.updateProgress(channelID, messageTs, percent_complete);
end

diary off
time_now = datetime;
time_now.Format = 'yyyy_MM_dd HH_mm_ss';
s.send("Finished processing all files at: " + string(time_now))
catch ME
time_now = datetime;
time_now.Format = 'yyyy_MM_dd HH_mm_ss';
s.send("Encountered error while processing files at: " + string(time_now)...
    + ". " + percent_complete + "% complete.")    
rethrow(ME)
end