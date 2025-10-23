function [offsets_cur, offsets_filename] = findMatchingOffset...
    (offsets_files, offsets_string, wing_freq_match, AoA_match, wind_speed_match, type_match, time_stamp_match)
    count = 0;
    timestamps_str = {};
    timestamps_val = [];
    cur_time_diff = 10000;
    % Go through each file, grab its data, take the mean over all results to
    % produce a "dot" (i.e. a single point value) for each force and moment
    for i = 1 : length(offsets_files)
        baseFileName = offsets_files(i).name;
        baseFolder = offsets_files(i).folder;

        if contains(baseFileName, AoA_match + "deg")
        [case_name, time_stamp, type, wing_freq, AoA, wind_speed, file_type] = parse_filename(baseFileName);
        type = convertCharsToStrings(type);
        
        if ((AoA == AoA_match)...
        && (~contains(baseFileName, "Hz") || wing_freq == wing_freq_match)...
        && (wind_speed == wind_speed_match) ...
        && strcmp(type, type_match) ...
        && strcmp(file_type, offsets_string))
            % can't contain the term Hz

        count = count + 1;
        time_val = timeStr2num(time_stamp);

        timestamps_str = [timestamps_str; time_stamp];
        timestamps_val = [timestamps_val; time_val];

            time_diff = abs(time_val - timeStr2num(time_stamp_match));
            if (time_diff < cur_time_diff)
                time_stamp_match_offsets = time_stamp;
                cur_time_diff = time_diff;
                offsets_filename = baseFileName;
                offsets_folder = baseFolder;
            end

        end
        end
    
    end

    % encountered another matching offsets file
    % in the past I had replicated wingbeat frequency cases
    disp("Found " + count + " files, timestamps: ")
    disp(timestamps_str)
    disp("    Using closest timestamp: " + time_stamp_match_offsets)
    disp(" ")

    if exist('offsets_folder', 'var')
        offsets_cur = load([offsets_folder '/' offsets_filename]).offsets;
        offsets_cur = offsets_cur(1,:);
    else
        error("Failed to find matching offsets file")
    end
end