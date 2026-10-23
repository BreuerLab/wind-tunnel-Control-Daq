function force = get_force(path, type, amp, freq, idx, var_name_F)
    % Loads the wingbeat-averaged load cell force for a given case.
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

    type = string(type);
    amp = string(amp);
    freq = string(freq);

    downstream_prefix = get_downstream_prefix(type); % "x3_", "MPS_", ...
    is_new_flapper = strlength(downstream_prefix) > 0;
    if is_new_flapper
        type = extractAfter(type, strlength(downstream_prefix));
    end

    old_dir = path + type + "_" + amp + "deg" + "\4 m.s\";
    new_dir = path + amp + " deg " + type + "\4 m.s\";

    if is_new_flapper
        candidate_dirs = [new_dir, old_dir];
    else
        candidate_dirs = [old_dir, new_dir];
    end

    parentDir = "";
    for k = 1:length(candidate_dirs)
        if isfolder(candidate_dirs(k))
            parentDir = candidate_dirs(k);
            break
        end
    end

    % Steady cases without a set amplitude (e.g. NACA, ring) may sit in a
    % folder like "30 deg NACA" or "NACA": use the single folder whose name
    % is the type, optionally preceded by "<number> deg "
    if parentDir == ""
        folders = dir(path);
        folders = folders([folders.isdir] & ~ismember({folders.name}, {'.', '..'}));
        folder_names = string({folders.name});
        pattern = "^(\d+ deg )?" + regexptranslate('escape', char(type)) + "$";
        is_match = ~cellfun(@isempty, regexpi(folder_names, pattern, 'once'));
        matches = folder_names(is_match);
        matches = matches(isfolder(path + matches + "\4 m.s"));
        if numel(matches) == 1
            parentDir = path + matches + "\4 m.s\";
        elseif numel(matches) > 1
            error("get_force:ambiguousFolder",...
                "Several load cell folders match type '%s':\n  %s",...
                type, strjoin(path + matches, "\n  "));
        end
    end

    if parentDir == ""
        error("get_force:folderNotFound",...
            "No load cell folder found for type '%s' at %s deg. Tried:\n  %s",...
            type, amp, strjoin(candidate_dirs, "\n  "));
    end

    contents = dir(parentDir);

    % Remove the '.' and '..' (which are always present in file systems)
    % and filter for actual folders
    contents = contents([contents.isdir] & ~ismember({contents.name}, {'.', '..'}));

    if isempty(contents)
        error("get_force:noDataFolder", "No data folder inside %s", parentDir);
    end

    % Use the first (normally the only) dated folder that has processed data
    dynamicFolderName = contents(1).name;
    for k = 1:length(contents)
        if isfolder(parentDir + contents(k).name + "\processed data")
            dynamicFolderName = contents(k).name;
            break
        end
    end

    force_path = parentDir + dynamicFolderName + "\processed data\";

    contents = dir(force_path);
    force_files = contents(~[contents.isdir]);

    force_filename = "";
    for j = 1:length(force_files)
        cur_name = force_files(j).name;
         % 10 deg AoA case and matching frequency
        % (the lookbehind stops "0Hz" from also matching "10Hz")
        if contains(cur_name, "10deg") &&...
                ~isempty(regexp(cur_name, "(?<![\d.])" + freq + "Hz", 'once'))
            force_filename = cur_name;
        end
    end

    if force_filename == ""
        error("get_force:fileNotFound",...
            "No 10deg AoA, %s Hz force file found in %s", freq, force_path);
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
end
