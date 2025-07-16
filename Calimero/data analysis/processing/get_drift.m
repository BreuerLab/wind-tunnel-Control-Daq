% returns drift since beginning of experiment
% offsets now - offsets from before first freq with wind on
function [drift] = get_drift(experiment_filename, offsets_files)
    wing_freqs = [120, 180, 0, 90, 150];
    offsets_string = "_before_offsets_";
    calibration_filepath = "../../DAQ/Calibration Files/Mini40/FT52907.cal";
    cal_mat = obtain_cal(calibration_filepath);

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
        time_val = timeStr2num(time_stamp);

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
    offsets_cur = load([offsets_folder '/' offsets_filename]).offsets;
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
                % time_str = extractBefore(extractAfter(time_baseFileName, case_name), ".mat");
                time_val = timeStr2num(time_stamp);

                timestamps_str = [timestamps_str; time_stamp];
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
    offsets_first = load([offsets_folder '/' offsets_filename]).offsets;
    offsets_first = offsets_first(1,:)';

    drift_volt = offsets_cur - offsets_first;
    drift_volt = drift_volt(1:6); % dropping voltage, current, encoder data
    drift_force = cal_mat * drift_volt;
    drift = coordinate_transformation(drift_force, AoA);
end