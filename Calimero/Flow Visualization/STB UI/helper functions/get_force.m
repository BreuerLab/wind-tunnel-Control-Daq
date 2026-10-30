function [force, frames] = get_force(path, type, amp, freq, idx, var_name_F, time_stamp)
    % Loads the wingbeat-averaged load cell force for a given case.
    %
    % Optional time_stamp (e.g. "2026_09_27_14_11_38"): load that repeat of
    % the case. By default the repeat with the latest timestamp is used
    % (get_force_timestamps lists the repeats).
    %
    % Optional second output: the wingbeat phase (t/T) of each sample in
    % force, read from the 'frames' variable saved alongside var_name_F
    % (e.g. wingbeat_avg_forces_smoothest -> frames_smoothest). Empty if no
    % matching frames variable was saved.
    %
    % Two folder conventions are supported:
    %   old flapper: <path>\<type>_<amp>deg\4 m.s\<dated folder>\processed data\
    %                e.g. "Force Measurements\flexible_20deg\4 m.s\..."
    %   new flapper: <path>\<amp> deg <type>\4 m.s\<dated folder>\processed data\
    %                e.g. "Force Measurements\20 deg wings\4 m.s\wings_2026_09_26\..."
    %
    % New flapper STB types carry a downstream position prefix
    % ("x1_wings", "x3_body", ...). The load cell is only measured at one
    % position, so that prefix is stripped before building the path.

    freq = string(freq);
    force_path = get_force_folder(path, type, amp);

    contents = dir(force_path);
    force_files = contents(~[contents.isdir]);

    % Each case is measured several times (repeats let thermal drift
    % settle), so several processed files can match. Use the repeat with
    % the latest timestamp, which should be the best measurement.
    % Processed file names look like:
    %   "body 10 4m.s 10deg 0.1Hz 2026_09_27_14_11_38.mat"
    freq_val = str2double(freq);
    if nargin < 7
        time_stamp = "";
    end
    time_stamp = string(time_stamp);
    force_filename = "";
    latest_time = NaT;
    num_matches = 0;
    for j = 1:length(force_files)
        cur_name = string(force_files(j).name);
        % 10 deg AoA case (the lookbehind stops "10deg" matching "110deg")
        if isempty(regexp(cur_name, "(?<![\d.])10deg", 'once'))
            continue
        end
        % matching frequency, compared as numbers ("0.1" == "0.10")
        freq_tok = regexp(cur_name, "(?<![\d.])(\d+(?:\.\d+)?)Hz", 'tokens', 'once');
        if isempty(freq_tok) || str2double(freq_tok{1}) ~= freq_val
            continue
        end
        time_tok = regexp(cur_name, "(\d{4})_(\d{2})_(\d{2})_(\d{2})_(\d{2})_(\d{2})\.mat$", 'tokens', 'once');
        if isempty(time_tok)
            continue
        end
        cur_time = datetime(str2double(time_tok));
        num_matches = num_matches + 1;
        if strlength(time_stamp) > 0
            if strjoin(string(time_tok), "_") == time_stamp
                force_filename = cur_name; % the requested repeat
            end
        elseif isnat(latest_time) || cur_time > latest_time
            latest_time = cur_time;
            force_filename = cur_name;
        end
    end

    if force_filename == "" && strlength(time_stamp) > 0
        error("get_force:fileNotFound",...
            "No 10deg AoA, %s Hz force file with timestamp %s found in %s", freq, time_stamp, force_path);
    end
    if force_filename == ""
        error("get_force:fileNotFound",...
            "No 10deg AoA, %s Hz force file found in %s", freq, force_path);
    end
    if num_matches > 1 && strlength(time_stamp) == 0
        disp("Using latest of " + num_matches + " repeats for " + type + " " + amp + " deg " + freq + " Hz")
    end

    % var_name_F = "wingbeat_avg_forces_raw";
    % var_name_F = "wingbeat_avg_forces";
    % var_name_F = "filtered_data";
    % var_name_F = "wingbeat_avg_forces_smoothest";
    disp("Load cell file: " + force_path + force_filename)
    file_vars = who('-file', force_path + force_filename);
    if ~ismember(char(var_name_F), file_vars)
        error("get_force:varNotFound", "%s not saved in load cell file %s",...
            var_name_F, force_path + force_filename);
    end
    c = load(force_path + force_filename, var_name_F);
    var_F = c.(var_name_F);

    force = var_F(idx,:);

    if nargout > 1
        frames = [];
        frames_name = replace(string(var_name_F), "wingbeat_avg_forces", "frames");
        if frames_name ~= string(var_name_F) && ismember(char(frames_name), file_vars)
            f = load(force_path + force_filename, frames_name);
            frames = double(f.(frames_name)(:)');
        end
    end
end
