function T = convert_legacy_STB_files(save_root, opts)
% CONVERT_LEGACY_STB_FILES  Write the new per-case file layout
% (stb_file_paths) from existing combined phase-average files:
%   <case>[_<v>]_phase_avg.mat + <case>[_<v>]_phase_avg_integral.mat
%   ->  <case>[_<ver>]_shared.mat
%       <case>[_<ver>]_<method>_phase_avg.mat
%       <case>[_<ver>]_<method>_integral.mat
% The old files are left in place.
%
%   T = convert_legacy_STB_files(save_root)
%   T = convert_legacy_STB_files(save_root, opts)
%
%   save_root : e.g. "F:\Processed Results\" (its phase_avg\ and
%               phase_avg\RPCA\ folders and the root are searched)
%   opts.cases     : only these case names (default: all found)
%   opts.dry_run   : true = only list what would be converted (default false)
%   opts.overwrite : true = redo files already converted (default false)
%
% Legacy version v -> binning variant ver and method:
%   ""             -> ver "",       method "bin"
%   "hr"           -> ver "",       method "bin_hr"
%   "coarse_hr"    -> ver "coarse", method "bin_hr"
%   RPCA files     -> method "..._RPCA"
%   "particle_pool_hr20"        -> ver "",       method "particle_pool_hr20"
%   "coarse_particle_pool_hr20" -> ver "coarse", method "particle_pool_hr20"
% The shared file is taken from a binned method's files when there is one.
%
% T: table of the files found (legacy file, case, ver, method, status).

    if nargin < 2, opts = struct(); end
    if ~isfield(opts, 'cases'), opts.cases = []; end
    if ~isfield(opts, 'dry_run'), opts.dry_run = false; end
    if ~isfield(opts, 'overwrite'), opts.overwrite = false; end
    save_root = string(save_root);
    case_names = string(get_PIV_paths());
    [~, idx] = sort(strlength(case_names), 'descend');   % longest names first, so
    case_names = case_names(idx);                         % x2_..._8Hz_v2 beats x2_..._8Hz

    dirs = [fullfile(save_root, "phase_avg"), fullfile(save_root, "phase_avg", "RPCA"), save_root];
    files = strings(0, 1);
    for d = dirs
        f = dir(fullfile(d, "*_phase_avg.mat"));
        files = [files; string(fullfile({f.folder}, {f.name}))']; %#ok<AGROW>
    end

    rows = {};
    for k = 1:numel(files)
        [~, name] = fileparts(files(k));
        stem = extractBefore(name, strlength(name) - strlength("_phase_avg") + 1);
        if endsWith(stem, "_shared"), continue; end
        cname = case_names(find(stem == case_names | startsWith(stem, case_names + "_"), 1));
        if isempty(cname), continue; end
        if ~isempty(opts.cases) && ~ismember(cname, string(opts.cases)), continue; end
        vars = who('-file', char(files(k)));
        if ismember('method', vars), continue; end      % already new layout
        if ismember('fitOpts', vars), continue; end     % particle fit (particlePhaseAverage), not a phase average
        v = extractAfter(stem, strlength(cname));
        v = regexprep(v, "^_", "");
        [ver, method] = legacy_version_to_method(v);
        rows(end+1, :) = {files(k), cname, ver, method, ""}; %#ok<AGROW>
    end
    T = cell2table(rows, 'VariableNames', {'legacy_file', 'case_name', 'version', 'method', 'status'});
    if isempty(T), disp("No legacy phase-average files found."); return; end
    % binned methods first, so they write the shared file
    [~, o] = sort(~startsWith(T.method, "bin"));  T = T(o, :);

    for k = 1:height(T)
        P = stb_file_paths(save_root, T.case_name(k), T.version(k), T.method(k));
        if ~opts.overwrite && isfile(P.fields) && isfile(P.integral)
            T.status(k) = "already converted";  continue
        end
        if opts.dry_run
            T.status(k) = "would convert -> " + P.fields;  continue
        end
        try
            convert_one(T.legacy_file(k), P, T.version(k), T.method(k));
            T.status(k) = "converted";
        catch err
            T.status(k) = "FAILED: " + err.message;
            fprintf(2, 'FAILED %s: %s\n', T.legacy_file(k), err.message);
        end
    end
    disp(T(:, {'case_name', 'version', 'method', 'status'}))
end

% -------------------------------------------------------------------------
function [ver, method] = legacy_version_to_method(v)
    v = string(v);
    if contains(v, "particle")
        i = strfind(v, "particle");
        method = extractAfter(v, i(1) - 1);
        ver = regexprep(extractBefore(v, i(1)), "_$", "");
        return
    end
    rpca = endsWith(v, "RPCA");
    v = regexprep(v, "_?RPCA$", "");
    hr = v == "hr" || endsWith(v, "_hr");
    v = regexprep(v, "_?hr$", "");
    method = "bin";
    if hr, method = method + "_hr"; end
    if rpca, method = method + "_RPCA"; end
    ver = v;
end

function convert_one(legacy_file, P, ver, method)
    fprintf('Converting %s -> %s (%s)\n', legacy_file, P.stem, method);
    S = load(legacy_file);
    integral_file = replace(legacy_file, "_phase_avg.mat", "_phase_avg_integral.mat");
    I = struct();
    if isfile(integral_file), I = load(integral_file); end

    % DAQ fields live in the legacy integral file
    [shared_names, before_avg] = stb_shared_names();
    daq = shared_names(find(strcmp(shared_names, 'freq_avg')):end);
    Daq = struct();
    for k = 1:numel(daq)
        if isfield(I, daq{k}), Daq.(daq{k}) = I.(daq{k}); I = rmfield(I, daq{k}); end
    end
    [Sh, Sf, Sba] = split_phase_avg_struct(S, Daq);
    clear S
    if ~isfield(Sh, 'frame_table')
        try, Sh.frame_table = get_case_frames(Sh.PIV_case_name); catch, end
    end
    Sf.method = method;  Sf.version = ver;
    Si = merge_stb_structs(I, Sba);
    Si.method = method;
    if isfield(Sh, 'PIV_case_name'), Si.PIV_case_name = string(Sh.PIV_case_name); end

    if ~isfolder(P.dir), mkdir(P.dir); end
    so = struct('compress_save', false);
    if ~isfile(P.shared) || startsWith(method, "bin")
        save_STB_struct(P.shared, Sh, so);
    end
    save_STB_struct(P.fields, Sf, so);
    if ~isempty(fieldnames(I)) || ~isempty(fieldnames(Sba))
        save_STB_struct(P.integral, Si, so);
    end
end
