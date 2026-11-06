function R = stb_resolve(file)
% STB_RESOLVE  Map a GUI-style phase-average path to the new file layout.
%
%   R = stb_resolve(file)
%
%   The GUIs still name a case's results the way the legacy single-file
%   layout did:
%       <root>\Processed Results\phase_avg\<sel>_phase_avg.mat           (fields)
%       <root>\Processed Results\phase_avg\<sel>_phase_avg_integral.mat  (integrals)
%   with <sel> = <case>[_<version>][_hr][_RPCA]          (DaVis binning)
%            or <case>[_<version>]_particle..._hr20      (particle tracks)
%   That path is "virtual": its contents now live in three files (see
%   stb_file_paths):
%       <case>[_<version>]_shared.mat
%       <case>[_<version>]_<method>_fields.mat
%       <case>[_<version>]_<method>_integral.mat
%   with <method> = bin, bin_hr, bin_RPCA, bin_hr_RPCA or particle_....
%
%   R.virtual  true if file has that form (else every other field is empty
%              and the stb_* helpers treat file as an ordinary file, e.g.
%              time-averaged files, which keep the old layout)
%   R.files    the new files in search order: a variable is read from the
%              first file holding it. Fields path: fields, shared,
%              integral. Integral path: integral, shared, fields.
%   R.primary  the file that must exist for the path to count as present
%              (fields file, or integral file for an integral path)
%   R.P        stb_file_paths result,  R.method, R.stem
%
%   See also stb_load, stb_who, stb_isfile, stb_list_phase_avg.

    file = string(file);
    R = struct('virtual', false, 'files', strings(0, 1), 'primary', "", ...
        'P', [], 'method', "", 'stem', "");

    [folder, name, ext] = fileparts(file);
    if ext ~= ".mat", return; end
    if endsWith(name, "_phase_avg_integral")
        is_integral = true;
        sel = extractBefore(name, strlength(name) - strlength("_phase_avg_integral") + 1);
    elseif endsWith(name, "_phase_avg")
        is_integral = false;
        sel = extractBefore(name, strlength(name) - strlength("_phase_avg") + 1);
    else
        return
    end

    % <root>\Processed Results\phase_avg[\RPCA]
    [parent, last] = fileparts(folder);
    if last == "RPCA", [parent, last] = fileparts(parent); end
    if lower(last) ~= "phase_avg", return; end
    save_root = parent;

    [stem, method] = stb_split_selection(sel);
    if strlength(method) == 0, return; end

    P = stb_file_paths(save_root, stem, "", method);
    R.virtual = true;
    R.P = P;
    R.method = method;
    R.stem = stem;
    if is_integral
        R.files = [P.integral; P.shared; P.fields];
        R.primary = P.integral;
    else
        R.files = [P.fields; P.shared; P.integral];
        R.primary = P.fields;
    end
end

function [stem, method] = stb_split_selection(sel)
% <case>[_<ver>][_hr][_RPCA] or <case>[_<ver>]_particle... -> stem, method
    stem = "";  method = "";
    parts = split(string(sel), "_");
    hz_idx = find(~cellfun(@isempty, regexp(cellstr(parts), '^\d+(\.\d+)?Hz$', 'once')), 1);
    if isempty(hz_idx), return; end
    rest = parts(hz_idx+1:end);

    j = find(startsWith(rest, "particle"), 1);
    if ~isempty(j)
        method = strjoin(rest(j:end), "_");
        rest = rest(1:j-1);
    else
        rpca = ~isempty(rest) && rest(end) == "RPCA";
        if rpca, rest(end) = []; end
        hr = ~isempty(rest) && rest(end) == "hr";
        if hr, rest(end) = []; end
        method = "bin";
        if hr, method = method + "_hr"; end
        if rpca, method = method + "_RPCA"; end
    end
    stem = strjoin(parts(1:hz_idx), "_");
    if ~isempty(rest), stem = stem + "_" + strjoin(rest, "_"); end
end
