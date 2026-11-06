function info = stb_dir(file)
% STB_DIR  dir() of a processed STB file, for its date and size.
% For a GUI-style phase-average path (see stb_resolve), the case's new
% fields file (integral file for *_phase_avg_integral.mat); else dir(file).
    R = stb_resolve(file);
    if R.virtual
        info = dir(char(R.primary));
    else
        info = dir(char(file));
    end
end
