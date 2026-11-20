function T = compress_STB_files(folder, opts)
% COMPRESS_STB_FILES  Re-save processed .mat files compressed, to free disk space.
%
%   T = compress_STB_files(folder)
%   T = compress_STB_files(folder, opts)
%
%   Processed files are written uncompressed by default (save_STB_struct,
%   bools.compress_save = false) because compressing is slow. This loads
%   each .mat file in folder and saves it again as a compressed -v7.3 file,
%   keeping whichever is smaller. The contents are unchanged. Each file is
%   written to a temporary file first and only then replaces the original,
%   so an interrupted run leaves the original intact.
%
%   folder   e.g. "F:\...\Processed Results\phase_avg"
%   opts.pattern    file pattern, default "*.mat"
%   opts.recursive  include subfolders, default false
%   opts.dry_run    only list the files and sizes, default false
%
%   T  table of file, MB before, MB after (and whether it was replaced)
%
%   Needs enough free memory to load the largest file, and free disk space
%   for one compressed copy of it.

    if nargin < 2, opts = struct(); end
    if ~isfield(opts, 'pattern'),   opts.pattern = "*.mat"; end
    if ~isfield(opts, 'recursive'), opts.recursive = false; end
    if ~isfield(opts, 'dry_run'),   opts.dry_run = false; end

    if opts.recursive
        list = dir(fullfile(char(folder), "**", char(opts.pattern)));
    else
        list = dir(fullfile(char(folder), char(opts.pattern)));
    end
    list = list(~[list.isdir]);
    list = list(~endsWith({list.name}, ".tmp.mat"));

    n = numel(list);
    file = strings(n, 1); before = zeros(n, 1); after = zeros(n, 1); replaced = false(n, 1);
    for i = 1:n
        f = fullfile(list(i).folder, list(i).name);
        file(i) = string(f);
        before(i) = list(i).bytes / 2^20;
        after(i) = before(i);
        if opts.dry_run, continue; end
        fprintf("(%d/%d) %s  %.0f MB ... ", i, n, list(i).name, before(i));
        tic
        S = load(f); %#ok<NASGU>
        tmp = [f(1:end-4) '.tmp.mat'];
        save(tmp, '-struct', 'S', '-v7.3');
        clear S
        info = dir(tmp);
        new_mb = info.bytes / 2^20;
        if new_mb < before(i)
            movefile(tmp, f, 'f');
            after(i) = new_mb;
            replaced(i) = true;
            fprintf("%.0f MB (%.0f%%), %.0f s\n", new_mb, 100 * new_mb / before(i), toc);
        else
            delete(tmp);
            fprintf("no smaller, kept\n");
        end
    end
    T = table(file, before, after, replaced, 'VariableNames', ["file", "MB_before", "MB_after", "replaced"]);
    fprintf("Total: %.1f GB -> %.1f GB\n", sum(before) / 1024, sum(after) / 1024);
end
