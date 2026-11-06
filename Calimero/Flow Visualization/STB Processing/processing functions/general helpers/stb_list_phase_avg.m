function cases = stb_list_phase_avg(phase_dir)
% STB_LIST_PHASE_AVG  Phase-averaged cases in a ...\Processed Results\phase_avg\ folder.
%
%   cases = stb_list_phase_avg(phase_dir)
%
%   One entry per <stem>_<method>_fields.mat (column struct array):
%     .label   selection label the GUIs list and pick cases by:
%              <stem>              method bin
%              <stem>_hr           bin_hr       (HR button)
%              <stem>_RPCA         bin_RPCA     (RPCA button)
%              <stem>_hr_RPCA      bin_hr_RPCA
%              <stem>_<method>     particle methods, e.g. _particle_pool_hr20
%              where <stem> = <case>[_<version>]
%     .stem, .method
%     .files   case struct (stb_file_paths): .shared, .fields, .integral
%   A label is only a name for the selection; the files come from .files.

    cases = struct('label', {}, 'stem', {}, 'method', {}, 'files', {});
    cases = cases(:);
    phase_dir = string(phase_dir);
    save_root = fileparts(regexprep(char(phase_dir), '[\\/]+$', ''));   % ...\Processed Results
    contents = dir(fullfile(phase_dir, "*_fields.mat"));
    for i = 1:numel(contents)
        name = string(contents(i).name);
        base = extractBefore(name, strlength(name) - strlength("_fields.mat") + 1);
        parts = split(base, "_");
        hz_idx = find(~cellfun(@isempty, regexp(cellstr(parts), '^\d+(\.\d+)?Hz$', 'once')), 1);
        if isempty(hz_idx), continue; end
        j = hz_idx + find(parts(hz_idx+1:end) == "bin" | startsWith(parts(hz_idx+1:end), "particle"), 1);
        if isempty(j), continue; end
        stem = strjoin(parts(1:j-1), "_");
        method = strjoin(parts(j:end), "_");
        if startsWith(method, "particle")
            suffix = "_" + method;
        else
            suffix = extractAfter(method, "bin");   % "", "_hr", "_RPCA", "_hr_RPCA"
            if ~ismember(suffix, ["", "_hr", "_RPCA", "_hr_RPCA"]), continue; end
        end
        P = stb_file_paths(save_root, stem, "", method);
        P.kind = "phase";
        cases(end+1, 1) = struct('label', stem + suffix, 'stem', stem, ...
            'method', method, 'files', P); %#ok<AGROW>
    end
end
