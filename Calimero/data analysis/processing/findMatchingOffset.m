function [offsets_cur, offsets_filename] = findMatchingOffset...
    (offsets_files, offsets_string, wing_freq_match, wing_amp_match, AoA_match, wind_speed_match, type_match, time_stamp_match)
    count = 0;
    timestamps_str = {};
    timestamps_val = [];
    matched_names = strings(0,1);
    matched_folders = strings(0,1);
    % Go through each file, grab its data, take the mean over all results to
    % produce a "dot" (i.e. a single point value) for each force and moment
    for i = 1 : length(offsets_files)
        baseFileName = offsets_files(i).name;
        baseFolder = offsets_files(i).folder;

        if contains(baseFileName, AoA_match + "deg")
        [case_name, time_stamp, type, wing_freq, AoA, wind_speed, amp, file_type] = parse_filename(baseFileName);
        type = convertCharsToStrings(type);
        
        if ((AoA == AoA_match)...
        && (~contains(baseFileName, "Hz") || wing_freq == wing_freq_match)...
        && (wind_speed == wind_speed_match) ...
        && (amp == wing_amp_match) ...
        && strcmp(type, type_match) ...
        && strcmp(file_type, offsets_string))
            % can't contain the term Hz

        count = count + 1;
        time_val = timeStr2num(time_stamp);

        timestamps_str = [timestamps_str; time_stamp];
        timestamps_val = [timestamps_val; time_val];

        matched_names = [matched_names; string(baseFileName)];
        matched_folders = [matched_folders; string(baseFolder)];

        end
        end
    
    end

    % Pick the offsets file that belongs to this trial. Before offsets are
    % recorded just before a trial and after offsets just after, so use the
    % latest before offsets at or before the trial's timestamp and the
    % earliest after/final offsets at or after it. (Picking the closest in
    % absolute time could pick another trial's offsets, e.g. the next
    % trial's before offsets.) Falls back to the closest if there is none
    % on the expected side.
    if count > 0
        exp_time = timeStr2num(time_stamp_match);
        if strcmp(offsets_string, "before_offsets")
            candidates = find(timestamps_val <= exp_time);
            [~, k] = max(timestamps_val(candidates));
            rule = "latest at or before the trial";
        else
            candidates = find(timestamps_val >= exp_time);
            [~, k] = min(timestamps_val(candidates));
            rule = "earliest at or after the trial";
        end
        if ~isempty(candidates)
            idx = candidates(k);
        else
            [~, idx] = min(abs(timestamps_val - exp_time));
            warning("findMatchingOffset:noneOnExpectedSide",...
                "No %s %s (%s); using the closest instead", offsets_string, rule, time_stamp_match);
            rule = "closest (none " + extractAfter(rule, " ") + ")";
        end
        time_stamp_match_offsets = timestamps_str{idx};
        offsets_filename = char(matched_names(idx));
        offsets_folder = char(matched_folders(idx));
    end

    if count > 1
    % encountered another matching offsets file
    % in the past I had replicated wingbeat frequency cases
    disp("Found " + count + " files, timestamps: ")
    disp(timestamps_str)
    disp("    Experiment timestamp: " + time_stamp_match)
    disp("    Using " + rule + ": " + time_stamp_match_offsets)
    disp(" ")
    end

    if exist('offsets_folder', 'var')
        offsets_cur = load([offsets_folder '/' offsets_filename]).offsets;
        offsets_cur = offsets_cur(1,:);
    else
        error("Failed to find matching offsets file")
    end
end