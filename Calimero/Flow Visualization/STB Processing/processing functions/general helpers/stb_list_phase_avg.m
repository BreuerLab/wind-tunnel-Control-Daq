function files = stb_list_phase_avg(phase_dir)
% STB_LIST_PHASE_AVG  Phase-averaged results in a folder, under GUI names.
%
%   files = stb_list_phase_avg(phase_dir)
%
%   Lists the new-layout flow-field files <stem>_<method>_fields.mat in
%   phase_dir (a ...\Processed Results\phase_avg\ folder) and returns them
%   as dir()-like structs whose .name is the GUI-style name
%   <sel>_phase_avg.mat that stb_resolve maps back:
%       <stem>_bin_fields.mat              -> <stem>_phase_avg.mat
%       <stem>_bin_hr_fields.mat           -> <stem>_hr_phase_avg.mat
%       <stem>_bin_RPCA_fields.mat         -> <stem>_RPCA_phase_avg.mat
%       <stem>_bin_hr_RPCA_fields.mat      -> <stem>_hr_RPCA_phase_avg.mat
%       <stem>_particle_..._fields.mat     -> <stem>_particle_..._phase_avg.mat
%   (.fields_file holds the real file). Legacy *_phase_avg.mat files are not
%   listed.

    files = struct('name', {}, 'folder', {}, 'date', {}, 'bytes', {}, ...
        'isdir', {}, 'datenum', {}, 'fields_file', {});
    files = files(:);   % column, like dir
    contents = dir(fullfile(char(phase_dir), "*_fields.mat"));
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
            suffix = erase(method, "bin");   % "", "_hr", "_RPCA", "_hr_RPCA"
            if ~ismember(suffix, ["", "_hr", "_RPCA", "_hr_RPCA"]), continue; end
        end
        e = contents(i);
        e.name = char(stem + suffix + "_phase_avg.mat");
        e.fields_file = fullfile(contents(i).folder, contents(i).name);
        files(end+1, 1) = e; %#ok<AGROW>
    end
end
