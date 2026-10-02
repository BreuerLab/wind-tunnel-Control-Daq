% Author: Ronan Gissler
% Last updated: January 2026

% TO ADD:
% BATCH PROCESSING OF MULTIPLE WIND SPEEDS OR TYPES (nested for loops)

% ADD CHECK IF USER DECIDES TO RUN THIS ON DATA THAT'S ALREADY BEEN
% ORGANIZED

% Note: Your current working directory in Matlab must include this file
% (i.e. you must be in the process trial folder)
clear
close all

% Change current working directory to the directory where this file is
cd(fileparts(mfilename('fullpath')));
addpath(genpath('../../'))

DELIM = string(filesep);

% Data stored in Dataset Name -> speed -> type + date

slack_bool = false;
user = "R"; % "Z": Zachary or "R": Ronan

% separating this for Windows vs Mac
if ispc && strcmp(user,"Z") % For Zachary's PC
    slack_path = "R:" + DELIM + "ENG_Breuer_Shared" + DELIM + "group" +...
                 DELIM + "Zachary" + DELIM;
elseif ismac && strcmp(user,"Z")
    slack_path = "/Volumes/LRSResearch/ENG_Breuer_Shared/group/Zachary/";
elseif ispc && strcmp(user,"R")
    slack_path = "R:" + DELIM + "ENG_Breuer_Shared" + DELIM + "group" +...
                 DELIM + "Ronan" + DELIM;
end

% data_path = "F:\Calimero Data\Calimero 09_23_2025_ascending\Calimero\";

h = helpdlg("Please select the 'data' folder you'd like to process.");
uiwait(h);     % ensure the user reads it before continuing

% Open a file selection dialog and get the file path
if strcmp(DELIM, "\")
    data_path = uigetdir(".", "Select the 'data' folder") + DELIM;
    if isequal(data_path, 0)
        disp('User canceled folder selection.');
    else
        disp(['Selected folder: ', data_path]);
    end
else  % For Zachary's Mac to directly open file
    data_path = uigetdir("/Users/zjrosoff/Documents/GitHub/wind-tunnel-Control-Daq/Calimero/data analysis/processing", "Select the 'data' folder") + DELIM;
    if isequal(data_path, 0)
        disp('User canceled folder selection.');
    else
        disp(['Selected folder: ', data_path]);
    end
end

contents = dir(data_path);

addFolders = false;
for i = 3:length(contents)
    name = contents(i).name;
    % If folder contains experiment data and other folders, but hasn't
    % already been put in a folder named raw data
    if strcmp(name, "experiment data") && ~contains(data_path, "raw data")
        addFolders = true;
    end
end

if addFolders
params_path = data_path + "experiment parameters" + DELIM;

% On July 7th removed freq_vals and AoA_vals here since not relevant for
% benchtop processing and seemingly not used for normal processing routine
[wind_speed, type, amp, time_stamp] = eval_params(params_path);

oldFolder = data_path;
raw_appendage = DELIM + "raw data";
newFolder = data_path + raw_appendage;
% Does 'raw data' folder already exist?
if ~isfolder(newFolder)
    % make raw_data folder
    mkdir(newFolder)
    % move data into raw_data folder
    movefile(oldFolder + DELIM + "*", newFolder)
    disp("raw data folder added")
else
    disp("raw data folder found")
end

parts = split(time_stamp, "_");
date = strjoin(parts(1:3), "_");

% Put 'raw data' in type + date folder
oldFolder = data_path;
type_appendage = DELIM + type + "_" + date;
newFolder = data_path + type_appendage;
% Does type + date folder already exist?
if ~isfolder(newFolder)
    % make type + date folder
    mkdir(newFolder)
    % move data into type + date folder
    movefile(oldFolder + DELIM + "*", newFolder)
    disp("type_date folder added")
else
    disp("type_date folder found")
end

% Put type + date folder in speed folder
oldFolder = data_path;
speed_appendage = DELIM + wind_speed + " m.s";
newFolder = data_path + speed_appendage;
% Does 'raw data' folder already exist?
if ~isfolder(newFolder)
    % make raw_data folder
    mkdir(newFolder)
    % move data into raw_data folder
    movefile(oldFolder + DELIM + "*", newFolder)
    disp("speed folder added")
else
    disp("speed folder found")
end
    filepath = data_path + speed_appendage + type_appendage;
else
    disp("Skipped folder organization")

    filepath = extractBefore(data_path, "raw data");
    s = extractBefore(filepath, " m.s");
    s_parts = split(s, DELIM);
    wind_speed = str2num(s_parts(end));

    s = erase(extractAfter(filepath, " m.s"), DELIM);
    s_parts = split(s, "_");
    idx = -1;
    for j = 1:length(s_parts)
        if isnan(str2double(s_parts(j))) % if is letters, not numbers
            idx = j;
        end
    end
    type = strjoin(s_parts(1:idx), "_");
end

if (slack_bool)
% set up Slack messenger objects
s = slackMsg(slack_path);
bot = slackProgressBar(slack_path);
end

% path to folders where raw data (.csv files) are stored
raw_data_path = [];
offsets_path = [];
processed_data_path = [];
wind_tunnel_path = [];

raw_data_path = [raw_data_path filepath + DELIM + "raw data" + DELIM + "experiment data" + DELIM];
offsets_path = [offsets_path filepath + DELIM + "raw data" + DELIM + "offsets data" + DELIM];
processed_data_path = [processed_data_path filepath + DELIM + "processed data" + DELIM];
wind_tunnel_path = [wind_tunnel_path filepath + DELIM + "raw data" + DELIM + "wind tunnel data" + DELIM];

if isempty(raw_data_path)
    error("Oops, no data paths made")
end

% Get a list of all files in the folder with the desired file name pattern.
filePattern = fullfile(raw_data_path, '*.mat'); % Change to whatever pattern you need.
exp_files = [];
for i = 1:length(filePattern)
    exp_files = [exp_files; dir(filePattern(i))];
end

dirPath = filepath + DELIM + "processed data";
if ~exist(dirPath, 'dir')
    mkdir(dirPath);
    fprintf('Directory "%s" created.\n', dirPath);
end

% Record log of outputs while processing data
dirPath = filepath + DELIM + "processing logs";
if ~exist(dirPath, 'dir')
    mkdir(dirPath);
    fprintf('Directory "%s" created.\n', dirPath);
end
diary(dirPath + DELIM + wind_speed + "ms_" + type + ".txt")
percent_complete = 0;
try
time_now = datetime;
time_now.Format = 'yyyy_MM_dd HH_mm_ss';

if slack_bool
    s.send("Started processing files at: " + string(time_now))
    
    % Post the initial message
    [channelID, messageTs] = bot.makeBar();
end

disp("---------------------------------------------------------------")
disp("---------------------------------------------------------------")

% Grab each file and process the data from that file, storing the results
for k = 1 : length(exp_files)
    baseFileName = convertCharsToStrings(exp_files(k).name);

    if ~contains(baseFileName, "speedCheck")
    disp("Reading from: ")
    disp(baseFileName)

    process_trial(baseFileName, raw_data_path, offsets_path, processed_data_path, wind_tunnel_path, type);
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