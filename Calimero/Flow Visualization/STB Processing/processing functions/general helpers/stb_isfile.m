function tf = stb_isfile(file)
% STB_ISFILE  isfile for processed STB files.
%
%   For a GUI-style phase-average path (see stb_resolve): true if the
%   case's new fields file (or integral file, for *_phase_avg_integral.mat)
%   exists. The legacy combined files are ignored. Any other path: isfile.
%   file may be a string array (element-wise, like isfile).

    file = string(file);
    tf = false(size(file));
    for k = 1:numel(file)
        R = stb_resolve(file(k));
        if R.virtual
            tf(k) = isfile(R.primary);
        else
            tf(k) = isfile(file(k));
        end
    end
end
