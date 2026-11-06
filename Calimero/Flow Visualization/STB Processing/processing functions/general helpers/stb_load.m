function S = stb_load(src, varargin)
% STB_LOAD  Load variables of a processed STB case into a struct.
%
%   S = stb_load(C, "a", "b")    from a case struct (stb_file_paths or
%                                stb_time_avg_case): each variable from the
%                                first of its files holding it (fields,
%                                integral, shared; see stb_case_files)
%   S = stb_load(C)              every variable (earlier files win)
%   S = stb_load(file, ...)      a plain .mat file: same as load
%
%   A missing variable gives a warning and is left out of S, as with load.

    if ~isstruct(src)
        args = cellfun(@char, varargin, 'UniformOutput', false);
        S = load(char(src), args{:});
        return
    end
    files = stb_case_files(src);
    if isempty(files)
        error("stb_load:notFound", "No processed files for %s.", stb_name(src));
    end

    S = struct();
    if isempty(varargin)
        for f = flipud(files).'
            S = merge_into(S, load(char(f)));
        end
        return
    end

    remaining = cellfun(@char, varargin, 'UniformOutput', false);
    for f = files.'
        if isempty(remaining), break; end
        here = remaining(ismember(remaining, stb_who_cached(f)));
        if isempty(here), continue; end
        S = merge_into(S, load(char(f), here{:}));
        remaining = setdiff(remaining, here, 'stable');
    end
    for k = 1:numel(remaining)
        warning("stb_load:varNotFound", "Variable '%s' not found in %s.", remaining{k}, stb_name(src));
    end
end

function S = merge_into(S, T)
    fn = fieldnames(T);
    for k = 1:numel(fn)
        S.(fn{k}) = T.(fn{k});
    end
end
