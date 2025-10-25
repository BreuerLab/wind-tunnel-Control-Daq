% Author: Ronan Gissler
% Last updated: October 2023
clear
close all
addpath(genpath('../../Wind Tunnel Test'))
addpath(genpath('.'))

% -----------------------------------------------------------------
% ----The parameter combinations you want to see the data for------
% -----------------------------------------------------------------
% freq_speed_combos = [2, 4; 3, 6; 0, 4; 0, 6];

wing_freq_sel = [0, 2, 4, 6, 8, 10];
wind_speed_sel = [4];
type_sel = ["flexible"];
AoA_sel = [-16:2:16];
sub_strings = [];
slack_bool = false;

% make type list from type and subtraction types to add all
% associated folders to the search
type_list = [type_sel sub_strings];
type_list = strrep(type_list, ' ', '_');

% data_path = "F:\Calimero Data\Calimero 09_23_2025_ascending\";
% Open a file selection dialog and get the file path
data_path = uigetdir("F:\Calimero Data", 'Select a folder') + "\";
if isequal(data_path, "0\")
    error('User canceled folder selection.');
else
    disp(['Selected folder: ', data_path]);
end

dirPath = data_path + "plot data\Calimero\";
if ~exist(dirPath, 'dir')
    mkdir(dirPath);
    fprintf('Directory "%s" created.\n', dirPath);
end
plot_data_path = dirPath;

if slack_bool
s = slackMsg(data_path);
bot = slackProgressBar(data_path);
end

% assuming that all experiment folders are in the same speed
% folder
speed_path = data_path + "Calimero/" + wind_speed_sel + " m.s/";
filePattern = fullfile(speed_path);
dir_names = dir(filePattern);

% path to folders where processed data (.mat files) are stored
processed_data_path = [];
% path to folders where offsets data (.csv files) are stored
offsets_path = [];
% ----------------------------------------------
% INDEX SHIFTED TO 4 ON MAC INSTEAD OF 3 SINCE NEED TO SKIP
% .DSSTORE directory too
% FIX THIS BY CHECKING FOR ., .., AND .DS_STORE DIRECTORIES
% ----------------------------------------------
for i = 3:(length(dir_names))
    cur_name_parts = split(dir_names(i).name);
    cur_name = cur_name_parts{1}; % strip date from name
    if (sum(type_list == cur_name) > 0) % find matches
        filepath = speed_path + dir_names(i).name;
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

if isempty(processed_files)
    error("Oops, no processed files found")
end

% Get a list of all files in the folder with the desired file name pattern.
filePattern = fullfile(offsets_path, '*.mat'); % Change to whatever pattern you need.
offsets_files = [];
for i = 1:length(filePattern)
    offsets_files = [offsets_files; dir(filePattern(i))];
end

norm_bool = true;
shift_bool = false;
regress_bool = false;
sub_drift_bool = true;

% Put all our selected variables into a struct called selected_vars
selected_vars.AoA = AoA_sel;
selected_vars.freq = wing_freq_sel;
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
    get_data_AoA(selected_vars, processed_files, offsets_files, norm_bool, sub_strings, shift_bool, sub_drift_bool, config_idx, num_config);
            
            if slack_bool
            bot.updateProgress(channelID, messageTs, config_idx*(100/8));
            end
            % (k + 2*(j-1) + 4*(i-1))*(100/8))

            time_now = datetime;
            time_now.Format = 'yyyy_MM_dd HH_mm_ss';
            
            name = type_sel + "_" + wind_speed_sel + "m.s.";
            if (norm_bool)
               name = name + "_norm"; 
            end
            % if (shift_bool)
            %     name = name + "_shift"; 
            % end
            if (sub_drift_bool)
                name = name + "_drift"; 
            end
            name = name + "_saved_" + string(time_now);

            if(~isempty(sub_strings))
                name = name + "Sub_" + sub_strings;
            end

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

% figure
% hold on
% plot(AoA_sel(1:7), COP(1:7), Color=[0, 0.4470, 0.7410])
% plot(AoA_sel(11:end), COP(11:end), Color=[0, 0.4470, 0.7410])
% % plot(AoA_sel, COP)
% plot(AoA_sel, 25*ones(1,length(AoA_sel)), 'k--')
% hold off
% xlabel("Angle of Attack (deg)")
% ylabel("Center of Pressure Location (% Chord)")
% title(type_sel + " " + wind_speed_sel + " m/s " + wing_freq_sel + " Hz")

% [NP_pos, NP_mom] = findNP(avg_forces, AoA_sel, true, sub_title);

% [distance_vals_chord, slopes] = findCOMrange(avg_forces, AoA_sel, true);

% plot_forces_AoA(selected_vars, avg_forces, err_forces, names, sub_title, norm_bool, 0, regress_bool, err_bool, shift_bool);
% plot_forces_AoA(selected_vars, avg_forces, err_forces, names, sub_title, norm_bool, 1, regress_bool, err_bool, shift_bool);
% plot_forces_AoA(selected_vars, avg_forces, err_forces, names, sub_title, norm_bool, 3, regress_bool, err_bool, shift_bool);
% plot_forces_AoA(selected_vars, avg_forces, err_forces, names, sub_title, norm_bool, 5, regress_bool, err_bool, shift_bool);

% [avg_forces, err_forces, names, sub_title] = get_data_AoA_combo(freq_speed_combos, selected_vars, processed_data_path, bool);
% 
% plot_forces_AoA_combo(freq_speed_combos, selected_vars, avg_forces, err_forces, names, sub_title, bool.norm, forceIndex);

% pitchMom = [];
% AoA = [];
% freq = [];
% for j=1:3
%     pitchMom = [pitchMom avg_forces(5, :, j, 1, 1)];
%     AoA = [AoA AoA_sel];
%     freq = [freq wing_freq_sel(j)*ones(1,length(AoA_sel))];
% end
% [h,atab,ctab,stats] = aoctool(AoA, pitchMom, freq);

% function name = type2filename(type)
%     if (type == "no wings")
%         name = "full_body";
%     elseif(type == "no wings half body" || type == "half body no wings")
%         name = "half_body";
%     elseif(type == "blue wings")
%         name = "full_wings";
%     elseif(type == "blue wings half body")
%         name = "half_wings";
%     elseif(type == "tail_blue_wings")
%         name = tail_blue_wings';
%     else
%         name = type;
%     end
% end