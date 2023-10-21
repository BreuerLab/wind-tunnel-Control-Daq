function [avg_forces, err_forces, names, sub_title] = get_data_AoA(selected_vars, processed_data_path, nondimensional)

AoA_sel = selected_vars.AoA;
wing_freq_sel = selected_vars.freq;
wind_speed_sel = selected_vars.wind;
type_sel = selected_vars.type;

% Initialize variables
avg_forces = zeros(length(AoA_sel), length(wing_freq_sel), length(wind_speed_sel), length(type_sel), 6);
err_forces = zeros(length(AoA_sel), length(wing_freq_sel), length(wind_speed_sel), length(type_sel), 6);
cases_final = strings(length(AoA_sel), length(wing_freq_sel), length(wind_speed_sel), length(type_sel));
names = strings(length(wing_freq_sel), length(wind_speed_sel), length(type_sel));

% Get a list of all files in the folder with the desired file name pattern.
filePattern = fullfile(processed_data_path, '*.mat'); % Change to whatever pattern you need.
theFiles = dir(filePattern);

% Go through each file, grab its data, take the mean over all results to
% produce a "dot" (i.e. a single point value) for each force and moment
for i = 1 : length(theFiles)
    baseFileName = theFiles(i).name;
    [case_name, type, wing_freq, AoA, wind_speed] = parse_filename(baseFileName);
    type = convertCharsToStrings(type);
    
    if (ismember(wing_freq, wing_freq_sel) && ismember(AoA, AoA_sel) && ismember(wind_speed, wind_speed_sel) && ismember(type, type_sel))        
        load(processed_data_path + baseFileName);
        for k = 1:6
            if (nondimensional)
                avg_forces(AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type, k) = mean(filtered_norm_data(:, k));
            else
                avg_forces(AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type, k) = mean(filtered_data(:, k));
            end
            if (wing_freq == 0)
                if (nondimensional)
                    err_forces(AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type, k) = std(filtered_norm_data(:, k));
                else
                err_forces(AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type, k) = std(filtered_data(:, k));
                end
            else % MISSING CORRECTION HERE FOR NONDIMENSIONALIZATION
                err_forces(AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type, k) = mean(wingbeat_rmse_forces(:, k));
            end
        end
        
        cases_final(AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = baseFileName;
        
        if (length(wing_freq_sel) == 1 && length(wind_speed_sel) == 1 && length(type_sel) == 1)
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = "";
            sub_title = type + " " + int2str(wind_speed) + " m/s " + int2str(wing_freq) + " Hz";
        elseif (length(wing_freq_sel) == 1 && length(wind_speed_sel) == 1)
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = type;
            sub_title = int2str(wind_speed) + " m/s " + int2str(wing_freq) + " Hz";
        elseif (length(wing_freq_sel) == 1 && length(type_sel) == 1)
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = int2str(wind_speed) + " m/s";
            sub_title = type + " " + int2str(wing_freq) + " Hz";
        elseif (length(wind_speed_sel) == 1 && length(type_sel) == 1)
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = int2str(wing_freq) + " Hz";
            sub_title = type + " " + int2str(wind_speed) + " m/s";
        elseif (length(wing_freq_sel) == 1)
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = type + " " + int2str(wind_speed) + " m/s";
            sub_title = int2str(wing_freq) + " Hz";
        elseif (length(wind_speed_sel) == 1)
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = type + " " + int2str(wing_freq) + " Hz";
            sub_title = int2str(wind_speed) + " m/s";
        elseif (length(type_sel) == 1)
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = int2str(wind_speed) + " m/s " + int2str(wing_freq) + " Hz";
            sub_title = type;
        else
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = type + " " + int2str(wind_speed) + " m/s " + int2str(wing_freq) + " Hz";
            sub_title = "";
        end
    end
end

end

