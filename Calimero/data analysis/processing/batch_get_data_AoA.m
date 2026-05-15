function [avg_forces, avg_up_forces, avg_down_forces, err_forces, err_up_forces,...
    err_down_forces, names, sub_title, norm_factors_arr, drift_vals, offsets_before_vals, offsets_after_vals] = ...
    batch_get_data_AoA(selected_vars, processed_files, processed_body_files, offsets_files, ...,
    nondimensional, shift_bool, sub_drift, config_idx, num_config, sub_bool, sub_strings, shift_type)

% MAKE SURE TO CLEAR getBody IN MAIN SO THAT CACHE IS RESTARTED FOR
% DIFFERENT WING/BODY CONFIGURATIONS

numAxes = 8;
n = 180; % number of wingbeats for standard error

if sub_bool
    body_subtraction = true;
else
    body_subtraction = false;
end

AoA_sel = selected_vars.AoA;
wing_freq_sel = selected_vars.freq;
wing_amp_sel = selected_vars.amp;
wind_speed_sel = selected_vars.wind;
type_sel = selected_vars.type;
type_sel = strjoin(split(type_sel, "_"));

% produces array of same size as wing_freq_sel but with the
% frequency of each value in its place, ex:
% [0, 2, 4, 2, 4] -> [1, 2, 2, 2, 2]
wing_freq_sel_count = wing_freq_sel;
for i = 1:length(wing_freq_sel)
    wing_freq_sel_count(i) = sum(wing_freq_sel == wing_freq_sel(i));
end

% Initialize variables
avg_forces = zeros(numAxes, length(AoA_sel), length(wing_freq_sel), length(wing_amp_sel), length(wind_speed_sel), length(type_sel));
avg_up_forces = zeros(numAxes, length(AoA_sel), length(wing_freq_sel), length(wing_amp_sel), length(wind_speed_sel), length(type_sel));
avg_down_forces = zeros(numAxes, length(AoA_sel), length(wing_freq_sel), length(wing_amp_sel), length(wind_speed_sel), length(type_sel));
% avg_forces_body = zeros(6, length(AoA_sel), length(wing_freq_sel), length(wind_speed_sel));
err_forces = zeros(numAxes, length(AoA_sel), length(wing_freq_sel), length(wing_amp_sel), length(wind_speed_sel), length(type_sel));
err_up_forces = zeros(numAxes, length(AoA_sel), length(wing_freq_sel), length(wing_amp_sel), length(wind_speed_sel), length(type_sel));
err_down_forces = zeros(numAxes, length(AoA_sel), length(wing_freq_sel), length(wing_amp_sel), length(wind_speed_sel), length(type_sel));
cases_final = strings(length(AoA_sel), length(wing_freq_sel), length(wing_amp_sel), length(wind_speed_sel), length(type_sel));
names = strings(length(wing_freq_sel), length(wing_amp_sel), length(wind_speed_sel), length(type_sel));
norm_factors_arr = zeros(2, length(AoA_sel), length(wing_freq_sel), length(wing_amp_sel), length(wind_speed_sel));
drift_vals = zeros(numAxes, length(AoA_sel), length(wing_freq_sel)+1, length(wing_amp_sel), length(wind_speed_sel), length(type_sel));
offsets_before_vals = zeros(numAxes, length(AoA_sel), length(wing_freq_sel)+1, length(wing_amp_sel), length(wind_speed_sel), length(type_sel));
offsets_after_vals = zeros(numAxes, length(AoA_sel), length(wing_freq_sel)+1, length(wing_amp_sel), length(wind_speed_sel), length(type_sel));
% really only the windspeed matters here but let's include all
% the variables include the normalization routine changes in the
% future

sub_title = "";

% Go through each file, grab its data, take the mean over all results to
% produce a "dot" (i.e. a single point value) for each force and moment
for i = 1 : length(processed_files)
    baseFileName = convertCharsToStrings(processed_files(i).name);
    baseFolder = convertCharsToStrings(processed_files(i).folder);
    [case_name, time_stamp, type, wing_freq, AoA, wind_speed, amp, file_type] = parse_filename(baseFileName);

    if strcmp(type, "body")
        type = type_sel;
    end

    type = convertCharsToStrings(type);

    %     pitch = deg2rad(-AoA);
    %     yaw = deg2rad(205);
    %     dcm_F = angle2dcm(yaw, pitch, 0,'ZYX');
    %     dcm_M = angle2dcm(yaw, 0, 0, 'ZYX');

    if (ismember(wing_freq, wing_freq_sel) ...
            && ismember(AoA, AoA_sel) ...
            && ismember(amp, wing_amp_sel) ...
            && ismember(wind_speed, wind_speed_sel) ...
            && ismember(type, type_sel))

        wing_freq_ind = wing_freq_sel == wing_freq;
        % wing_freq_ind = find(wing_freq_sel == wing_freq);

        modFileName = baseFileName;

        % Check if any other files were recorded for the same set
        % of parameters but at a different time
        count = 0;
        timestamps_str = {};
        timestamps_val = [];
        for m = 1 : length(processed_files)
            baseFileName = processed_files(m).name;
            if (contains(baseFileName, case_name))
                count = count + 1;
                time_val = timeStr2num(time_stamp);

                timestamps_str = [timestamps_str; time_stamp];
                timestamps_val = [timestamps_val; time_val];
            end
        end

        [B,I] = sort(timestamps_val);
        timestamps_str_sorted = timestamps_str(I);
        cur_time_index = find(timestamps_str_sorted == time_stamp);

        num_repeat_freqs = wing_freq_sel_count(find(wing_freq_sel == wing_freq, 1, 'first'));

        disp("Obtaining data for " + type + " phi=" + 2*amp + " " + wing_freq + " Hz " + wind_speed + " m/s "  + AoA + " deg trial")
        if (count > 1) % counted multiple repeats in datastream
            if (num_repeat_freqs == count)
                % num_repeat_freqs > 1 && cur_time_index > length(timestamps_str) - num_repeat_freqs
                wing_freq_ind = find(wing_freq_sel == wing_freq);
                wing_freq_ind = wing_freq_ind(cur_time_index);

                disp("Found " + count + " files, timestamps: ")
                disp(timestamps_str)
                disp("    Using current timestamp: " + time_stamp)
                disp(" ")
            else
                disp("Extra files found and current file too old, moving on...")
                continue
                % wing_freq_ind = wing_freq_sel == wing_freq;
                %
                % modFileName = case_name + string(timestamps_str_sorted(end)) + ".mat";
                %
                % disp("Found " + count + " files, timestamps: " + timestamps_str)
                % disp("    Using last timestamp: " + timestamps_str_sorted(end))
                % disp(" ")
            end
        end

        load_AoA_data(baseFolder, modFileName); % loads norm_factors
        %load(baseFolder + "/" + modFileName);

        % if (wing_freq == 0)
        data = filtered_data; % loads data and cycle_avg_forces
        % up_forces = zeros(size(filtered_data));
        % down_forces = zeros(size(filtered_data));
        % else
        %     data = cycle_avg_forces;
        %     % up_forces = upstroke_avg_forces;
        %     % down_forces = downstroke_avg_forces;
        % end
        % up_forces = zeros(size(data));
        % down_forces = zeros(size(data));
        % Maybe need to add squeeze(cycle_avg_forces) above

        % get offsets from before and after trial
        [drift, offsets_before, offsets_after] = get_drift(modFileName, offsets_files, wing_freq_sel);
        drift_vals(:, AoA_sel == AoA, wing_freq_ind, wing_amp_sel == amp, wind_speed_sel == wind_speed, type_sel == type)...
            = drift;
        offsets_before_vals(:, AoA_sel == AoA, wing_freq_ind, wing_amp_sel == amp, wind_speed_sel == wind_speed, type_sel == type)...
            = offsets_before;
        offsets_after_vals(:, AoA_sel == AoA, wing_freq_ind, wing_amp_sel == amp, wind_speed_sel == wind_speed, type_sel == type)...
            = offsets_after;

        % Get total drift over the course of all freq at an AoA
        if wing_freq == wing_freq_sel(end)
            [drift, offsets_before, offsets_after] = get_total_drift(modFileName, offsets_files);
            drift_vals(:, AoA_sel == AoA, end, wing_amp_sel == amp, wind_speed_sel == wind_speed, type_sel == type)...
                = drift;
            offsets_before_vals(:, AoA_sel == AoA, end, wing_amp_sel == amp, wind_speed_sel == wind_speed, type_sel == type)...
                = offsets_before;
            offsets_after_vals(:, AoA_sel == AoA, end, wing_amp_sel == amp, wind_speed_sel == wind_speed, type_sel == type)...
                = offsets_after;
        end

        % must applyBools to data and cycle_avg_forces
        data = applyBools(data, sub_drift, drift, shift_bool, AoA, nondimensional, norm_factors, type_sel, shift_type);
        if wing_freq > 0 
            cycle_avg_forces = applyBools(cycle_avg_forces, sub_drift, drift, shift_bool, AoA, nondimensional, norm_factors, type_sel, shift_type);
        end
        % up_forces = applyBools(up_forces, sub_drift, modFileName, offsets_files, shift_bool, AoA, nondimensional, norm_factors);
        % down_forces = applyBools(down_forces, sub_drift, modFileName, offsets_files, shift_bool, AoA, nondimensional, norm_factors);

        norm_factors_arr(:, AoA_sel == AoA, wing_freq_ind, wing_amp_sel == amp, wind_speed_sel == wind_speed) = norm_factors;

        sub_string = "";
        sub_term = zeros(1,numAxes);
        if (body_subtraction)
            forces_body_list = zeros(length(sub_strings),numAxes);
            sub_bools = ones(length(sub_strings));
            for j = 1:length(sub_strings)
                sub_string = sub_strings(j);
                % handle case with addition rather than subtraction
                case_parts = strtrim(split(sub_string));
                if (case_parts(1) == "-")
                    sub_bools(j) = false;
                    sub_string = strjoin(case_parts(2:end));
                end
                [forces_body, cycle_avg_body_forces] = getBody(wing_freq, AoA, wind_speed, amp, nondimensional, ...
                    processed_body_files, sub_string, sub_bools(j), shift_bool, sub_drift, type_sel, norm_factors, shift_type, numAxes, offsets_files); % offsets contains wing and body

                forces_body_list(j,:) = mean(forces_body,2); % returns average of 8 rows (avg lift, drag, pitch, etc.)

                if (sub_bools(j) == true)
                    sub_term = sub_term + forces_body_list(j,:);
                else
                    sub_term = sub_term - forces_body_list(j,:);
                end
            end
        else
            forces_body = zeros(numAxes, 1);
            cycle_avg_body_forces = zeros(numAxes, 1);
        end


        for k = 1:numAxes % this is where subtraction and standard error calculations happen!

            % define std_wing because depends if frequency is zero
            if wing_freq == 0 % check std deviation of wing
                std_wing = std(data(k, :));
                std_body = std(forces_body(k, :)); % This is the data that has already done applyBool.m (good!)
            else % must find standard deviation of same points in wingbeat, otherwise oscillations cause huge std
                std_wing = std(cycle_avg_forces(k, :));
                std_body = std(cycle_avg_body_forces(k, :));
            end

            if (body_subtraction)

                avg_forces(k, AoA_sel == AoA, wing_freq_ind, wing_amp_sel == amp, wind_speed_sel == wind_speed, type_sel == type)...
                    = mean(data(k,:)) - sub_term(k);

                % standard error of a sum = sqrt(var_wing+var_body)/sqrt(num_trials)
                err_forces(k, AoA_sel == AoA, wing_freq_ind, wing_amp_sel == amp, wind_speed_sel == wind_speed, type_sel == type)...
                    = sqrt(std_wing^2+std_body^2)/sqrt(n);

            else
                avg_forces(k, AoA_sel == AoA, wing_freq_ind, wing_amp_sel == amp, wind_speed_sel == wind_speed, type_sel == type)...
                    = mean(data(k,:));

                % err_forces from just the wing
                err_forces(k, AoA_sel == AoA, wing_freq_ind, wing_amp_sel == amp, wind_speed_sel == wind_speed, type_sel == type)...
                    = std_wing/sqrt(n);
            end
        end

        cases_final(AoA_sel == AoA, wing_freq_ind, wing_amp_sel == amp, wind_speed_sel == wind_speed, type_sel == type) = modFileName;
        [names, sub_title] = get_labels(names, selected_vars, wing_freq_ind, wing_freq, wind_speed, type, Re, St, sub_string, nondimensional, body_subtraction);
    end
    percent_done = round((i / length(processed_files))*100, 2);
    disp(percent_done + "% Done (" + config_idx + " / " + num_config + ")")
end
end

function [forces_body, cycle_avg_body_forces] = getBody(wing_freq_sel, AoA_sel, wind_speed_sel, amp_sel,...
    nondimensional, processed_body_files, sub_string, sub_bool, shift_bool, sub_drift, type_sel, norm_factors, shift_type, numAxes, offsets_files)

% Parse relevant information from subtraction string
case_parts = strtrim(split(sub_string));
sub_type = "";
sub_amp = amp_sel;
sub_wing_freq = wing_freq_sel;
sub_wind_speed = wind_speed_sel;
index = length(case_parts) + 1;
% Handle case where subtraction wingbeat frequency or wind speed
% selected by user rather than just providing the type
for j=1:length(case_parts)
    if (contains(case_parts(j), "Hz"))
        sub_wing_freq = str2double(erase(case_parts(j), "Hz"));
        if index ~= -1
            index = j;
        end
    elseif (contains(case_parts(j), "m.s"))
        sub_wind_speed = str2double(erase(case_parts(j), "m.s"));
        if index ~= -1
            index = j;
        end
    end
end
str = strjoin(case_parts(1:index-1)); % speed is first thing after type

tokens = regexp(str, '^(.*?)(\d+)$', 'tokens', 'once');

if isempty(tokens)
    sub_type = str;
else
    sub_type = strtrim(tokens{1});   % "wings"
    sub_amp   = str2double(tokens{2}); % 10
end

if (sub_bool)
    sub_state = "Subtracting";
else
    sub_state = "Adding";
end

disp(sub_state + " data from " + sub_type + " " + sub_wing_freq + " Hz " + sub_wind_speed + " m/s "  + AoA_sel + " deg trial")

% I am saving body data for each pass, as this will be called four times
% total to generate each of the four trials. Therefore, after the first
% pass, the body data will be saved to the wing data, and it will be much
% clearer. This is cleared each time in batch_compare_trials to ensure that
% the next wing trial does not match to old body data

persistent bodyCache  % This stays in RAM between function calls
if isempty(bodyCache)
    fprintf('>>> CACHE INITIALIZED (Memory is empty)\n');
end

% Generate a unique ID for the specific file/settings requested
clean_AoA = strtrim(strrep(num2str(AoA_sel), '-', 'n')); % because negative AoA cannot be -A in field, must say nA
cacheKey = sprintf('f%d_A%s_S%d_p%d', ...
    wing_freq_sel, clean_AoA, wind_speed_sel, amp_sel); % don't need to check type because
% type is always body

% CHECK: Do we already have this in the "cabinet"?
if isfield(bodyCache, cacheKey)

    % load in filtered data from earlier
    baseFileName = bodyCache.(cacheKey).name;
    filtered_data = bodyCache.(cacheKey).data;
    
    % take the wing_freq out of cacheKey so that we know if to calc cycle_avg_body_forces
    wing_freq = sscanf(cacheKey, 'f%d');

    % process forces_body the same way wing_data is processed for shifts, etc.
    [body_drift, ~, ~] = get_drift(baseFileName, offsets_files, wing_freq_sel);
    forces_body = applyBools(filtered_data, sub_drift, body_drift, shift_bool, AoA_sel, nondimensional, norm_factors, type_sel, shift_type);

    % will only be able to give cycle_avg if f > 0 (otherwise not calculated)
    if wing_freq > 0
        % process cycle_averaged_forces the same way wing_data is processed for shifts, etc.
        cycle_avg_forces = bodyCache.(cacheKey).cycle_avg;
        cycle_avg_body_forces = applyBools(cycle_avg_forces, sub_drift, body_drift, shift_bool, AoA_sel, nondimensional, norm_factors, type_sel, shift_type);
    else
        cycle_avg_body_forces = zeros(numAxes, 1);
    end

else % ... [If not found, search, load, and shift as usual] ...
    for j = 1 : length(processed_body_files)
        baseFileName = processed_body_files(j).name;
        baseFolder = processed_body_files(j).folder;
        [case_name, time_stamp, type, wing_freq, AoA, wind_speed, amp, file_type] = parse_filename(baseFileName);

        type = convertCharsToStrings(type);
        % type = string(sub_string); this alwasy makes type == sub_string. For
        % all my files, I need type == body from parse_filenames

        if (AoA == AoA_sel ...
                && wing_freq == sub_wing_freq ...
                && strcmp(type, "body") ... % && type == sub_type ... if defining from name (not params) - Zachary
                && wind_speed == sub_wind_speed ...
                && amp == sub_amp)

            load([baseFolder '/' baseFileName]); % loads filtered_data, cycle_avg_forces

            % SAVE: Put it in the cabinet so we have it for the next pass
            bodyCache.(cacheKey).name = baseFileName;
            bodyCache.(cacheKey).data = filtered_data;

            % process forces_body the same way wing_data is processed for shifts, etc.
            [body_drift, ~, ~] = get_drift(baseFileName, offsets_files, wing_freq_sel);
            forces_body = applyBools(filtered_data, sub_drift, body_drift, shift_bool, AoA_sel, nondimensional, norm_factors, type_sel, shift_type);

            % will only be able to give cycle_avg if f > 0 (otherwise not calculated)
            if wing_freq > 0
                % process cycle_averaged_forces the same way wing_data is processed for shifts, etc.
                bodyCache.(cacheKey).cycle_avg = cycle_avg_forces;
                cycle_avg_body_forces = applyBools(cycle_avg_forces, sub_drift, body_drift, shift_bool, AoA_sel, nondimensional, norm_factors, type_sel, shift_type);
            else
                cycle_avg_body_forces = zeros(numAxes, 1);
            end

            return; % Exit the function immediately because we found our data!

        end
    end
    % if match is found, return is above and code will exit loop, so error will never be called
    error("No matching body file found for parameters: " + sub_type + " at " + AoA_sel + " deg");
end
end