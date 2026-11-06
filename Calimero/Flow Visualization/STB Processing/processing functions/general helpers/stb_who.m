function vars = stb_who(file)
% STB_WHO  Variable names in a processed STB file, like who('-file', file).
%
%   vars = stb_who(file)   cellstr (column)
%
%   For a GUI-style phase-average path (see stb_resolve) the names held by
%   any of the case's new files (fields, shared, integral) are returned.
%   Any other path is passed to who('-file', ...) unchanged.

    R = stb_resolve(file);
    if ~R.virtual
        vars = who('-file', char(file));
        return
    end
    if ~isfile(R.primary)
        error("stb_who:notFound", "No processed file %s (for %s).", R.primary, file);
    end
    vars = {};
    for f = R.files.'
        if isfile(f)
            vars = [vars; stb_who_cached(f)]; %#ok<AGROW>
        end
    end
    vars = unique(vars, 'stable');
end
