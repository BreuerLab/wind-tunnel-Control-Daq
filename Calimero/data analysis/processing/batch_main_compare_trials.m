clear
close all

% Change current working directory to the directory where this file is
cd(fileparts(mfilename('fullpath')));
addpath(genpath('../../'))

DELIM = string(filesep);
user = "Z";

% WING DATA
h = helpdlg("Please select the folder containing the batch of processed WING data");
uiwait(h);     % ensure the user reads it before continuing

% Open a file selection dialog and get the file path
if ismac && strcmp(user,"Z") % For Zachary's Mac to directly open file
    search_path = "/Users/zjrosoff/Documents/GitHub/wind-tunnel-Control-Daq/Calimero/data analysis/processing";
else
    search_path = ".";
end

data_path = uigetdir(search_path,...
    "Select the folder containing the batch of processed WING data") + DELIM;
if isequal(data_path, "0\")
    disp('User canceled folder selection.');
else
    disp(['Selected folder: ', data_path]);
end

% BODY DATA TO BE SUBTRACTED
h = helpdlg("Please select the subtraction folder containing the batch of processed BODY data for deletion");
uiwait(h);     % ensure the user reads it before continuing

sub_data_path = uigetdir(search_path, "Select the folder containing the batch of processed BODY data for deletion") + DELIM;
if isequal(sub_data_path, "0\")
    disp('User canceled folder selection.');
else
    disp(['Selected folder: ', sub_data_path]);
end

% Create paths to these large batch folders
wing_batch = dir(data_path);
body_batch = dir(sub_data_path);

for i=4:length(wing_batch)

    wing_path1 = fullfile(data_path, wing_batch(i).name);

    % next folder in wing_batch(i) is wind speed
    d1 = dir(wing_path1);
    d1 = d1([d1.isdir]);                         % keep only directories
    d1 = d1(~ismember({d1.name},{'.','..'}));    % drop . and ..
    wing_path2 = fullfile(wing_path1, d1(1).name); % assume there is exactly one subfolder

    % next folder is a name
    d2 = dir(wing_path2);
    d2 = d2([d2.isdir]);
    d2 = d2(~ismember({d2.name},{'.','..'}));
    final_wing_path = fullfile(wing_path2, d2(1).name) + DELIM; % again assume exactly one subfolder

    % get wing type and wind speed for comparison
    wing_params_path = final_wing_path + DELIM + "raw data" + DELIM + "experiment parameters" + DELIM;
    [wind_speed_sel, type_sel, wing_freq_sel, AoA_sel, wing_amp_sel] = eval_params(wing_params_path);

    for j=4:length(body_batch)
        body_path1 = fullfile(sub_data_path, body_batch(j).name);

        % next folder in body_batch(j) is wind speed
        d3 = dir(body_path1);
        d3 = d3([d3.isdir]);
        d3 = d3(~ismember({d3.name},{'.','..'}));
        body_path2 = fullfile(body_path1, d3(1).name); % assume there is exactly one subfolder

        % next folder is a name
        d4 = dir(body_path2);
        d4 = d4([d4.isdir]);
        d4 = d4(~ismember({d4.name},{'.','..'}));
        compare_body_path = fullfile(body_path2, d4(1).name) + DELIM; % again assume exactly one subfolder

        % get body type and wind speed for comparison
        sub_params_path = compare_body_path + DELIM + "raw data" + DELIM + "experiment parameters" + DELIM;
        [sub_wind_speed_sel, sub_type_sel, sub_wing_freq_sel, sub_AoA_sel, sub_wing_amp_sel] = eval_params(sub_params_path);

        % Only match if same wind speed and same wing_type
        found_match = false; % instantiating var
        TOL = 1e-6;  % building tolerance to compare double
        if  abs(sub_wind_speed_sel - wind_speed_sel) < TOL
            if (strcmp(type_sel, 'default') && strcmp(sub_type_sel, 'bodyDefault'))
                found_match = true;
                final_body_path = compare_body_path;
                break

            elseif (strcmp(type_sel, 'chord_half') && strcmp(sub_type_sel, 'bodyChordhalf'))
                found_match = true;
                final_body_path = compare_body_path;
                break

            elseif (strcmp(type_sel, 'span_half') && strcmp(sub_type_sel, 'bodySpanhalf'))
                found_match = true;
                final_body_path = compare_body_path;
                break
            end
        end
    end

    if found_match
        batch_compare_trials_AoA(final_wing_path, final_body_path, false)
        batch_compare_trials_AoA(final_wing_path, final_body_path, true)
    else
        error('No matching body data found for wing %s', wing_batch(i).name);
    end
end