% Author: Ronan Gissler
% Last updated: October 2023

% Note: Your current working directory in Matlab must include this file
% (i.e. you must be in the process trial folder)
clear
close all
addpath(genpath('../Wind Tunnel Test'))
addpath(genpath('.'))

AFAM_bool = false;
[f, tiles] = compare_AoA_fig(AFAM_bool);

% Get force calibration file
calibration_filepath = "../../DAQ/Calibration Files/Mini40/FT52907.cal"; 
cal_matrix = obtain_cal(calibration_filepath);

wing_freq_sel = [0, 90, 120, 150, 180];

wind_speeds = [4];
types = ["flexible"]; % needs to match folder name only
data_path = "F:\Calimero Data\Calimero_07_12_to_07_14_Tests\";
% ADD PATH WHERE DATA SHOULD GET DUMPED

for n = 1:length(wind_speeds)
    for m = 1:length(types)

wind_speed_sel = wind_speeds(n);
type = types(m);

% set up Slack messenger objects
s = slackMsg(data_path);
bot = slackProgressBar(data_path);

speed_path = data_path + wind_speed_sel + " m.s/";
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
    end
end

% Get a list of all files in the folder with the desired file name pattern.
filePattern = fullfile(raw_data_path, '*.mat'); % Change to whatever pattern you need.
exp_files = [];
for i = 1:length(filePattern)
    exp_files = [exp_files; dir(filePattern(i))];
end

% Record log of outputs while processing data
diary(data_path + "processing logs/" + wind_speed_sel + "ms_" + type + ".txt")
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

    % process_trial(baseFileName, raw_data_path, offsets_path, processed_data_path, wind_tunnel_path);
    
    [case_name, time_stamp, type, wing_freq, AoA, wind_speed] = parse_filename(baseFileName);

    % find matching offsets file
    offsets_file = findFileMatchingCase(offsets_path, case_name);
    load(offsets_path + offsets_file); % load in results var
    
    % Get raw data from file
    load(raw_data_path + baseFileName); % load in results var
    
    [time_data, force_data, voltAdj, curAdj, theta, Z] = process_data(results, offsets, cal_matrix);

    cur_ind = find(wing_freq == wing_freq_sel);

    process_and_plot(force_data, cur_ind, AoA, tiles, wing_freq_sel)

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

    end
end