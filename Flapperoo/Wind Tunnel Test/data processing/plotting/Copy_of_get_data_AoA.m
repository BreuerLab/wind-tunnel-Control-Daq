function [avg_forces, err_forces, names, sub_title, norm_factors_arr] = ...
    get_data_AoA(selected_vars, processed_data_path, nondimensional, sub_strings, shift_bool)

if (sub_strings(1) == "")
    body_subtraction = false;
else
    body_subtraction = true;
end

AoA_sel = selected_vars.AoA;
wing_freq_sel = selected_vars.freq;
wind_speed_sel = selected_vars.wind;
type_sel = selected_vars.type;

% make array of same length as wing_freq_sel with each value
% indicating the frequency count of that value in wing_freq_sel
count = 0;
for i = 1:length(wing_freq_sel)
    % freq_ind = find(wing_freq_sel, wing_freq_sel(i));
    if (sum(wing_freq_sel == wing_freq_sel(i)) > count)
        count = sum(wing_freq_sel == wing_freq_sel(i));
    end
end
instance_sel = 1:1:count;

% Initialize variables
avg_forces = zeros(6, length(AoA_sel), length(wing_freq_sel), length(wind_speed_sel), length(type_sel), count);
% avg_forces_body = zeros(6, length(AoA_sel), length(wing_freq_sel), length(wind_speed_sel));
err_forces = zeros(6, length(AoA_sel), length(wing_freq_sel), length(wind_speed_sel), length(type_sel), count);
cases_final = strings(length(AoA_sel), length(wing_freq_sel), length(wind_speed_sel), length(type_sel), count);
names = strings(length(wing_freq_sel), length(wind_speed_sel), length(type_sel), count);
norm_factors_arr = zeros(2, length(AoA_sel), length(wing_freq_sel), length(wind_speed_sel));
% really only the windspeed matters here but let's include all
% the variables include the normalization routine changes in the
% future

% Get a list of all files in the folder with the desired file name pattern.
filePattern = fullfile(processed_data_path, '*.mat'); % Change to whatever pattern you need.
theFiles = dir(filePattern);

% Go through each file, grab its data, take the mean over all results to
% produce a "dot" (i.e. a single point value) for each force and moment
for i = 1 : length(theFiles)
    baseFileName = theFiles(i).name;
    [case_name, time_stamp, type, wing_freq, AoA, wind_speed] = parse_filename(baseFileName);
    
    type = convertCharsToStrings(type);
    
%     pitch = deg2rad(-AoA);
%     yaw = deg2rad(205);
%     dcm_F = angle2dcm(yaw, pitch, 0,'ZYX');
%     dcm_M = angle2dcm(yaw, 0, 0, 'ZYX');
    
    if (ismember(wing_freq, wing_freq_sel) ...
    && ismember(AoA, AoA_sel) ...
    && ismember(wind_speed, wind_speed_sel) ...
    && ismember(type, type_sel))

        % Check if any other files were recorded for the same set
        % of parameters but at a different time
        count = 0;
        timestamps_str = {};
        timestamps_val = [];
        for m = 1 : length(theFiles)
            baseFileName = theFiles(m).name;
            if (contains(baseFileName, case_name))
                count = count + 1;
                time_str = extractBefore(extractAfter(baseFileName, case_name), ".mat");
                split_time_str = split(time_str);
                h_m_s = split_time_str(2);
                split_h_m_s = str2double(split(h_m_s, "-"));
                if (split_h_m_s(1) < 6)
                    split_h_m_s(1) = split_h_m_s(1) + 12;
                end
                time_val = split_h_m_s(1)*3600 + split_h_m_s(2)*60 + split_h_m_s(3);

                timestamps_str = [timestamps_str, time_str];
                timestamps_val = [timestamps_val, time_val];
            end
        end

        [M,I] = max(timestamps_val);
        modFileName = case_name + string(timestamps_str(I)) + ".mat";


        disp("   Obtaining data for " + type + " " + wing_freq + " Hz " + wind_speed + " m/s "  + AoA + " deg trial")
        if (count > 1)
            disp("Found " + count + " files, timestamps: " + timestamps_str)
            disp("Using timestamp: " + timestamps_str(I))
        end

        load(processed_data_path + modFileName);

        if (shift_bool)
        [mod_filtered_data] = shiftPitchMoment(filtered_data, AoA);
        filtered_data = mod_filtered_data;
        end

        plot_data = filtered_data;
        norm_plot_data = dimensionless(filtered_data, norm_factors);
        % plot_data = force_data;
        % norm_plot_data = dimensionless(force_data, norm_factors);
        
        norm_factors_arr(:, AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed) = norm_factors;

        sub_term = zeros(1,6);
        if (body_subtraction)
            forces_body_list = zeros(length(sub_strings),6);
            sub_bools = ones(length(sub_strings));
            for j = 1:length(sub_strings)
                sub_string = sub_strings(j);
                case_parts = strtrim(split(sub_string));
                if (case_parts(1) == "-")
                    sub_bools(j) = false;
                    sub_string = strjoin(case_parts(2:end));
                end
                forces_body = getBody(wing_freq, AoA, wind_speed, nondimensional, ...
                    theFiles, processed_data_path, sub_string, sub_bools(j), shift_bool);
                forces_body_list(j,:) = mean(forces_body,2);
                
                if (sub_bools(j) == true)
                    sub_term = sub_term + forces_body_list(j,:);
                else
                    sub_term = sub_term - forces_body_list(j,:);
                end
            end
        end

        if (nondimensional)
            forces = norm_plot_data;
        else
            forces = plot_data;
        end

        for k = 1:6
            if (body_subtraction)
                % if (length(forces_body) > length(forces))
                %     wing_forces = forces - forces_body(:,1:length(forces));
                % else
                %     wing_forces = forces(:,1:length(forces_body)) - forces_body;
                % end
                % avg_forces(k, AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type)...
                %         = mean(wing_forces);

                avg_forces(k, AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type)...
                            = mean(forces(k,:)) - sub_term(k);
            else
                avg_forces(k, AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type)...
                    = mean(forces(k,:));
            end

            if (wing_freq == 0)
                if (nondimensional)
                    % err_forces(k, AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type)...
                    %     = std(norm_plot_data(k,:));
                    cycle_avg_norm = dimensionless(squeeze(cycle_avg_forces), norm_factors);
                    err_forces(k, AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type)...
                        = std(cycle_avg_norm(k, :));
                else
                    % err_forces(k, AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type)...
                    %     = std(plot_data(k, :));
                    cycle_avg = squeeze(cycle_avg_forces);
                    err_forces(k, AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type)...
                        = std(cycle_avg(k, :));
                end
            else
                if (nondimensional)
                    % wingbeat_std_forces_norm = dimensionless(wingbeat_std_forces, norm_factors);
                    % err_forces(k, AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type)...
                    %     = mean(wingbeat_std_forces_norm(k, :));
                    cycle_avg_forces_norm = dimensionless(cycle_avg_forces, norm_factors);
                    err_forces(k, AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type)...
                        = std(cycle_avg_forces_norm(k, :));
                else
                    % err_forces(k, AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type)...
                    %     = mean(wingbeat_std_forces(k, :));
                    err_forces(k, AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type)...
                        = std(cycle_avg_forces(k, :));
                end
            end
        end

%         avg_forces(1:3, AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) ...
%                     = (dcm_F * avg_forces_temp(1:3, AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type));
%         avg_forces(4:6, AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) ...
%                     = (1 * dcm_M * avg_forces_temp(4:6, AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type));
        
        cases_final(AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = modFileName;
        
        if (nondimensional)
        if (isscalar(wing_freq_sel) && isscalar(wind_speed_sel) && isscalar(type_sel))
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = "";
            if (body_subtraction)
                sub_title = [type2name(type) +  ", Re: " + num2str(round(Re,2,"significant")) + ", St: " + num2str(round(St,2,"significant")) "{\color{red}{SUBTRACTION}}: " + sub_string];
            else
                sub_title = type2name(type) +  ", Re: " + num2str(round(Re,2,"significant")) + ", St: " + num2str(round(St,2,"significant"));
            end
        elseif (isscalar(wing_freq_sel) && isscalar(wind_speed_sel))
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = type2name(type);
            if (body_subtraction)
                sub_title = [" Re: " + num2str(round(Re,2,"significant")) + ", St: " + num2str(round(St,2,"significant")) "{\color{red}{SUBTRACTION}}: " + sub_string];
            else
                sub_title = " Re: " + num2str(round(Re,2,"significant")) + ", St: " + num2str(round(St,2,"significant"));
            end
        elseif (isscalar(wing_freq_sel) && isscalar(type_sel))
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) =  " Re: " + num2str(round(Re,2,"significant"));
            if (body_subtraction)
                sub_title = [type2name(type) + " St: " + num2str(round(St,2,"significant")) "{\color{red}{SUBTRACTION}}: " + sub_string];
            else
                sub_title = type2name(type) + " St: " + num2str(round(St,2,"significant"));
            end
        elseif (isscalar(wind_speed_sel) && isscalar(type_sel))
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) =  " St: " + num2str(round(St,2,"significant"));
            if (body_subtraction)
                sub_title = [type2name(type) +  " Re: " + num2str(round(Re,2,"significant")) "{\color{red}{SUBTRACTION}}: " + sub_string];
            else
                sub_title = type2name(type) +  " Re: " + num2str(round(Re,2,"significant"));
            end
        % elseif (length(wing_freq_sel) == 1)
        %     names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = type2name(type) +  " Re: " + num2str(round(Re,2,"significant"));
        %     sub_title = " St: " + num2str(round(St,2,"significant"));
        elseif (isscalar(wind_speed_sel))
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = type2name(type) + ", St: " + num2str(round(St,2,"significant"));
            if (body_subtraction)
                sub_title = [" Re: " + num2str(round(Re,2,"significant")) "{\color{red}{SUBTRACTION}}: " + sub_string];
            else
                sub_title = " Re: " + num2str(round(Re,2,"significant"));
            end
        elseif (isscalar(type_sel))
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) =  " Re: " + num2str(round(Re,2,"significant")) + ", St: " + num2str(round(St,2,"significant"));
            if (body_subtraction)
                sub_title = [type2name(type) "{\color{red}{SUBTRACTION}}: " + sub_string];
            else
                sub_title = type2name(type);
            end
        else
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = type2name(type) +  ", Re: " + num2str(round(Re,2,"significant")) + ", St: " + num2str(round(St,2,"significant"));
            if (body_subtraction)
                sub_title = "{\color{red}{SUBTRACTION}}: " + sub_string;
            else
                sub_title = "";
            end
        end
        
        else
            
        if (isscalar(wing_freq_sel) && isscalar(wind_speed_sel) && isscalar(type_sel))
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = "";
            if (body_subtraction)
                sub_title = [type2name(type) + " " + num2str(wind_speed) + " m/s " + num2str(wing_freq) + " Hz" "{\color{red}{SUBTRACTION}}: " + sub_string];
            else
                sub_title = type2name(type) + " " + num2str(wind_speed) + " m/s " + num2str(wing_freq) + " Hz";
            end
        elseif (isscalar(wing_freq_sel) && isscalar(wind_speed_sel))
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = type2name(type);
            if (body_subtraction)
                sub_title = [num2str(wind_speed) + " m/s " + num2str(wing_freq) + " Hz" "{\color{red}{SUBTRACTION}}: " + sub_string];
            else
                sub_title = num2str(wind_speed) + " m/s " + num2str(wing_freq) + " Hz";
            end
        elseif (isscalar(wing_freq_sel) && isscalar(type_sel))
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = num2str(wind_speed) + " m/s";
            if (body_subtraction)
                sub_title = [type2name(type) + " " + num2str(wing_freq) + " Hz" "{\color{red}{SUBTRACTION}}: " + sub_string];
            else
                sub_title = type2name(type) + " " + num2str(wing_freq) + " Hz";
            end
        elseif (isscalar(wind_speed_sel) && isscalar(type_sel))
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = num2str(wing_freq) + " Hz";
            if (body_subtraction)
                sub_title = [type2name(type) + " " + num2str(wind_speed) + " m/s" "{\color{red}{SUBTRACTION}}: " + sub_string];
            else
                sub_title = type2name(type) + " " + num2str(wind_speed) + " m/s";
            end
        elseif (isscalar(wing_freq_sel))
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = type2name(type) + " " + num2str(wind_speed) + " m/s";
            if (body_subtraction)
                sub_title = [num2str(wing_freq) + " Hz" "{\color{red}{SUBTRACTION}}: " + sub_string];
            else
                sub_title = num2str(wing_freq) + " Hz";
            end
        elseif (isscalar(wind_speed_sel))
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = type2name(type) + " " + num2str(wing_freq) + " Hz";
            if (body_subtraction)
                sub_title = [num2str(wind_speed) + " m/s" "{\color{red}{SUBTRACTION}}: " + sub_string];
            else
                sub_title = num2str(wind_speed) + " m/s";
            end
        elseif (isscalar(type_sel))
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = num2str(wind_speed) + " m/s " + num2str(wing_freq) + " Hz";
            if (body_subtraction)
                sub_title = [type2name(type) "{\color{red}{SUBTRACTION}}: " + sub_string];
            else
                sub_title = type2name(type);
            end
        else
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = type2name(type) + " " + num2str(wind_speed) + " m/s " + num2str(wing_freq) + " Hz";
            if (body_subtraction)
                sub_title = "{\color{red}{SUBTRACTION}}: " + sub_string;
            else
                sub_title = "";
            end
        end
        end
    end
end   

end

function name = type2name(type)
    name = type;
    if (type == "blue wings")
        name = "Wings";
    elseif (type == "blue wings with tail")
        name = "Wings with Tail";
    elseif (type == "no wings with tail")
        name = "No Wings with Tail";
    elseif (type == "no wings")
        name = "No Wings";
    elseif (type == "inertial")
        name = "Skeleton Wings";
    end
end

function [forces_body] = getBody(wing_freq_sel, AoA_sel, wind_speed_sel, ...
    nondimensional, theFiles, processed_data_path, sub_string, sub_bool, shift_bool)

    % Parse relevant information from subtraction string
    case_parts = strtrim(split(sub_string));
    sub_type = "";
    sub_wing_freq = wing_freq_sel;
    sub_wind_speed = wind_speed_sel;
    index = length(case_parts) + 1;
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
    sub_type = strjoin(case_parts(1:index-1)); % speed is first thing after type

    if (sub_bool)
        sub_state = "Subtracting";
    else
        sub_state = "Adding";
    end

    disp(sub_state + " data from " + sub_type + " " + sub_wing_freq + " Hz " + sub_wind_speed + " m/s "  + AoA_sel + " deg trial")

    for j = 1 : length(theFiles)
        baseFileName = theFiles(j).name;
        [case_name, time_stamp, type, wing_freq, AoA, wind_speed] = parse_filename(baseFileName);
        
        type = convertCharsToStrings(type);

        if (type == sub_type ...
        && wing_freq == sub_wing_freq ...
        && AoA == AoA_sel ...
        && wind_speed == sub_wind_speed)

        load(processed_data_path + baseFileName);

        if (shift_bool)
        [mod_filtered_data] = shiftPitchMoment(filtered_data, AoA);
        filtered_data = mod_filtered_data;
        end

        norm_filtered_data = dimensionless(filtered_data, norm_factors);

        if (nondimensional)
            forces_body = norm_filtered_data;
        else
            forces_body = filtered_data;
        end

        end
    end

end