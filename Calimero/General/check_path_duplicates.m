function dups = check_path_duplicates(opts)
% CHECK_PATH_DUPLICATES  Warn about function names that are on the MATLAB
% path more than once (one copy shadows the others).
%
%   check_path_duplicates()           % call right after the addpath lines
%   dups = check_path_duplicates()    % also return them
%   check_path_duplicates(struct('matlab', true))
%
% Looks at every folder on the path (plus the current folder, which MATLAB
% searches first), outside MATLAB's own toolboxes, and finds .m / .mlx /
% .p / MEX files whose names appear in more than one folder. It doesn't
% matter whether they came from one addpath(genpath(...)) or from several
% addpath calls: the whole path as it stands is checked. MATLAB uses the
% copy that comes first (current folder, then path order), which is the
% one marked "used" in the warning.
%
% opts.matlab : true = also flag your functions that shadow a MATLAB
%               toolbox function of the same name (slower: scans the
%               toolbox folders). Default false.
% opts.ignore : names that may legitimately repeat (default "Contents",
%               "startup")
% opts.quiet  : true = return dups without printing a warning
%
% dups : struct array, one entry per repeated name, in path order:
%   .name     function name
%   .folders  folders holding it (string array), the first is the one used

    if nargin < 1, opts = struct(); end
    if ~isfield(opts, 'matlab'), opts.matlab = false; end
    if ~isfield(opts, 'ignore'), opts.ignore = ["Contents", "startup"]; end
    if ~isfield(opts, 'quiet'), opts.quiet = false; end

    folders = string(strsplit(path, pathsep));
    folders = folders(strlength(folders) > 0);
    here = string(pwd);
    if ~any(strcmpi(folders, here))
        folders = [here, folders];          % current folder comes first
    else
        folders = [here, folders(~strcmpi(folders, here))];
    end

    mroot = string(matlabroot);
    in_matlab = startsWith(folders, mroot, 'IgnoreCase', ispc);
    user_folders = folders(~in_matlab);

    exts = [".m", ".mlx", ".p", "." + string(mexext)];

    % name -> folders that hold it, in path order
    map = containers.Map('KeyType', 'char', 'ValueType', 'any');
    order = strings(0);
    for i = 1:numel(user_folders)
        names = function_names(user_folders(i), exts);
        for n = names
            key = char(n);
            if isKey(map, key)
                map(key) = [map(key), user_folders(i)];
            else
                map(key) = user_folders(i);
                order(end + 1) = n; %#ok<AGROW>
            end
        end
    end

    if opts.matlab
        mw_names = strings(0);
        for f = folders(in_matlab)
            mw_names = [mw_names, function_names(f, exts)]; %#ok<AGROW>
        end
        mw_names = unique(mw_names);
        for n = reshape(intersect(order, mw_names, 'stable'), 1, [])
            map(char(n)) = [map(char(n)), "(MATLAB toolbox)"];
        end
    end

    dups = struct('name', {}, 'folders', {});
    for n = order
        if any(n == string(opts.ignore)), continue; end
        f = map(char(n));
        if numel(f) > 1
            dups(end + 1) = struct('name', n, 'folders', f); %#ok<AGROW>
        end
    end

    if ~opts.quiet && ~isempty(dups)
        msg = sprintf('%d function name(s) are on the path more than once; MATLAB uses the first copy of each:', numel(dups));
        for k = 1:numel(dups)
            msg = [msg, sprintf('\n  %s', dups(k).name)]; %#ok<AGROW>
            for j = 1:numel(dups(k).folders)
                if j == 1, tag = 'used'; else, tag = 'hidden'; end
                msg = [msg, sprintf('\n      %-6s %s', tag, dups(k).folders(j))]; %#ok<AGROW>
            end
        end
        warning('check_path_duplicates:duplicates', '%s', msg);
    end

    if nargout == 0
        clear dups
    end
end

% Names of the functions/scripts in one folder (each name once, even if
% e.g. both name.m and name.mexw64 are there)
function names = function_names(folder, exts)
    names = strings(0);
    d = dir(folder);
    if isempty(d), return; end
    d = d(~[d.isdir]);
    if isempty(d), return; end
    [~, base, ext] = fileparts(string({d.name}));
    names = reshape(unique(base(ismember(lower(ext), exts)), 'stable'), 1, []);
end
