% Author: Ronan Gissler (written with Claude)
% Last updated: October 2026
%
% Read-only inventory of STB data roots, to see what the older data set
% ("STB Round 1", old flapper) saved compared with the current one, before
% making the UIs read both. For each root it lists:
%   - the top-level folders
%   - Processed Results: the cases in phase_avg\, phase_avg\RPCA\ and
%     time_avg\, and which variables their .mat / _integral.mat files hold
%   - Force Measurements: the folder layout and the variables in the
%     processed load cell files
% and then, for every kind of file, the variables the first (reference)
% root has that the others lack. Nothing is written except the report.
%
% Run it, then send the report file (saved next to this script).

clear
cd(fileparts(mfilename('fullpath')));

roots = [
    "F:\"                                        % reference (new flapper)
    "C:\Users\rgissler\Documents\STB Round 1\"   % old flapper
    ];

report_file = fullfile(pwd, "stb_inventory_" + string(datetime("now", Format="yyyy_MM_dd_HH_mm_ss")) + ".txt");
fid = fopen(report_file, "w");
out = @(varargin) log_line(fid, varargin{:});

% kind name -> containers.Map(variable -> number of files holding it) per root
kinds = ["phase_avg", "phase_avg_integral", "phase_avg_RPCA", "time_avg",...
         "time_avg_integral", "load_cell"];
inv = cell(numel(roots), 1);

for r = 1:numel(roots)
    root = roots(r);
    out("\n################################################################")
    out("ROOT: %s", root)
    out("################################################################")
    if ~isfolder(root)
        out("  (folder not found)")
        continue
    end
    top = dir(root);
    top = top([top.isdir] & ~startsWith({top.name}, "."));
    out("Top-level folders: %s", strjoin(string({top.name}), ", "))

    S = struct();
    for k = kinds
        S.(k) = struct('counts', containers.Map(), 'n', 0, 'cases', strings(0, 1));
    end

    % ---- Processed Results ----
    pr = fullfile(root, "Processed Results");
    groups = {fullfile(pr, "phase_avg"), "phase_avg", "_phase_avg";
              fullfile(pr, "phase_avg", "RPCA"), "phase_avg_RPCA", "_phase_avg";
              fullfile(pr, "time_avg"), "time_avg", "_time_avg"};
    for g = 1:size(groups, 1)
        folder = groups{g, 1}; kind = groups{g, 2}; suffix = groups{g, 3};
        files = dir(fullfile(folder, "*.mat"));
        out("\n%s: %d .mat files", folder, numel(files))
        for f = 1:numel(files)
            name = string(files(f).name);
            this_kind = kind;
            if endsWith(name, "_integral.mat")
                this_kind = kind + "_integral";
                if ~isfield(S, this_kind), this_kind = kind; end
            else
                S.(kind).cases(end+1) = extractBefore(name, suffix);
            end
            S.(this_kind) = add_vars(S.(this_kind), fullfile(folder, name), out);
        end
        if ~isempty(S.(kind).cases)
            out("  cases: %s", strjoin(unique(S.(kind).cases), ", "))
        end
    end

    % ---- Force Measurements ----
    fm = fullfile(root, "Force Measurements");
    out("\n%s", fm)
    if isfolder(fm)
        type_dirs = dir(fm);
        type_dirs = type_dirs([type_dirs.isdir] & ~startsWith({type_dirs.name}, "."));
        for t = 1:numel(type_dirs)
            proc = dir(fullfile(fm, type_dirs(t).name, "**", "processed data", "*.mat"));
            out("  %-28s %3d processed files", type_dirs(t).name, numel(proc))
            for f = 1:numel(proc)
                S.load_cell = add_vars(S.load_cell, fullfile(proc(f).folder, proc(f).name), out);
            end
        end
    else
        out("  (folder not found)")
    end

    % ---- variables per kind of file ----
    for k = kinds
        out("\n[%s] %d files", k, S.(k).n)
        if S.(k).n == 0, continue, end
        names = string(keys(S.(k).counts));
        counts = cell2mat(values(S.(k).counts));
        for i = 1:numel(names)
            tag = "";
            if counts(i) < S.(k).n, tag = sprintf("  (only %d of %d files)", counts(i), S.(k).n); end
            out("  %s%s", names(i), tag)
        end
    end
    inv{r} = S;
end

% ---- what the reference root has that the others lack ----
out("\n################################################################")
out("DIFFERENCES relative to %s", roots(1))
out("################################################################")
for r = 2:numel(roots)
    if isempty(inv{r}) || isempty(inv{1}), continue, end
    out("\n%s", roots(r))
    for k = kinds
        A = inv{1}.(k); B = inv{r}.(k);
        if A.n == 0 && B.n == 0, continue, end
        a = string(keys(A.counts)); b = string(keys(B.counts));
        missing = setdiff(a, b); extra = setdiff(b, a);
        out("  [%s] files: %d vs %d", k, A.n, B.n)
        if ~isempty(missing), out("    missing here: %s", strjoin(missing, ", ")), end
        if ~isempty(extra),   out("    only here:    %s", strjoin(extra, ", ")), end
    end
end

fclose(fid);
fprintf("\nReport saved to %s\n", report_file);

function S = add_vars(S, file, out)
    S.n = S.n + 1;
    try
        v = string(who('-file', file));
    catch ME
        out("  could not read %s: %s", file, ME.message)
        return
    end
    for i = 1:numel(v)
        if isKey(S.counts, v(i))
            S.counts(v(i)) = S.counts(v(i)) + 1;
        else
            S.counts(v(i)) = 1;
        end
    end
end

function log_line(fid, fmt, varargin)
    s = sprintf(fmt, varargin{:});
    fprintf("%s\n", s);
    fprintf(fid, "%s\n", s);
end
