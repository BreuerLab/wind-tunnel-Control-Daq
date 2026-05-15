% NOTE: RUN AFTER batch_main_process_trials.m ON THAT OUTPUTTED FOLDER

clear
clc
close all
clear batch_get_data_AoA % must clear the cache with new set of wing files (see getBody function in batch_get_data_AoA.m)

% IF SUBTRACTING, MAKE subtraction_boolean = true
subtraction_boolean = false;

% Options: ["center_to_LE", "center_to_quartchord"]
% Will not be called unless shift_bool in batch_compare_trials_AoA is true
shift_type = "center_to_LE";

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

% Gather body data to be subtracted (will now be in separate folders,
% instead of combined folder like previous version)
if subtraction_boolean
    h = helpdlg("Please select the subtraction folder containing the batch of processed BODY data for deletion");
    uiwait(h);     % ensure the user reads it before continuing

    sub_data_path = uigetdir(search_path, "Select the folder containing the batch of processed BODY data for deletion") + DELIM;
    if isequal(sub_data_path, "0\")
        disp('User canceled folder selection.');
    else
        disp(['Selected folder: ', sub_data_path]);
    end
end

% Make log file in wing data folder
log_name = "Processing_Log_" + string(datetime('now','Format','yyyyMMdd_HHmm')) + ".txt";
fid = fopen(fullfile(data_path, log_name), 'w'); % w means write -> creates or overwrites existing file
cleanupObj = onCleanup(@() fclose(fid)); % if I quit this function, file will still close

% start printing messages
fprintf(fid, '--- BATCH PROCESSING LOG ---\n'); % print to fid path, \n is new line
fprintf(fid, 'Date: %s\n', string(datetime));
fprintf(fid, 'Subtraction Enabled: %d\n', subtraction_boolean);
fprintf(fid, 'Shift Type: %s\n\n', shift_type);

% Create paths to the large batch folders

% first, create wing_batch
wing_batch = dir(data_path);

% filter out any other files (not dir) and then ., .., store in batch cases
is_valid_dir_wing = [wing_batch.isdir] & ~startsWith({wing_batch.name}, ".");
wing_batch = wing_batch(is_valid_dir_wing);

% now create body_batch
if subtraction_boolean
    body_batch = dir(sub_data_path);

    % same filter for body
    is_valid_dir_body = [body_batch.isdir] & ~startsWith({body_batch.name}, ".");
    body_batch = body_batch(is_valid_dir_body);
else
    body_batch = []; % no need for body_batch
end

% counting number of errors and successes to be printed later
error_count = 0;
success_count = 0;
tic; % let's time it

for i=1:length(wing_batch)

    try
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

        found_match = false; % instantiating var

        if subtraction_boolean
            for j=1:length(body_batch)
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
                
                TOL = 1e-6;  % building tolerance to compare double
                if  abs(sub_wind_speed_sel - wind_speed_sel) < TOL
                    if (((strcmpi(type_sel, 'default') || strcmpi(type_sel, 'bodyDefault'))) && strcmpi(sub_type_sel, 'bodyDefault'))
                        found_match = true;
                        break

                    elseif (((strcmpi(type_sel, 'chord_half') || strcmpi(type_sel, 'bodyChordhalf'))) && strcmpi(sub_type_sel, 'bodyChordhalf'))
                        found_match = true;
                        break

                    elseif (((strcmpi(type_sel, 'span_half') || strcmpi(type_sel, 'bodySpanhalf'))) && strcmpi(sub_type_sel, 'bodySpanhalf'))
                        found_match = true;
                        break
                    end
                end
            end
        else
            found_match = true; % because no match is needed anyway
        end


        if found_match
            fprintf(fid, 'Wing: %s\n', wing_batch(i).name); % wing name

            if subtraction_boolean
                final_body_path = compare_body_path;
                fprintf(fid, '  -> MATCHED BODY: %s\n', body_batch(j).name); % body name

                batch_compare_trials_AoA(final_wing_path, final_body_path, true, true, shift_type) % sub and shift
                batch_compare_trials_AoA(final_wing_path, final_body_path, true, false, shift_type) % sub
                batch_compare_trials_AoA(final_wing_path, final_body_path, false, true, shift_type) % shift
                batch_compare_trials_AoA(final_wing_path, final_body_path, false, false, shift_type) % none

            else
                final_body_path = "";

                batch_compare_trials_AoA(final_wing_path, final_body_path, false, true, shift_type) % shift
                batch_compare_trials_AoA(final_wing_path, final_body_path, false, false, shift_type) % no corrections
            end

            fprintf(fid, '  -> STATUS: SUCCESS\n\n');
            success_count = success_count + 1;

            clear batch_get_data_AoA % must clear the cache with new set of wing files (see getBody function in batch_get_data_AoA.m)

        else
            fprintf(fid, 'WING: %s\n  -> STATUS: ERROR (No matching body data found)\n\n', wing_batch(i).name);
            error('No matching body data found for wing %s', wing_batch(i).name);
            % now it will jump to catch ME
        end

    catch ME
        % If ANYTHING fails inside the 'try' block, MATLAB jumps here
        fprintf(fid, '  -> STATUS: FAILED\n');
        fprintf(fid, '  -> ERROR MESSAGE: %s\n\n', ME.message);

        % Display a warning in the command window so you know it skipped one
        warning('Error processing %s: %s', wing_batch(i).name, ME.message);
        error_count = error_count + 1;
        continue
    end
end

total_time = toc;

% write summary messages
fprintf(fid, "--- BATCH COMPLETE ---\n");
fprintf(fid, "Total Successes:%d\n", success_count);
fprintf(fid, "Total Errors:%d\n", error_count);
fprintf(fid, "Time to complete: %d minutes\n", round(total_time/60)); % in minutes

% Close the log file when the script finishes
fclose(fid); 

% display
disp("--- BATCH COMPLETE ---");
disp("Log saved to: " + log_name + " in " + data_path);