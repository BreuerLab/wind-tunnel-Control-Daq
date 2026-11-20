function C = stb_time_avg_case(file_base)
% STB_TIME_AVG_CASE  Case struct of a time-averaged case (old layout:
% <base>.mat with the fields, <base>_integral.mat), shaped like
% stb_file_paths' so the GUIs and stb_load treat both kinds alike.
%   file_base   ...\time_avg\<case>_time_avg  (no extension)
    file_base = string(file_base);
    [folder, name] = fileparts(file_base);
    C = struct('kind', "time", 'dir', string(folder), 'stem', string(name), ...
        'method', "", 'shared', "", 'fields', file_base + ".mat", ...
        'integral', file_base + "_integral.mat", 'fit', "");
end
