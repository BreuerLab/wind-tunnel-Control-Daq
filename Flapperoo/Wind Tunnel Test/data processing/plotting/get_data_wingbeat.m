function [frames_padded, avg_forces, err_forces, names, sub_title, norm_factors_arr] = ...
    get_data_wingbeat(selected_vars, processed_data_path, nondimensional, sub_strings, shift_bool)

    if (sub_strings(1) == "")
        body_subtraction = false;
    else
        body_subtraction = true;
    end

    AoA_sel = selected_vars.AoA;
    wing_freq_sel = selected_vars.freq;
    wind_speed_sel = selected_vars.wind;
    type_sel = selected_vars.type;

    frames_length = 9000; % really it varies from wingbeat to wingbeat but those values will just be zero

    frames_padded = 100*ones(frames_length, length(AoA_sel), length(wing_freq_sel), length(wind_speed_sel), length(type_sel));
    avg_forces = 100*ones(6, frames_length, length(AoA_sel), length(wing_freq_sel), length(wind_speed_sel), length(type_sel));
    err_forces = 100*ones(6, frames_length, length(AoA_sel), length(wing_freq_sel), length(wind_speed_sel), length(type_sel));
    cases_final = strings(length(AoA_sel), length(wing_freq_sel), length(wind_speed_sel), length(type_sel));
    names = strings(length(wing_freq_sel), length(wind_speed_sel), length(type_sel));
    norm_factors_arr = zeros(2, length(AoA_sel), length(wing_freq_sel), length(wind_speed_sel));

    % Get a list of all files in the folder with the desired file name pattern.
    filePattern = fullfile(processed_data_path, '*.mat'); % Change to whatever pattern you need.
    theFiles = dir(filePattern);
    
    % Shorten list of filenames based on parameter requirements
    cases = "";
    for k = 1 : length(theFiles)
        baseFileName = theFiles(k).name;
        [case_name, type, wing_freq, AoA, wind_speed] = parse_filename(baseFileName);
        type = convertCharsToStrings(type);
    
        if (ismember(wing_freq, wing_freq_sel) && ismember(AoA, AoA_sel) ...
                && ismember(wind_speed, wind_speed_sel) && ismember(type,type_sel))
            
        disp("   Obtaining data for " + type + " " + wing_freq + " Hz " + wind_speed + " m/s "  + AoA + " deg trial")

        load(processed_data_path + baseFileName);

        frames_padded(:, AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type)...
            = [frames -100*ones(1,frames_length - length(frames))];
        mean_forces = wingbeat_avg_forces_smooth;
        std_forces = wingbeat_std_forces_smooth;

        if (shift_bool)
            [mod_filtered_data] = shiftPitchMoment(mean_forces, AoA);
            mean_forces = mod_filtered_data;
        end

        norm_mean_forces = dimensionless(mean_forces, norm_factors);
        norm_std_forces = dimensionless(std_forces, norm_factors);
    
        norm_factors_arr(:, AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed) = norm_factors;

        sub_term = zeros(1,6,frames_length);
        if (body_subtraction)
            forces_body_list = zeros(length(sub_strings),6,frames_length);
            sub_bools = ones(length(sub_strings));
            for j = 1:length(sub_strings)
                sub_string = sub_strings(j);
                case_parts = strtrim(split(sub_string));
                if (case_parts(1) == "-")
                    sub_bools(j) = false;
                    sub_string = strjoin(case_parts(2:end));
                end
                [mean_forces_body, std_forces_body] = getBody(wing_freq, AoA, wind_speed, nondimensional, ...
                    theFiles, processed_data_path, sub_string, sub_bools(j), shift_bool);
                forces_body_list(j,:,:) = [mean_forces_body -100*ones(6,frames_length - length(mean_forces_body))];
                
                if (sub_bools(j) == true)
                    sub_term = sub_term + forces_body_list(j,:,:);
                else
                    sub_term = sub_term - forces_body_list(j,:,:);
                end
            end
        end

        if (nondimensional)
            mean_forces = norm_mean_forces;
            std_forces = norm_std_forces;
        end

        fin_sub_term = squeeze(sub_term);
        for k = 1:6
        if (body_subtraction)
            cur_sub = fin_sub_term(k,:);
            cur_sub(cur_sub == -100) = [];
            avg_forces(k, :, AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type)...
                        = [mean_forces(k,:) - cur_sub, -100*ones(1,frames_length - length(frames))];
        else
            avg_forces(k, :, AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type)...
                = [mean_forces(k,:), -100*ones(1,frames_length - length(frames))];
        end

        err_forces(k, :, AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type)...
                = [std_forces(k,:), -100*ones(1,frames_length - length(frames))];
        
        cases_final(AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = baseFileName;

        if (nondimensional)
        if (length(wing_freq_sel) == 1 && length(wind_speed_sel) == 1 && length(type_sel) == 1)
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = "";
            if (body_subtraction)
                sub_title = [type2name(type) +  ", Re: " + num2str(round(Re,2,"significant")) + ", St: " + num2str(round(St,2,"significant")) "{\color{red}{SUBTRACTION}}: " + sub_string];
            else
                sub_title = type2name(type) +  ", Re: " + num2str(round(Re,2,"significant")) + ", St: " + num2str(round(St,2,"significant"));
            end
        elseif (length(wing_freq_sel) == 1 && length(wind_speed_sel) == 1)
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = type2name(type);
            if (body_subtraction)
                sub_title = [" Re: " + num2str(round(Re,2,"significant")) + ", St: " + num2str(round(St,2,"significant")) "{\color{red}{SUBTRACTION}}: " + sub_string];
            else
                sub_title = " Re: " + num2str(round(Re,2,"significant")) + ", St: " + num2str(round(St,2,"significant"));
            end
        elseif (length(wing_freq_sel) == 1 && length(type_sel) == 1)
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) =  " Re: " + num2str(round(Re,2,"significant"));
            if (body_subtraction)
                sub_title = [type2name(type) + " St: " + num2str(round(St,2,"significant")) "{\color{red}{SUBTRACTION}}: " + sub_string];
            else
                sub_title = type2name(type) + " St: " + num2str(round(St,2,"significant"));
            end
        elseif (length(wind_speed_sel) == 1 && length(type_sel) == 1)
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) =  " St: " + num2str(round(St,2,"significant"));
            if (body_subtraction)
                sub_title = [type2name(type) +  " Re: " + num2str(round(Re,2,"significant")) "{\color{red}{SUBTRACTION}}: " + sub_string];
            else
                sub_title = type2name(type) +  " Re: " + num2str(round(Re,2,"significant"));
            end
        % elseif (length(wing_freq_sel) == 1)
        %     names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = type2name(type) +  " Re: " + num2str(round(Re,2,"significant"));
        %     sub_title = " St: " + num2str(round(St,2,"significant"));
        elseif (length(wind_speed_sel) == 1)
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = type2name(type) + ", St: " + num2str(round(St,2,"significant"));
            if (body_subtraction)
                sub_title = [" Re: " + num2str(round(Re,2,"significant")) "{\color{red}{SUBTRACTION}}: " + sub_string];
            else
                sub_title = " Re: " + num2str(round(Re,2,"significant"));
            end
        elseif (length(type_sel) == 1)
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
            
        if (length(wing_freq_sel) == 1 && length(wind_speed_sel) == 1 && length(type_sel) == 1)
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = "";
            if (body_subtraction)
                sub_title = [type2name(type) + " " + int2str(wind_speed) + " m/s " + int2str(wing_freq) + " Hz" "{\color{red}{SUBTRACTION}}: " + sub_string];
            else
                sub_title = type2name(type) + " " + int2str(wind_speed) + " m/s " + int2str(wing_freq) + " Hz";
            end
        elseif (length(wing_freq_sel) == 1 && length(wind_speed_sel) == 1)
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = type2name(type);
            if (body_subtraction)
                sub_title = [int2str(wind_speed) + " m/s " + int2str(wing_freq) + " Hz" "{\color{red}{SUBTRACTION}}: " + sub_string];
            else
                sub_title = int2str(wind_speed) + " m/s " + int2str(wing_freq) + " Hz";
            end
        elseif (length(wing_freq_sel) == 1 && length(type_sel) == 1)
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = int2str(wind_speed) + " m/s";
            if (body_subtraction)
                sub_title = [type2name(type) + " " + int2str(wing_freq) + " Hz" "{\color{red}{SUBTRACTION}}: " + sub_string];
            else
                sub_title = type2name(type) + " " + int2str(wing_freq) + " Hz";
            end
        elseif (length(wind_speed_sel) == 1 && length(type_sel) == 1)
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = int2str(wing_freq) + " Hz";
            if (body_subtraction)
                sub_title = [type2name(type) + " " + int2str(wind_speed) + " m/s" "{\color{red}{SUBTRACTION}}: " + sub_string];
            else
                sub_title = type2name(type) + " " + int2str(wind_speed) + " m/s";
            end
        elseif (length(wing_freq_sel) == 1)
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = type2name(type) + " " + int2str(wind_speed) + " m/s";
            if (body_subtraction)
                sub_title = [int2str(wing_freq) + " Hz" "{\color{red}{SUBTRACTION}}: " + sub_string];
            else
                sub_title = int2str(wing_freq) + " Hz";
            end
        elseif (length(wind_speed_sel) == 1)
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = type2name(type) + " " + int2str(wing_freq) + " Hz";
            if (body_subtraction)
                sub_title = [int2str(wind_speed) + " m/s" "{\color{red}{SUBTRACTION}}: " + sub_string];
            else
                sub_title = int2str(wind_speed) + " m/s";
            end
        elseif (length(type_sel) == 1)
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = int2str(wind_speed) + " m/s " + int2str(wing_freq) + " Hz";
            if (body_subtraction)
                sub_title = [type2name(type) "{\color{red}{SUBTRACTION}}: " + sub_string];
            else
                sub_title = type2name(type);
            end
        else
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = type2name(type) + " " + int2str(wind_speed) + " m/s " + int2str(wing_freq) + " Hz";
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

function [mean_forces_body, std_forces_body] = getBody(wing_freq_sel, AoA_sel, wind_speed_sel, ...
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
        [case_name, type, wing_freq, AoA, wind_speed] = parse_filename(baseFileName);
        type = convertCharsToStrings(type);

        if (type == sub_type ...
        && wing_freq == sub_wing_freq ...
        && AoA == AoA_sel ...
        && wind_speed == sub_wind_speed)

        load(processed_data_path + baseFileName);

        mean_forces_body = wingbeat_avg_forces_smooth;
        std_forces_body = wingbeat_std_forces_smooth;

        if (shift_bool)
        [mod_filtered_data] = shiftPitchMoment(mean_forces_body, AoA);
        mean_forces_body = mod_filtered_data;
        end

        norm_mean_forces = dimensionless(mean_forces_body, norm_factors);
        norm_std_forces = dimensionless(std_forces_body, norm_factors);

        if (nondimensional)
            mean_forces_body = norm_mean_forces;
            std_forces_body = norm_std_forces;
        end

        end
    end
end