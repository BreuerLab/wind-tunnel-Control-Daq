function files = stb_case_files(src, first)
% STB_CASE_FILES  The files that make up a processed STB case.
%
%   files = stb_case_files(src)               string column, existing files only
%   files = stb_case_files(src, "integral")   integral file first
%
%   src is either
%     - a case struct: stb_file_paths output (phase average, new layout:
%       .fields, .integral, .shared) or stb_time_avg_case output; or
%     - a plain .mat path (one file).
%   Order is the search order of stb_load / stb_who: fields, integral,
%   shared. Only bin_placement is in more than one of them with different
%   values (fields: the method's, e.g. HR; shared: the frames'), so the
%   fields file comes first.

    if nargin < 2, first = "fields"; end
    if isstruct(src)
        order = ["fields", "integral", "shared"];
        if string(first) == "integral", order = ["integral", "fields", "shared"]; end
        files = strings(0, 1);
        for f = order
            if isfield(src, f) && strlength(string(src.(f))) > 0
                files(end+1, 1) = string(src.(f)); %#ok<AGROW>
            end
        end
    else
        files = string(src);
    end
    files = files(isfile(files));
end
