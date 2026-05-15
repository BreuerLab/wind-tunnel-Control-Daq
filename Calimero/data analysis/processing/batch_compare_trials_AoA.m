function batch_compare_trials_AoA(data_path, sub_data_path, sub_bool, shift_bool, shift_type)

% Author: Ronan Gissler / Zachary Rosoff
% Last updated: March 2026

slack_bool = false;
user = "Z"; % "Z": Zachary or "R": Ronan

if ismac
    DELIM = "/";
elseif ispc
    DELIM = "\";
end

if ispc && strcmp(user,"Z") % For Zachary's PC
    slack_path = "R:" + DELIM + "ENG_Breuer_Shared" + DELIM + "group" +...
                 DELIM + "Zachary" + DELIM;
elseif ismac && strcmp(user,"Z")
    slack_path = "/Volumes/LRSResearch/ENG_Breuer_Shared/group/Zachary";
elseif ispc && strcmp(user,"R")
    slack_path = "R:" + DELIM + "ENG_Breuer_Shared" + DELIM + "group" +...
                 DELIM + "Ronan" + DELIM;
end

if sub_bool
    sub_params_path = sub_data_path + "raw data" + DELIM + "experiment parameters" + DELIM;

    % Might not need eval_params, as we are making sub_strings the
    % clean_body_type from main, as this will allow for subtraction matching
    [sub_wind_speed_sel, sub_type_sel, sub_wing_freq_sel, sub_AoA_sel, sub_wing_amp_sel] = eval_params(sub_params_path);
    sub_strings = sub_type_sel;
else
    sub_strings = "";
end

params_path = data_path + "raw data" + DELIM + "experiment parameters" + DELIM;

[wind_speed_sel, type_sel, wing_freq_sel, AoA_sel, wing_amp_sel] = eval_params(params_path);
AoA_sel = unique(AoA_sel);

path_parts = split(extractBefore(data_path, "m.s"), DELIM);
root_path = strjoin(path_parts(1:end-1), DELIM);

% Make plot data folder
dirPath = root_path + DELIM + "plot data" + DELIM + "Calimero" + DELIM;
if ~exist(dirPath, 'dir')
    mkdir(dirPath);
    fprintf('Directory "%s" created.\n', dirPath);
end
plot_data_path = dirPath;

if slack_bool
s = slackMsg(slack_path);
bot = slackProgressBar(slack_path);
end

% I am separating wing and body data so that it is handled separately
% (quicker). Offsets is still one folder which is fine.

% path to folders where processed data (.mat files) are stored
processed_data_path = [];
% path to folders where processed body data (.mat files) are stored
processed_body_path = [];
% path to folders where offsets data (.mat files) are stored
offsets_path = [];

processed_data_path = [processed_data_path data_path + "processed data" + DELIM];

% offsets include both wing and body data (if sub_bool)
offsets_path = [offsets_path data_path + "raw data" + DELIM + "offsets data" + DELIM];
if sub_bool
    offsets_path = [offsets_path sub_data_path + "raw data" + DELIM + "offsets data" + DELIM];
end

% Get a list of all 'processed data' files
filePattern = fullfile(processed_data_path, '*.mat');
processed_files = [];
for i = 1:length(filePattern)
    processed_files = [processed_files; dir(filePattern(i))];
end

% Get a list of all 'offset data' files
filePattern = fullfile(offsets_path, '*.mat');
offsets_files = [];
for i = 1:length(filePattern)
    offsets_files = [offsets_files; dir(filePattern(i))];
end

if isempty(processed_data_path)
    error("Oops, no processed data path found")
end

if sub_bool
    processed_body_path = sub_data_path + "processed data" + DELIM;

    % Get a list of all 'processed body' files
    filePattern = fullfile(processed_body_path, '*.mat');
    processed_body_files = [];
    for i = 1:length(filePattern)
        processed_body_files = [processed_body_files; dir(filePattern(i))];
    end
else
    processed_body_files = [];
end

% shift_bool and sub_bool are defined by function
norm_bool = true;
regress_bool = false;
sub_drift_bool = true;

% Put all our selected variables into a struct called selected_vars
selected_vars.AoA = AoA_sel;
selected_vars.freq = wing_freq_sel;
selected_vars.amp = wing_amp_sel;
selected_vars.wind = wind_speed_sel;
selected_vars.type = type_sel;

% Slack message
time_now = datetime;
time_now.Format = 'yyyy_MM_dd HH_mm_ss';

if slack_bool
s.send("Started making plots at: " + string(time_now))

% Post the initial message
[channelID, messageTs] = bot.makeBar();
end

num_config = 2*2;
for i = 1:2
    % for j = 1:2
        for k = 1:2
            config_idx = (k + 2*(i-1));

            [avg_forces, avg_up_forces, avg_down_forces, err_forces, ...
             err_up_forces, err_down_forces, names, sub_title, norm_factors, drift_vals, offsets_before_vals, offsets_after_vals] = ...
    batch_get_data_AoA(selected_vars, processed_files, processed_body_files, offsets_files, norm_bool, shift_bool, sub_drift_bool, ...
                        config_idx, num_config, sub_bool, sub_strings, shift_type);
            
            if slack_bool
            bot.updateProgress(channelID, messageTs, config_idx*(100/8));
            end

            time_now = datetime;
            time_now.Format = 'yyyy_MM_dd HH_mm_ss';
            
            % I want it to say shift or sub right after type_sel for
            % plotting GUI
            if sub_bool && shift_bool
                name = type_sel + "_sub_shift_" + wing_amp_sel + "_" + wind_speed_sel + "m.s.";
            elseif sub_bool
                name = type_sel + "_sub_" + wing_amp_sel + "_" + wind_speed_sel + "m.s.";
            elseif shift_bool
                name = type_sel + "_shift_" + wing_amp_sel + "_" + wind_speed_sel + "m.s.";
            else % if no shift or sub, this is the default
                name = type_sel + "_" + wing_amp_sel + "_" + wind_speed_sel + "m.s.";
            end

            % these go at the very end for plotting GUI
            if (norm_bool)
               name = name + "_norm"; 
            end
            if (sub_drift_bool)
                name = name + "_drift"; 
            end
            
            % give it a time stamp
            name = name + "_saved_" + string(time_now);
        
            save(plot_data_path + name + ".mat","avg_forces", "avg_up_forces", "avg_down_forces",...
                "err_forces", "err_up_forces", "err_down_forces", "norm_factors", "names", "drift_vals", "offsets_before_vals", "offsets_after_vals")

            norm_bool = ~norm_bool;
        end
        % shift_bool = ~shift_bool;
    % end
    sub_drift_bool = ~sub_drift_bool;
end

% Slack message
time_now = datetime;
time_now.Format = 'yyyy_MM_dd HH_mm_ss';

if slack_bool
s.send("Finished making plots at: " + string(time_now))
end