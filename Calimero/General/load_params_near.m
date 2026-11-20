function [d, params_file] = load_params_near(params_dir, time_stamp)
    % Loads the experiment_params file that applies to a recording: the one
    % with the latest timestamp at or before time_stamp (e.g.
    % "2026_09_28_08_58_56"), since run_experiment.m / benchtop_test.m save
    % the params when a run starts. Falls back to the closest one if none
    % is earlier. Returns [] (and params_file "") if the folder has no
    % params files.
    d = [];
    params_file = "";
    files = dir(fullfile(params_dir, "*params*.mat"));
    if isempty(files)
        return
    end
    times = NaT(numel(files), 1);
    for k = 1:numel(files)
        tok = regexp(files(k).name, "(\d{4}_\d{2}_\d{2}_\d{2}_\d{2}_\d{2})\.mat$", 'tokens', 'once');
        if ~isempty(tok)
            times(k) = timeStr2num(tok{1});
        end
    end
    valid = ~isnat(times);
    if ~any(valid)
        return
    end
    t = timeStr2num(time_stamp);
    before = find(valid & times <= t);
    if ~isempty(before)
        [~, i] = max(times(before));
        idx = before(i);
    else
        cand = find(valid);
        [~, i] = min(abs(times(cand) - t));
        idx = cand(i);
    end
    params_file = string(fullfile(files(idx).folder, files(idx).name));
    d = load(params_file);
end
