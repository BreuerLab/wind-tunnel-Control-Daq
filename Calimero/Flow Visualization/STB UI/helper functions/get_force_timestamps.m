function time_stamps = get_force_timestamps(path, type, amp, freq)
    % Timestamps (oldest first) of every processed 10 deg AoA load cell file
    % for a case, i.e. each repeat of the measurement, e.g.
    % ["2026_09_27_13_14_28", ..., "2026_09_27_14_11_38"]. Pass one to
    % get_force to load that repeat. Empty if there is no load cell data.
    time_stamps = strings(1, 0);
    try
        force_path = get_force_folder(path, type, amp);
    catch ME
        if startsWith(ME.identifier, "get_force:")
            disp(ME.message)
            return
        end
        rethrow(ME)
    end

    freq_val = str2double(string(freq));
    contents = dir(force_path + "*.mat");
    for j = 1:length(contents)
        cur_name = string(contents(j).name);
        if isempty(regexp(cur_name, "(?<![\d.])10deg", 'once'))
            continue
        end
        freq_tok = regexp(cur_name, "(?<![\d.])(\d+(?:\.\d+)?)Hz", 'tokens', 'once');
        if isempty(freq_tok) || str2double(freq_tok{1}) ~= freq_val
            continue
        end
        time_tok = regexp(cur_name, "(\d{4}_\d{2}_\d{2}_\d{2}_\d{2}_\d{2})\.mat$", 'tokens', 'once');
        if ~isempty(time_tok)
            time_stamps(end+1) = string(time_tok{1}); %#ok<AGROW>
        end
    end
    % fixed-width yyyy_MM_dd_HH_mm_ss sorts chronologically as text
    time_stamps = unique(time_stamps);
end
