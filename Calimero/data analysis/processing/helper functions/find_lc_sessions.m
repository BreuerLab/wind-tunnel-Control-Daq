function sessions = find_lc_sessions(paths)
    % Load cell session folders (the <type>_<date> folders holding
    % "raw data") for the diagnostics. A path that is already a session
    % folder is kept; any other folder (e.g. "F:\Force Measurements\NACA")
    % is searched for the session folders below it, so a type's folder can
    % be listed without knowing its dated subfolder name.
    sessions = strings(0, 1);
    for k = 1:numel(paths)
        p = string(paths(k));
        p = regexprep(p, "[\\/]+$", "");
        if isfolder(fullfile(p, "raw data"))
            sessions(end+1, 1) = p; %#ok<AGROW>
            continue
        end
        found = dir(fullfile(p, "**", "raw data"));
        found = found([found.isdir] & string({found.name}) == "raw data");
        if isempty(found)
            warning("find_lc_sessions:none", "No session folder (with 'raw data') found in %s", p);
            continue
        end
        for f = 1:numel(found)
            % found(f).folder is the session folder holding "raw data"
            sessions(end+1, 1) = string(found(f).folder); %#ok<AGROW>
        end
    end
    sessions = unique(sessions, 'stable');
end
