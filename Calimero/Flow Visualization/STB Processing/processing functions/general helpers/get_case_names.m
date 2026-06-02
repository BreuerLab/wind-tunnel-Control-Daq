function case_names = get_case_names(path)
    files = dir(path);

    % Extract just the names
    names = {files.name};

    % Create full paths to check accurately
    fullPaths = fullfile(path, names);

    % Filter: Must be a folder AND not '.' or '..'
    folders = names(isfolder(fullPaths) & ~ismember(names, {'.', '..'}));
    case_names = string(folders);
end