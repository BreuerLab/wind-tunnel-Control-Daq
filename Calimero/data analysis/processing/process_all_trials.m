% Author: Ronan Gissler
% Last updated: October 2023

% Note: Your current working directory in Matlab must include this file
% (i.e. you must be in the process trial folder)
clear
close all

% Change current working directory to the directory where this file is
cd(fileparts(mfilename('fullpath')));
addpath(genpath('../../Wind Tunnel Test'))
addpath(genpath('../'))

wind_speeds = [4];
types = ["flexible_10"]; % needs to match folder name only
slack_bool = false;
% ADD PATH WHERE DATA SHOULD GET DUMPED

% data_path = "F:\Calimero Data\Calimero 09_23_2025_ascending\Calimero\";

h = helpdlg('Please select the folder that contains speed folders (e.g. 4 m.s).');
uiwait(h);     % ensure the user reads it before continuing

% Open a file selection dialog and get the file path
data_path = uigetdir("F:\Calimero Data", 'Select a folder that contains speed folders') + "\";
if isequal(data_path, 0)
    disp('User canceled folder selection.');
else
    disp(['Selected folder: ', data_path]);
end

for n = 1:length(wind_speeds)
    for m = 1:length(types)

wind_speed_sel = wind_speeds(n);
type = types(m);

if (slack_bool)
% set up Slack messenger objects
s = slackMsg(data_path);
bot = slackProgressBar(data_path);
end

speed_path = data_path + wind_speed_sel + " m.s/";
% speed_path = data_path;
filePattern = fullfile(speed_path); % Change to whatever pattern you need.
dir_names = dir(filePattern);

% path to folders where raw data (.csv files) are stored
raw_data_path = [];
offsets_path = [];
processed_data_path = [];
wind_tunnel_path = [];
for i = 3:length(dir_names)
    cur_name_parts = split(dir_names(i).name);
    cur_name = cur_name_parts{1};
    if (type == cur_name)
        filepath = speed_path + dir_names(i).name;

        raw_data_path = [raw_data_path filepath + "/raw data/experiment data/"];
        offsets_path = [offsets_path filepath + "/raw data/offsets data/"];
        processed_data_path = [processed_data_path filepath + "/processed data/"];
        wind_tunnel_path = [wind_tunnel_path filepath + "/raw data/wind tunnel data/"];

        dirPath = filepath + "/processed data";
        if ~exist(dirPath, 'dir')
            mkdir(dirPath);
            fprintf('Directory "%s" created.\n', dirPath);
        end
    end
end

% filepath = data_path;
% raw_data_path = [raw_data_path filepath + "/raw data/experiment data/"];
% offsets_path = [offsets_path filepath + "/raw data/offsets data/"];
% wind_tunnel_path = [wind_tunnel_path filepath + "/raw data/wind tunnel data/"];
% processed_data_path = [processed_data_path filepath + "/processed data/"];

if isempty(raw_data_path)
    error("Oops, no data paths made")
end

% Get a list of all files in the folder with the desired file name pattern.
filePattern = fullfile(raw_data_path, '*.mat'); % Change to whatever pattern you need.
exp_files = [];
for i = 1:length(filePattern)
    exp_files = [exp_files; dir(filePattern(i))];
end

% Record log of outputs while processing data
dirPath = data_path + "processing logs";
if ~exist(dirPath, 'dir')
    mkdir(dirPath);
    fprintf('Directory "%s" created.\n', dirPath);
end
diary(dirPath + "/" + wind_speed_sel + "ms_" + type + ".txt")
percent_complete = 0;
try
time_now = datetime;
time_now.Format = 'yyyy_MM_dd HH_mm_ss';

if slack_bool
    s.send("Started processing files at: " + string(time_now))
    
    % Post the initial message
    [channelID, messageTs] = bot.makeBar();
end

% Grab each file and process the data from that file, storing the results
for k = 1 : length(exp_files)
    baseFileName = convertCharsToStrings(exp_files(k).name);

    if ~contains(baseFileName, "speedCheck")
    disp("Reading from: ")
    disp(baseFileName)

    process_trial(baseFileName, raw_data_path, offsets_path, processed_data_path, wind_tunnel_path);
    end

    percent_complete = round((k / length(exp_files)) * 100, 2);
    disp(percent_complete + "% complete")
            
    if slack_bool
    bot.updateProgress(channelID, messageTs, percent_complete);
    end
end

diary off
time_now = datetime;
time_now.Format = 'yyyy_MM_dd HH_mm_ss';

if slack_bool
s.send("Finished processing all files at: " + string(time_now))
end
catch ME
time_now = datetime;
time_now.Format = 'yyyy_MM_dd HH_mm_ss';

if slack_bool
s.send("Encountered error while processing files at: " + string(time_now)...
    + ". " + percent_complete + "% complete.")    
end
rethrow(ME)
end

    end
end