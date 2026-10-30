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
% Close any processing log left open by a run that was interrupted (Ctrl+C)
% or errored, so this run's output doesn't spill into the old log
diary off

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
[d, time_stamp] = eval_params(params_path);
wind_speed = d.speed;
type = d.wing_type;
amp = d.amp;

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
params_path = [];

raw_data_path = [raw_data_path filepath + DELIM + "raw data" + DELIM + "experiment data" + DELIM];
offsets_path = [offsets_path filepath + DELIM + "raw data" + DELIM + "offsets data" + DELIM];
processed_data_path = [processed_data_path filepath + DELIM + "processed data" + DELIM];
wind_tunnel_path = [wind_tunnel_path filepath + DELIM + "raw data" + DELIM + "wind tunnel data" + DELIM];
params_path = [params_path filepath + DELIM + "raw data" + DELIM + "experiment parameters" + DELIM];

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
% One log per run, named with its start time, rather than appending every
% run to the same file
log_time = datetime('now', 'Format', 'yyyy_MM_dd_HH_mm_ss');
log_file = dirPath + DELIM + wind_speed + "ms_" + type + "_" + string(log_time) + ".txt";
diary(log_file)
disp("Processing log started " + string(log_time))
disp("Data folder: " + filepath)
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

% Get some general parameters from the params file
[d, latest_timestamp] = eval_params(params_path);
params.freq_vals = d.freq_vals;
% DAQ sampling rate saved by run_experiment / benchtop_test (used for
% filtering and trimming in process_trial)
if isfield(d, 'rate')
    params.rate = d.rate;
    disp("DAQ rate from experiment params: " + params.rate + " Hz")
end

% Processing timers: per trial and for the whole run
fmt_dur = @(sec) string(duration(0, 0, sec, 'Format', 'hh:mm:ss.SSS'));
is_trial = ~contains(string({exp_files.name}), "speedCheck");
num_trials = nnz(is_trial);
trial_times = nan(1, num_trials);
trial_count = 0;
total_timer = tic;
disp("Processing " + num_trials + " trials (started " + string(time_now) + ")")

% Grab each file and process the data from that file, storing the results
for k = 1 : length(exp_files)
    baseFileName = convertCharsToStrings(exp_files(k).name);

    if is_trial(k)
    trial_count = trial_count + 1;
    disp("Reading from: ")
    disp(baseFileName)

    trial_timer = tic;
    process_trial(baseFileName, raw_data_path, offsets_path, processed_data_path, wind_tunnel_path, params);
    trial_times(trial_count) = toc(trial_timer);

    elapsed = toc(total_timer);
    mean_trial = mean(trial_times, 'omitnan');
    remaining = mean_trial * (num_trials - trial_count);
    fprintf("Trial %d/%d processed in %s | elapsed %s | est. remaining %s\n",...
        trial_count, num_trials, fmt_dur(trial_times(trial_count)),...
        fmt_dur(elapsed), fmt_dur(remaining));
    end

    percent_complete = round((k / length(exp_files)) * 100, 2);
    disp(percent_complete + "% complete")
            
    if slack_bool
    bot.updateProgress(channelID, messageTs, percent_complete);
    end
end

total_time = toc(total_timer);
disp("---------------------------------------------------------------")
fprintf("Processed %d trials in %s total\n", trial_count, fmt_dur(total_time));
if trial_count > 0
    fprintf("Per trial: mean %s | min %s | max %s\n",...
        fmt_dur(mean(trial_times, 'omitnan')),...
        fmt_dur(min(trial_times)), fmt_dur(max(trial_times)));
end
disp("---------------------------------------------------------------")

diary off
clean_log(log_file)
time_now = datetime;
time_now.Format = 'yyyy_MM_dd HH_mm_ss';

if slack_bool
s.send("Finished processing all files at: " + string(time_now) +...
    " (" + trial_count + " trials in " + fmt_dur(total_time) + ")")
end
catch ME
% Record the error in the log, then close the log before rethrowing
disp(getReport(ME, 'extended', 'hyperlinks', 'off'))
disp(percent_complete + "% complete when the error occurred")
diary off
clean_log(log_file)
time_now = datetime;
time_now.Format = 'yyyy_MM_dd HH_mm_ss';

if slack_bool
s.send("Encountered error while processing files at: " + string(time_now)...
    + ". " + percent_complete + "% complete.")    
end
rethrow(ME)
end

% Strip the MATLAB hyperlink markup (<a href=...>) that warnings and errors
% write into the diary, so the log reads as plain text
function clean_log(log_file)
    try
        txt = fileread(log_file);
        txt = regexprep(txt, '<a\s[^>]*>|</a>', '');
        fid = fopen(log_file, 'w', 'n', 'UTF-8');
        fprintf(fid, '%s', txt);
        fclose(fid);
    catch
        warning("Could not clean up log file " + log_file)
    end
end
