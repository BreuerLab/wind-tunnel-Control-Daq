function [offsets_cur, offsets_filename] = findMatchingOffset(offsets_files, offsets_string, wing_freq_match, AoA_match, wind_speed_match, type_match)
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
        && (wing_freq == wing_freq_match) ...
        && (AoA == AoA_match) ...
        && (wind_speed == wind_speed_match) ...
        && strcmp(type, type_match))

        count = count + 1;
        time_val = timeStr2num(time_stamp);

        timestamps_str = [timestamps_str; time_stamp];
        timestamps_val = [timestamps_val; time_val];
    
        % encountered another matching offsets file
        % in the past I had replicated wingbeat frequency cases
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

    offsets_cur = load([offsets_folder '/' offsets_filename]).offsets;
    offsets_cur = offsets_cur(1,:);
end