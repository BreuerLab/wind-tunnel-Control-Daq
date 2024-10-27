% returns drift since beginning of experiment
% offsets now - offsets from before first freq with wind on
function [drift] = get_drift(experiment_filename, offsets_files)
    wing_freqs = [3.5, 4, 3.75, 2, 3, 0, 0.1, 2.5, 4.5, 5, 2, 4];
    offsets_string = "_before_offsets_";
    cal_mat = obtain_cal("Calibration Files\FT43243.cal");

    [case_name_exp, time_stamp_exp, type_exp, wing_freq_exp, AoA_exp, wind_speed_exp] = parse_filename(experiment_filename);

    disp("Searching for matching offsets file...")
    count = 0;
    timestamps_str = {};
    timestamps_val = [];
    % Go through each file, grab its data, take the mean over all results to
    % produce a "dot" (i.e. a single point value) for each force and moment
    for i = 1 : length(offsets_files)
        baseFileName = offsets_files(i).name;
        baseFolder = offsets_files(i).folder;

        [case_name, time_stamp, type, wing_freq, AoA, wind_speed] = parse_filename(baseFileName);
        
        type = convertCharsToStrings(type);
        
        if (contains(baseFileName, offsets_string) ...
        && (wing_freq == wing_freq_exp) ...
        && (AoA == AoA_exp) ...
        && (wind_speed == wind_speed_exp) ...
        && strcmp(type, type_exp))

        count = count + 1;
        time_val = time_str2num(time_stamp);

        timestamps_str = [timestamps_str; time_stamp];
        timestamps_val = [timestamps_val; time_val];
    
        if count > 1
            [M,I] = min(abs(timestamps_val - time_str2num(time_stamp_exp)));
            offsets_filename = strrep(case_name," ","_") + offsets_string + string(timestamps_str(I)) + ".csv";
            offsets_filename = convertStringsToChars(offsets_filename);

            disp("Found " + count + " files, timestamps: ")
            disp(timestamps_str)
            disp("    Using closest timestamp: " + timestamps_str(I))
            disp(" ")
        else
            offsets_filename = baseFileName;
            offsets_folder = baseFolder;
        end

        end
    
    end

    disp("Current offsets: " + offsets_filename)
    offsets_cur = readmatrix([offsets_folder '/' offsets_filename]);
    offsets_cur = offsets_cur(1,:)';

    % Find offset associated with first trial at that angle
    for i = 1 : length(offsets_files)
    baseFileName = offsets_files(i).name;
    baseFolder = offsets_files(i).folder;

    [case_name, time_stamp, type, wing_freq, AoA, wind_speed] = parse_filename(baseFileName);
    
    type = convertCharsToStrings(type);
    
    if (contains(baseFileName, offsets_string) ...
    && (wing_freq == wing_freqs(1)) ...
    && (AoA == AoA_exp) ...
    && (wind_speed == wind_speed_exp) ...
    && strcmp(type, type_exp))

        % Check if any other files were recorded for the same set
        % of parameters but at a different time
        count = 0;
        timestamps_str = {};
        timestamps_val = [];
        for m = 1 : length(offsets_files)
            time_baseFileName = offsets_files(m).name;
            if (contains(time_baseFileName, case_name))
                count = count + 1;
                time_str = extractBefore(extractAfter(time_baseFileName, case_name), ".mat");
                time_val = time_str2num(time_str);

                timestamps_str = [timestamps_str; time_str];
                timestamps_val = [timestamps_val; time_val];
            end
        end
    
        if count > 1
            [M,I] = min(abs(timestamps_val - time_str2num(time_stamp_exp)));
            offsets_filename = case_name + offsets_string + string(timestamps_str(I)) + ".csv";
            offsets_filename = convertStringsToChars(offsets_filename);

            disp("Found " + count + " files, timestamps: ")
            disp(timestamps_str)
            disp("    Using closest timestamp: " + timestamps_str(I))
            disp(" ")
        else
            offsets_filename = baseFileName;
            offsets_folder = baseFolder;
        end

    end

    end

    disp("Original offsets: " + offsets_filename)
    offsets_first = readmatrix([offsets_folder '/' offsets_filename]);
    offsets_first = offsets_first(1,:)';

    drift_volt = offsets_cur - offsets_first;
    drift_force = cal_mat * drift_volt;
    drift = coordinate_transformation(drift_force, AoA);
end

function time_val = time_str2num(time_str)
    split_time_str = split(time_str);
    h_m_s = split_time_str(2);
    split_h_m_s = str2double(split(h_m_s, "-"));
    if (split_h_m_s(1) < 6)
        split_h_m_s(1) = split_h_m_s(1) + 12;
    end
    time_val = split_h_m_s(1)*3600 + split_h_m_s(2)*60 + split_h_m_s(3);
end

% This function parses an ATI .cal calibration file into a matrix in
% Matlab that can be worked with more easily.
% Inputs: calibration_filepath - The path to a .cal file
% Returns: cal_mat - A matlab matrix
function cal_mat = obtain_cal(calibration_filepath)

    % Preallocate space for calibration matrix
    cal_mat = zeros(6,6);

    file_id = fopen(calibration_filepath);
    
    % Get first line from file
    tline = convertCharsToStrings(fgetl(file_id));
    
    % Counter for each measurement axis (6 total: Fx, Fy, Fz, Mx, My, Mz)
    axis_count = 1;
    
    % Loop through each line until reaching the end of the file
    while isstring(tline)
        
        % Lines with "UserAxis Name" have the calibration values
        if contains(tline, "UserAxis Name")
            split_line = split(tline);
            
            % Counter for each calibration value (six values for each axis)
            value_count = 1;
            
            for i = 1:length(split_line)
                % Check if phrase is numeric
                [num, status] = str2num(split_line(i));
                if status
                    % add that calibration value to matrix
                    cal_mat(axis_count, value_count) = num;
                    
                    % move on to the next value
                    value_count = value_count + 1;
                end
            end
            
            % move on to the next measurement axis
            axis_count = axis_count + 1;
        end
        
        % get next line
        tline = convertCharsToStrings(fgetl(file_id));
    end
    
    fclose(file_id);

end