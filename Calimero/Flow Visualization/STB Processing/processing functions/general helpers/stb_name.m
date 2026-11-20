function name = stb_name(src)
% STB_NAME  Name of a processed STB case for messages and old-case checks:
% <stem>_<method> for a phase-average case struct, <case>_time_avg for a
% time-averaged one, the file name for a path.
    if isstruct(src)
        name = string(src.stem);
        if isfield(src, 'method') && strlength(string(src.method)) > 0
            name = name + "_" + string(src.method);
        end
    else
        [~, name] = fileparts(string(src));
    end
end
