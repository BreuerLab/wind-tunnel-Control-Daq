function [force_path, type] = get_force_folder(path, type, amp)
    % Folder holding the processed load cell files for a wing type and
    % amplitude (shared by get_force and get_force_freqs).
    %
    % Two folder conventions are supported:
    %   old flapper: <path>\<type>_<amp>deg\4 m.s\<dated folder>\processed data\
    %                e.g. "Force Measurements\flexible_20deg\4 m.s\..."
    %   new flapper: <path>\<amp> deg <type>\4 m.s\<dated folder>\processed data\
    %                e.g. "Force Measurements\20 deg wings\4 m.s\wings_2026_09_26\..."
    %
    % New flapper STB types carry a downstream position prefix
    % ("x1_wings", "x3_body", ...). The load cell is only measured at one
    % position, so that prefix is stripped (returned type is without it).

    type = string(type);
    amp = string(amp);

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
end
