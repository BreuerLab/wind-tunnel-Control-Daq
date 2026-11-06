function S = stb_load(file, varargin)
% STB_LOAD  load() for processed STB files, always returning a struct.
%
%   S = stb_load(file)              every variable
%   S = stb_load(file, "a", "b")    the named variables
%
%   For a GUI-style phase-average path (see stb_resolve) each variable is
%   read from the first of the case's new files holding it (fields path:
%   fields, shared, integral; integral path: integral, shared, fields), so
%   callers written for the legacy combined files keep working. A missing
%   variable gives load's warning and is left out of S, as with load.
%   Any other path (e.g. time-averaged files) is passed to load unchanged.

    R = stb_resolve(file);
    if ~R.virtual
        args = cellfun(@char, varargin, 'UniformOutput', false);
        S = load(char(file), args{:});
        return
    end
    if ~isfile(R.primary)
        error("stb_load:notFound", "No processed file %s (for %s).", R.primary, file);
    end

    files = R.files(isfile(R.files));
    if isempty(varargin)
        % every variable, earlier files winning
        S = struct();
        for f = flipud(files(:)).'
            S = merge_into(S, load(char(f)));
        end
        return
    end

    names = cellfun(@char, varargin, 'UniformOutput', false);
    S = struct();
    remaining = names;
    for f = files(:).'
        if isempty(remaining), break; end
        here = remaining(ismember(remaining, stb_who_cached(f)));
        if isempty(here), continue; end
        S = merge_into(S, load(char(f), here{:}));
        remaining = setdiff(remaining, here, 'stable');
    end
    for k = 1:numel(remaining)
        warning("stb_load:varNotFound", "Variable '%s' not found in %s.", remaining{k}, file);
    end
end

function S = merge_into(S, T)
    fn = fieldnames(T);
    for k = 1:numel(fn)
        S.(fn{k}) = T.(fn{k});
    end
end
