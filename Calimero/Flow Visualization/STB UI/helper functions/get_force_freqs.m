function freqs = get_force_freqs(path, type, amp)
    % Wingbeat frequencies (Hz, sorted, unique) with processed 10 deg AoA
    % load cell data for a wing type and amplitude, whether or not there is
    % flow field data for them. Repeats of a case count once (get_force
    % uses the latest). Empty if no load cell folder is found.
    %
    % Processed file names look like:
    %   "body 10 4m.s 10deg 0.1Hz 2026_09_27_14_11_38.mat"
    freqs = zeros(1, 0);
    try
        force_path = get_force_folder(path, type, amp);
    catch ME
        if startsWith(ME.identifier, "get_force:")
            disp(ME.message)
            return
        end
        rethrow(ME)
    end

    contents = dir(force_path + "*.mat");
    for j = 1:length(contents)
        cur_name = string(contents(j).name);
        if isempty(regexp(cur_name, "(?<![\d.])10deg", 'once')) ||...
                isempty(regexp(cur_name, "\d{4}_\d{2}_\d{2}_\d{2}_\d{2}_\d{2}\.mat$", 'once'))
            continue
        end
        freq_tok = regexp(cur_name, "(?<![\d.])(\d+(?:\.\d+)?)Hz", 'tokens', 'once');
        if ~isempty(freq_tok)
            freqs(end+1) = str2double(freq_tok{1}); %#ok<AGROW>
        end
    end
    freqs = unique(freqs);
end
