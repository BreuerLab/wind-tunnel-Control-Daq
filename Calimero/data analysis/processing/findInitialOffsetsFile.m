function file_name = findInitialOffsetsFile(path, case_name, time_stamp)
% Finds the initial (wind-off tare) offsets file for a trial.
%
% Inputs:
% path - folder containing the offsets .mat files
% case_name - case name of the trial (from parse_filename), e.g.
%             "body 10 4m.s 10deg 0.1Hz". The wingbeat frequency is
%             dropped since the initial tare is shared by all frequencies.
% time_stamp - (optional) the trial's timestamp, e.g. "2026_09_27_14_11_38"
%
% A tare is taken at the start of each AoA in run_experiment, so if a case
% was run more than once (e.g. the experiment was restarted) there can be
% several matching offsets files. With time_stamp given, the tare taken
% most recently at or before the trial is used. Without it, the most recent
% matching tare is used (with a warning when there are several).
    filePattern = fullfile(path, '*.mat');
    theFiles = dir(filePattern);
    parts = split(case_name);
    case_name = strjoin(parts(1:end-1), " "); % removing wingbeat frequency

    names = strings(0, 1);
    times = datetime.empty(0, 1);
    for k = 1 : length(theFiles)
        baseFileName = string(theFiles(k).name);
        [case_name_cur, time_stamp_cur, ~, ~, ~, ~, ~, file_type] = parse_filename(baseFileName);

        if strcmp(case_name, case_name_cur) && strcmp(file_type, "offsets")
            names(end+1, 1) = baseFileName;
            times(end+1, 1) = timeStr2num(time_stamp_cur);
        end
    end

    if isempty(names)
        error("findInitialOffsetsFile:notFound",...
            "No initial offsets file found for case '%s' in %s", case_name, path);
    end

    if nargin < 3 || strlength(string(time_stamp)) == 0
        [~, idx] = max(times);
        if numel(names) > 1
            warning("findInitialOffsetsFile:multiple",...
                "%d initial offsets files for '%s' and no trial timestamp given; using the latest, %s",...
                numel(names), case_name, names(idx));
        end
    else
        exp_time = timeStr2num(time_stamp);
        before = find(times <= exp_time);
        if ~isempty(before)
            [~, k] = max(times(before));
            idx = before(k);
        else
            [~, idx] = min(abs(times - exp_time));
            warning("findInitialOffsetsFile:noneBefore",...
                "No initial offsets for '%s' recorded before the trial (%s); using the closest, %s",...
                case_name, time_stamp, names(idx));
        end
    end

    if numel(names) > 1
        disp("Found " + numel(names) + " initial offsets files for " + case_name + ", using " + names(idx))
    end
    file_name = names(idx);
end
